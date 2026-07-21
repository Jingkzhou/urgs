use keyring::Entry;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tauri::{AppHandle, Emitter, Manager, State};
use tauri_plugin_shell::process::{CommandChild, CommandEvent};
use tauri_plugin_shell::ShellExt;
use tokio::sync::{oneshot, Mutex as AsyncMutex};

const GROK_EVENT_NAME: &str = "grok-event";
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);
const INITIALIZE_TIMEOUT: Duration = Duration::from_secs(90);
const MODEL_PROVIDER_FILE: &str = "model-providers.json";
const MODEL_CREDENTIAL_SERVICE: &str = "com.urgs.desktop.grok-model";
const MODEL_KEY_AUTHORIZATION_REQUIRED: &str = "MODEL_KEY_AUTHORIZATION_REQUIRED:";
static PROCESS_SEQUENCE: AtomicU64 = AtomicU64::new(1);
static MODEL_API_KEY_CACHE: OnceLock<Mutex<HashMap<String, String>>> = OnceLock::new();
#[cfg(target_os = "macos")]
static MACOS_KEYCHAIN_READ_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

fn request_timeout(method: &str) -> Duration {
    match method {
        "session/prompt" => Duration::from_secs(60 * 60),
        "initialize" => INITIALIZE_TIMEOUT,
        _ => REQUEST_TIMEOUT,
    }
}

fn initialize_client_meta(rules: Option<&str>) -> Value {
    let mut meta = json!({
        "clientType": "urgs-ark-desktop",
        "clientVersion": env!("CARGO_PKG_VERSION"),
        "startupHints": {
            "nonInteractive": false,
            "skipGitStatus": true,
            "skipProjectLayout": true
        }
    });
    if let Some(rules) = rules.filter(|value| !value.trim().is_empty()) {
        meta["rules"] = json!(rules);
    }
    meta
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokRuntimeStatus {
    pub available: bool,
    pub authenticated: bool,
    pub version: Option<String>,
    pub grok_home: String,
    pub message: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokSession {
    pub session_id: String,
    pub workspace: String,
    pub process_id: String,
    pub available_commands: Vec<GrokAvailableCommand>,
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct GrokAvailableCommand {
    pub name: String,
    pub description: String,
    pub input_hint: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct GrokAcpOptions {
    pub reasoning_effort: Option<String>,
    pub permission_mode: Option<String>,
    pub sandbox_profile: Option<String>,
    pub always_approve: Option<bool>,
    pub reauth: Option<bool>,
    pub agent_profile: Option<String>,
    pub plugin_dirs: Option<Vec<String>>,
    pub leader_mode: Option<String>,
    pub grok_ws_origin: Option<String>,
    pub grok_ws_url: Option<String>,
    pub cli_chat_proxy_url: Option<String>,
    pub xai_api_base_url: Option<String>,
    pub debug: Option<bool>,
    pub debug_file: Option<String>,
    pub leader_socket: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokCliResult {
    pub arguments: Vec<String>,
    pub success: bool,
    pub exit_code: Option<i32>,
    pub stdout: String,
    pub stderr: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokCliServiceInfo {
    pub id: String,
    pub arguments: Vec<String>,
    pub pid: u32,
    pub alive: bool,
    pub started_at: u64,
    pub exit_code: Option<i32>,
    pub stdout: String,
    pub stderr: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokConfigFile {
    pub scope: String,
    pub kind: String,
    pub path: String,
    pub exists: bool,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokModelProvider {
    pub id: String,
    pub name: String,
    pub model: String,
    pub base_url: String,
    pub api_backend: String,
    pub auth_scheme: String,
    pub context_window: u64,
    pub enabled: bool,
    #[serde(default)]
    pub has_api_key: bool,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokModelProviderInput {
    pub id: String,
    pub name: String,
    pub model: String,
    pub base_url: String,
    pub api_backend: String,
    pub auth_scheme: String,
    pub context_window: u64,
    pub enabled: bool,
    pub api_key: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct GrokBridgeEvent {
    event_type: String,
    payload: Value,
}

#[derive(Clone)]
struct PendingPermission {
    session_id: String,
    request_id: Value,
}

#[derive(Clone)]
struct PendingUserQuestion {
    session_id: String,
    request_id: Value,
}

#[derive(Clone)]
struct PendingPlanApproval {
    session_id: String,
    request_id: Value,
}

pub struct GrokRuntimeState {
    prepared_process: Mutex<Option<Arc<GrokProcess>>>,
    session_processes: Mutex<HashMap<String, Arc<GrokProcess>>>,
    cli_services: Mutex<HashMap<String, Arc<GrokCliService>>>,
    cli_service_sequence: AtomicU64,
}

impl Default for GrokRuntimeState {
    fn default() -> Self {
        Self {
            prepared_process: Mutex::new(None),
            session_processes: Mutex::new(HashMap::new()),
            cli_services: Mutex::new(HashMap::new()),
            cli_service_sequence: AtomicU64::new(1),
        }
    }
}

struct GrokCliService {
    id: String,
    arguments: Vec<String>,
    pid: u32,
    child: Mutex<Option<CommandChild>>,
    alive: AtomicBool,
    started_at: u64,
    exit_code: Mutex<Option<i32>>,
    stdout: Mutex<String>,
    stderr: Mutex<String>,
    retain_full_output: bool,
}

impl GrokCliService {
    fn info(&self) -> GrokCliServiceInfo {
        GrokCliServiceInfo {
            id: self.id.clone(),
            arguments: self.arguments.clone(),
            pid: self.pid,
            alive: self.alive.load(Ordering::Relaxed),
            started_at: self.started_at,
            exit_code: self.exit_code.lock().ok().and_then(|value| *value),
            stdout: self
                .stdout
                .lock()
                .map(|value| value.clone())
                .unwrap_or_default(),
            stderr: self
                .stderr
                .lock()
                .map(|value| value.clone())
                .unwrap_or_default(),
        }
    }

    fn append_output(target: &Mutex<String>, line: &[u8], retain_full_output: bool) {
        if let Ok(mut output) = target.lock() {
            if !output.is_empty() {
                output.push('\n');
            }
            output.push_str(String::from_utf8_lossy(line).trim());
            if !retain_full_output && output.len() > 100_000 {
                let desired_start = output.len().saturating_sub(80_000);
                let keep_from = output
                    .char_indices()
                    .find_map(|(index, _)| (index >= desired_start).then_some(index))
                    .unwrap_or(output.len());
                output.drain(..keep_from);
            }
        }
    }

    fn stop(&self) -> Result<(), String> {
        let child = self
            .child
            .lock()
            .map_err(|_| "Grok CLI 服务锁不可用".to_string())?
            .take();
        if let Some(child) = child {
            child
                .kill()
                .map_err(|error| format!("停止 Grok CLI 服务失败: {error}"))?;
        }
        self.alive.store(false, Ordering::Relaxed);
        Ok(())
    }
}

struct GrokProcess {
    process_id: String,
    launch_key: String,
    child: Mutex<Option<CommandChild>>,
    stderr: Mutex<String>,
    pending_requests: Mutex<HashMap<u64, oneshot::Sender<Result<Value, String>>>>,
    pending_permissions: Mutex<Vec<PendingPermission>>,
    pending_user_questions: Mutex<Vec<PendingUserQuestion>>,
    pending_plan_approvals: Mutex<Vec<PendingPlanApproval>>,
    available_commands: Mutex<Vec<GrokAvailableCommand>>,
    request_sequence: AtomicU64,
    initialized: AsyncMutex<bool>,
    replaying_session: AtomicBool,
    alive: AtomicBool,
}

impl GrokProcess {
    fn new(child: CommandChild, launch_key: String) -> Self {
        Self {
            process_id: format!(
                "runtime-{}",
                PROCESS_SEQUENCE.fetch_add(1, Ordering::Relaxed)
            ),
            launch_key,
            child: Mutex::new(Some(child)),
            stderr: Mutex::new(String::new()),
            pending_requests: Mutex::new(HashMap::new()),
            pending_permissions: Mutex::new(Vec::new()),
            pending_user_questions: Mutex::new(Vec::new()),
            pending_plan_approvals: Mutex::new(Vec::new()),
            available_commands: Mutex::new(Vec::new()),
            request_sequence: AtomicU64::new(1),
            initialized: AsyncMutex::new(false),
            replaying_session: AtomicBool::new(false),
            alive: AtomicBool::new(true),
        }
    }

    fn write_json(&self, message: Value) -> Result<(), String> {
        let serialized = serde_json::to_vec(&message)
            .map_err(|error| format!("序列化 Grok ACP 消息失败: {error}"))?;
        let mut child = self
            .child
            .lock()
            .map_err(|_| "Grok 进程锁不可用".to_string())?;
        let child = child
            .as_mut()
            .ok_or_else(|| "Grok 本地进程已经停止".to_string())?;

        child
            .write(&serialized)
            .and_then(|_| child.write(b"\n"))
            .map_err(|error| format!("发送 Grok ACP 消息失败: {error}"))
    }

    async fn request(&self, method: &str, params: Value) -> Result<Value, String> {
        let id = self.request_sequence.fetch_add(1, Ordering::Relaxed);
        let (sender, receiver) = oneshot::channel();
        self.pending_requests
            .lock()
            .map_err(|_| "Grok 请求队列锁不可用".to_string())?
            .insert(id, sender);

        let message = json!({
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params,
        });
        if let Err(error) = self.write_json(message) {
            self.pending_requests
                .lock()
                .map_err(|_| "Grok 请求队列锁不可用".to_string())?
                .remove(&id);
            return Err(error);
        }

        match tokio::time::timeout(request_timeout(method), receiver).await {
            Ok(Ok(result)) => result,
            Ok(Err(_)) => Err("Grok 本地进程在响应前退出".to_string()),
            Err(_) => {
                self.pending_requests
                    .lock()
                    .map_err(|_| "Grok 请求队列锁不可用".to_string())?
                    .remove(&id);
                Err(format!("等待 Grok {method} 响应超时"))
            }
        }
    }

    fn notify(&self, method: &str, params: Value) -> Result<(), String> {
        self.write_json(json!({
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
        }))
    }

    async fn initialize(&self, rules: Option<&str>) -> Result<(), String> {
        let mut initialized = self.initialized.lock().await;
        if *initialized {
            return Ok(());
        }

        let response = self
            .request(
                "initialize",
                json!({
                    "protocolVersion": 1,
                    "clientCapabilities": {
                        "fs": {},
                        "terminal": false
                    },
                    "_meta": initialize_client_meta(rules)
                }),
            )
            .await?;
        self.replace_available_commands(available_commands_from_initialize(&response));
        let method_id = select_auth_method(&response)?;

        self.request(
            "authenticate",
            json!({
                "methodId": method_id,
                "_meta": { "headless": false }
            }),
        )
        .await
        .map_err(|error| format!("Grok 登录不可用，请先点击“登录 Grok”：{error}"))?;

        *initialized = true;
        Ok(())
    }

    async fn discover_available_commands(
        &self,
        workspace: &Path,
    ) -> Result<Vec<GrokAvailableCommand>, String> {
        let response = self
            .request(
                "initialize",
                json!({
                    "protocolVersion": 1,
                    "clientCapabilities": {
                        "fs": {},
                        "terminal": false
                    },
                    "_meta": initialize_client_meta(None)
                }),
            )
            .await?;
        let initialize_commands = available_commands_from_initialize(&response);
        let response = self
            .request(
                "_x.ai/commands/list",
                json!({ "cwd": workspace.to_string_lossy() }),
            )
            .await?;
        let discovered_commands = available_commands_from_list(&response);
        Ok(if discovered_commands.is_empty() {
            initialize_commands
        } else {
            discovered_commands
        })
    }

    fn replace_available_commands(&self, commands: Vec<GrokAvailableCommand>) {
        if let Ok(mut available_commands) = self.available_commands.lock() {
            *available_commands = commands;
        }
    }

    fn available_commands(&self) -> Vec<GrokAvailableCommand> {
        self.available_commands
            .lock()
            .map(|commands| commands.clone())
            .unwrap_or_default()
    }

    fn resolve_response(&self, id: u64, message: Value) {
        let sender = self
            .pending_requests
            .lock()
            .ok()
            .and_then(|mut pending| pending.remove(&id));
        let Some(sender) = sender else {
            return;
        };

        let result = if let Some(error) = message.get("error") {
            Err(format_rpc_error(error))
        } else {
            Ok(message.get("result").cloned().unwrap_or(Value::Null))
        };
        let _ = sender.send(result);
    }

    fn remember_stderr(&self, message: &str) {
        if message.trim().is_empty() {
            return;
        }
        if let Ok(mut stderr) = self.stderr.lock() {
            if !stderr.is_empty() {
                stderr.push('\n');
            }
            stderr.push_str(message.trim());
            if stderr.len() > 8_000 {
                let desired_start = stderr.len().saturating_sub(6_000);
                let keep_from = stderr
                    .char_indices()
                    .find_map(|(index, _)| (index >= desired_start).then_some(index))
                    .unwrap_or(stderr.len());
                stderr.drain(..keep_from);
            }
        }
    }

    fn fail_pending_requests(&self, message: String) {
        let pending = self
            .pending_requests
            .lock()
            .map(|mut requests| {
                requests
                    .drain()
                    .map(|(_, sender)| sender)
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();
        for sender in pending {
            let _ = sender.send(Err(message.clone()));
        }
    }

    fn termination_error(&self, code: Option<i32>) -> String {
        let stderr = self
            .stderr
            .lock()
            .map(|value| value.trim().to_string())
            .unwrap_or_default();
        let status = code.map_or_else(|| "未知状态".to_string(), |code| format!("状态码 {code}"));
        if stderr.is_empty() {
            format!("Grok 本地进程已退出（{status}）")
        } else {
            format!("Grok 本地进程已退出（{status}）：{stderr}")
        }
    }

    fn remember_permission(&self, session_id: String, request_id: Value) {
        if let Ok(mut pending) = self.pending_permissions.lock() {
            pending.push(PendingPermission {
                session_id,
                request_id,
            });
        }
    }

    fn clear_permission(&self, request_id: &Value) {
        if let Ok(mut pending) = self.pending_permissions.lock() {
            pending.retain(|permission| permission.request_id != *request_id);
        }
    }

    fn cancel_permissions(&self, session_id: &str) -> Vec<Value> {
        let Ok(mut pending) = self.pending_permissions.lock() else {
            return Vec::new();
        };
        let mut cancelled = Vec::new();
        pending.retain(|permission| {
            if permission.session_id == session_id {
                cancelled.push(permission.request_id.clone());
                false
            } else {
                true
            }
        });
        cancelled
    }

    fn remember_user_question(&self, session_id: String, request_id: Value) {
        if let Ok(mut pending) = self.pending_user_questions.lock() {
            pending.retain(|question| question.request_id != request_id);
            pending.push(PendingUserQuestion {
                session_id,
                request_id,
            });
        }
    }

    fn clear_user_question(&self, request_id: &Value) {
        if let Ok(mut pending) = self.pending_user_questions.lock() {
            pending.retain(|question| question.request_id != *request_id);
        }
    }

    fn cancel_user_questions(&self, session_id: &str) -> Vec<Value> {
        let Ok(mut pending) = self.pending_user_questions.lock() else {
            return Vec::new();
        };
        let mut cancelled = Vec::new();
        pending.retain(|question| {
            if question.session_id == session_id {
                cancelled.push(question.request_id.clone());
                false
            } else {
                true
            }
        });
        cancelled
    }

    fn remember_plan_approval(&self, session_id: String, request_id: Value) {
        if let Ok(mut pending) = self.pending_plan_approvals.lock() {
            pending.retain(|approval| approval.request_id != request_id);
            pending.push(PendingPlanApproval {
                session_id,
                request_id,
            });
        }
    }

    fn clear_plan_approval(&self, request_id: &Value) {
        if let Ok(mut pending) = self.pending_plan_approvals.lock() {
            pending.retain(|approval| approval.request_id != *request_id);
        }
    }

    fn cancel_plan_approvals(&self, session_id: &str) -> Vec<Value> {
        let Ok(mut pending) = self.pending_plan_approvals.lock() else {
            return Vec::new();
        };
        let mut cancelled = Vec::new();
        pending.retain(|approval| {
            if approval.session_id == session_id {
                cancelled.push(approval.request_id.clone());
                false
            } else {
                true
            }
        });
        cancelled
    }

    fn stop(&self) {
        self.alive.store(false, Ordering::Relaxed);
        let child = self.child.lock().ok().and_then(|mut child| child.take());
        if let Some(child) = child {
            let _ = child.kill();
        }
    }
}

fn parse_available_commands(value: Option<&Value>) -> Vec<GrokAvailableCommand> {
    let Some(commands) = value.and_then(Value::as_array) else {
        return Vec::new();
    };
    let parsed = commands
        .iter()
        .filter_map(|command| {
            let name = command.get("name")?.as_str()?.trim();
            if name.is_empty() || name.len() > 128 {
                return None;
            }
            let description = command
                .get("description")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .trim();
            let input_hint = command
                .get("input")
                .and_then(|input| input.get("hint"))
                .or_else(|| command.get("argumentHint"))
                .and_then(Value::as_str)
                .map(str::trim)
                .filter(|hint| !hint.is_empty())
                .map(ToString::to_string);
            Some(GrokAvailableCommand {
                name: name.to_string(),
                description: description.to_string(),
                input_hint,
            })
        })
        .collect::<Vec<_>>();
    parsed.into_iter().fold(Vec::new(), |mut unique, command| {
        if !unique
            .iter()
            .any(|existing: &GrokAvailableCommand| existing.name == command.name)
        {
            unique.push(command);
        }
        unique
    })
}

fn available_commands_from_initialize(response: &Value) -> Vec<GrokAvailableCommand> {
    parse_available_commands(
        response
            .get("_meta")
            .or_else(|| response.get("meta"))
            .and_then(|meta| meta.get("availableCommands")),
    )
}

fn available_commands_from_list(response: &Value) -> Vec<GrokAvailableCommand> {
    parse_available_commands(response.get("commands"))
}

fn available_commands_from_session_update(message: &Value) -> Option<Vec<GrokAvailableCommand>> {
    let update = message
        .get("params")
        .and_then(|params| params.get("update").or_else(|| params.get("sessionUpdate")))?;
    (update.get("sessionUpdate").and_then(Value::as_str) == Some("available_commands_update"))
        .then(|| parse_available_commands(update.get("availableCommands")))
}

fn grok_home(app: &AppHandle) -> Result<PathBuf, String> {
    let directory = app
        .path()
        .app_config_dir()
        .map_err(|error| format!("无法定位 ARK Desktop 配置目录: {error}"))?
        .join("grok-build");
    fs::create_dir_all(&directory).map_err(|error| format!("创建 Grok 配置目录失败: {error}"))?;
    Ok(directory)
}

fn model_provider_path(app: &AppHandle) -> Result<PathBuf, String> {
    Ok(grok_home(app)?.join(MODEL_PROVIDER_FILE))
}

fn normalize_provider_id(value: &str) -> Result<String, String> {
    let value = value.trim();
    if value.is_empty()
        || value.len() > 64
        || !value
            .chars()
            .all(|character| character.is_ascii_alphanumeric() || matches!(character, '-' | '_'))
    {
        return Err("模型连接标识仅支持字母、数字、短横线和下划线，且长度不超过 64".to_string());
    }
    Ok(value.to_string())
}

fn model_key_env_name(provider_id: &str) -> String {
    format!(
        "URGS_GROK_MODEL_{}",
        provider_id
            .chars()
            .map(|character| if character.is_ascii_alphanumeric() {
                character.to_ascii_uppercase()
            } else {
                '_'
            })
            .collect::<String>()
    )
}

fn provider_credential(provider_id: &str) -> Result<Entry, String> {
    Entry::new(MODEL_CREDENTIAL_SERVICE, provider_id)
        .map_err(|error| format!("无法访问系统凭据库: {error}"))
}

fn cached_provider_api_key(provider_id: &str) -> Option<String> {
    MODEL_API_KEY_CACHE
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .ok()
        .and_then(|cache| cache.get(provider_id).cloned())
}

fn cache_provider_api_key(provider_id: &str, api_key: &str) {
    if let Ok(mut cache) = MODEL_API_KEY_CACHE
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
    {
        cache.insert(provider_id.to_string(), api_key.to_string());
    }
}

fn forget_cached_provider_api_key(provider_id: &str) {
    if let Some(cache) = MODEL_API_KEY_CACHE.get() {
        if let Ok(mut cache) = cache.lock() {
            cache.remove(provider_id);
        }
    }
}

#[cfg(target_os = "macos")]
fn get_provider_password(entry: &Entry, allow_interaction: bool) -> Result<String, keyring::Error> {
    if allow_interaction {
        return entry.get_password();
    }
    use security_framework::os::macos::keychain::SecKeychain;

    let _read_lock = MACOS_KEYCHAIN_READ_LOCK
        .get_or_init(|| Mutex::new(()))
        .lock()
        .map_err(|_| keyring::Error::PlatformFailure("钥匙串读取锁不可用".into()))?;
    let _interaction_lock = SecKeychain::disable_user_interaction()
        .map_err(|error| keyring::Error::PlatformFailure(Box::new(error)))?;
    entry.get_password()
}

#[cfg(not(target_os = "macos"))]
fn get_provider_password(
    entry: &Entry,
    _allow_interaction: bool,
) -> Result<String, keyring::Error> {
    entry.get_password()
}

fn read_provider_api_key(
    provider_id: &str,
    allow_interaction: bool,
) -> Result<Option<String>, String> {
    if let Some(api_key) = cached_provider_api_key(provider_id) {
        return Ok(Some(api_key));
    }
    match get_provider_password(&provider_credential(provider_id)?, allow_interaction) {
        Ok(api_key) if !api_key.trim().is_empty() => {
            cache_provider_api_key(provider_id, &api_key);
            Ok(Some(api_key))
        }
        Ok(_) | Err(keyring::Error::NoEntry) => Ok(None),
        #[cfg(target_os = "macos")]
        Err(_) if !allow_interaction => {
            Err(format!("{MODEL_KEY_AUTHORIZATION_REQUIRED}{provider_id}"))
        }
        Err(error) => Err(format!("读取模型密钥失败: {error}")),
    }
}

fn read_model_providers(app: &AppHandle) -> Result<Vec<GrokModelProvider>, String> {
    let path = model_provider_path(app)?;
    if !path.is_file() {
        return Ok(Vec::new());
    }
    let content =
        fs::read_to_string(&path).map_err(|error| format!("读取模型连接失败: {error}"))?;
    serde_json::from_str::<Vec<GrokModelProvider>>(&content)
        .map_err(|error| format!("解析模型连接失败: {error}"))
}

fn write_model_providers(app: &AppHandle, providers: &[GrokModelProvider]) -> Result<(), String> {
    let path = model_provider_path(app)?;
    let content = serde_json::to_string_pretty(providers)
        .map_err(|error| format!("序列化模型连接失败: {error}"))?;
    fs::write(path, content).map_err(|error| format!("保存模型连接失败: {error}"))
}

fn normalize_model_provider(
    input: GrokModelProviderInput,
) -> Result<(GrokModelProvider, Option<String>), String> {
    let id = normalize_provider_id(&input.id)?;
    let name = input.name.trim();
    let model = normalize_model_id(&input.model)?;
    let base_url = input.base_url.trim().trim_end_matches('/');
    let parsed = url::Url::parse(base_url).map_err(|_| "模型服务地址格式不正确".to_string())?;
    if !matches!(parsed.scheme(), "http" | "https") || parsed.host_str().is_none() {
        return Err("模型服务地址必须是有效的 HTTP 或 HTTPS 地址".to_string());
    }
    if name.is_empty() || name.len() > 80 {
        return Err("请输入长度不超过 80 个字符的连接名称".to_string());
    }
    if !matches!(
        input.api_backend.as_str(),
        "chat_completions" | "responses" | "messages"
    ) {
        return Err("暂不支持该模型 API 协议".to_string());
    }
    if !matches!(input.auth_scheme.as_str(), "bearer" | "x_api_key") {
        return Err("暂不支持该认证方案".to_string());
    }
    if !(4_096..=2_000_000).contains(&input.context_window) {
        return Err("上下文窗口应在 4096 到 2000000 之间".to_string());
    }
    Ok((
        GrokModelProvider {
            id,
            name: name.to_string(),
            model,
            base_url: base_url.to_string(),
            api_backend: input.api_backend,
            auth_scheme: input.auth_scheme,
            context_window: input.context_window,
            enabled: input.enabled,
            has_api_key: false,
        },
        input.api_key,
    ))
}

fn parse_grok_toml(content: &str) -> Result<toml::Value, String> {
    if content.trim().is_empty() {
        return Ok(toml::Value::Table(toml::map::Map::new()));
    }
    if let Ok(config) = content.parse::<toml::Value>() {
        return Ok(config);
    }
    // A previous release serialized the document root as an inline table. TOML
    // documents cannot start with `{`, but the table itself can be recovered by
    // assigning it to a temporary key and then extracting that value.
    let inline_root = content.trim();
    if inline_root.starts_with('{') && inline_root.ends_with('}') {
        let wrapped = format!("__urgs_recovery_root = {inline_root}");
        if let Ok(recovered) = wrapped.parse::<toml::Value>() {
            if let Some(root) = recovered.get("__urgs_recovery_root") {
                return Ok(root.clone());
            }
        }
    }
    content
        .parse::<toml::Value>()
        .map_err(|error| format!("本地智能引擎 TOML 配置无效: {error}"))
}

fn serialize_grok_toml(config: &toml::Value) -> Result<String, String> {
    toml::to_string(config).map_err(|error| format!("序列化本地智能引擎配置失败: {error}"))
}

fn sync_provider_to_grok_config(
    app: &AppHandle,
    provider: &GrokModelProvider,
) -> Result<(), String> {
    let path = grok_config_path(app, "user", "config", None)?;
    let content = if path.is_file() {
        fs::read_to_string(&path).map_err(|error| format!("读取本地智能引擎配置失败: {error}"))?
    } else {
        String::new()
    };
    let mut config = parse_grok_toml(&content)?;
    let root = config
        .as_table_mut()
        .ok_or_else(|| "本地智能引擎配置根节点必须是对象".to_string())?;
    let models = root
        .entry("model".to_string())
        .or_insert_with(|| toml::Value::Table(toml::map::Map::new()))
        .as_table_mut()
        .ok_or_else(|| "本地智能引擎配置中的 model 必须是对象".to_string())?;
    let entry = models
        .entry(provider.id.clone())
        .or_insert_with(|| toml::Value::Table(toml::map::Map::new()))
        .as_table_mut()
        .ok_or_else(|| "模型配置必须是对象".to_string())?;
    entry.insert(
        "model".to_string(),
        toml::Value::String(provider.model.clone()),
    );
    entry.insert(
        "base_url".to_string(),
        toml::Value::String(provider.base_url.clone()),
    );
    entry.insert(
        "name".to_string(),
        toml::Value::String(provider.name.clone()),
    );
    entry.insert(
        "env_key".to_string(),
        toml::Value::String(model_key_env_name(&provider.id)),
    );
    entry.insert(
        "api_backend".to_string(),
        toml::Value::String(provider.api_backend.clone()),
    );
    entry.insert(
        "auth_scheme".to_string(),
        toml::Value::String(provider.auth_scheme.clone()),
    );
    entry.insert(
        "context_window".to_string(),
        toml::Value::Integer(provider.context_window as i64),
    );
    entry.insert(
        "agent_type".to_string(),
        toml::Value::String("grok-build".to_string()),
    );
    entry.insert("supported_in_api".to_string(), toml::Value::Boolean(true));
    entry.remove("api_key");
    let parent = path
        .parent()
        .ok_or_else(|| "本地智能引擎配置目录无效".to_string())?;
    fs::create_dir_all(parent).map_err(|error| format!("创建本地智能引擎配置目录失败: {error}"))?;
    if path.is_file() {
        fs::copy(&path, path.with_extension("toml.urgs-backup"))
            .map_err(|error| format!("备份本地智能引擎配置失败: {error}"))?;
    }
    fs::write(path, serialize_grok_toml(&config)?)
        .map_err(|error| format!("保存本地智能引擎配置失败: {error}"))
}

fn provider_is_registered_in_grok_config(
    app: &AppHandle,
    provider: &GrokModelProvider,
) -> Result<bool, String> {
    let path = grok_config_path(app, "user", "config", None)?;
    if !path.is_file() {
        return Ok(false);
    }
    let content =
        fs::read_to_string(path).map_err(|error| format!("读取本地智能引擎配置失败: {error}"))?;
    if content.trim_start().starts_with('{') {
        return Ok(false);
    }
    let config = parse_grok_toml(&content)?;
    let entry = config
        .get("model")
        .and_then(toml::Value::as_table)
        .and_then(|models| models.get(&provider.id))
        .and_then(toml::Value::as_table);
    Ok(entry.is_some_and(|entry| {
        entry.get("model").and_then(toml::Value::as_str) == Some(provider.model.as_str())
            && entry.get("base_url").and_then(toml::Value::as_str)
                == Some(provider.base_url.as_str())
            && entry.get("env_key").and_then(toml::Value::as_str)
                == Some(model_key_env_name(&provider.id).as_str())
            && entry.get("api_backend").and_then(toml::Value::as_str)
                == Some(provider.api_backend.as_str())
    }))
}

fn remove_provider_from_grok_config(app: &AppHandle, provider_id: &str) -> Result<(), String> {
    let path = grok_config_path(app, "user", "config", None)?;
    if !path.is_file() {
        return Ok(());
    }
    let content =
        fs::read_to_string(&path).map_err(|error| format!("读取本地智能引擎配置失败: {error}"))?;
    let mut config = parse_grok_toml(&content)?;
    let root = config
        .as_table_mut()
        .ok_or_else(|| "本地智能引擎配置根节点必须是对象".to_string())?;
    if let Some(models) = root.get_mut("model").and_then(toml::Value::as_table_mut) {
        models.remove(provider_id);
    }
    if let Some(models) = root.get_mut("models").and_then(toml::Value::as_table_mut) {
        if models.get("default").and_then(toml::Value::as_str) == Some(provider_id) {
            models.remove("default");
        }
    }
    fs::copy(&path, path.with_extension("toml.urgs-backup"))
        .map_err(|error| format!("备份本地智能引擎配置失败: {error}"))?;
    fs::write(path, serialize_grok_toml(&config)?)
        .map_err(|error| format!("保存本地智能引擎配置失败: {error}"))
}

fn model_provider_envs(
    app: &AppHandle,
    model: Option<&str>,
) -> Result<Vec<(String, String)>, String> {
    let Some(model) = model.map(str::trim).filter(|model| !model.is_empty()) else {
        return Ok(Vec::new());
    };
    let mut providers = read_model_providers(app)?;
    let Some(index) = providers.iter().position(|provider| provider.id == model) else {
        return Ok(Vec::new());
    };
    let provider = providers[index].clone();
    if !provider.enabled {
        return Err(format!(
            "模型连接“{}”已停用，请在设置中启用后再使用",
            provider.name
        ));
    }
    let api_key = match read_provider_api_key(&provider.id, false)? {
        Some(api_key) => api_key,
        None => {
            let provider_name = provider.name.clone();
            if provider.has_api_key {
                providers[index].has_api_key = false;
                write_model_providers(app, &providers)?;
            }
            return Err(format!("模型连接“{provider_name}”尚未配置 API Key"));
        }
    };
    let env_name = model_key_env_name(&provider.id);
    if !provider.has_api_key {
        providers[index].has_api_key = true;
        write_model_providers(app, &providers)?;
    }
    Ok(vec![(env_name, api_key)])
}

fn ensure_model_provider_ready(app: &AppHandle, model: Option<&str>) -> Result<(), String> {
    let Some(model) = model.map(str::trim).filter(|model| !model.is_empty()) else {
        return Ok(());
    };
    let Some(provider) = read_model_providers(app)?
        .into_iter()
        .find(|provider| provider.id == model)
    else {
        return Ok(());
    };
    if !provider.enabled {
        return Err(format!(
            "模型连接“{}”已停用，请在设置中启用后再使用",
            provider.name
        ));
    }
    if !provider_is_registered_in_grok_config(app, &provider)? {
        sync_provider_to_grok_config(app, &provider)?;
    }
    Ok(())
}

fn model_from_arguments(arguments: &[String]) -> Option<&str> {
    arguments
        .windows(2)
        .find(|pair| pair[0] == "--model")
        .map(|pair| pair[1].as_str())
}

fn validate_workspace(workspace: &str) -> Result<PathBuf, String> {
    let candidate = PathBuf::from(workspace.trim());
    if workspace.trim().is_empty() || !candidate.is_absolute() {
        return Err("请选择一个本地绝对路径作为 Grok 工作区".to_string());
    }
    let canonical = candidate
        .canonicalize()
        .map_err(|error| format!("无法访问所选工作区: {error}"))?;
    if !canonical.is_dir() {
        return Err("所选路径不是目录".to_string());
    }
    Ok(canonical)
}

fn grok_config_path(
    app: &AppHandle,
    scope: &str,
    kind: &str,
    workspace: Option<&str>,
) -> Result<PathBuf, String> {
    match (scope, kind) {
        ("user", "config") => Ok(grok_home(app)?.join("config.toml")),
        ("user", "appearance") => Ok(grok_home(app)?.join("pager.toml")),
        ("project", "config") => workspace
            .ok_or_else(|| "项目配置需要先选择工作区".to_string())
            .and_then(validate_workspace)
            .map(|directory| directory.join(".grok").join("config.toml")),
        ("project", "appearance") => Err("pager.toml 仅支持用户级配置".to_string()),
        (_, "config" | "appearance") => Err("Grok 配置作用域仅支持 user 或 project".to_string()),
        _ => Err("Grok 配置文件仅支持 config 或 appearance".to_string()),
    }
}

fn validate_cli_arguments(arguments: &[String]) -> Result<(), String> {
    const ALLOWED_COMMANDS: &[&str] = &[
        "agent",
        "completions",
        "dashboard",
        "export",
        "help",
        "inspect",
        "leader",
        "login",
        "logout",
        "mcp",
        "memory",
        "models",
        "plugin",
        "sessions",
        "setup",
        "trace",
        "update",
        "version",
        "worktree",
        "wrap",
    ];
    let command = arguments
        .first()
        .map(|value| value.as_str())
        .ok_or_else(|| "请选择要执行的 Grok CLI 功能".to_string())?;
    let is_single_task = arguments.iter().any(|argument| {
        matches!(
            argument.as_str(),
            "-p" | "--single" | "--prompt-file" | "--prompt-json"
        )
    });
    if !ALLOWED_COMMANDS.contains(&command) && !is_single_task {
        return Err(format!("不支持的 Grok CLI 功能: {command}"));
    }
    if arguments.len() > 128 {
        return Err("Grok CLI 参数数量不能超过 128 个".to_string());
    }
    if arguments
        .iter()
        .any(|argument| argument.len() > 8_192 || argument.contains('\0'))
    {
        return Err("Grok CLI 参数过长或包含非法字符".to_string());
    }
    Ok(())
}

fn validate_service_arguments(arguments: &[String]) -> Result<(), String> {
    validate_cli_arguments(arguments)?;
    let is_agent_service = arguments.first().map(String::as_str) == Some("agent")
        && arguments
            .iter()
            .skip(1)
            .any(|argument| matches!(argument.as_str(), "headless" | "serve" | "leader"));
    let is_single_task = arguments.iter().any(|argument| {
        matches!(
            argument.as_str(),
            "-p" | "--single" | "--prompt-file" | "--prompt-json"
        )
    });
    if !is_agent_service && !is_single_task {
        return Err("后台模式仅支持 Headless 单任务和 agent headless/serve/leader".to_string());
    }
    Ok(())
}

fn select_auth_method(initialize_response: &Value) -> Result<String, String> {
    let methods = initialize_response
        .get("authMethods")
        .and_then(Value::as_array)
        .ok_or_else(|| "Grok 未返回可用登录方式，请先完成登录".to_string())?;
    let method_ids = methods
        .iter()
        .filter_map(|method| method.get("id").and_then(Value::as_str))
        .collect::<Vec<_>>();
    if method_ids.is_empty() {
        return Err("未检测到可用的 Grok 登录凭据，请先点击“登录 Grok”".to_string());
    }

    let default_id = initialize_response
        .get("_meta")
        .and_then(|meta| meta.get("defaultAuthMethodId"))
        .and_then(Value::as_str);
    if let Some(default_id) = default_id.filter(|id| method_ids.contains(id)) {
        return Ok(default_id.to_string());
    }
    if let Some(cached_token) = method_ids.iter().find(|id| **id == "cached_token") {
        return Ok((*cached_token).to_string());
    }
    Ok(method_ids[0].to_string())
}

fn format_rpc_error(error: &Value) -> String {
    error
        .get("message")
        .and_then(Value::as_str)
        .map(ToString::to_string)
        .unwrap_or_else(|| error.to_string())
}

fn emit_event(app: &AppHandle, event_type: &str, payload: Value) {
    let _ = app.emit(
        GROK_EVENT_NAME,
        GrokBridgeEvent {
            event_type: event_type.to_string(),
            payload,
        },
    );
}

fn emit_process_event(
    app: &AppHandle,
    process: &GrokProcess,
    event_type: &str,
    mut payload: Value,
) {
    if let Some(object) = payload.as_object_mut() {
        object.insert("processId".to_string(), json!(process.process_id));
    } else {
        payload = json!({ "processId": process.process_id, "data": payload });
    }
    emit_event(app, event_type, payload);
}

fn user_question_params(message: &Value) -> Option<&Value> {
    let method = message.get("method")?.as_str()?;
    let params = message.get("params")?;
    if matches!(method, "x.ai/ask_user_question" | "_x.ai/ask_user_question")
        && params.get("sessionId").is_some()
    {
        return Some(params);
    }
    (method == "_x.ai/ask_user_question"
        && params.get("method").and_then(Value::as_str) == Some("x.ai/ask_user_question"))
    .then(|| params.get("params"))
    .flatten()
}

fn plan_approval_params(message: &Value) -> Option<&Value> {
    let method = message.get("method")?.as_str()?;
    let params = message.get("params")?;
    if matches!(method, "x.ai/exit_plan_mode" | "_x.ai/exit_plan_mode")
        && params.get("sessionId").is_some()
    {
        return Some(params);
    }
    (method == "_x.ai/exit_plan_mode"
        && params.get("method").and_then(Value::as_str) == Some("x.ai/exit_plan_mode"))
    .then(|| params.get("params"))
    .flatten()
}

fn handle_stdout(app: &AppHandle, process: &Arc<GrokProcess>, line: Vec<u8>) {
    let line = String::from_utf8_lossy(&line).trim().to_string();
    if line.is_empty() {
        return;
    }
    let message = match serde_json::from_str::<Value>(&line) {
        Ok(message) => message,
        Err(error) => {
            emit_process_event(
                app,
                process,
                "runtime_error",
                json!({ "message": format!("无法解析 Grok ACP 输出: {error}"), "line": line }),
            );
            return;
        }
    };

    if message.get("method").is_none() {
        if let Some(id) = message.get("id").and_then(Value::as_u64) {
            process.resolve_response(id, message);
        }
        return;
    }

    let method = message
        .get("method")
        .and_then(Value::as_str)
        .unwrap_or_default();
    match method {
        "session/update" | "sessionUpdate" => {
            if let Some(commands) = available_commands_from_session_update(&message) {
                process.replace_available_commands(commands);
            }
            if !process.replaying_session.load(Ordering::Relaxed) {
                emit_process_event(app, process, "session_update", message);
            }
        }
        "session/request_permission" => {
            let request_id = message.get("id").cloned();
            let session_id = message
                .get("params")
                .and_then(|params| params.get("sessionId"))
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string();
            if let Some(request_id) = request_id {
                process.remember_permission(session_id, request_id);
                emit_process_event(app, process, "permission_request", message);
            }
        }
        "x.ai/ask_user_question" | "_x.ai/ask_user_question" => {
            let request_id = message.get("id").cloned();
            let params = user_question_params(&message);
            let session_id = params
                .and_then(|params| params.get("sessionId"))
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string();
            if let (Some(request_id), Some(params)) = (request_id, params) {
                if session_id.is_empty() {
                    let _ = process.write_json(json!({
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "error": { "code": -32602, "message": "AskUserQuestion 缺少 sessionId" }
                    }));
                    return;
                }
                process.remember_user_question(session_id.clone(), request_id.clone());
                emit_process_event(
                    app,
                    process,
                    "user_question_request",
                    json!({
                        "requestId": request_id,
                        "sessionId": session_id,
                        "toolCallId": params.get("toolCallId"),
                        "questions": params.get("questions").cloned().unwrap_or_else(|| json!([])),
                        "mode": params.get("mode").and_then(Value::as_str).unwrap_or("default"),
                    }),
                );
            }
        }
        "x.ai/exit_plan_mode" | "_x.ai/exit_plan_mode" => {
            let request_id = message.get("id").cloned();
            let params = plan_approval_params(&message);
            let session_id = params
                .and_then(|params| params.get("sessionId"))
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string();
            if let (Some(request_id), Some(params)) = (request_id, params) {
                if session_id.is_empty() {
                    let _ = process.write_json(json!({
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "error": { "code": -32602, "message": "ExitPlanMode 缺少 sessionId" }
                    }));
                    return;
                }
                process.remember_plan_approval(session_id.clone(), request_id.clone());
                emit_process_event(
                    app,
                    process,
                    "plan_approval_request",
                    json!({
                        "requestId": request_id,
                        "sessionId": session_id,
                        "toolCallId": params.get("toolCallId"),
                        "planContent": params.get("planContent"),
                    }),
                );
            }
        }
        _ => {
            if let Some(request_id) = message.get("id").cloned() {
                let _ = process.write_json(json!({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": { "code": -32601, "message": "ARK Desktop 暂不支持该 ACP 客户端方法" }
                }));
            }
            emit_process_event(app, process, "agent_event", message);
        }
    }
}

fn push_optional_argument(arguments: &mut Vec<String>, flag: &str, value: Option<&String>) {
    if let Some(value) = value.filter(|value| !value.trim().is_empty()) {
        arguments.push(flag.to_string());
        arguments.push(value.trim().to_string());
    }
}

fn process_launch_key(
    workspace: &Path,
    model: Option<&str>,
    options: &GrokAcpOptions,
    rules: Option<&str>,
) -> Result<String, String> {
    serde_json::to_string(&json!({
        "workspace": workspace.to_string_lossy(),
        "model": model.unwrap_or_default().trim(),
        "options": options,
        "rules": rules.unwrap_or_default().trim(),
    }))
    .map_err(|error| format!("生成 Grok 会话启动配置失败: {error}"))
}

fn grok_agent_arguments(
    model: Option<&str>,
    options: &GrokAcpOptions,
) -> Result<Vec<String>, String> {
    let mut arguments = vec!["--no-auto-update".to_string(), "agent".to_string()];
    if let Some(model) = model.filter(|value| !value.trim().is_empty()) {
        arguments.push("--model".to_string());
        arguments.push(model.trim().to_string());
    }
    push_optional_argument(
        &mut arguments,
        "--reasoning-effort",
        options.reasoning_effort.as_ref(),
    );
    if options.always_approve.unwrap_or(false)
        || options.permission_mode.as_deref() == Some("bypassPermissions")
    {
        arguments.push("--always-approve".to_string());
    }
    if options.reauth.unwrap_or(false) {
        arguments.push("--reauth".to_string());
    }
    push_optional_argument(
        &mut arguments,
        "--agent-profile",
        options.agent_profile.as_ref(),
    );
    for directory in options.plugin_dirs.as_deref().unwrap_or_default() {
        if !directory.trim().is_empty() {
            arguments.push("--plugin-dir".to_string());
            arguments.push(directory.trim().to_string());
        }
    }
    match options.leader_mode.as_deref().unwrap_or("default") {
        "default" => {}
        "leader" => arguments.push("--leader".to_string()),
        "standalone" => arguments.push("--no-leader".to_string()),
        _ => return Err("不支持的 Grok Leader 连接模式".to_string()),
    }
    push_optional_argument(
        &mut arguments,
        "--grok-ws-origin",
        options.grok_ws_origin.as_ref(),
    );
    push_optional_argument(
        &mut arguments,
        "--grok-ws-url",
        options.grok_ws_url.as_ref(),
    );
    push_optional_argument(
        &mut arguments,
        "--cli-chat-proxy-base-url",
        options.cli_chat_proxy_url.as_ref(),
    );
    push_optional_argument(
        &mut arguments,
        "--xai-api-base-url",
        options.xai_api_base_url.as_ref(),
    );
    if options.debug.unwrap_or(false) {
        arguments.push("--debug".to_string());
    }
    push_optional_argument(&mut arguments, "--debug-file", options.debug_file.as_ref());
    push_optional_argument(
        &mut arguments,
        "--leader-socket",
        options.leader_socket.as_ref(),
    );
    arguments.push("stdio".to_string());
    Ok(arguments)
}

fn spawn_grok_process(
    app: &AppHandle,
    workspace: &Path,
    model: Option<&str>,
    options: &GrokAcpOptions,
    rules: Option<&str>,
) -> Result<Arc<GrokProcess>, String> {
    ensure_model_provider_ready(app, model)?;
    let launch_key = process_launch_key(workspace, model, options, rules)?;
    let home = grok_home(app)?;
    let arguments = grok_agent_arguments(model, options)?;
    let model_envs = model_provider_envs(app, model)?;
    spawn_grok_process_with_env(app, workspace, arguments, model_envs, home, launch_key)
}

fn spawn_grok_discovery_process(
    app: &AppHandle,
    workspace: &Path,
) -> Result<Arc<GrokProcess>, String> {
    spawn_grok_process_with_env(
        app,
        workspace,
        grok_agent_arguments(None, &GrokAcpOptions::default())?,
        Vec::new(),
        grok_home(app)?,
        format!("command-discovery:{}", workspace.to_string_lossy()),
    )
}

fn spawn_grok_process_with_env(
    app: &AppHandle,
    workspace: &Path,
    arguments: Vec<String>,
    model_envs: Vec<(String, String)>,
    home: PathBuf,
    launch_key: String,
) -> Result<Arc<GrokProcess>, String> {
    let (mut receiver, child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(arguments)
        .current_dir(workspace)
        .env("GROK_HOME", &home)
        .envs(model_envs)
        .spawn()
        .map_err(|error| format!("启动本地 Grok Build 失败: {error}"))?;
    let process = Arc::new(GrokProcess::new(child, launch_key));
    let reader_process = Arc::clone(&process);
    let reader_app = app.clone();
    tauri::async_runtime::spawn(async move {
        while let Some(event) = receiver.recv().await {
            match event {
                CommandEvent::Stdout(line) => handle_stdout(&reader_app, &reader_process, line),
                CommandEvent::Stderr(line) => {
                    let message = String::from_utf8_lossy(&line).trim().to_string();
                    reader_process.remember_stderr(&message);
                    emit_process_event(
                        &reader_app,
                        &reader_process,
                        "stderr",
                        json!({ "message": message }),
                    );
                }
                CommandEvent::Error(error) => {
                    reader_process.alive.store(false, Ordering::Relaxed);
                    reader_process.remember_stderr(&error);
                    reader_process.fail_pending_requests(format!("Grok 本地进程运行失败：{error}"));
                    emit_process_event(
                        &reader_app,
                        &reader_process,
                        "runtime_error",
                        json!({ "message": error }),
                    );
                }
                CommandEvent::Terminated(status) => {
                    reader_process.alive.store(false, Ordering::Relaxed);
                    reader_process
                        .fail_pending_requests(reader_process.termination_error(status.code));
                    emit_event(
                        &reader_app,
                        "terminated",
                        json!({
                            "code": status.code,
                            "processId": reader_process.process_id,
                        }),
                    );
                }
                _ => {}
            }
        }
    });
    Ok(process)
}

fn session_process(state: &GrokRuntimeState, session_id: &str) -> Result<Arc<GrokProcess>, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let mut processes = state
        .session_processes
        .lock()
        .map_err(|_| "Grok 会话进程池锁不可用".to_string())?;
    processes.retain(|_, process| process.alive.load(Ordering::Relaxed));
    processes
        .get(session_id)
        .cloned()
        .ok_or_else(|| "Grok 本地会话尚未挂载".to_string())
}

fn register_session_process(
    state: &GrokRuntimeState,
    session_id: &str,
    process: Arc<GrokProcess>,
) -> Result<(), String> {
    let previous = state
        .session_processes
        .lock()
        .map_err(|_| "Grok 会话进程池锁不可用".to_string())?
        .insert(session_id.to_string(), Arc::clone(&process));
    if let Some(previous) = previous.filter(|previous| previous.process_id != process.process_id) {
        previous.stop();
    }
    Ok(())
}

fn stop_prepared_process(state: &GrokRuntimeState) -> Result<(), String> {
    let prepared = state
        .prepared_process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .take();
    if let Some(prepared) = prepared {
        prepared.stop();
    }
    Ok(())
}

#[tauri::command]
pub async fn grok_runtime_status(app: AppHandle) -> Result<GrokRuntimeStatus, String> {
    let home = grok_home(&app)?;
    let output = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(["--no-auto-update", "--version"])
        .output()
        .await
        .map_err(|error| format!("检测 Grok Build 失败: {error}"))?;
    let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let available = output.status.success();

    Ok(GrokRuntimeStatus {
        available,
        authenticated: home.join("auth.json").is_file(),
        version: (!version.is_empty()).then_some(version),
        grok_home: home.to_string_lossy().to_string(),
        message: (!available).then(|| String::from_utf8_lossy(&output.stderr).trim().to_string()),
    })
}

#[tauri::command]
pub async fn grok_available_commands(
    app: AppHandle,
    workspace: String,
) -> Result<Vec<GrokAvailableCommand>, String> {
    let workspace = validate_workspace(&workspace)?;
    let process = spawn_grok_discovery_process(&app, &workspace)?;
    let result = process.discover_available_commands(&workspace).await;
    process.stop();
    result
}

#[tauri::command]
pub async fn grok_runtime_prepare(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: String,
    model: String,
    options: Option<GrokAcpOptions>,
) -> Result<(), String> {
    let workspace = validate_workspace(&workspace)?;
    let model = normalize_model_id(&model)?;
    let has_live_session = state
        .session_processes
        .lock()
        .map_err(|_| "Grok 会话进程池锁不可用".to_string())?
        .values()
        .any(|process| process.alive.load(Ordering::Relaxed));
    if has_live_session {
        return Ok(());
    }
    if state
        .prepared_process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .as_ref()
        .is_some_and(|process| process.alive.load(Ordering::Relaxed))
    {
        return Ok(());
    }
    let process = spawn_grok_process(
        &app,
        &workspace,
        Some(&model),
        &options.unwrap_or_default(),
        None,
    )?;
    if let Err(error) = process.initialize(None).await {
        process.stop();
        return Err(error);
    }
    *state
        .prepared_process
        .lock()
        .map_err(|_| "本地智能引擎运行时锁不可用".to_string())? = Some(process);
    Ok(())
}

#[tauri::command]
pub async fn grok_cli_run(
    app: AppHandle,
    workspace: Option<String>,
    arguments: Vec<String>,
    timeout_seconds: Option<u64>,
) -> Result<GrokCliResult, String> {
    validate_cli_arguments(&arguments)?;
    let model = model_from_arguments(&arguments);
    ensure_model_provider_ready(&app, model)?;
    let current_dir = match workspace.filter(|value| !value.trim().is_empty()) {
        Some(workspace) => validate_workspace(&workspace)?,
        None => grok_home(&app)?,
    };
    let mut command_arguments = vec!["--no-auto-update".to_string()];
    command_arguments.extend(arguments.iter().cloned());
    let command = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(command_arguments)
        .current_dir(current_dir)
        .env("GROK_HOME", grok_home(&app)?)
        .envs(model_provider_envs(&app, model)?);
    let timeout = Duration::from_secs(timeout_seconds.unwrap_or(120).clamp(5, 600));
    let output = tokio::time::timeout(timeout, command.output())
        .await
        .map_err(|_| format!("Grok CLI 执行超过 {} 秒，已停止等待", timeout.as_secs()))?
        .map_err(|error| format!("执行 Grok CLI 失败: {error}"))?;

    Ok(GrokCliResult {
        arguments,
        success: output.status.success(),
        exit_code: output.status.code(),
        stdout: String::from_utf8_lossy(&output.stdout).trim().to_string(),
        stderr: String::from_utf8_lossy(&output.stderr).trim().to_string(),
    })
}

#[tauri::command]
pub fn grok_config_read(
    app: AppHandle,
    scope: String,
    kind: Option<String>,
    workspace: Option<String>,
) -> Result<GrokConfigFile, String> {
    let kind = kind.unwrap_or_else(|| "config".to_string());
    let path = grok_config_path(&app, &scope, &kind, workspace.as_deref())?;
    let exists = path.is_file();
    let content = if exists {
        fs::read_to_string(&path).map_err(|error| format!("读取 Grok 配置失败: {error}"))?
    } else {
        String::new()
    };
    Ok(GrokConfigFile {
        scope,
        kind,
        path: path.to_string_lossy().to_string(),
        exists,
        content,
    })
}

#[tauri::command]
pub fn grok_config_save(
    app: AppHandle,
    scope: String,
    kind: Option<String>,
    workspace: Option<String>,
    content: String,
) -> Result<GrokConfigFile, String> {
    if !content.trim().is_empty() {
        parse_grok_toml(&content)?;
    }
    let kind = kind.unwrap_or_else(|| "config".to_string());
    let path = grok_config_path(&app, &scope, &kind, workspace.as_deref())?;
    let parent = path
        .parent()
        .ok_or_else(|| "Grok 配置目录无效".to_string())?;
    fs::create_dir_all(parent).map_err(|error| format!("创建 Grok 配置目录失败: {error}"))?;
    if path.is_file() {
        fs::copy(&path, path.with_extension("toml.urgs-backup"))
            .map_err(|error| format!("备份 Grok 配置失败: {error}"))?;
    }
    fs::write(&path, content.as_bytes()).map_err(|error| format!("保存 Grok 配置失败: {error}"))?;
    let content = if scope == "user" && kind == "config" {
        for provider in read_model_providers(&app)? {
            sync_provider_to_grok_config(&app, &provider)?;
        }
        fs::read_to_string(&path).map_err(|error| format!("读取已保存配置失败: {error}"))?
    } else {
        content
    };
    Ok(GrokConfigFile {
        scope,
        kind,
        path: path.to_string_lossy().to_string(),
        exists: true,
        content,
    })
}

fn normalize_model_id(model: &str) -> Result<String, String> {
    let model = model.trim();
    if model.is_empty() {
        return Err("请输入模型标识".to_string());
    }
    if model.len() > 128 || model.chars().any(|character| character.is_control()) {
        return Err("模型标识格式无效".to_string());
    }
    Ok(model.to_string())
}

#[tauri::command]
pub fn grok_model_apply(app: AppHandle, model: String) -> Result<(), String> {
    let model = normalize_model_id(&model)?;
    let path = grok_config_path(&app, "user", "config", None)?;
    let content = if path.is_file() {
        fs::read_to_string(&path).map_err(|error| format!("读取 Grok 配置失败: {error}"))?
    } else {
        String::new()
    };
    let mut config = parse_grok_toml(&content)?;
    let root = config
        .as_table_mut()
        .ok_or_else(|| "Grok 配置根节点必须是对象".to_string())?;
    let models = root
        .entry("models".to_string())
        .or_insert_with(|| toml::Value::Table(toml::map::Map::new()))
        .as_table_mut()
        .ok_or_else(|| "Grok 配置中的 models 必须是对象".to_string())?;
    if models.get("default").and_then(toml::Value::as_str) == Some(model.as_str()) {
        return Ok(());
    }
    models.insert("default".to_string(), toml::Value::String(model));
    let parent = path
        .parent()
        .ok_or_else(|| "Grok 配置目录无效".to_string())?;
    fs::create_dir_all(parent).map_err(|error| format!("创建 Grok 配置目录失败: {error}"))?;
    if path.is_file() {
        fs::copy(&path, path.with_extension("toml.urgs-backup"))
            .map_err(|error| format!("备份 Grok 配置失败: {error}"))?;
    }
    fs::write(&path, serialize_grok_toml(&config)?)
        .map_err(|error| format!("保存 Grok 配置失败: {error}"))?;
    Ok(())
}

#[tauri::command]
pub fn grok_model_provider_list(app: AppHandle) -> Result<Vec<GrokModelProvider>, String> {
    read_model_providers(&app)
}

#[tauri::command]
pub fn grok_model_provider_authorize(
    app: AppHandle,
    provider_id: String,
) -> Result<GrokModelProvider, String> {
    let provider_id = normalize_provider_id(&provider_id)?;
    let mut providers = read_model_providers(&app)?;
    let index = providers
        .iter()
        .position(|provider| provider.id == provider_id)
        .ok_or_else(|| "未找到该模型连接".to_string())?;
    let provider = providers[index].clone();
    if !provider.enabled {
        return Err(format!("模型连接“{}”已停用", provider.name));
    }
    if read_provider_api_key(&provider.id, true)?.is_none() {
        providers[index].has_api_key = false;
        write_model_providers(&app, &providers)?;
        return Err(format!("模型连接“{}”尚未配置 API Key", provider.name));
    }
    providers[index].has_api_key = true;
    write_model_providers(&app, &providers)?;
    Ok(providers[index].clone())
}

#[tauri::command]
pub fn grok_model_provider_save(
    app: AppHandle,
    input: GrokModelProviderInput,
) -> Result<GrokModelProvider, String> {
    let (mut provider, api_key) = normalize_model_provider(input)?;
    let mut providers = read_model_providers(&app)?;
    provider.has_api_key = providers
        .iter()
        .find(|item| item.id == provider.id)
        .is_some_and(|item| item.has_api_key);
    if let Some(api_key) = api_key {
        let credential = provider_credential(&provider.id)?;
        if api_key.trim().is_empty() {
            match credential.delete_credential() {
                Ok(()) | Err(keyring::Error::NoEntry) => {}
                Err(error) => return Err(format!("从系统凭据库删除模型密钥失败: {error}")),
            }
            forget_cached_provider_api_key(&provider.id);
            provider.has_api_key = false;
        } else {
            credential
                .set_password(api_key.trim())
                .map_err(|error| format!("保存模型密钥到系统凭据库失败: {error}"))?;
            cache_provider_api_key(&provider.id, api_key.trim());
            provider.has_api_key = true;
        }
    }
    if let Some(index) = providers.iter().position(|item| item.id == provider.id) {
        providers[index] = provider.clone();
    } else {
        providers.push(provider.clone());
    }
    write_model_providers(&app, &providers)?;
    sync_provider_to_grok_config(&app, &provider)?;
    grok_model_apply(app.clone(), provider.id.clone())?;
    Ok(provider)
}

#[tauri::command]
pub fn grok_model_provider_delete(app: AppHandle, provider_id: String) -> Result<(), String> {
    let provider_id = normalize_provider_id(&provider_id)?;
    let mut providers = read_model_providers(&app)?;
    let before = providers.len();
    providers.retain(|provider| provider.id != provider_id);
    if before == providers.len() {
        return Err("未找到该模型连接".to_string());
    }
    let _ = provider_credential(&provider_id)?.delete_credential();
    forget_cached_provider_api_key(&provider_id);
    write_model_providers(&app, &providers)?;
    remove_provider_from_grok_config(&app, &provider_id)?;
    Ok(())
}

#[tauri::command]
pub fn grok_cli_service_start(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: Option<String>,
    arguments: Vec<String>,
) -> Result<GrokCliServiceInfo, String> {
    validate_service_arguments(&arguments)?;
    let model = model_from_arguments(&arguments);
    ensure_model_provider_ready(&app, model)?;
    let current_dir = match workspace.filter(|value| !value.trim().is_empty()) {
        Some(workspace) => validate_workspace(&workspace)?,
        None => grok_home(&app)?,
    };
    let mut command_arguments = vec!["--no-auto-update".to_string()];
    command_arguments.extend(arguments.iter().cloned());
    let model_envs = model_provider_envs(&app, model)?;
    let (mut receiver, child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(command_arguments)
        .current_dir(current_dir)
        .env("GROK_HOME", grok_home(&app)?)
        .envs(model_envs)
        .spawn()
        .map_err(|error| format!("启动 Grok CLI 服务失败: {error}"))?;
    let pid = child.pid();
    let sequence = state.cli_service_sequence.fetch_add(1, Ordering::Relaxed);
    let id = format!("grok-service-{sequence}");
    let retain_full_output = arguments.iter().any(|argument| {
        matches!(
            argument.as_str(),
            "-p" | "--single" | "--prompt-file" | "--prompt-json"
        )
    });
    let service = Arc::new(GrokCliService {
        id: id.clone(),
        arguments,
        pid,
        child: Mutex::new(Some(child)),
        alive: AtomicBool::new(true),
        started_at: SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as u64,
        exit_code: Mutex::new(None),
        stdout: Mutex::new(String::new()),
        stderr: Mutex::new(String::new()),
        retain_full_output,
    });
    state
        .cli_services
        .lock()
        .map_err(|_| "Grok CLI 服务列表锁不可用".to_string())?
        .insert(id.clone(), Arc::clone(&service));
    let reader_service = Arc::clone(&service);
    let reader_app = app.clone();
    tauri::async_runtime::spawn(async move {
        while let Some(event) = receiver.recv().await {
            match event {
                CommandEvent::Stdout(line) => {
                    GrokCliService::append_output(
                        &reader_service.stdout,
                        &line,
                        reader_service.retain_full_output,
                    );
                    emit_event(
                        &reader_app,
                        "cli_service_output",
                        json!({ "serviceId": reader_service.id, "stream": "stdout", "message": String::from_utf8_lossy(&line).trim() }),
                    );
                }
                CommandEvent::Stderr(line) => {
                    GrokCliService::append_output(
                        &reader_service.stderr,
                        &line,
                        reader_service.retain_full_output,
                    );
                    emit_event(
                        &reader_app,
                        "cli_service_output",
                        json!({ "serviceId": reader_service.id, "stream": "stderr", "message": String::from_utf8_lossy(&line).trim() }),
                    );
                }
                CommandEvent::Error(error) => {
                    GrokCliService::append_output(
                        &reader_service.stderr,
                        error.as_bytes(),
                        reader_service.retain_full_output,
                    );
                }
                CommandEvent::Terminated(status) => {
                    reader_service.alive.store(false, Ordering::Relaxed);
                    if let Ok(mut exit_code) = reader_service.exit_code.lock() {
                        *exit_code = status.code;
                    }
                    emit_event(
                        &reader_app,
                        "cli_service_terminated",
                        json!({ "serviceId": reader_service.id, "code": status.code }),
                    );
                }
                _ => {}
            }
        }
    });
    Ok(service.info())
}

#[tauri::command]
pub fn grok_cli_service_list(
    state: State<'_, GrokRuntimeState>,
) -> Result<Vec<GrokCliServiceInfo>, String> {
    let mut services = state
        .cli_services
        .lock()
        .map_err(|_| "Grok CLI 服务列表锁不可用".to_string())?
        .values()
        .map(|service| service.info())
        .collect::<Vec<_>>();
    services.sort_by(|left, right| right.started_at.cmp(&left.started_at));
    Ok(services)
}

#[tauri::command]
pub fn grok_cli_service_stop(
    state: State<'_, GrokRuntimeState>,
    service_id: String,
) -> Result<(), String> {
    let service = state
        .cli_services
        .lock()
        .map_err(|_| "Grok CLI 服务列表锁不可用".to_string())?
        .get(&service_id)
        .cloned()
        .ok_or_else(|| "未找到 Grok CLI 服务".to_string())?;
    service.stop()
}

#[tauri::command]
pub async fn grok_create_session(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: String,
    rules: Option<String>,
    model: Option<String>,
    options: Option<GrokAcpOptions>,
) -> Result<GrokSession, String> {
    let workspace = validate_workspace(&workspace)?;
    stop_prepared_process(&state)?;
    let process = spawn_grok_process(
        &app,
        &workspace,
        model.as_deref(),
        &options.unwrap_or_default(),
        rules.as_deref(),
    )?;
    if let Err(error) = process.initialize(rules.as_deref()).await {
        process.stop();
        return Err(error);
    }
    let response = match process
        .request(
            "session/new",
            json!({
                "cwd": workspace,
                "mcpServers": [],
            }),
        )
        .await
    {
        Ok(response) => response,
        Err(error) => {
            process.stop();
            return Err(error);
        }
    };
    let session_id = match response.get("sessionId").and_then(Value::as_str) {
        Some(session_id) => session_id.to_string(),
        None => {
            process.stop();
            return Err("Grok 未返回会话标识".to_string());
        }
    };
    if let Err(error) = register_session_process(&state, &session_id, Arc::clone(&process)) {
        process.stop();
        return Err(error);
    }
    Ok(GrokSession {
        session_id,
        workspace: workspace.to_string_lossy().to_string(),
        process_id: process.process_id.clone(),
        available_commands: process.available_commands(),
    })
}

#[tauri::command]
pub async fn grok_load_session(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    workspace: String,
    rules: Option<String>,
    model: Option<String>,
    options: Option<GrokAcpOptions>,
) -> Result<GrokSession, String> {
    let session_id = session_id.trim().to_string();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let workspace = validate_workspace(&workspace)?;
    let options = options.unwrap_or_default();
    let launch_key = process_launch_key(&workspace, model.as_deref(), &options, rules.as_deref())?;
    let existing = {
        let mut processes = state
            .session_processes
            .lock()
            .map_err(|_| "Grok 会话进程池锁不可用".to_string())?;
        processes.retain(|_, process| process.alive.load(Ordering::Relaxed));
        if let Some(process) = processes
            .get(&session_id)
            .filter(|process| process.launch_key == launch_key)
            .cloned()
        {
            return Ok(GrokSession {
                session_id,
                workspace: workspace.to_string_lossy().to_string(),
                process_id: process.process_id.clone(),
                available_commands: process.available_commands(),
            });
        }
        processes.remove(&session_id)
    };
    if let Some(existing) = existing {
        existing.stop();
    }
    stop_prepared_process(&state)?;
    let process = spawn_grok_process(
        &app,
        &workspace,
        model.as_deref(),
        &options,
        rules.as_deref(),
    )?;
    if let Err(error) = process.initialize(rules.as_deref()).await {
        process.stop();
        return Err(error);
    }
    process.replaying_session.store(true, Ordering::Relaxed);
    let load_result = process
        .request(
            "session/load",
            json!({
                "sessionId": session_id,
                "cwd": workspace,
                "mcpServers": [],
            }),
        )
        .await;
    process.replaying_session.store(false, Ordering::Relaxed);
    if let Err(error) = load_result {
        process.stop();
        return Err(error);
    }
    if let Err(error) = register_session_process(&state, &session_id, Arc::clone(&process)) {
        process.stop();
        return Err(error);
    }
    Ok(GrokSession {
        session_id,
        workspace: workspace.to_string_lossy().to_string(),
        process_id: process.process_id.clone(),
        available_commands: process.available_commands(),
    })
}

#[tauri::command]
pub async fn grok_send_prompt(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    prompt: String,
) -> Result<(), String> {
    if prompt.trim().is_empty() {
        return Err("请输入要发送给 Grok 的内容".to_string());
    }
    let process = session_process(&state, &session_id)?;
    process
        .request(
            "session/prompt",
            json!({
                "sessionId": session_id,
                "prompt": [{ "type": "text", "text": prompt.trim() }]
            }),
        )
        .await?;
    Ok(())
}

#[tauri::command]
pub async fn grok_session_set_model(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    model: String,
) -> Result<(), String> {
    let model = normalize_model_id(&model)?;
    ensure_model_provider_ready(&app, Some(&model))?;
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let process = session_process(&state, session_id)?;
    process
        .request(
            "session/set_model",
            json!({ "sessionId": session_id, "modelId": model }),
        )
        .await?;
    Ok(())
}

#[tauri::command]
pub fn grok_cancel(state: State<'_, GrokRuntimeState>, session_id: String) -> Result<(), String> {
    let process = session_process(&state, &session_id)?;
    process.notify("session/cancel", json!({ "sessionId": session_id }))?;
    for request_id in process.cancel_permissions(&session_id) {
        process.write_json(json!({
            "jsonrpc": "2.0",
            "id": request_id,
            "result": { "outcome": { "outcome": "cancelled" } }
        }))?;
    }
    for request_id in process.cancel_user_questions(&session_id) {
        process.write_json(json!({
            "jsonrpc": "2.0",
            "id": request_id,
            "result": { "outcome": "cancelled" }
        }))?;
    }
    for request_id in process.cancel_plan_approvals(&session_id) {
        process.write_json(json!({
            "jsonrpc": "2.0",
            "id": request_id,
            "result": { "outcome": "abandoned" }
        }))?;
    }
    Ok(())
}

#[tauri::command]
pub fn grok_respond_permission(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    request_id: Value,
    option_id: Option<String>,
) -> Result<(), String> {
    let process = session_process(&state, &session_id)?;
    let outcome = option_id.map_or_else(
        || json!({ "outcome": "cancelled" }),
        |option_id| json!({ "outcome": "selected", "optionId": option_id }),
    );
    process.write_json(json!({
        "jsonrpc": "2.0",
        "id": request_id,
        "result": { "outcome": outcome }
    }))?;
    process.clear_permission(&request_id);
    Ok(())
}

#[tauri::command]
pub fn grok_respond_user_question(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    request_id: Value,
    response: Value,
) -> Result<(), String> {
    let process = session_process(&state, &session_id)?;
    let outcome = response
        .get("outcome")
        .and_then(Value::as_str)
        .unwrap_or_default();
    if !matches!(
        outcome,
        "accepted" | "chat_about_this" | "skip_interview" | "cancelled"
    ) {
        return Err("无效的用户问卷响应结果".to_string());
    }
    process.write_json(json!({
        "jsonrpc": "2.0",
        "id": request_id,
        "result": response
    }))?;
    process.clear_user_question(&request_id);
    Ok(())
}

#[tauri::command]
pub fn grok_respond_plan_approval(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    request_id: Value,
    response: Value,
) -> Result<(), String> {
    let process = session_process(&state, &session_id)?;
    let outcome = response
        .get("outcome")
        .and_then(Value::as_str)
        .unwrap_or_default();
    if !matches!(outcome, "approved" | "cancelled" | "abandoned") {
        return Err("无效的计划审批响应结果".to_string());
    }
    process.write_json(json!({
        "jsonrpc": "2.0",
        "id": request_id,
        "result": response
    }))?;
    process.clear_plan_approval(&request_id);
    Ok(())
}

#[tauri::command]
pub fn grok_shutdown(state: State<'_, GrokRuntimeState>) -> Result<(), String> {
    stop_prepared_process(&state)?;
    let processes = state
        .session_processes
        .lock()
        .map_err(|_| "Grok 会话进程池锁不可用".to_string())?
        .drain()
        .map(|(_, process)| process)
        .collect::<Vec<_>>();
    for process in processes {
        process.stop();
    }
    Ok(())
}

#[tauri::command]
pub fn grok_start_login(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    method: Option<String>,
) -> Result<(), String> {
    grok_shutdown(state)?;
    let home = grok_home(&app)?;
    let mut arguments = vec!["--no-auto-update".to_string(), "login".to_string()];
    match method.as_deref().unwrap_or("browser") {
        "browser" => {}
        "oauth" => arguments.push("--oauth".to_string()),
        "device" => arguments.push("--device-auth".to_string()),
        _ => return Err("不支持的 Grok 登录方式".to_string()),
    }
    let (mut receiver, _child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(arguments)
        .env("GROK_HOME", &home)
        .spawn()
        .map_err(|error| format!("启动 Grok 登录失败: {error}"))?;
    tauri::async_runtime::spawn(async move {
        while let Some(event) = receiver.recv().await {
            match event {
                CommandEvent::Stdout(line) | CommandEvent::Stderr(line) => emit_event(
                    &app,
                    "login_output",
                    json!({ "message": String::from_utf8_lossy(&line).trim() }),
                ),
                CommandEvent::Error(error) => {
                    emit_event(&app, "runtime_error", json!({ "message": error }))
                }
                CommandEvent::Terminated(status) => {
                    emit_event(&app, "login_completed", json!({ "code": status.code }))
                }
                _ => {}
            }
        }
    });
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::{
        available_commands_from_initialize, available_commands_from_list,
        available_commands_from_session_update, cache_provider_api_key,
        forget_cached_provider_api_key, format_rpc_error, grok_agent_arguments, model_key_env_name,
        normalize_model_id, normalize_model_provider, parse_grok_toml, plan_approval_params,
        process_launch_key, read_provider_api_key, request_timeout, select_auth_method,
        serialize_grok_toml, user_question_params, validate_cli_arguments,
        validate_service_arguments, GrokAcpOptions, GrokCliService, GrokModelProviderInput,
        INITIALIZE_TIMEOUT, REQUEST_TIMEOUT,
    };
    use serde_json::json;
    use std::path::Path;
    use std::sync::Mutex;

    #[test]
    fn extracts_direct_and_wrapped_user_question_requests() {
        let direct = json!({
            "method": "x.ai/ask_user_question",
            "params": { "sessionId": "session-direct", "questions": [] }
        });
        assert_eq!(
            user_question_params(&direct)
                .and_then(|params| params.get("sessionId"))
                .and_then(|value| value.as_str()),
            Some("session-direct")
        );

        let wrapped = json!({
            "method": "_x.ai/ask_user_question",
            "params": {
                "method": "x.ai/ask_user_question",
                "params": { "sessionId": "session-wrapped", "questions": [] }
            }
        });
        assert_eq!(
            user_question_params(&wrapped)
                .and_then(|params| params.get("sessionId"))
                .and_then(|value| value.as_str()),
            Some("session-wrapped")
        );

        let private_direct = json!({
            "method": "_x.ai/ask_user_question",
            "params": { "sessionId": "session-private-direct", "questions": [] }
        });
        assert_eq!(
            user_question_params(&private_direct)
                .and_then(|params| params.get("sessionId"))
                .and_then(|value| value.as_str()),
            Some("session-private-direct")
        );
    }

    #[test]
    fn extracts_direct_and_wrapped_plan_approval_requests() {
        let direct = json!({
            "method": "x.ai/exit_plan_mode",
            "params": { "sessionId": "session-direct", "toolCallId": "tool-direct" }
        });
        assert_eq!(
            plan_approval_params(&direct)
                .and_then(|params| params.get("sessionId"))
                .and_then(|value| value.as_str()),
            Some("session-direct")
        );

        let wrapped = json!({
            "method": "_x.ai/exit_plan_mode",
            "params": {
                "method": "x.ai/exit_plan_mode",
                "params": { "sessionId": "session-wrapped", "toolCallId": "tool-wrapped" }
            }
        });
        assert_eq!(
            plan_approval_params(&wrapped)
                .and_then(|params| params.get("sessionId"))
                .and_then(|value| value.as_str()),
            Some("session-wrapped")
        );

        let private_direct = json!({
            "method": "_x.ai/exit_plan_mode",
            "params": { "sessionId": "session-private-direct", "toolCallId": "tool-private-direct" }
        });
        assert_eq!(
            plan_approval_params(&private_direct)
                .and_then(|params| params.get("sessionId"))
                .and_then(|value| value.as_str()),
            Some("session-private-direct")
        );
    }

    #[test]
    fn prefers_agent_default_auth_method() {
        let response = json!({
            "authMethods": [{ "id": "xai.api_key" }, { "id": "cached_token" }],
            "_meta": { "defaultAuthMethodId": "cached_token" }
        });
        assert_eq!(select_auth_method(&response).unwrap(), "cached_token");
    }

    #[test]
    fn falls_back_to_cached_token_then_first_method() {
        let cached = json!({
            "authMethods": [{ "id": "xai.api_key" }, { "id": "cached_token" }]
        });
        assert_eq!(select_auth_method(&cached).unwrap(), "cached_token");

        let first = json!({ "authMethods": [{ "id": "grok.com" }] });
        assert_eq!(select_auth_method(&first).unwrap(), "grok.com");
    }

    #[test]
    fn reports_json_rpc_message() {
        assert_eq!(
            format_rpc_error(&json!({ "message": "认证失败" })),
            "认证失败"
        );
    }

    #[test]
    fn parses_available_commands_from_initialize_metadata() {
        let commands = available_commands_from_initialize(&json!({
            "_meta": {
                "availableCommands": [
                    {
                        "name": "compact",
                        "description": "Compress conversation history",
                        "input": { "hint": "optional context" }
                    },
                    { "name": "context", "description": "Show context usage" }
                ]
            }
        }));
        assert_eq!(commands.len(), 2);
        assert_eq!(commands[0].name, "compact");
        assert_eq!(commands[0].input_hint.as_deref(), Some("optional context"));
        assert_eq!(commands[1].name, "context");
    }

    #[test]
    fn parses_available_commands_from_commands_list() {
        let commands = available_commands_from_list(&json!({
            "commands": [
                { "name": "compact", "description": "Compress history" },
                {
                    "name": "project:review",
                    "description": "Review changes",
                    "input": { "hint": "optional scope" }
                }
            ]
        }));
        assert_eq!(commands.len(), 2);
        assert_eq!(commands[1].name, "project:review");
        assert_eq!(commands[1].input_hint.as_deref(), Some("optional scope"));
    }

    #[test]
    fn parses_available_commands_update_and_rejects_other_updates() {
        let commands = available_commands_from_session_update(&json!({
            "method": "session/update",
            "params": {
                "sessionId": "session-1",
                "update": {
                    "sessionUpdate": "available_commands_update",
                    "availableCommands": [{ "name": "goal", "description": "Manage goal" }]
                }
            }
        }))
        .unwrap();
        assert_eq!(commands[0].name, "goal");
        assert!(available_commands_from_session_update(&json!({
            "params": { "update": { "sessionUpdate": "agent_message_chunk" } }
        }))
        .is_none());
    }

    #[test]
    fn session_launch_key_changes_only_when_runtime_configuration_changes() {
        let workspace = Path::new("/tmp/urgs");
        let base = GrokAcpOptions {
            permission_mode: Some("dontAsk".into()),
            ..Default::default()
        };
        let same = process_launch_key(workspace, Some("model-a"), &base, Some("rules")).unwrap();
        assert_eq!(
            same,
            process_launch_key(workspace, Some("model-a"), &base, Some("rules")).unwrap()
        );

        let changed = GrokAcpOptions {
            permission_mode: Some("bypassPermissions".into()),
            ..Default::default()
        };
        assert_ne!(
            same,
            process_launch_key(workspace, Some("model-a"), &changed, Some("rules")).unwrap()
        );
    }

    #[test]
    fn initialize_has_a_longer_timeout_than_regular_acp_requests() {
        assert_eq!(request_timeout("initialize"), INITIALIZE_TIMEOUT);
        assert_eq!(request_timeout("session/load"), REQUEST_TIMEOUT);
        assert!(request_timeout("initialize") > request_timeout("session/load"));
    }

    #[test]
    fn permission_modes_do_not_emit_unsupported_grok_cli_arguments() {
        let interactive = GrokAcpOptions {
            permission_mode: Some("acceptEdits".into()),
            sandbox_profile: Some("workspace-write".into()),
            ..Default::default()
        };
        let interactive_args = grok_agent_arguments(Some("model-a"), &interactive).unwrap();
        assert!(!interactive_args
            .iter()
            .any(|arg| arg == "--permission-mode"));
        assert!(!interactive_args.iter().any(|arg| arg == "--sandbox"));
        assert!(!interactive_args.iter().any(|arg| arg == "--always-approve"));

        let unrestricted = GrokAcpOptions {
            permission_mode: Some("bypassPermissions".into()),
            ..Default::default()
        };
        assert!(grok_agent_arguments(Some("model-a"), &unrestricted)
            .unwrap()
            .iter()
            .any(|arg| arg == "--always-approve"));
    }

    #[test]
    fn validates_cli_command_allowlist_and_limits() {
        assert!(validate_cli_arguments(&["models".to_string()]).is_ok());
        assert!(validate_cli_arguments(&["mcp".to_string(), "list".to_string()]).is_ok());
        assert!(validate_cli_arguments(&[
            "--model".into(),
            "grok-4.5-build-free".into(),
            "--single".into(),
            "hello".into(),
        ])
        .is_ok());
        assert!(validate_cli_arguments(&["bash".to_string()]).is_err());
        assert!(validate_cli_arguments(&[]).is_err());
    }

    #[test]
    fn validates_model_identifier_before_persisting_config() {
        assert_eq!(normalize_model_id("  model-1  ").unwrap(), "model-1");
        assert!(normalize_model_id("").is_err());
        assert!(normalize_model_id("model\n1").is_err());
    }

    #[test]
    fn normalizes_openai_compatible_model_provider() {
        let (provider, api_key) = normalize_model_provider(GrokModelProviderInput {
            id: "qwen-plus".into(),
            name: "Qwen 连接".into(),
            model: "qwen-plus".into(),
            base_url: "https://dashscope.aliyuncs.com/compatible-mode/v1/".into(),
            api_backend: "chat_completions".into(),
            auth_scheme: "bearer".into(),
            context_window: 128_000,
            enabled: true,
            api_key: Some("secret".into()),
        })
        .unwrap();
        assert_eq!(
            provider.base_url,
            "https://dashscope.aliyuncs.com/compatible-mode/v1"
        );
        assert_eq!(
            model_key_env_name(&provider.id),
            "URGS_GROK_MODEL_QWEN_PLUS"
        );
        assert_eq!(api_key.as_deref(), Some("secret"));
    }

    #[test]
    fn reuses_cached_model_key_without_reading_platform_credentials() {
        let provider_id = "urgs-test-cached-provider";
        cache_provider_api_key(provider_id, "cached-secret");
        assert_eq!(
            read_provider_api_key(provider_id, false)
                .unwrap()
                .as_deref(),
            Some("cached-secret")
        );
        forget_cached_provider_api_key(provider_id);
    }

    #[test]
    fn recovers_and_rewrites_legacy_inline_root_toml() {
        let legacy = r#"{ marketplace = { official_marketplace_auto_installed = true, sources = [{ git = "https://github.com/xai-org/plugin-marketplace.git", name = "xAI Official" }] }, models = { default = "Ff" } }"#;
        let config = parse_grok_toml(legacy).unwrap();
        assert_eq!(
            config
                .get("models")
                .and_then(toml::Value::as_table)
                .and_then(|models| models.get("default"))
                .and_then(toml::Value::as_str),
            Some("Ff")
        );
        let rewritten = serialize_grok_toml(&config).unwrap();
        assert!(!rewritten.trim_start().starts_with('{'));
        assert!(rewritten.parse::<toml::Value>().is_ok());
    }

    #[test]
    fn restricts_background_services_to_agent_server_modes() {
        assert!(validate_service_arguments(&["agent".into(), "serve".into()]).is_ok());
        assert!(validate_service_arguments(&["agent".into(), "leader".into()]).is_ok());
        assert!(validate_service_arguments(&[
            "agent".into(),
            "--model".into(),
            "grok-4.5-build-free".into(),
            "serve".into(),
            "--bind".into(),
            "127.0.0.1:2419".into(),
        ])
        .is_ok());
        assert!(validate_service_arguments(&[
            "--model".into(),
            "grok-4.5-build-free".into(),
            "--single".into(),
            "hello".into(),
        ])
        .is_ok());
        assert!(validate_service_arguments(&["models".into()]).is_err());
        assert!(validate_service_arguments(&["agent".into(), "stdio".into()]).is_err());
    }

    #[test]
    fn truncates_multibyte_service_output_on_character_boundaries() {
        let output = Mutex::new(String::new());
        let line = "中文输出".repeat(30_000);
        GrokCliService::append_output(&output, line.as_bytes(), false);
        let retained = output.lock().unwrap();
        assert!(retained.len() <= 80_003);
        assert!(retained
            .chars()
            .all(|character| "中文输出".contains(character)));
    }

    #[test]
    fn retains_full_output_for_one_shot_tasks() {
        let output = Mutex::new(String::new());
        let line = "x".repeat(120_000);
        GrokCliService::append_output(&output, line.as_bytes(), true);
        assert_eq!(output.lock().unwrap().len(), 120_000);
    }
}
