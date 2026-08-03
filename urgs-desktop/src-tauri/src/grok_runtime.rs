use base64::{engine::general_purpose::STANDARD as BASE64_STANDARD, Engine as _};
use keyring::Entry;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tauri::{AppHandle, Emitter, Manager, State};
use tauri_plugin_dialog::DialogExt;
use tauri_plugin_shell::process::{CommandChild, CommandEvent};
use tauri_plugin_shell::ShellExt;
use tokio::sync::{oneshot, Mutex as AsyncMutex};
use uuid::Uuid;

const GROK_EVENT_NAME: &str = "grok-event";
// ACP extension methods use an underscore-prefixed JSON-RPC wire name. The
// Grok agent strips the prefix before dispatching to its `x.ai/interject` handler.
const GROK_INTERJECT_METHOD: &str = "_x.ai/interject";
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);
const INITIALIZE_TIMEOUT: Duration = Duration::from_secs(90);
const AUTHENTICATE_TIMEOUT: Duration = Duration::from_secs(180);
const SESSION_START_TIMEOUT: Duration = Duration::from_secs(120);
const MODEL_PROVIDER_FILE: &str = "model-providers.json";
const MODEL_CREDENTIAL_SERVICE: &str = "com.urgs.desktop.grok-model";
const MODEL_KEY_AUTHORIZATION_REQUIRED: &str = "MODEL_KEY_AUTHORIZATION_REQUIRED:";
const OFFLINE_AUTH_FILE: &str = "urgs-offline-auth.json";
const MAX_PROMPT_ATTACHMENTS: usize = 20;
const MAX_PROMPT_ATTACHMENT_BYTES: u64 = 10 * 1024 * 1024;
const MAX_PROMPT_ATTACHMENTS_TOTAL_BYTES: u64 = 25 * 1024 * 1024;
const PROMPT_ATTACHMENT_GRANT_TTL_SECONDS: u64 = 60 * 60;
const MAX_PROMPT_ATTACHMENT_GRANTS: usize = 64;
static PROCESS_SEQUENCE: AtomicU64 = AtomicU64::new(1);
static MODEL_API_KEY_CACHE: OnceLock<Mutex<HashMap<String, String>>> = OnceLock::new();
#[cfg(target_os = "macos")]
static MACOS_KEYCHAIN_READ_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

fn request_timeout(method: &str) -> Duration {
    match method {
        "session/prompt" => Duration::from_secs(60 * 60),
        "initialize" => INITIALIZE_TIMEOUT,
        "authenticate" => AUTHENTICATE_TIMEOUT,
        "session/new" | "session/load" => SESSION_START_TIMEOUT,
        _ => REQUEST_TIMEOUT,
    }
}

fn initialize_client_meta(rules: Option<&str>) -> Value {
    let mut meta = json!({
        "clientType": "urgs-ark-desktop",
        "clientIdentifier": "urgs-desktop",
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
    pub model_catalog: Option<GrokModelCatalog>,
    pub mcp_servers: Vec<GrokMcpServerState>,
    pub replayed_events: Vec<Value>,
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct GrokAvailableCommand {
    pub name: String,
    pub description: String,
    pub input_hint: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokReasoningEffort {
    pub id: String,
    pub value: String,
    pub label: String,
    pub description: String,
    pub default: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokModelOption {
    pub model_id: String,
    pub name: String,
    pub description: String,
    pub supports_reasoning_effort: bool,
    pub reasoning_efforts: Vec<GrokReasoningEffort>,
    pub total_context_tokens: Option<u64>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokModelCatalog {
    pub current_model_id: Option<String>,
    pub available_models: Vec<GrokModelOption>,
    pub total_context_tokens: Option<u64>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokMcpServerState {
    pub name: String,
    pub transport: String,
    pub enabled: bool,
    pub source: String,
    pub command: Option<String>,
    pub args: Vec<String>,
    pub url: Option<String>,
    pub env_keys: Vec<String>,
    pub header_names: Vec<String>,
    pub health: String,
    pub tools: Vec<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokRuntimeDiagnostics {
    pub process_id: String,
    pub workspace: String,
    pub alive: bool,
    pub session_ids: Vec<String>,
    pub available_commands: Vec<GrokAvailableCommand>,
    pub model_catalog: Option<GrokModelCatalog>,
    pub mcp_servers: Vec<GrokMcpServerState>,
    pub initialize_meta: Value,
    pub stderr: String,
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

struct PromptAttachmentGrant {
    paths: Vec<PathBuf>,
    created_at: u64,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokPromptAttachmentSelection {
    paths: Vec<String>,
    grant_id: Option<String>,
}

pub struct GrokRuntimeState {
    startup: AsyncMutex<()>,
    prepared_process: Mutex<Option<Arc<GrokProcess>>>,
    session_processes: Mutex<HashMap<String, Arc<GrokProcess>>>,
    cli_services: Mutex<HashMap<String, Arc<GrokCliService>>>,
    prompt_attachment_grants: Mutex<HashMap<String, PromptAttachmentGrant>>,
    cli_service_sequence: AtomicU64,
    runtime_generation: AtomicU64,
}

impl Default for GrokRuntimeState {
    fn default() -> Self {
        Self {
            startup: AsyncMutex::new(()),
            prepared_process: Mutex::new(None),
            session_processes: Mutex::new(HashMap::new()),
            cli_services: Mutex::new(HashMap::new()),
            prompt_attachment_grants: Mutex::new(HashMap::new()),
            cli_service_sequence: AtomicU64::new(1),
            runtime_generation: AtomicU64::new(1),
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
    workspace: PathBuf,
    child: Mutex<Option<CommandChild>>,
    stderr: Mutex<String>,
    pending_requests: Mutex<HashMap<u64, oneshot::Sender<Result<Value, String>>>>,
    pending_permissions: Mutex<Vec<PendingPermission>>,
    pending_user_questions: Mutex<Vec<PendingUserQuestion>>,
    pending_plan_approvals: Mutex<Vec<PendingPlanApproval>>,
    available_commands: Mutex<Vec<GrokAvailableCommand>>,
    model_catalog: Mutex<Option<GrokModelCatalog>>,
    mcp_servers: Mutex<Vec<GrokMcpServerState>>,
    initialize_meta: Mutex<Value>,
    replayed_events: Mutex<Vec<Value>>,
    request_sequence: AtomicU64,
    initialized: AsyncMutex<bool>,
    uses_custom_model: bool,
    replaying_session: AtomicBool,
    alive: AtomicBool,
}

impl GrokProcess {
    fn new(
        child: CommandChild,
        launch_key: String,
        workspace: PathBuf,
        uses_custom_model: bool,
    ) -> Self {
        Self {
            process_id: format!(
                "runtime-{}",
                PROCESS_SEQUENCE.fetch_add(1, Ordering::Relaxed)
            ),
            launch_key,
            workspace,
            child: Mutex::new(Some(child)),
            stderr: Mutex::new(String::new()),
            pending_requests: Mutex::new(HashMap::new()),
            pending_permissions: Mutex::new(Vec::new()),
            pending_user_questions: Mutex::new(Vec::new()),
            pending_plan_approvals: Mutex::new(Vec::new()),
            available_commands: Mutex::new(Vec::new()),
            model_catalog: Mutex::new(None),
            mcp_servers: Mutex::new(Vec::new()),
            initialize_meta: Mutex::new(Value::Null),
            replayed_events: Mutex::new(Vec::new()),
            request_sequence: AtomicU64::new(1),
            initialized: AsyncMutex::new(false),
            uses_custom_model,
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
        self.request_with_meta(method, params, None).await
    }

    async fn request_with_meta(
        &self,
        method: &str,
        params: Value,
        meta: Option<Value>,
    ) -> Result<Value, String> {
        let id = self.request_sequence.fetch_add(1, Ordering::Relaxed);
        let (sender, receiver) = oneshot::channel();
        self.pending_requests
            .lock()
            .map_err(|_| "Grok 请求队列锁不可用".to_string())?
            .insert(id, sender);

        let mut message = json!({
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params,
        });
        if let Some(meta) = meta {
            message["meta"] = meta;
        }
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
        if let Ok(mut meta) = self.initialize_meta.lock() {
            *meta = response
                .get("_meta")
                .or_else(|| response.get("meta"))
                .cloned()
                .unwrap_or(Value::Null);
        }
        self.replace_model_catalog(model_catalog_from_initialize(&response));
        self.replace_available_commands(available_commands_from_initialize(&response));
        if !self.uses_custom_model {
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
        }

        *initialized = true;
        Ok(())
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

    fn replace_model_catalog(&self, catalog: Option<GrokModelCatalog>) {
        if let Ok(mut current) = self.model_catalog.lock() {
            *current = catalog;
        }
    }

    fn model_catalog(&self) -> Option<GrokModelCatalog> {
        self.model_catalog
            .lock()
            .ok()
            .and_then(|catalog| catalog.clone())
    }

    fn replace_mcp_servers(&self, servers: Vec<GrokMcpServerState>) {
        if let Ok(mut current) = self.mcp_servers.lock() {
            *current = servers;
        }
    }

    fn mcp_servers(&self) -> Vec<GrokMcpServerState> {
        self.mcp_servers
            .lock()
            .map(|servers| servers.clone())
            .unwrap_or_default()
    }

    fn initialize_meta(&self) -> Value {
        self.initialize_meta
            .lock()
            .map(|meta| meta.clone())
            .unwrap_or(Value::Null)
    }

    fn push_replayed_event(&self, event: Value) {
        if let Ok(mut events) = self.replayed_events.lock() {
            events.push(event);
            if events.len() > 10_000 {
                let keep_from = events.len().saturating_sub(8_000);
                events.drain(..keep_from);
            }
        }
    }

    fn take_replayed_events(&self) -> Vec<Value> {
        self.replayed_events
            .lock()
            .map(|mut events| std::mem::take(&mut *events))
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

fn model_catalog_from_initialize(response: &Value) -> Option<GrokModelCatalog> {
    let meta = response.get("_meta").or_else(|| response.get("meta"))?;
    let state = meta.get("modelState")?;
    let current_model_id = state
        .get("currentModelId")
        .or_else(|| state.get("current_model_id"))
        .and_then(Value::as_str)
        .map(str::to_string);
    let available_models = state
        .get("availableModels")
        .or_else(|| state.get("available_models"))
        .and_then(Value::as_array)
        .map(|models| {
            models
                .iter()
                .filter_map(|model| {
                    let model_id = model
                        .get("modelId")
                        .or_else(|| model.get("model_id"))
                        .or_else(|| model.get("id"))
                        .and_then(Value::as_str)
                        .map(str::trim)
                        .filter(|id| !id.is_empty())
                        .map(str::to_string)?;
                    let model_meta = model.get("_meta").or_else(|| model.get("meta"));
                    let reasoning_efforts = model_meta
                        .and_then(|value| value.get("reasoningEfforts"))
                        .or_else(|| model.get("reasoningEfforts"))
                        .and_then(Value::as_array)
                        .map(|efforts| {
                            efforts
                                .iter()
                                .filter_map(|effort| {
                                    let id = effort
                                        .get("id")
                                        .or_else(|| effort.get("value"))
                                        .and_then(Value::as_str)
                                        .map(str::trim)
                                        .filter(|value| !value.is_empty())
                                        .map(str::to_string)?;
                                    Some(GrokReasoningEffort {
                                        value: effort
                                            .get("value")
                                            .and_then(Value::as_str)
                                            .unwrap_or(&id)
                                            .to_string(),
                                        label: effort
                                            .get("label")
                                            .and_then(Value::as_str)
                                            .unwrap_or(&id)
                                            .to_string(),
                                        description: effort
                                            .get("description")
                                            .and_then(Value::as_str)
                                            .unwrap_or_default()
                                            .to_string(),
                                        default: effort
                                            .get("default")
                                            .and_then(Value::as_bool)
                                            .unwrap_or(false),
                                        id,
                                    })
                                })
                                .collect::<Vec<_>>()
                        })
                        .unwrap_or_default();
                    let total_context_tokens = model_meta
                        .and_then(|value| value.get("totalContextTokens"))
                        .or_else(|| model.get("totalContextTokens"))
                        .and_then(Value::as_u64);
                    Some(GrokModelOption {
                        model_id,
                        name: model
                            .get("name")
                            .and_then(Value::as_str)
                            .unwrap_or_default()
                            .to_string(),
                        description: model
                            .get("description")
                            .and_then(Value::as_str)
                            .unwrap_or_default()
                            .to_string(),
                        supports_reasoning_effort: model_meta
                            .and_then(|value| value.get("supportsReasoningEffort"))
                            .or_else(|| model.get("supportsReasoningEffort"))
                            .and_then(Value::as_bool)
                            .unwrap_or(!reasoning_efforts.is_empty()),
                        reasoning_efforts,
                        total_context_tokens,
                    })
                })
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();
    let total_context_tokens = state
        .get("totalContextTokens")
        .or_else(|| state.get("total_context_tokens"))
        .and_then(Value::as_u64);
    Some(GrokModelCatalog {
        current_model_id,
        available_models,
        total_context_tokens,
    })
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

fn toml_string_list(value: Option<&toml::Value>) -> Vec<String> {
    value
        .and_then(toml::Value::as_array)
        .into_iter()
        .flatten()
        .filter_map(toml::Value::as_str)
        .map(str::to_string)
        .collect()
}

fn toml_string_map(value: Option<&toml::Value>) -> Vec<(String, String)> {
    let mut entries = value
        .and_then(toml::Value::as_table)
        .into_iter()
        .flatten()
        .filter_map(|(key, value)| value.as_str().map(|value| (key.clone(), value.to_string())))
        .collect::<Vec<_>>();
    entries.sort_by(|left, right| left.0.cmp(&right.0));
    entries
}

fn mcp_server_from_toml(
    name: &str,
    entry: &toml::Value,
    source: &str,
) -> Option<(Value, GrokMcpServerState)> {
    let table = entry.as_table()?;
    let enabled = table
        .get("enabled")
        .and_then(toml::Value::as_bool)
        .unwrap_or(true);
    let args = toml_string_list(table.get("args"));
    let env = toml_string_map(table.get("env"));
    let headers = toml_string_map(table.get("headers"));
    let transport_type = table
        .get("type")
        .or_else(|| table.get("transport"))
        .and_then(toml::Value::as_str)
        .unwrap_or("http")
        .to_ascii_lowercase();
    if let Some(command) = table.get("command").and_then(toml::Value::as_str) {
        let mut command_args = Vec::with_capacity(args.len() + 1);
        command_args.extend(args.clone());
        let server = json!({
            "name": name,
            "command": command,
            "args": command_args,
            "env": env.iter().map(|(key, value)| json!({"name": key, "value": value})).collect::<Vec<_>>(),
        });
        let state = GrokMcpServerState {
            name: name.to_string(),
            transport: "stdio".to_string(),
            enabled,
            source: source.to_string(),
            command: Some(command.to_string()),
            args,
            url: None,
            env_keys: env.into_iter().map(|(key, _)| key).collect(),
            header_names: Vec::new(),
            health: if enabled { "configured" } else { "disabled" }.to_string(),
            tools: Vec::new(),
        };
        return Some((server, state));
    }
    let url = table.get("url").and_then(toml::Value::as_str)?.trim();
    if url.is_empty() {
        return None;
    }
    let transport = if transport_type == "sse" {
        "sse"
    } else {
        "http"
    };
    let server = json!({
        "type": transport,
        "name": name,
        "url": url,
        "headers": headers.iter().map(|(key, value)| json!({"name": key, "value": value})).collect::<Vec<_>>(),
    });
    let state = GrokMcpServerState {
        name: name.to_string(),
        transport: transport.to_string(),
        enabled,
        source: source.to_string(),
        command: None,
        args: Vec::new(),
        url: Some(url.to_string()),
        env_keys: env.into_iter().map(|(key, _)| key).collect(),
        header_names: headers.into_iter().map(|(key, _)| key).collect(),
        health: if enabled { "configured" } else { "disabled" }.to_string(),
        tools: Vec::new(),
    };
    Some((server, state))
}

fn mcp_servers_from_config_content(
    content: &str,
    source: &str,
) -> Result<Vec<(Value, GrokMcpServerState)>, String> {
    let config = parse_grok_toml(content)?;
    let Some(servers) = config.get("mcp_servers").and_then(toml::Value::as_table) else {
        return Ok(Vec::new());
    };
    Ok(servers
        .iter()
        .filter_map(|(name, entry)| mcp_server_from_toml(name, entry, source))
        .collect())
}

fn configured_mcp_servers(
    app: &AppHandle,
    workspace: &Path,
) -> Result<(Vec<Value>, Vec<GrokMcpServerState>), String> {
    let user_path = grok_config_path(app, "user", "config", None)?;
    let project_path = workspace.join(".grok").join("config.toml");
    let mut by_name: HashMap<String, (Value, GrokMcpServerState)> = HashMap::new();
    for (source, path) in [("user", user_path), ("project", project_path)] {
        if !path.is_file() {
            continue;
        }
        let content = fs::read_to_string(&path)
            .map_err(|error| format!("读取 {source} MCP 配置失败: {error}"))?;
        for (server, state) in mcp_servers_from_config_content(&content, source)? {
            by_name.insert(state.name.clone(), (server, state));
        }
    }
    let mut values = by_name.into_values().collect::<Vec<_>>();
    values.sort_by(|left, right| left.1.name.cmp(&right.1.name));
    let states = values
        .iter()
        .map(|(_, state)| state.clone())
        .collect::<Vec<_>>();
    let servers = values
        .into_iter()
        .filter_map(|(server, state)| state.enabled.then_some(server))
        .collect::<Vec<_>>();
    Ok((servers, states))
}

fn serialize_grok_toml(config: &toml::Value) -> Result<String, String> {
    toml::to_string(config).map_err(|error| format!("序列化本地智能引擎配置失败: {error}"))
}

fn apply_offline_config(config: &mut toml::Value) -> Result<(), String> {
    let root = config
        .as_table_mut()
        .ok_or_else(|| "本地智能引擎配置根节点必须是对象".to_string())?;
    root.remove("grok_com_config");

    let mut auth = toml::map::Map::new();
    auth.insert(
        "preferred_method".to_string(),
        toml::Value::String("api_key".to_string()),
    );
    root.insert("auth".to_string(), toml::Value::Table(auth));

    let cli = root
        .entry("cli".to_string())
        .or_insert_with(|| toml::Value::Table(toml::map::Map::new()))
        .as_table_mut()
        .ok_or_else(|| "本地智能引擎配置中的 cli 必须是对象".to_string())?;
    cli.insert("auto_update".to_string(), toml::Value::Boolean(false));

    let features = root
        .entry("features".to_string())
        .or_insert_with(|| toml::Value::Table(toml::map::Map::new()))
        .as_table_mut()
        .ok_or_else(|| "本地智能引擎配置中的 features 必须是对象".to_string())?;
    features.insert("remote_fetch".to_string(), toml::Value::Boolean(false));
    features.insert("telemetry".to_string(), toml::Value::Boolean(false));
    features.insert("feedback".to_string(), toml::Value::Boolean(false));

    let mut marketplace = toml::map::Map::new();
    marketplace.insert(
        "official_marketplace_auto_installed".to_string(),
        toml::Value::Boolean(true),
    );
    marketplace.insert(
        "default_skills_installs_purged".to_string(),
        toml::Value::Boolean(true),
    );
    root.insert("marketplace".to_string(), toml::Value::Table(marketplace));
    Ok(())
}

fn enforce_offline_config(app: &AppHandle) -> Result<(), String> {
    let path = grok_config_path(app, "user", "config", None)?;
    let content = if path.is_file() {
        fs::read_to_string(&path).map_err(|error| format!("读取本地智能引擎配置失败: {error}"))?
    } else {
        String::new()
    };
    let mut config = parse_grok_toml(&content)?;
    apply_offline_config(&mut config)?;
    let next = serialize_grok_toml(&config)?;
    if next != content {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .map_err(|error| format!("创建本地智能引擎配置目录失败: {error}"))?;
        }
        fs::write(path, next).map_err(|error| format!("保存内网运行配置失败: {error}"))?;
    }
    Ok(())
}

fn offline_runtime_envs(home: &Path) -> Vec<(String, String)> {
    let mut envs = std::env::vars()
        .filter(|(key, _)| {
            !key.starts_with("XAI_")
                && !matches!(
                    key.as_str(),
                    "GROK_AUTH"
                        | "GROK_AUTH_PATH"
                        | "GROK_AUTH_PROVIDER_COMMAND"
                        | "GROK_AUTH_PROVIDER_LABEL"
                        | "GROK_AUTH_TOKEN_TTL"
                        | "GROK_CODE_XAI_API_KEY"
                        | "GROK_OIDC_ISSUER"
                        | "GROK_OIDC_CLIENT_ID"
                        | "GROK_CLI_CHAT_PROXY_BASE_URL"
                )
        })
        .collect::<Vec<_>>();
    envs.extend([
        (
            "GROK_AUTH_PATH".to_string(),
            home.join(OFFLINE_AUTH_FILE).to_string_lossy().to_string(),
        ),
        ("GROK_OAUTH_ENABLED".to_string(), "false".to_string()),
        (
            "GROK_OFFICIAL_MARKETPLACE_AUTO_REGISTER".to_string(),
            "false".to_string(),
        ),
        ("GROK_TELEMETRY_ENABLED".to_string(), "false".to_string()),
        (
            "GROK_TELEMETRY_TRACE_UPLOAD".to_string(),
            "false".to_string(),
        ),
        ("GROK_BACKEND_SEARCH".to_string(), "false".to_string()),
        ("GROK_WEB_FETCH".to_string(), "false".to_string()),
        ("GROK_IMAGE_GEN".to_string(), "false".to_string()),
        ("GROK_IMAGE_EDIT".to_string(), "false".to_string()),
        ("GROK_VIDEO_GEN".to_string(), "false".to_string()),
        ("GROK_VOICE_MODE".to_string(), "false".to_string()),
    ]);
    envs
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
        "context_window".to_string(),
        toml::Value::Integer(provider.context_window as i64),
    );
    entry.insert(
        "agent_type".to_string(),
        toml::Value::String("grok-build".to_string()),
    );
    entry.insert("supported_in_api".to_string(), toml::Value::Boolean(true));
    entry.remove("api_key");
    entry.remove("auth_scheme");
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
            && !entry.contains_key("auth_scheme")
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

fn effective_acp_options(
    app: &AppHandle,
    model: Option<&str>,
    options: &GrokAcpOptions,
) -> Result<GrokAcpOptions, String> {
    let Some(model) = model.map(str::trim).filter(|model| !model.is_empty()) else {
        return Ok(options.clone());
    };
    let uses_custom_model = read_model_providers(app)?
        .iter()
        .any(|provider| provider.id == model);
    let mut effective = options.clone();
    if uses_custom_model {
        effective.reauth = None;
    }
    Ok(effective)
}

fn ensure_model_provider_ready(app: &AppHandle, model: Option<&str>) -> Result<(), String> {
    let Some(model) = model.map(str::trim).filter(|model| !model.is_empty()) else {
        return Ok(());
    };
    enforce_offline_config(app)?;
    let Some(provider) = read_model_providers(app)?
        .into_iter()
        .find(|provider| provider.id == model)
    else {
        return Err(format!(
            "模型连接“{model}”不存在；内网模式禁止回退到 xAI，请选择已配置的内网模型"
        ));
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

fn current_unix_seconds() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

fn build_prompt_content(prompt: &str, attachments: Vec<PathBuf>) -> Result<Vec<Value>, String> {
    let prompt = prompt.trim();
    if prompt.is_empty() {
        return Err("请输入要发送给智能体的内容".to_string());
    }
    if attachments.len() > MAX_PROMPT_ATTACHMENTS {
        return Err(format!("单次最多添加 {MAX_PROMPT_ATTACHMENTS} 个本地文件"));
    }

    let mut content = vec![json!({ "type": "text", "text": prompt })];
    let mut seen = HashSet::new();
    let mut total_size = 0_u64;
    for candidate in attachments {
        if !candidate.is_absolute() {
            return Err("附件必须是本地绝对路径".to_string());
        }
        let canonical = candidate
            .canonicalize()
            .map_err(|error| format!("无法访问附件 {}: {error}", candidate.display()))?;
        if !canonical.is_file() {
            return Err(format!("附件不是文件: {}", canonical.display()));
        }
        if !seen.insert(canonical.clone()) {
            continue;
        }
        let size = fs::metadata(&canonical)
            .map_err(|error| format!("无法读取附件信息 {}: {error}", canonical.display()))?
            .len();
        if size > MAX_PROMPT_ATTACHMENT_BYTES {
            return Err(format!(
                "附件超过单文件 10 MB 限制: {}",
                canonical.display()
            ));
        }
        total_size = total_size.saturating_add(size);
        if total_size > MAX_PROMPT_ATTACHMENTS_TOTAL_BYTES {
            return Err("附件总大小不能超过 25 MB".to_string());
        }
        let bytes = fs::read(&canonical)
            .map_err(|error| format!("无法读取附件 {}: {error}", canonical.display()))?;
        let uri = url::Url::from_file_path(&canonical)
            .map_err(|_| format!("无法生成附件 URI: {}", canonical.display()))?
            .to_string();
        match String::from_utf8(bytes) {
            Ok(text) => content.push(json!({
                "type": "resource",
                "resource": {
                    "uri": uri,
                    "mimeType": "text/plain",
                    "text": text
                }
            })),
            Err(error) => content.push(json!({
                "type": "resource",
                "resource": {
                    "uri": uri,
                    "mimeType": "application/octet-stream",
                    "blob": BASE64_STANDARD.encode(error.into_bytes())
                }
            })),
        }
    }
    Ok(content)
}

fn authorize_prompt_attachments(
    state: &GrokRuntimeState,
    attachments: Option<Vec<String>>,
    attachment_grants: Option<Vec<String>>,
) -> Result<Vec<PathBuf>, String> {
    let requested = attachments.unwrap_or_default();
    let grant_ids = attachment_grants.unwrap_or_default();
    if requested.is_empty() {
        return Ok(Vec::new());
    }
    if grant_ids.is_empty() {
        return Err("附件授权已失效，请重新选择本地文件".to_string());
    }

    let now = current_unix_seconds();
    let mut grants = state
        .prompt_attachment_grants
        .lock()
        .map_err(|_| "附件授权列表锁不可用".to_string())?;
    grants.retain(|_, grant| {
        now.saturating_sub(grant.created_at) <= PROMPT_ATTACHMENT_GRANT_TTL_SECONDS
    });

    let mut allowed = HashSet::new();
    for grant_id in &grant_ids {
        if let Some(grant) = grants.get(grant_id) {
            allowed.extend(grant.paths.iter().cloned());
        }
    }
    if allowed.is_empty() {
        return Err("附件授权已失效，请重新选择本地文件".to_string());
    }

    let mut authorized = Vec::new();
    let mut seen = HashSet::new();
    for requested_path in requested {
        let candidate = PathBuf::from(requested_path.trim());
        if requested_path.trim().is_empty() || !candidate.is_absolute() {
            return Err("附件必须是本地绝对路径".to_string());
        }
        let canonical = candidate
            .canonicalize()
            .map_err(|error| format!("无法访问附件 {}: {error}", candidate.display()))?;
        if !allowed.contains(&canonical) {
            return Err(format!(
                "附件未经过本次原生文件选择授权: {}",
                canonical.display()
            ));
        }
        if seen.insert(canonical.clone()) {
            authorized.push(canonical);
        }
    }

    Ok(authorized)
}

fn consume_prompt_attachment_grants(state: &GrokRuntimeState, grant_ids: &[String]) {
    if let Ok(mut grants) = state.prompt_attachment_grants.lock() {
        for grant_id in grant_ids {
            grants.remove(grant_id);
        }
    }
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
        "doctor",
        "export",
        "help",
        "inspect",
        "leader",
        "mcp",
        "memory",
        "plugin",
        "sessions",
        "trace",
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

fn normalized_session_update_message(message: &Value) -> Option<Value> {
    let method = message.get("method")?.as_str()?;
    let params = message.get("params")?;
    let normalized_params = match method {
        "session/update"
        | "sessionUpdate"
        | "x.ai/session_notification"
        | "x.ai/scheduled_task_created"
        | "x.ai/scheduled_task_fired"
        | "x.ai/scheduled_task_deleted" => params,
        "_x.ai/session/update" => params.get("params").unwrap_or(params),
        "_x.ai/session_notification"
            if params.get("method").and_then(Value::as_str)
                == Some("x.ai/session_notification") =>
        {
            params.get("params")?
        }
        _ => return None,
    };
    Some(json!({
        "jsonrpc": "2.0",
        "method": "session/update",
        "params": normalized_params,
    }))
}

fn normalized_queue_changed_params(message: &Value) -> Option<Value> {
    let method = message.get("method")?.as_str()?;
    let params = message.get("params")?;
    match method {
        "x.ai/queue/changed" => Some(params.clone()),
        "_x.ai/queue/changed" => {
            if params.get("method").and_then(Value::as_str) == Some("x.ai/queue/changed") {
                Some(
                    params
                        .get("params")
                        .cloned()
                        .unwrap_or_else(|| params.clone()),
                )
            } else {
                Some(params.clone())
            }
        }
        _ => None,
    }
}

fn mcp_server_state_from_value(value: &Value) -> Option<GrokMcpServerState> {
    let name = value.get("name").and_then(Value::as_str)?.trim();
    if name.is_empty() {
        return None;
    }
    let transport = value
        .get("type")
        .or_else(|| value.get("transport"))
        .and_then(Value::as_str)
        .unwrap_or_else(|| {
            if value.get("command").is_some() {
                "stdio"
            } else {
                "http"
            }
        })
        .to_ascii_lowercase();
    let args = value
        .get("args")
        .and_then(Value::as_array)
        .map(|items| {
            items
                .iter()
                .filter_map(Value::as_str)
                .map(str::to_string)
                .collect()
        })
        .unwrap_or_default();
    let env_keys = value
        .get("env")
        .and_then(Value::as_array)
        .map(|items| {
            items
                .iter()
                .filter_map(|item| item.get("name").and_then(Value::as_str).map(str::to_string))
                .collect()
        })
        .unwrap_or_default();
    let header_names = value
        .get("headers")
        .and_then(Value::as_array)
        .map(|items| {
            items
                .iter()
                .filter_map(|item| item.get("name").and_then(Value::as_str).map(str::to_string))
                .collect()
        })
        .unwrap_or_default();
    Some(GrokMcpServerState {
        name: name.to_string(),
        transport,
        enabled: true,
        source: value
            .get("source")
            .and_then(Value::as_str)
            .unwrap_or("session")
            .to_string(),
        command: value
            .get("command")
            .and_then(Value::as_str)
            .map(str::to_string),
        args,
        url: value.get("url").and_then(Value::as_str).map(str::to_string),
        env_keys,
        header_names,
        health: "connected".to_string(),
        tools: value
            .get("tools")
            .and_then(Value::as_array)
            .map(|items| {
                items
                    .iter()
                    .filter_map(Value::as_str)
                    .map(str::to_string)
                    .collect()
            })
            .unwrap_or_default(),
    })
}

fn normalized_mcp_servers_update_params(message: &Value) -> Option<Value> {
    let method = message.get("method")?.as_str()?;
    let params = message.get("params")?;
    let params = if method == "_x.ai/mcp/servers_updated"
        && params.get("method").and_then(Value::as_str) == Some("x.ai/mcp/servers_updated")
    {
        params.get("params").unwrap_or(params)
    } else {
        params
    };
    matches!(
        method,
        "x.ai/mcp/servers_updated" | "_x.ai/mcp/servers_updated"
    )
    .then(|| params.clone())
}

fn normalized_interjection_params(message: &Value) -> Option<Value> {
    let method = message.get("method")?.as_str()?;
    let params = message.get("params")?;
    match method {
        "x.ai/session/interjection" => Some(params.clone()),
        "_x.ai/session/interjection" => {
            if params.get("method").and_then(Value::as_str) == Some("x.ai/session/interjection") {
                Some(
                    params
                        .get("params")
                        .cloned()
                        .unwrap_or_else(|| params.clone()),
                )
            } else {
                Some(params.clone())
            }
        }
        _ => None,
    }
}

fn scheduled_prompt_injection(message: &Value) -> Option<(String, String, String)> {
    let method = message.get("method")?.as_str()?;
    let outer_params = message.get("params")?;
    let params = match method {
        "x.ai/scheduled_task_inject_prompt" => outer_params,
        "_x.ai/scheduled_task_inject_prompt" => outer_params.get("params").unwrap_or(outer_params),
        _ => return None,
    };
    let session_id = params.get("sessionId")?.as_str()?.trim().to_string();
    let prompt = params.get("prompt")?.as_str()?.trim().to_string();
    if session_id.is_empty() || prompt.is_empty() {
        return None;
    }
    let task_id = params
        .get("taskId")
        .and_then(Value::as_str)
        .unwrap_or_default()
        .trim()
        .to_string();
    Some((session_id, prompt, task_id))
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
    if matches!(
        method,
        "x.ai/scheduled_task_inject_prompt" | "_x.ai/scheduled_task_inject_prompt"
    ) {
        let Some((session_id, prompt, task_id)) = scheduled_prompt_injection(&message) else {
            emit_process_event(
                app,
                process,
                "runtime_error",
                json!({ "message": "Grok 定时任务注入事件缺少 sessionId 或 prompt" }),
            );
            return;
        };
        let app = app.clone();
        let process = Arc::clone(process);
        tauri::async_runtime::spawn(async move {
            emit_process_event(
                &app,
                &process,
                "scheduled_prompt",
                json!({
                    "sessionId": session_id,
                    "taskId": task_id,
                    "prompt": prompt,
                    "phase": "started",
                }),
            );
            let content = vec![json!({ "type": "text", "text": prompt })];
            match process
                .request(
                    "session/prompt",
                    json!({
                        "sessionId": session_id,
                        "prompt": content,
                    }),
                )
                .await
            {
                Ok(_) => emit_process_event(
                    &app,
                    &process,
                    "scheduled_prompt",
                    json!({
                        "sessionId": session_id,
                        "taskId": task_id,
                        "phase": "completed",
                    }),
                ),
                Err(error) => emit_process_event(
                    &app,
                    &process,
                    "scheduled_prompt",
                    json!({
                        "sessionId": session_id,
                        "taskId": task_id,
                        "phase": "failed",
                        "message": error,
                    }),
                ),
            }
        });
        return;
    }
    if let Some(queue_changed) = normalized_queue_changed_params(&message) {
        emit_process_event(app, process, "queue_changed", queue_changed);
        return;
    }
    if let Some(interjection) = normalized_interjection_params(&message) {
        emit_process_event(app, process, "interjection", interjection);
        return;
    }
    if let Some(mcp_update) = normalized_mcp_servers_update_params(&message) {
        let states = mcp_update
            .get("mcpServers")
            .or_else(|| mcp_update.get("mcp_servers"))
            .and_then(Value::as_array)
            .map(|servers| {
                servers
                    .iter()
                    .filter_map(mcp_server_state_from_value)
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();
        process.replace_mcp_servers(states.clone());
        emit_process_event(
            app,
            process,
            "mcp_servers_updated",
            json!({ "mcpServers": states, "raw": mcp_update }),
        );
        return;
    }
    if let Some(session_update) = normalized_session_update_message(&message) {
        if let Some(commands) = available_commands_from_session_update(&session_update) {
            process.replace_available_commands(commands);
        }
        if process.replaying_session.load(Ordering::Relaxed) {
            process.push_replayed_event(session_update);
        } else {
            emit_process_event(app, process, "session_update", session_update);
        }
        return;
    }
    match method {
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
    runtime_generation: u64,
) -> Result<String, String> {
    serde_json::to_string(&json!({
        "workspace": workspace.to_string_lossy(),
        "model": model.unwrap_or_default().trim(),
        "options": options,
        "rules": rules.unwrap_or_default().trim(),
        "runtimeGeneration": runtime_generation,
    }))
    .map_err(|error| format!("生成 Grok 会话启动配置失败: {error}"))
}

fn grok_agent_arguments(
    model: Option<&str>,
    options: &GrokAcpOptions,
    uses_custom_model: bool,
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
    if options.reauth.unwrap_or(false) && !uses_custom_model {
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
    runtime_generation: u64,
) -> Result<Arc<GrokProcess>, String> {
    if model
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .is_none()
    {
        return Err("内网模式必须选择已配置的模型连接".to_string());
    }
    ensure_model_provider_ready(app, model)?;
    let home = grok_home(app)?;
    let model_envs = model_provider_envs(app, model)?;
    let uses_custom_model = !model_envs.is_empty();
    let mut effective_options = options.clone();
    if uses_custom_model {
        effective_options.reauth = None;
    }
    let launch_key = process_launch_key(
        workspace,
        model,
        &effective_options,
        rules,
        runtime_generation,
    )?;
    let arguments = grok_agent_arguments(model, &effective_options, uses_custom_model)?;
    spawn_grok_process_with_env(app, workspace, arguments, model_envs, home, launch_key)
}

fn spawn_grok_process_with_env(
    app: &AppHandle,
    workspace: &Path,
    arguments: Vec<String>,
    model_envs: Vec<(String, String)>,
    home: PathBuf,
    launch_key: String,
) -> Result<Arc<GrokProcess>, String> {
    let uses_custom_model = !model_envs.is_empty();
    let mut process_envs = offline_runtime_envs(&home);
    process_envs.extend(model_envs);
    let (mut receiver, child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(arguments)
        .current_dir(workspace)
        .env_clear()
        .env("GROK_HOME", &home)
        .envs(process_envs)
        .spawn()
        .map_err(|error| format!("启动本地 Grok Build 失败: {error}"))?;
    let process = Arc::new(GrokProcess::new(
        child,
        launch_key,
        workspace.to_path_buf(),
        uses_custom_model,
    ));
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

fn take_prepared_process(
    state: &GrokRuntimeState,
    launch_key: &str,
) -> Result<Option<Arc<GrokProcess>>, String> {
    let prepared = state
        .prepared_process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .take();
    match prepared {
        Some(process)
            if process.alive.load(Ordering::Relaxed) && process.launch_key == launch_key =>
        {
            Ok(Some(process))
        }
        Some(process) => {
            process.stop();
            Ok(None)
        }
        None => Ok(None),
    }
}

fn live_process_for_launch_key(
    state: &GrokRuntimeState,
    launch_key: &str,
) -> Result<Option<Arc<GrokProcess>>, String> {
    let mut processes = state
        .session_processes
        .lock()
        .map_err(|_| "Grok 会话进程池锁不可用".to_string())?;
    processes.retain(|_, process| process.alive.load(Ordering::Relaxed));
    Ok(processes
        .values()
        .find(|process| process.launch_key == launch_key)
        .cloned())
}

fn workspace_process(
    state: &GrokRuntimeState,
    workspace: &Path,
) -> Result<Arc<GrokProcess>, String> {
    let prepared = state
        .prepared_process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .as_ref()
        .filter(|process| process.alive.load(Ordering::Relaxed) && process.workspace == workspace)
        .cloned();
    if let Some(process) = prepared {
        return Ok(process);
    }
    let mut processes = state
        .session_processes
        .lock()
        .map_err(|_| "Grok 会话进程池锁不可用".to_string())?;
    processes.retain(|_, process| process.alive.load(Ordering::Relaxed));
    processes
        .values()
        .find(|process| process.workspace == workspace)
        .cloned()
        .ok_or_else(|| "本地智能引擎正在准备会话能力".to_string())
}

#[tauri::command]
pub async fn grok_runtime_status(app: AppHandle) -> Result<GrokRuntimeStatus, String> {
    let home = grok_home(&app)?;
    enforce_offline_config(&app)?;
    let output = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(["--no-auto-update", "--version"])
        .env_clear()
        .envs(offline_runtime_envs(&home))
        .output()
        .await
        .map_err(|error| format!("检测 Grok Build 失败: {error}"))?;
    let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let available = output.status.success();

    Ok(GrokRuntimeStatus {
        available,
        authenticated: false,
        version: (!version.is_empty()).then_some(version),
        grok_home: home.to_string_lossy().to_string(),
        message: if available {
            Some("内网隔离模式已启用".to_string())
        } else {
            Some(String::from_utf8_lossy(&output.stderr).trim().to_string())
        },
    })
}

#[tauri::command]
pub async fn grok_available_commands(
    state: State<'_, GrokRuntimeState>,
    workspace: String,
) -> Result<Vec<GrokAvailableCommand>, String> {
    let workspace = validate_workspace(&workspace)?;
    let prepared = state
        .prepared_process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .as_ref()
        .filter(|process| process.alive.load(Ordering::Relaxed) && process.workspace == workspace)
        .cloned();
    let process = match prepared {
        Some(process) => process,
        None => {
            let mut processes = state
                .session_processes
                .lock()
                .map_err(|_| "Grok 会话进程池锁不可用".to_string())?;
            processes.retain(|_, process| process.alive.load(Ordering::Relaxed));
            processes
                .values()
                .find(|process| process.workspace == workspace)
                .cloned()
                .ok_or_else(|| "本地智能引擎正在准备会话能力".to_string())?
        }
    };
    let cached = process.available_commands();
    let response = process
        .request(
            "_x.ai/commands/list",
            json!({ "cwd": workspace.to_string_lossy() }),
        )
        .await?;
    let commands = available_commands_from_list(&response);
    if commands.is_empty() {
        return Ok(cached);
    }
    process.replace_available_commands(commands.clone());
    Ok(commands)
}

#[tauri::command]
pub async fn grok_model_catalog(
    state: State<'_, GrokRuntimeState>,
    workspace: String,
) -> Result<Option<GrokModelCatalog>, String> {
    let workspace = validate_workspace(&workspace)?;
    Ok(workspace_process(&state, &workspace)?.model_catalog())
}

#[tauri::command]
pub async fn grok_session_list(
    state: State<'_, GrokRuntimeState>,
    workspace: String,
    query: Option<String>,
    limit: Option<usize>,
    cursor: Option<String>,
) -> Result<Value, String> {
    let workspace = validate_workspace(&workspace)?;
    let process = workspace_process(&state, &workspace)?;
    process
        .request(
            "x.ai/session/list",
            json!({
                "cwd": workspace.to_string_lossy(),
                "query": query.filter(|value| !value.trim().is_empty()),
                "limit": limit.unwrap_or(50).clamp(1, 200),
                "cursor": cursor.filter(|value| !value.trim().is_empty()),
            }),
        )
        .await
}

#[tauri::command]
pub async fn grok_session_search(
    state: State<'_, GrokRuntimeState>,
    workspace: String,
    query: String,
    limit: Option<usize>,
) -> Result<Value, String> {
    let workspace = validate_workspace(&workspace)?;
    let query = query.trim();
    if query.is_empty() {
        return Ok(json!({ "results": [], "nextOffset": null, "totalEstimate": 0 }));
    }
    let process = workspace_process(&state, &workspace)?;
    process
        .request(
            "x.ai/session/search",
            json!({
                "query": query,
                "cwd": workspace.to_string_lossy(),
                "limit": limit.unwrap_or(20).clamp(1, 100),
                "offset": 0,
                "includeContent": true,
            }),
        )
        .await
}

#[tauri::command]
pub async fn grok_session_info(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    session_process(&state, session_id)?
        .request("x.ai/session/info", json!({ "sessionId": session_id }))
        .await
}

#[tauri::command]
pub async fn grok_compact_session(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    user_context: Option<String>,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    session_process(&state, session_id)?
        .request(
            "x.ai/compact_conversation",
            json!({ "sessionId": session_id, "userContext": user_context }),
        )
        .await
}

#[tauri::command]
pub async fn grok_recap_session(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    session_process(&state, session_id)?
        .request(
            "x.ai/recap",
            json!({ "sessionId": session_id, "auto": false }),
        )
        .await
}

#[tauri::command]
pub async fn grok_session_rename(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    title: String,
    workspace: Option<String>,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    let title = title.trim();
    if session_id.is_empty() || title.is_empty() {
        return Err("会话标识和名称不能为空".to_string());
    }
    let process = if let Some(workspace_value) = workspace
        .as_deref()
        .filter(|value| !value.trim().is_empty())
    {
        workspace_process(&state, &validate_workspace(workspace_value)?)?
    } else {
        session_process(&state, session_id)?
    };
    process
        .request(
            "x.ai/session/rename",
            json!({ "sessionId": session_id, "title": title, "cwd": workspace }),
        )
        .await
}

#[tauri::command]
pub async fn grok_session_delete(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    workspace: Option<String>,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let process = if let Some(workspace_value) = workspace
        .as_deref()
        .filter(|value| !value.trim().is_empty())
    {
        workspace_process(&state, &validate_workspace(workspace_value)?)?
    } else {
        session_process(&state, session_id)?
    };
    process
        .request(
            "x.ai/session/delete",
            json!({ "sessionId": session_id, "cwd": workspace }),
        )
        .await
}

#[tauri::command]
pub async fn grok_list_background_tasks(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    session_process(&state, session_id)?
        .request("x.ai/task/list", json!({ "sessionId": session_id }))
        .await
}

#[tauri::command]
pub async fn grok_kill_background_task(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    task_id: String,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    let task_id = task_id.trim();
    if session_id.is_empty() || task_id.is_empty() {
        return Err("会话和后台任务标识不能为空".to_string());
    }
    session_process(&state, session_id)?
        .request(
            "x.ai/task/kill",
            json!({ "sessionId": session_id, "taskId": task_id }),
        )
        .await
}

#[tauri::command]
pub async fn grok_get_subagent(
    state: State<'_, GrokRuntimeState>,
    subagent_id: String,
) -> Result<Value, String> {
    let subagent_id = subagent_id.trim();
    if subagent_id.is_empty() {
        return Err("子智能体标识不能为空".to_string());
    }
    let process = state
        .prepared_process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .as_ref()
        .filter(|process| process.alive.load(Ordering::Relaxed))
        .cloned()
        .or_else(|| {
            state.session_processes.lock().ok().and_then(|processes| {
                processes
                    .values()
                    .find(|process| process.alive.load(Ordering::Relaxed))
                    .cloned()
            })
        })
        .ok_or_else(|| "本地智能引擎尚未挂载会话".to_string())?;
    process
        .request("x.ai/subagent/get", json!({ "subagentId": subagent_id }))
        .await
}

#[tauri::command]
pub async fn grok_cancel_subagent(
    state: State<'_, GrokRuntimeState>,
    subagent_id: String,
) -> Result<Value, String> {
    let subagent_id = subagent_id.trim();
    if subagent_id.is_empty() {
        return Err("子智能体标识不能为空".to_string());
    }
    let process = state
        .prepared_process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .as_ref()
        .filter(|process| process.alive.load(Ordering::Relaxed))
        .cloned()
        .or_else(|| {
            state.session_processes.lock().ok().and_then(|processes| {
                processes
                    .values()
                    .find(|process| process.alive.load(Ordering::Relaxed))
                    .cloned()
            })
        })
        .ok_or_else(|| "本地智能引擎尚未挂载会话".to_string())?;
    process
        .request("x.ai/subagent/cancel", json!({ "subagentId": subagent_id }))
        .await
}

#[tauri::command]
pub async fn grok_session_update_mcp_servers(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    mcp_servers: Vec<Value>,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let process = session_process(&state, session_id)?;
    let states = mcp_servers
        .iter()
        .filter_map(mcp_server_state_from_value)
        .collect::<Vec<_>>();
    let result = process
        .request(
            "x.ai/session/update_mcp_servers",
            json!({ "sessionId": session_id, "mcpServers": mcp_servers }),
        )
        .await?;
    process.replace_mcp_servers(states);
    Ok(result)
}

#[tauri::command]
pub fn grok_mcp_list(app: AppHandle, workspace: String) -> Result<Vec<GrokMcpServerState>, String> {
    let workspace = validate_workspace(&workspace)?;
    Ok(configured_mcp_servers(&app, &workspace)?.1)
}

#[tauri::command]
pub fn grok_mcp_set_enabled(
    app: AppHandle,
    name: String,
    enabled: bool,
    workspace: Option<String>,
) -> Result<Vec<GrokMcpServerState>, String> {
    let name = name.trim();
    if name.is_empty() || name.len() > 128 || name.contains('\0') {
        return Err("MCP 服务名称不合法".to_string());
    }
    let workspace_path = workspace
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .map(validate_workspace)
        .transpose()?;
    let user_path = grok_config_path(&app, "user", "config", None)?;
    let project_path = workspace_path
        .as_ref()
        .map(|path| path.join(".grok").join("config.toml"));
    let project_has_server = project_path.as_ref().is_some_and(|path| {
        path.is_file()
            && fs::read_to_string(path)
                .ok()
                .and_then(|content| parse_grok_toml(&content).ok())
                .and_then(|config| config.get("mcp_servers").cloned())
                .and_then(|servers| servers.as_table().cloned())
                .is_some_and(|servers| servers.contains_key(name))
    });
    let path = if project_has_server {
        project_path.expect("project_has_server implies project_path")
    } else {
        user_path
    };
    let content = if path.is_file() {
        fs::read_to_string(&path).map_err(|error| format!("读取 MCP 配置失败: {error}"))?
    } else {
        String::new()
    };
    let mut config = parse_grok_toml(&content)?;
    let root = config
        .as_table_mut()
        .ok_or_else(|| "Grok 配置根节点必须是对象".to_string())?;
    let servers = root
        .get_mut("mcp_servers")
        .and_then(toml::Value::as_table_mut)
        .ok_or_else(|| format!("未找到 MCP 服务“{name}”"))?;
    let entry = servers
        .get_mut(name)
        .and_then(toml::Value::as_table_mut)
        .ok_or_else(|| format!("未找到 MCP 服务“{name}”"))?;
    entry.insert("enabled".to_string(), toml::Value::Boolean(enabled));
    if path.is_file() {
        fs::copy(&path, path.with_extension("toml.urgs-backup"))
            .map_err(|error| format!("备份 MCP 配置失败: {error}"))?;
    }
    fs::write(&path, serialize_grok_toml(&config)?)
        .map_err(|error| format!("保存 MCP 配置失败: {error}"))?;
    let display_workspace =
        workspace_path.unwrap_or(std::env::current_dir().map_err(|error| error.to_string())?);
    Ok(configured_mcp_servers(&app, &display_workspace)?.1)
}

#[tauri::command]
pub async fn grok_reload_mcp_servers(
    state: State<'_, GrokRuntimeState>,
    workspace: String,
) -> Result<Value, String> {
    let workspace = validate_workspace(&workspace)?;
    workspace_process(&state, &workspace)?
        .request("x.ai/internal/reload_all_mcp_servers", json!({}))
        .await
}

#[tauri::command]
pub async fn grok_memory_flush(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    session_process(&state, session_id)?
        .request("x.ai/memory/flush", json!({ "session_id": session_id }))
        .await
}

#[tauri::command]
pub fn grok_runtime_diagnostics(
    state: State<'_, GrokRuntimeState>,
) -> Result<Vec<GrokRuntimeDiagnostics>, String> {
    let mut by_process: HashMap<String, (Arc<GrokProcess>, Vec<String>)> = HashMap::new();
    if let Some(process) = state
        .prepared_process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .as_ref()
        .filter(|process| process.alive.load(Ordering::Relaxed))
        .cloned()
    {
        by_process.insert(process.process_id.clone(), (process, Vec::new()));
    }
    for (session_id, process) in state
        .session_processes
        .lock()
        .map_err(|_| "Grok 会话进程池锁不可用".to_string())?
        .iter()
    {
        if !process.alive.load(Ordering::Relaxed) {
            continue;
        }
        by_process
            .entry(process.process_id.clone())
            .or_insert_with(|| (Arc::clone(process), Vec::new()))
            .1
            .push(session_id.clone());
    }
    Ok(by_process
        .into_values()
        .map(|(process, session_ids)| GrokRuntimeDiagnostics {
            process_id: process.process_id.clone(),
            workspace: process.workspace.to_string_lossy().to_string(),
            alive: process.alive.load(Ordering::Relaxed),
            session_ids,
            available_commands: process.available_commands(),
            model_catalog: process.model_catalog(),
            mcp_servers: process.mcp_servers(),
            initialize_meta: process.initialize_meta(),
            stderr: process
                .stderr
                .lock()
                .map(|value| value.clone())
                .unwrap_or_default(),
        })
        .collect())
}

#[tauri::command]
pub async fn grok_runtime_prepare(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: String,
    model: String,
    options: Option<GrokAcpOptions>,
    rules: Option<String>,
) -> Result<(), String> {
    let workspace = validate_workspace(&workspace)?;
    let model = normalize_model_id(&model)?;
    let options = options.unwrap_or_default();
    let effective_options = effective_acp_options(&app, Some(&model), &options)?;
    let _startup = state.startup.lock().await;
    let runtime_generation = state.runtime_generation.load(Ordering::Relaxed);
    let launch_key = process_launch_key(
        &workspace,
        Some(&model),
        &effective_options,
        rules.as_deref(),
        runtime_generation,
    )?;
    let has_compatible_live_session = state
        .session_processes
        .lock()
        .map_err(|_| "Grok 会话进程池锁不可用".to_string())?
        .values()
        .any(|process| process.alive.load(Ordering::Relaxed) && process.launch_key == launch_key);
    if has_compatible_live_session {
        return Ok(());
    }
    {
        let mut prepared = state
            .prepared_process
            .lock()
            .map_err(|_| "Grok 运行时锁不可用".to_string())?;
        if prepared.as_ref().is_some_and(|process| {
            process.alive.load(Ordering::Relaxed) && process.launch_key == launch_key
        }) {
            return Ok(());
        }
        if let Some(process) = prepared.take() {
            process.stop();
        }
    }
    let process = spawn_grok_process(
        &app,
        &workspace,
        Some(&model),
        &options,
        rules.as_deref(),
        runtime_generation,
    )?;
    if let Err(error) = process.initialize(rules.as_deref()).await {
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
    enforce_offline_config(&app)?;
    let model = model_from_arguments(&arguments);
    ensure_model_provider_ready(&app, model)?;
    let current_dir = match workspace.filter(|value| !value.trim().is_empty()) {
        Some(workspace) => validate_workspace(&workspace)?,
        None => grok_home(&app)?,
    };
    let mut command_arguments = vec!["--no-auto-update".to_string()];
    command_arguments.extend(arguments.iter().cloned());
    let home = grok_home(&app)?;
    let mut process_envs = offline_runtime_envs(&home);
    process_envs.extend(model_provider_envs(&app, model)?);
    let command = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(command_arguments)
        .current_dir(current_dir)
        .env_clear()
        .env("GROK_HOME", &home)
        .envs(process_envs);
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
        enforce_offline_config(&app)?;
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
    ensure_model_provider_ready(&app, Some(&model))?;
    let path = grok_config_path(&app, "user", "config", None)?;
    let content = if path.is_file() {
        fs::read_to_string(&path).map_err(|error| format!("读取 Grok 配置失败: {error}"))?
    } else {
        String::new()
    };
    let mut config = parse_grok_toml(&content)?;
    apply_offline_config(&mut config)?;
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
    enforce_offline_config(&app)?;
    let model = model_from_arguments(&arguments);
    ensure_model_provider_ready(&app, model)?;
    let current_dir = match workspace.filter(|value| !value.trim().is_empty()) {
        Some(workspace) => validate_workspace(&workspace)?,
        None => grok_home(&app)?,
    };
    let mut command_arguments = vec!["--no-auto-update".to_string()];
    command_arguments.extend(arguments.iter().cloned());
    let home = grok_home(&app)?;
    let mut process_envs = offline_runtime_envs(&home);
    process_envs.extend(model_provider_envs(&app, model)?);
    let (mut receiver, child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(command_arguments)
        .current_dir(current_dir)
        .env_clear()
        .env("GROK_HOME", &home)
        .envs(process_envs)
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
    let options = options.unwrap_or_default();
    let effective_options = effective_acp_options(&app, model.as_deref(), &options)?;
    let _startup = state.startup.lock().await;
    let runtime_generation = state.runtime_generation.load(Ordering::Relaxed);
    let launch_key = process_launch_key(
        &workspace,
        model.as_deref(),
        &effective_options,
        rules.as_deref(),
        runtime_generation,
    )?;
    let (process, exclusive_process) =
        if let Some(process) = take_prepared_process(&state, &launch_key)? {
            (process, true)
        } else if let Some(process) = live_process_for_launch_key(&state, &launch_key)? {
            (process, false)
        } else {
            let process = spawn_grok_process(
                &app,
                &workspace,
                model.as_deref(),
                &options,
                rules.as_deref(),
                runtime_generation,
            )?;
            if let Err(error) = process.initialize(rules.as_deref()).await {
                process.stop();
                return Err(error);
            }
            (process, true)
        };
    let (mcp_payload, mcp_states) = configured_mcp_servers(&app, &workspace)?;
    process.replace_mcp_servers(mcp_states.clone());
    let response = match process
        .request(
            "session/new",
            json!({
                "cwd": workspace,
                "mcpServers": mcp_payload,
            }),
        )
        .await
    {
        Ok(response) => response,
        Err(error) => {
            if exclusive_process {
                process.stop();
            }
            return Err(error);
        }
    };
    let session_id = match response.get("sessionId").and_then(Value::as_str) {
        Some(session_id) => session_id.to_string(),
        None => {
            if exclusive_process {
                process.stop();
            }
            return Err("Grok 未返回会话标识".to_string());
        }
    };
    if let Err(error) = register_session_process(&state, &session_id, Arc::clone(&process)) {
        if exclusive_process {
            process.stop();
        }
        return Err(error);
    }
    Ok(GrokSession {
        session_id,
        workspace: workspace.to_string_lossy().to_string(),
        process_id: process.process_id.clone(),
        available_commands: process.available_commands(),
        model_catalog: process.model_catalog(),
        mcp_servers: mcp_states,
        replayed_events: Vec::new(),
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
    let effective_options = effective_acp_options(&app, model.as_deref(), &options)?;
    let _startup = state.startup.lock().await;
    let runtime_generation = state.runtime_generation.load(Ordering::Relaxed);
    let launch_key = process_launch_key(
        &workspace,
        model.as_deref(),
        &effective_options,
        rules.as_deref(),
        runtime_generation,
    )?;
    let (existing, existing_is_shared) = {
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
                model_catalog: process.model_catalog(),
                mcp_servers: process.mcp_servers(),
                replayed_events: Vec::new(),
            });
        }
        let existing = processes.remove(&session_id);
        let shared = existing.as_ref().is_some_and(|existing| {
            processes
                .values()
                .any(|process| process.process_id == existing.process_id)
        });
        (existing, shared)
    };
    if let Some(existing) = existing.filter(|_| !existing_is_shared) {
        existing.stop();
    }
    stop_prepared_process(&state)?;
    let process = spawn_grok_process(
        &app,
        &workspace,
        model.as_deref(),
        &options,
        rules.as_deref(),
        runtime_generation,
    )?;
    if let Err(error) = process.initialize(rules.as_deref()).await {
        process.stop();
        return Err(error);
    }
    let (mcp_payload, mcp_states) = configured_mcp_servers(&app, &workspace)?;
    process.replace_mcp_servers(mcp_states.clone());
    process.replaying_session.store(true, Ordering::Relaxed);
    let load_result = process
        .request(
            "session/load",
            json!({
                "sessionId": session_id,
                "cwd": workspace,
                "mcpServers": mcp_payload,
            }),
        )
        .await;
    process.replaying_session.store(false, Ordering::Relaxed);
    let replayed_events = process.take_replayed_events();
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
        model_catalog: process.model_catalog(),
        mcp_servers: mcp_states,
        replayed_events,
    })
}

#[tauri::command]
pub async fn grok_pick_prompt_attachments(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
) -> Result<GrokPromptAttachmentSelection, String> {
    let selected = app
        .dialog()
        .file()
        .set_title("选择任务附件")
        .blocking_pick_files()
        .unwrap_or_default();
    if selected.len() > MAX_PROMPT_ATTACHMENTS {
        return Err(format!("单次最多添加 {MAX_PROMPT_ATTACHMENTS} 个本地文件"));
    }

    let mut paths = Vec::new();
    let mut seen = HashSet::new();
    for selected_path in selected {
        let candidate = selected_path
            .into_path()
            .map_err(|error| format!("无法读取所选附件路径: {error}"))?;
        let canonical = candidate
            .canonicalize()
            .map_err(|error| format!("无法访问附件 {}: {error}", candidate.display()))?;
        if !canonical.is_file() {
            return Err(format!("附件不是文件: {}", canonical.display()));
        }
        if seen.insert(canonical.clone()) {
            paths.push(canonical);
        }
    }
    if paths.is_empty() {
        return Ok(GrokPromptAttachmentSelection {
            paths: Vec::new(),
            grant_id: None,
        });
    }

    let grant_id = Uuid::new_v4().to_string();
    let now = current_unix_seconds();
    let mut grants = state
        .prompt_attachment_grants
        .lock()
        .map_err(|_| "附件授权列表锁不可用".to_string())?;
    grants.retain(|_, grant| {
        now.saturating_sub(grant.created_at) <= PROMPT_ATTACHMENT_GRANT_TTL_SECONDS
    });
    while grants.len() >= MAX_PROMPT_ATTACHMENT_GRANTS {
        let Some(oldest_id) = grants
            .iter()
            .min_by_key(|(_, grant)| grant.created_at)
            .map(|(id, _)| id.clone())
        else {
            break;
        };
        grants.remove(&oldest_id);
    }
    grants.insert(
        grant_id.clone(),
        PromptAttachmentGrant {
            paths: paths.clone(),
            created_at: now,
        },
    );
    Ok(GrokPromptAttachmentSelection {
        paths: paths
            .into_iter()
            .map(|path| path.to_string_lossy().to_string())
            .collect(),
        grant_id: Some(grant_id),
    })
}

#[tauri::command]
pub async fn grok_send_prompt(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    prompt: String,
    attachments: Option<Vec<String>>,
    attachment_grants: Option<Vec<String>>,
    queued: Option<bool>,
) -> Result<(), String> {
    let grants_to_consume = attachment_grants.clone().unwrap_or_default();
    let attachments = authorize_prompt_attachments(&state, attachments, attachment_grants)?;
    let content = build_prompt_content(&prompt, attachments)?;
    let process = session_process(&state, &session_id)?;
    let prompt_meta = Some(json!({ "clientIdentifier": "urgs-desktop" }));
    if queued.unwrap_or(false) {
        let queued_session_id = session_id.clone();
        let queued_process = Arc::clone(&process);
        emit_process_event(
            &app,
            &queued_process,
            "queued_prompt",
            json!({ "sessionId": queued_session_id, "phase": "accepted" }),
        );
        tauri::async_runtime::spawn(async move {
            let result = queued_process
                .request_with_meta(
                    "session/prompt",
                    json!({
                        "sessionId": queued_session_id,
                        "prompt": content
                    }),
                    prompt_meta,
                )
                .await;
            match result {
                Ok(_) => emit_process_event(
                    &app,
                    &queued_process,
                    "queued_prompt",
                    json!({ "sessionId": queued_session_id, "phase": "completed" }),
                ),
                Err(error) => emit_process_event(
                    &app,
                    &queued_process,
                    "queued_prompt",
                    json!({
                        "sessionId": queued_session_id,
                        "phase": "failed",
                        "message": error,
                    }),
                ),
            }
        });
        consume_prompt_attachment_grants(&state, &grants_to_consume);
        return Ok(());
    }
    process
        .request_with_meta(
            "session/prompt",
            json!({
                "sessionId": session_id,
                "prompt": content
            }),
            prompt_meta,
        )
        .await?;
    consume_prompt_attachment_grants(&state, &grants_to_consume);
    Ok(())
}

#[tauri::command]
pub async fn grok_queue_action(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    action: String,
    id: Option<String>,
    expected_version: Option<u64>,
    new_text: Option<String>,
    ordered_ids: Option<Vec<String>>,
) -> Result<(), String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let process = session_process(&state, session_id)?;
    let mut params = json!({ "sessionId": session_id, "clientIdentifier": "urgs-desktop" });
    let method = match action.trim() {
        "remove" => {
            params["id"] = json!(id
                .filter(|value| !value.trim().is_empty())
                .ok_or_else(|| "队列项标识不能为空".to_string())?);
            params["expectedVersion"] = json!(expected_version.unwrap_or(0));
            "_x.ai/queue/remove"
        }
        "edit" => {
            params["id"] = json!(id
                .filter(|value| !value.trim().is_empty())
                .ok_or_else(|| "队列项标识不能为空".to_string())?);
            let text = new_text
                .filter(|value| !value.trim().is_empty())
                .ok_or_else(|| "队列内容不能为空".to_string())?;
            params["newText"] = json!(text);
            "_x.ai/queue/edit"
        }
        "reorder" => {
            params["orderedIds"] = json!(ordered_ids.unwrap_or_default());
            "_x.ai/queue/reorder"
        }
        "clear" => "_x.ai/queue/clear",
        "send_now" => {
            params["id"] = json!(id
                .filter(|value| !value.trim().is_empty())
                .ok_or_else(|| "队列项标识不能为空".to_string())?);
            params["expectedVersion"] = json!(expected_version.unwrap_or(0));
            if let Some(text) = new_text.filter(|value| !value.trim().is_empty()) {
                params["newText"] = json!(text);
            }
            "_x.ai/queue/interject"
        }
        "interject" => {
            let id = id
                .filter(|value| !value.trim().is_empty())
                .ok_or_else(|| "队列项标识不能为空".to_string())?;
            let text = new_text
                .filter(|value| !value.trim().is_empty())
                .ok_or_else(|| "补充内容不能为空".to_string())?;
            let interjection_id = format!("urgs-{}", Uuid::new_v4());
            process
                .request(
                    GROK_INTERJECT_METHOD,
                    json!({
                        "sessionId": session_id,
                        "text": text,
                        "interjectionId": interjection_id,
                    }),
                )
                .await?;
            return process.notify(
                "_x.ai/queue/remove",
                json!({
                    "sessionId": session_id,
                    "id": id,
                    "expectedVersion": expected_version.unwrap_or(0),
                }),
            );
        }
        _ => return Err("不支持的队列操作".to_string()),
    };
    process.notify(method, params)
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
pub async fn grok_rewind_points(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let process = session_process(&state, session_id)?;
    process
        .request("_x.ai/rewind/points", json!({ "sessionId": session_id }))
        .await
}

#[tauri::command]
pub async fn grok_rewind_files(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    target_prompt_index: usize,
    workspace: String,
    model: String,
    rules: Option<String>,
    options: Option<GrokAcpOptions>,
    force: bool,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let workspace = validate_workspace(&workspace)?;
    let model = normalize_model_id(&model)?;
    let provider = read_model_providers(&app)?
        .into_iter()
        .find(|provider| provider.id == model)
        .ok_or_else(|| format!("模型连接“{model}”不存在"))?;
    if !provider.enabled {
        return Err(format!("模型连接“{}”已停用", provider.name));
    }
    let (process, transient) = match session_process(&state, session_id) {
        Ok(process) => (process, false),
        Err(_) => {
            enforce_offline_config(&app)?;
            let mut effective_options = options.unwrap_or_default();
            effective_options.reauth = None;
            let arguments = grok_agent_arguments(Some(&model), &effective_options, true)?;
            let home = grok_home(&app)?;
            let process = spawn_grok_process_with_env(
                &app,
                &workspace,
                arguments,
                vec![(
                    model_key_env_name(&model),
                    "urgs-rewind-local-only".to_string(),
                )],
                home,
                format!("rewind-{}", Uuid::new_v4()),
            )?;
            if let Err(error) = process.initialize(rules.as_deref()).await {
                process.stop();
                return Err(error);
            }
            let (mcp_payload, mcp_states) = configured_mcp_servers(&app, &workspace)?;
            process.replace_mcp_servers(mcp_states);
            process.replaying_session.store(true, Ordering::Relaxed);
            let load_result = process
                .request(
                    "session/load",
                    json!({
                        "sessionId": session_id,
                        "cwd": workspace,
                        "mcpServers": mcp_payload,
                    }),
                )
                .await;
            process.replaying_session.store(false, Ordering::Relaxed);
            if let Err(error) = load_result {
                process.stop();
                return Err(error);
            }
            (process, true)
        }
    };
    let points = process
        .request("_x.ai/rewind/points", json!({ "sessionId": session_id }))
        .await;
    let points = match points {
        Ok(points) => points,
        Err(error) => {
            if transient {
                process.stop();
            }
            return Err(error);
        }
    };
    let matching_point = points
        .get("rewindPoints")
        .or_else(|| points.get("rewind_points"))
        .and_then(Value::as_array)
        .and_then(|items| {
            items.iter().find(|item| {
                item.get("promptIndex")
                    .or_else(|| item.get("prompt_index"))
                    .and_then(Value::as_u64)
                    == Some(target_prompt_index as u64)
            })
        })
        .ok_or_else(|| "当前会话没有对应的文件撤销检查点".to_string());
    let matching_point = match matching_point {
        Ok(point) => point,
        Err(error) => {
            if transient {
                process.stop();
            }
            return Err(error);
        }
    };
    let has_file_changes = matching_point
        .get("hasFileChanges")
        .or_else(|| matching_point.get("has_file_changes"))
        .and_then(Value::as_bool)
        .unwrap_or(false);
    if !has_file_changes {
        if transient {
            process.stop();
        }
        return Err("该轮没有可撤销的文件修改".to_string());
    }
    let result = process
        .request(
            "_x.ai/rewind/execute",
            json!({
                "sessionId": session_id,
                "targetPromptIndex": target_prompt_index,
                "force": force,
                "mode": "files_only",
            }),
        )
        .await;
    if transient {
        process.stop();
    }
    result
}

#[tauri::command]
pub async fn grok_scheduled_task_delete(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    task_id: String,
) -> Result<bool, String> {
    let session_id = session_id.trim();
    let task_id = task_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    if task_id.is_empty() {
        return Err("计划任务标识不能为空".to_string());
    }
    let process = session_process(&state, session_id)?;
    let response = process
        .request(
            "x.ai/scheduler/delete",
            json!({ "sessionId": session_id, "taskId": task_id }),
        )
        .await?;
    Ok(response
        .get("deleted")
        .and_then(Value::as_bool)
        .unwrap_or(false))
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
pub fn grok_release_session(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<(), String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let (process, shared) = {
        let mut processes = state
            .session_processes
            .lock()
            .map_err(|_| "Grok 会话进程池锁不可用".to_string())?;
        let process = processes.remove(session_id);
        let shared = process.as_ref().is_some_and(|removed| {
            processes
                .values()
                .any(|candidate| candidate.process_id == removed.process_id)
        });
        (process, shared)
    };
    if let Some(process) = process {
        if shared {
            for request_id in process.cancel_permissions(session_id) {
                process.write_json(json!({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": { "outcome": { "outcome": "cancelled" } }
                }))?;
            }
            for request_id in process.cancel_user_questions(session_id) {
                process.write_json(json!({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": { "outcome": "cancelled" }
                }))?;
            }
            for request_id in process.cancel_plan_approvals(session_id) {
                process.write_json(json!({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": { "outcome": "abandoned" }
                }))?;
            }
        } else {
            process.stop();
        }
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
pub async fn grok_runtime_invalidate_prepared(
    state: State<'_, GrokRuntimeState>,
) -> Result<(), String> {
    let _startup = state.startup.lock().await;
    state.runtime_generation.fetch_add(1, Ordering::Relaxed);
    stop_prepared_process(&state)
}

#[tauri::command]
pub fn grok_start_login(
    _app: AppHandle,
    _state: State<'_, GrokRuntimeState>,
    _method: Option<String>,
) -> Result<(), String> {
    Err("URGS 已启用内网隔离模式，不支持 xAI 登录".to_string())
}

#[cfg(test)]
mod tests {
    use super::{
        apply_offline_config, authorize_prompt_attachments, available_commands_from_initialize,
        available_commands_from_list, available_commands_from_session_update, build_prompt_content,
        cache_provider_api_key, consume_prompt_attachment_grants, forget_cached_provider_api_key,
        format_rpc_error, grok_agent_arguments, model_key_env_name, normalize_model_id,
        normalize_model_provider, normalized_interjection_params, normalized_queue_changed_params,
        normalized_session_update_message, parse_grok_toml, plan_approval_params,
        process_launch_key, read_provider_api_key, request_timeout, scheduled_prompt_injection,
        select_auth_method, serialize_grok_toml, user_question_params, validate_cli_arguments,
        validate_service_arguments, GrokAcpOptions, GrokCliService, GrokModelProviderInput,
        GrokRuntimeState, PromptAttachmentGrant, AUTHENTICATE_TIMEOUT, GROK_INTERJECT_METHOD,
        INITIALIZE_TIMEOUT, MAX_PROMPT_ATTACHMENT_BYTES, REQUEST_TIMEOUT, SESSION_START_TIMEOUT,
    };
    use serde_json::json;
    use std::fs;
    use std::path::{Path, PathBuf};
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
    fn builds_embedded_acp_resources_for_selected_attachments() {
        let attachment = Path::new(env!("CARGO_MANIFEST_DIR")).join("Cargo.toml");
        let content = build_prompt_content("分析这个文件", vec![attachment]).unwrap();

        assert_eq!(content[0]["type"], "text");
        assert_eq!(content[0]["text"], "分析这个文件");
        assert_eq!(content[1]["type"], "resource");
        assert_eq!(content[1]["resource"]["mimeType"], "text/plain");
        assert!(content[1]["resource"]["text"]
            .as_str()
            .is_some_and(|text| text.contains("[package]")));
        assert!(content[1]["resource"]["uri"]
            .as_str()
            .is_some_and(|uri| uri.starts_with("file://")));
    }

    #[test]
    fn encodes_spaces_and_non_ascii_characters_in_attachment_uris() {
        let test_directory = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("target")
            .join(format!("attachment-test-{}", std::process::id()));
        fs::create_dir_all(&test_directory).unwrap();
        let attachment = test_directory.join("本地 报告.txt");
        fs::write(&attachment, "attachment test").unwrap();

        let content = build_prompt_content("分析这个文件", vec![attachment.clone()]).unwrap();
        let uri = content[1]["resource"]["uri"].as_str().unwrap();

        assert!(uri.contains("%20"));
        assert!(uri.contains("%E6%9C%AC%E5%9C%B0"));

        fs::remove_file(&attachment).unwrap();
        fs::remove_dir(&test_directory).unwrap();
    }

    #[test]
    fn embeds_binary_attachments_as_base64_resources() {
        let test_directory = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("target")
            .join(format!("binary-attachment-test-{}", std::process::id()));
        fs::create_dir_all(&test_directory).unwrap();
        let attachment = test_directory.join("sample.bin");
        fs::write(&attachment, [0, 159, 146, 150]).unwrap();

        let content = build_prompt_content("分析这个文件", vec![attachment.clone()]).unwrap();

        assert_eq!(
            content[1]["resource"]["mimeType"],
            "application/octet-stream"
        );
        assert_eq!(content[1]["resource"]["blob"], "AJ+Slg==");

        fs::remove_file(&attachment).unwrap();
        fs::remove_dir(&test_directory).unwrap();
    }

    #[test]
    fn rejects_oversized_prompt_attachments_before_reading_them() {
        let test_directory = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("target")
            .join(format!("large-attachment-test-{}", std::process::id()));
        fs::create_dir_all(&test_directory).unwrap();
        let attachment = test_directory.join("large.bin");
        let file = fs::File::create(&attachment).unwrap();
        file.set_len(MAX_PROMPT_ATTACHMENT_BYTES + 1).unwrap();

        let error = build_prompt_content("分析这个文件", vec![attachment.clone()]).unwrap_err();

        assert!(error.contains("10 MB"));

        fs::remove_file(&attachment).unwrap();
        fs::remove_dir(&test_directory).unwrap();
    }

    #[test]
    fn rejects_relative_prompt_attachments() {
        let error = build_prompt_content("分析", vec![PathBuf::from("relative.txt")]).unwrap_err();
        assert!(error.contains("绝对路径"));
    }

    #[test]
    fn only_accepts_native_picker_granted_attachment_paths_once() {
        let test_directory = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("target")
            .join(format!("attachment-grant-test-{}", std::process::id()));
        fs::create_dir_all(&test_directory).unwrap();
        let attachment = test_directory.join("allowed.txt");
        fs::write(&attachment, "allowed").unwrap();
        let canonical = attachment.canonicalize().unwrap();
        let state = GrokRuntimeState::default();
        state.prompt_attachment_grants.lock().unwrap().insert(
            "grant-1".to_string(),
            PromptAttachmentGrant {
                paths: vec![canonical.clone()],
                created_at: super::current_unix_seconds(),
            },
        );

        let authorized = authorize_prompt_attachments(
            &state,
            Some(vec![attachment.to_string_lossy().to_string()]),
            Some(vec!["stale-grant".to_string(), "grant-1".to_string()]),
        )
        .unwrap();
        assert_eq!(authorized, vec![canonical]);

        let authorized_retry = authorize_prompt_attachments(
            &state,
            Some(vec![attachment.to_string_lossy().to_string()]),
            Some(vec!["grant-1".to_string()]),
        )
        .unwrap();
        assert_eq!(authorized_retry, vec![attachment.canonicalize().unwrap()]);

        consume_prompt_attachment_grants(&state, &["grant-1".to_string()]);
        let replay_error = authorize_prompt_attachments(
            &state,
            Some(vec![attachment.to_string_lossy().to_string()]),
            Some(vec!["grant-1".to_string()]),
        )
        .unwrap_err();
        assert!(replay_error.contains("授权已失效"));

        fs::remove_file(&attachment).unwrap();
        fs::remove_dir(&test_directory).unwrap();
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
    fn normalizes_standard_and_xai_session_updates_for_the_desktop_event_stream() {
        for method in [
            "session/update",
            "x.ai/session_notification",
            "_x.ai/session/update",
            "x.ai/scheduled_task_created",
            "x.ai/scheduled_task_fired",
            "x.ai/scheduled_task_deleted",
        ] {
            let normalized = normalized_session_update_message(&json!({
                "jsonrpc": "2.0",
                "method": method,
                "params": {
                    "sessionId": "session-1",
                    "update": { "sessionUpdate": "task_backgrounded", "task_id": "task-1" }
                }
            }))
            .unwrap();
            assert_eq!(normalized["method"], "session/update");
            assert_eq!(normalized["params"]["sessionId"], "session-1");
            assert_eq!(
                normalized["params"]["update"]["sessionUpdate"],
                "task_backgrounded"
            );
        }

        let nested = normalized_session_update_message(&json!({
            "jsonrpc": "2.0",
            "method": "_x.ai/session_notification",
            "params": {
                "method": "x.ai/session_notification",
                "params": {
                    "sessionId": "session-2",
                    "update": { "sessionUpdate": "subagent_spawned", "subagent_id": "child-1" }
                }
            }
        }))
        .unwrap();
        assert_eq!(nested["params"]["sessionId"], "session-2");
        assert_eq!(
            nested["params"]["update"]["sessionUpdate"],
            "subagent_spawned"
        );
        assert!(normalized_session_update_message(&json!({
            "method": "session/request_permission",
            "params": { "sessionId": "session-1" }
        }))
        .is_none());
    }

    #[test]
    fn normalizes_direct_and_wrapped_queue_changed_notifications() {
        let direct = normalized_queue_changed_params(&json!({
            "method": "x.ai/queue/changed",
            "params": {
                "sessionId": "session-1",
                "entries": [{ "id": "prompt-1", "version": 0, "text": "继续检查" }]
            }
        }))
        .unwrap();
        assert_eq!(direct["sessionId"], "session-1");
        assert_eq!(direct["entries"][0]["id"], "prompt-1");

        let wrapped = normalized_queue_changed_params(&json!({
            "method": "_x.ai/queue/changed",
            "params": {
                "method": "x.ai/queue/changed",
                "params": { "sessionId": "session-2", "entries": [], "runningPromptId": "prompt-2" }
            }
        }))
        .unwrap();
        assert_eq!(wrapped["sessionId"], "session-2");
        assert_eq!(wrapped["runningPromptId"], "prompt-2");
        assert!(normalized_queue_changed_params(&json!({
            "method": "session/update",
            "params": {}
        }))
        .is_none());
    }

    #[test]
    fn normalizes_direct_and_wrapped_interjection_notifications() {
        assert_eq!(GROK_INTERJECT_METHOD, "_x.ai/interject");
        let direct = normalized_interjection_params(&json!({
            "method": "x.ai/session/interjection",
            "params": {
                "sessionId": "session-1",
                "text": "补充检查测试",
                "interjectionId": "interjection-1"
            }
        }))
        .unwrap();
        assert_eq!(direct["sessionId"], "session-1");
        assert_eq!(direct["text"], "补充检查测试");
        assert_eq!(direct["interjectionId"], "interjection-1");

        let wrapped = normalized_interjection_params(&json!({
            "method": "_x.ai/session/interjection",
            "params": {
                "method": "x.ai/session/interjection",
                "params": {
                    "sessionId": "session-2",
                    "text": "继续执行",
                    "interjectionId": "interjection-2"
                }
            }
        }))
        .unwrap();
        assert_eq!(wrapped["sessionId"], "session-2");
        assert_eq!(wrapped["text"], "继续执行");
        assert!(normalized_interjection_params(&json!({
            "method": "session/update",
            "params": {}
        }))
        .is_none());
    }

    #[test]
    fn parses_scheduled_prompt_injection_for_direct_and_wrapped_notifications() {
        for message in [
            json!({
                "method": "x.ai/scheduled_task_inject_prompt",
                "params": {
                    "sessionId": "session-1",
                    "taskId": "loop-1",
                    "prompt": "check deploy"
                }
            }),
            json!({
                "method": "_x.ai/scheduled_task_inject_prompt",
                "params": {
                    "params": {
                        "sessionId": "session-1",
                        "taskId": "loop-1",
                        "prompt": "check deploy"
                    }
                }
            }),
        ] {
            assert_eq!(
                scheduled_prompt_injection(&message),
                Some((
                    "session-1".to_string(),
                    "check deploy".to_string(),
                    "loop-1".to_string()
                ))
            );
        }
        assert!(scheduled_prompt_injection(&json!({
            "method": "x.ai/scheduled_task_inject_prompt",
            "params": { "sessionId": "session-1", "prompt": " " }
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
        let same = process_launch_key(workspace, Some("model-a"), &base, Some("rules"), 1).unwrap();
        assert_eq!(
            same,
            process_launch_key(workspace, Some("model-a"), &base, Some("rules"), 1).unwrap()
        );

        let changed = GrokAcpOptions {
            permission_mode: Some("bypassPermissions".into()),
            ..Default::default()
        };
        assert_ne!(
            same,
            process_launch_key(workspace, Some("model-a"), &changed, Some("rules"), 1).unwrap()
        );
        assert_ne!(
            same,
            process_launch_key(workspace, Some("model-a"), &base, Some("rules"), 2).unwrap()
        );
    }

    #[test]
    fn startup_requests_have_network_tolerant_timeouts() {
        assert_eq!(request_timeout("initialize"), INITIALIZE_TIMEOUT);
        assert_eq!(request_timeout("authenticate"), AUTHENTICATE_TIMEOUT);
        assert_eq!(request_timeout("session/new"), SESSION_START_TIMEOUT);
        assert_eq!(request_timeout("session/load"), SESSION_START_TIMEOUT);
        assert_eq!(request_timeout("_x.ai/commands/list"), REQUEST_TIMEOUT);
        assert!(request_timeout("authenticate") > request_timeout("session/new"));
        assert!(request_timeout("session/new") > request_timeout("_x.ai/commands/list"));
    }

    #[test]
    fn permission_modes_do_not_emit_unsupported_grok_cli_arguments() {
        let interactive = GrokAcpOptions {
            permission_mode: Some("acceptEdits".into()),
            sandbox_profile: Some("workspace-write".into()),
            ..Default::default()
        };
        let interactive_args = grok_agent_arguments(Some("model-a"), &interactive, false).unwrap();
        assert!(!interactive_args
            .iter()
            .any(|arg| arg == "--permission-mode"));
        assert!(!interactive_args.iter().any(|arg| arg == "--sandbox"));
        assert!(!interactive_args.iter().any(|arg| arg == "--always-approve"));

        let unrestricted = GrokAcpOptions {
            permission_mode: Some("bypassPermissions".into()),
            ..Default::default()
        };
        assert!(grok_agent_arguments(Some("model-a"), &unrestricted, false)
            .unwrap()
            .iter()
            .any(|arg| arg == "--always-approve"));

        let reauth = GrokAcpOptions {
            reauth: Some(true),
            ..Default::default()
        };
        assert!(grok_agent_arguments(Some("model-a"), &reauth, false)
            .unwrap()
            .iter()
            .any(|arg| arg == "--reauth"));
        assert!(!grok_agent_arguments(Some("model-a"), &reauth, true)
            .unwrap()
            .iter()
            .any(|arg| arg == "--reauth"));
    }

    #[test]
    fn validates_cli_command_allowlist_and_limits() {
        assert!(validate_cli_arguments(&["models".to_string()]).is_err());
        assert!(validate_cli_arguments(&["login".to_string()]).is_err());
        assert!(validate_cli_arguments(&["update".to_string()]).is_err());
        assert!(validate_cli_arguments(&["doctor".to_string(), "--json".to_string()]).is_ok());
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
    fn offline_config_removes_xai_sources_and_disables_remote_features() {
        let mut config = parse_grok_toml(
            r#"
[auth]
auth_provider_command = "online"

[grok_com_config.oidc]
issuer = "https://auth.x.ai"
client_id = "client"

[features]
remote_fetch = true
telemetry = true

[marketplace]
official_marketplace_auto_installed = true

[[marketplace.sources]]
git = "https://github.com/xai-org/plugin-marketplace.git"
name = "xAI Official"
"#,
        )
        .unwrap();
        apply_offline_config(&mut config).unwrap();
        assert_eq!(config["auth"]["preferred_method"].as_str(), Some("api_key"));
        assert!(config["auth"].get("auth_provider_command").is_none());
        assert!(config.get("grok_com_config").is_none());
        assert_eq!(config["features"]["remote_fetch"].as_bool(), Some(false));
        assert_eq!(config["features"]["telemetry"].as_bool(), Some(false));
        assert!(config["marketplace"].get("sources").is_none());
        assert_eq!(config["cli"]["auto_update"].as_bool(), Some(false));
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
