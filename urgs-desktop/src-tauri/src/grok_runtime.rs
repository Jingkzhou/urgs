use crate::desktop_log;
use base64::{engine::general_purpose::STANDARD as BASE64_STANDARD, Engine as _};
use keyring::Entry;
use portable_pty::{native_pty_system, Child as PtyChild, CommandBuilder, MasterPty, PtySize};
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, CONTENT_TYPE};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use tauri::{AppHandle, Emitter, Manager, State};
use tauri_plugin_dialog::DialogExt;
use tauri_plugin_shell::process::{CommandChild, CommandEvent};
use tauri_plugin_shell::ShellExt;
use tokio::process::Command as TokioCommand;
use tokio::sync::{oneshot, Mutex as AsyncMutex};
use uuid::Uuid;

const GROK_EVENT_NAME: &str = "grok-event";
// ACP extension methods use an underscore-prefixed JSON-RPC wire name. The
// Grok agent strips the prefix before dispatching to its `x.ai/interject` handler.
const GROK_INTERJECT_METHOD: &str = "_x.ai/interject";
const GROK_RECAP_METHOD: &str = "_x.ai/recap";
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);
const INITIALIZE_TIMEOUT: Duration = Duration::from_secs(90);
const AUTHENTICATE_TIMEOUT: Duration = Duration::from_secs(180);
const SESSION_START_TIMEOUT: Duration = Duration::from_secs(120);
const SESSION_CLOSE_TIMEOUT: Duration = Duration::from_secs(10);
const MODEL_PROVIDER_FILE: &str = "model-providers.json";
const MODEL_CREDENTIAL_SERVICE: &str = "com.urgs.desktop.grok-model";
const MODEL_KEY_AUTHORIZATION_REQUIRED: &str = "MODEL_KEY_AUTHORIZATION_REQUIRED:";
const OFFLINE_AUTH_FILE: &str = "urgs-offline-auth.json";
const MAX_PROMPT_ATTACHMENTS: usize = 20;
const MAX_PROMPT_ATTACHMENT_BYTES: u64 = 10 * 1024 * 1024;
const MAX_PROMPT_ATTACHMENTS_TOTAL_BYTES: u64 = 25 * 1024 * 1024;
const PROMPT_ATTACHMENT_GRANT_TTL_SECONDS: u64 = 60 * 60;
const MAX_PROMPT_ATTACHMENT_GRANTS: usize = 64;
const MAX_WORKFLOW_SOURCE_BYTES: u64 = 1024 * 1024;
const MAX_PLAN_FILE_BYTES: u64 = 2 * 1024 * 1024;
const MAX_LLM_PROMPT_BYTES: usize = 512 * 1024;
const MAX_LLM_RESPONSE_BYTES: usize = 4 * 1024 * 1024;
const LLM_REQUEST_TIMEOUT: Duration = Duration::from_secs(120);
const TERMINAL_COMMAND_TIMEOUT: Duration = Duration::from_secs(120);
static PROCESS_SEQUENCE: AtomicU64 = AtomicU64::new(1);
static MODEL_API_KEY_CACHE: OnceLock<Mutex<HashMap<String, String>>> = OnceLock::new();
#[cfg(target_os = "macos")]
static MACOS_KEYCHAIN_READ_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

fn request_timeout(method: &str) -> Duration {
    match method {
        "session/prompt" => Duration::from_secs(60 * 60),
        "initialize" => INITIALIZE_TIMEOUT,
        "authenticate" => AUTHENTICATE_TIMEOUT,
        "session/new" | "session/load" | "session/resume" => SESSION_START_TIMEOUT,
        "session/close" => SESSION_CLOSE_TIMEOUT,
        _ => REQUEST_TIMEOUT,
    }
}

fn session_startup_hints() -> Value {
    json!({
        "nonInteractive": false,
        "skipGitStatus": true,
        "skipProjectLayout": true,
        "deliveryTools": []
    })
}

fn session_request_meta(rules: Option<&str>) -> Value {
    let mut meta = json!({
        "startupHints": session_startup_hints()
    });
    if let Some(rules) = rules.filter(|value| !value.trim().is_empty()) {
        meta["rules"] = json!(rules);
    }
    meta
}

fn initialize_client_meta(rules: Option<&str>) -> Value {
    let mut meta = json!({
        "clientType": "urgs-ark-desktop",
        "clientIdentifier": "urgs-desktop",
        "clientVersion": env!("CARGO_PKG_VERSION"),
        "startupHints": session_startup_hints()
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

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokWorkflowListing {
    pub name: String,
    pub description: String,
    pub when_to_use: Option<String>,
    pub source: String,
    pub path: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokWorkflowFile {
    pub name: String,
    pub description: String,
    pub when_to_use: Option<String>,
    pub source: String,
    pub path: Option<String>,
    pub content: Option<String>,
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
    pub agent_capabilities: Value,
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
pub struct TerminalCommandResult {
    pub shell: String,
    pub cwd: String,
    pub command: String,
    pub success: bool,
    pub exit_code: Option<i32>,
    pub stdout: String,
    pub stderr: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TerminalSessionInfo {
    pub session_id: String,
    pub shell: String,
    pub cwd: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct TerminalOutputEvent {
    session_id: String,
    data_base64: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct TerminalExitEvent {
    session_id: String,
}

struct TerminalSession {
    master: Mutex<Box<dyn MasterPty + Send>>,
    writer: Mutex<Box<dyn Write + Send>>,
    child: Mutex<Box<dyn PtyChild + Send + Sync>>,
}

#[derive(Clone, Default)]
pub struct TerminalState {
    sessions: Arc<Mutex<HashMap<String, Arc<TerminalSession>>>>,
}

impl TerminalState {
    pub fn close_all(&self) -> Result<(), String> {
        let sessions = self
            .sessions
            .lock()
            .map_err(|_| "终端会话锁不可用".to_string())?
            .drain()
            .map(|(_, session)| session)
            .collect::<Vec<_>>();
        for session in sessions {
            if let Ok(mut child) = session.child.lock() {
                let _ = child.kill();
            }
        }
        Ok(())
    }
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
    #[serde(default = "legacy_model_provider_supports_reasoning_effort")]
    pub supports_reasoning_effort: bool,
    #[serde(default)]
    pub has_api_key: bool,
}

fn legacy_model_provider_supports_reasoning_effort() -> bool {
    true
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
    #[serde(default)]
    pub supports_reasoning_effort: bool,
    pub api_key: Option<String>,
}

const CUSTOM_MODEL_REASONING_EFFORTS: [&str; 4] = ["none", "low", "high", "max"];
const CUSTOM_MODEL_DEFAULT_REASONING_EFFORT: &str = "high";

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LlmTextGenerationInput {
    pub provider_id: String,
    pub prompt: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LlmTextGenerationResult {
    pub provider_id: String,
    pub model: String,
    pub text: String,
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
    agent_capabilities: Mutex<Value>,
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
            agent_capabilities: Mutex::new(Value::Null),
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
        let started_at = Instant::now();
        desktop_log::debug(
            "grok.acp",
            &format!(
                "ACP request started: process={} id={} method={method}",
                self.process_id, id
            ),
        );
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
            message["params"]["_meta"] = meta;
        }
        if let Err(error) = self.write_json(message) {
            self.pending_requests
                .lock()
                .map_err(|_| "Grok 请求队列锁不可用".to_string())?
                .remove(&id);
            desktop_log::error(
                "grok.acp",
                &format!(
                    "ACP request write failed: process={} id={} method={method} error={error}",
                    self.process_id, id
                ),
            );
            return Err(error);
        }

        match tokio::time::timeout(request_timeout(method), receiver).await {
            Ok(Ok(result)) => {
                match &result {
                    Ok(_) => desktop_log::debug(
                        "grok.acp",
                        &format!(
                            "ACP request completed: process={} id={} method={method} elapsed_ms={}",
                            self.process_id,
                            id,
                            started_at.elapsed().as_millis()
                        ),
                    ),
                    Err(error) => desktop_log::warn(
                        "grok.acp",
                        &format!(
                            "ACP request returned error: process={} id={} method={method} elapsed_ms={} error={error}",
                            self.process_id,
                            id,
                            started_at.elapsed().as_millis()
                        ),
                    ),
                }
                result
            }
            Ok(Err(_)) => {
                let error = "Grok 本地进程在响应前退出".to_string();
                desktop_log::warn(
                    "grok.acp",
                    &format!(
                        "ACP request interrupted: process={} id={} method={method} elapsed_ms={}",
                        self.process_id,
                        id,
                        started_at.elapsed().as_millis()
                    ),
                );
                Err(error)
            }
            Err(_) => {
                self.pending_requests
                    .lock()
                    .map_err(|_| "Grok 请求队列锁不可用".to_string())?
                    .remove(&id);
                let error = format!("等待 Grok {method} 响应超时");
                desktop_log::error(
                    "grok.acp",
                    &format!(
                        "ACP request timed out: process={} id={} method={method} elapsed_ms={}",
                        self.process_id,
                        id,
                        started_at.elapsed().as_millis()
                    ),
                );
                Err(error)
            }
        }
    }

    fn notify(&self, method: &str, params: Value) -> Result<(), String> {
        let result = self.write_json(json!({
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
        }));
        if let Err(error) = &result {
            desktop_log::error(
                "grok.acp",
                &format!(
                    "ACP notification failed: process={} method={method} error={error}",
                    self.process_id
                ),
            );
        }
        result
    }

    async fn initialize(&self, rules: Option<&str>) -> Result<(), String> {
        let mut initialized = self.initialized.lock().await;
        if *initialized {
            return Ok(());
        }

        desktop_log::info(
            "grok.process",
            &format!(
                "Initializing ACP process={} workspace={}",
                self.process_id,
                self.workspace.display()
            ),
        );

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
        if let Ok(mut capabilities) = self.agent_capabilities.lock() {
            *capabilities = response
                .get("agentCapabilities")
                .or_else(|| response.get("agent_capabilities"))
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
            .map_err(|error| {
                desktop_log::error(
                    "grok.auth",
                    &format!(
                        "Grok authentication failed for process={}: {error}",
                        self.process_id
                    ),
                );
                format!("Grok 登录不可用，请先点击“登录 Grok”：{error}")
            })?;
        }

        *initialized = true;
        desktop_log::info(
            "grok.process",
            &format!(
                "ACP process initialized: process={} commands={} custom_model={}",
                self.process_id,
                self.available_commands().len(),
                self.uses_custom_model
            ),
        );
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

    fn agent_capabilities(&self) -> Value {
        self.agent_capabilities
            .lock()
            .map(|capabilities| capabilities.clone())
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
        desktop_log::info(
            "grok.process",
            &format!("Stopping ACP process={}", self.process_id),
        );
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

fn general_task_workspace(app: &AppHandle) -> Result<PathBuf, String> {
    let directory = app
        .path()
        .app_data_dir()
        .map_err(|error| format!("无法定位智能任务中心数据目录: {error}"))?
        .join("task-center")
        .join("general");
    fs::create_dir_all(&directory).map_err(|error| format!("创建通用任务目录失败: {error}"))?;
    directory
        .canonicalize()
        .map_err(|error| format!("无法访问通用任务目录: {error}"))
}

const GENERAL_SESSION_WORKSPACE_PREFIX: &str = "urgs-general-session://";

fn general_session_key(workspace: &str) -> Result<Option<&str>, String> {
    let workspace = workspace.trim();
    let Some(key) = workspace.strip_prefix(GENERAL_SESSION_WORKSPACE_PREFIX) else {
        return Ok(None);
    };
    if key.is_empty()
        || key.len() > 128
        || !key
            .bytes()
            .all(|value| value.is_ascii_alphanumeric() || matches!(value, b'-' | b'_'))
    {
        return Err("通用会话目录标识不合法".to_string());
    }
    Ok(Some(key))
}

fn general_session_workspace(app: &AppHandle, key: &str) -> Result<PathBuf, String> {
    let root = general_task_workspace(app)?;
    let directory = root.join(key);
    fs::create_dir_all(&directory).map_err(|error| format!("创建会话隔离目录失败: {error}"))?;
    let directory = directory
        .canonicalize()
        .map_err(|error| format!("无法访问会话隔离目录: {error}"))?;
    if !directory.starts_with(&root) {
        return Err("通用会话目录超出允许范围".to_string());
    }
    Ok(directory)
}

fn resolve_task_workspace(app: &AppHandle, workspace: &str) -> Result<PathBuf, String> {
    let workspace = workspace.trim();
    if workspace.is_empty() {
        general_task_workspace(app)
    } else if let Some(key) = general_session_key(workspace)? {
        general_session_workspace(app, key)
    } else {
        validate_workspace(workspace)
    }
}

fn persisted_session_number(value: &Value, camel_case: &str, snake_case: &str) -> u64 {
    value
        .get(camel_case)
        .or_else(|| value.get(snake_case))
        .and_then(Value::as_u64)
        .unwrap_or_default()
}

fn persisted_session_string(value: &Value, camel_case: &str, snake_case: &str) -> Option<String> {
    value
        .get(camel_case)
        .or_else(|| value.get(snake_case))
        .and_then(Value::as_str)
        .map(str::to_string)
}

fn find_persisted_session_directory(
    app: &AppHandle,
    session_id: &str,
) -> Result<Option<PathBuf>, String> {
    let sessions_root = grok_home(app)?.join("sessions");
    if !sessions_root.is_dir() {
        return Ok(None);
    }

    let direct_directory = sessions_root.join(session_id);
    if direct_directory.is_dir() {
        return Ok(Some(direct_directory));
    }

    let entries = match fs::read_dir(&sessions_root) {
        Ok(entries) => entries,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(error) => return Err(format!("读取 Grok 会话目录失败: {error}")),
    };
    for entry in entries {
        let entry = match entry {
            Ok(entry) => entry,
            Err(_) => continue,
        };
        let workspace_directory = entry.path();
        if !workspace_directory.is_dir() {
            continue;
        }
        let session_directory = workspace_directory.join(session_id);
        if session_directory.is_dir() {
            return Ok(Some(session_directory));
        }
    }
    Ok(None)
}

fn validate_session_mode(mode: &str) -> Result<&str, String> {
    match mode.trim() {
        "default" => Ok("default"),
        "plan" => Ok("plan"),
        "ask" => Ok("ask"),
        _ => Err("会话模式仅支持 default、plan 或 ask".to_string()),
    }
}

fn validate_persisted_session_id(session_id: &str) -> Result<&str, String> {
    let session_id = session_id.trim();
    if session_id.is_empty()
        || session_id == "."
        || session_id == ".."
        || session_id.contains('/')
        || session_id.contains('\\')
    {
        return Err("会话 ID 格式无效".to_string());
    }
    Ok(session_id)
}

#[tauri::command]
pub async fn grok_session_plan(app: AppHandle, session_id: String) -> Result<Value, String> {
    let session_id = validate_persisted_session_id(&session_id)?;
    let Some(session_directory) = find_persisted_session_directory(&app, session_id)? else {
        return Err("未找到对应的 Grok 会话目录".to_string());
    };
    let plan_path = session_directory.join("plan.md");
    let metadata = match fs::symlink_metadata(&plan_path) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
            return Ok(json!({ "sessionId": session_id, "content": Value::Null }));
        }
        Err(error) => return Err(format!("读取计划文件失败: {error}")),
    };
    if metadata.file_type().is_symlink() || !metadata.is_file() {
        return Err("计划文件类型不安全".to_string());
    }
    if metadata.len() > MAX_PLAN_FILE_BYTES {
        return Err("计划文件超过 2 MB，无法在任务中心预览".to_string());
    }
    let canonical_session = session_directory
        .canonicalize()
        .map_err(|error| format!("校验会话目录失败: {error}"))?;
    let canonical_sessions_root = grok_home(&app)?
        .join("sessions")
        .canonicalize()
        .map_err(|error| format!("校验会话根目录失败: {error}"))?;
    if !canonical_session.starts_with(&canonical_sessions_root) {
        return Err("会话目录不在 Grok 会话根目录内".to_string());
    }
    let canonical_plan = plan_path
        .canonicalize()
        .map_err(|error| format!("校验计划文件失败: {error}"))?;
    if canonical_plan.parent() != Some(canonical_session.as_path()) {
        return Err("计划文件不在当前会话目录内".to_string());
    }
    let content =
        fs::read_to_string(canonical_plan).map_err(|error| format!("读取计划文件失败: {error}"))?;
    Ok(json!({ "sessionId": session_id, "content": content }))
}

fn read_persisted_session_info(app: &AppHandle, session_id: &str) -> Result<Option<Value>, String> {
    let Some(session_directory) = find_persisted_session_directory(app, session_id)? else {
        return Ok(None);
    };
    let signals_path = session_directory.join("signals.json");
    let signals = match fs::read_to_string(&signals_path)
        .ok()
        .and_then(|content| serde_json::from_str::<Value>(&content).ok())
    {
        Some(signals) => signals,
        None => return Ok(None),
    };
    let summary = fs::read_to_string(session_directory.join("summary.json"))
        .ok()
        .and_then(|content| serde_json::from_str::<Value>(&content).ok());
    let summary_info = summary.as_ref().and_then(|value| value.get("info"));

    let used = persisted_session_number(&signals, "contextTokensUsed", "context_tokens_used");
    let total = persisted_session_number(&signals, "contextWindowTokens", "context_window_tokens");
    let usage_pct =
        persisted_session_number(&signals, "contextWindowUsage", "context_window_usage");
    if used == 0 && total == 0 && usage_pct == 0 {
        return Ok(None);
    }

    let model =
        persisted_session_string(&signals, "primaryModelId", "primary_model_id").or_else(|| {
            summary_info.and_then(|value| {
                persisted_session_string(value, "currentModelId", "current_model_id")
            })
        });
    let cwd = summary_info
        .and_then(|value| persisted_session_string(value, "cwd", "cwd"))
        .unwrap_or_default();
    let turn_count = persisted_session_number(&signals, "turnCount", "turn_count");

    Ok(Some(json!({
        "sessionId": session_id,
        "cwd": cwd,
        "agentName": summary_info.and_then(|value| persisted_session_string(value, "agentName", "agent_name")),
        "model": model.clone(),
        "modelDisplayName": model.clone(),
        "resolvedModelId": model,
        "turns": turn_count,
        "turnIndex": turn_count.saturating_sub(1),
        "context": {
            "used": used,
            "total": total,
            "systemPromptTokens": 0,
            "toolDefinitionsCount": 0,
            "toolDefinitionsTokens": 0,
            "compactionCount": persisted_session_number(&signals, "compactionCount", "compaction_count"),
            "turnCount": turn_count,
            "toolCallCount": persisted_session_number(&signals, "toolCallCount", "tool_call_count"),
            "messageCount": 0,
            "messageTokens": 0,
            "freeTokens": total.saturating_sub(used),
            "usagePct": usage_pct,
            "autoCompactThresholdPercent": 85,
            "usageCategories": [],
        },
    })))
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
            supports_reasoning_effort: input.supports_reasoning_effort,
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

fn write_grok_user_config(app: &AppHandle, config: &toml::Value) -> Result<(), String> {
    let path = grok_config_path(app, "user", "config", None)?;
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|error| format!("创建 Grok 配置目录失败: {error}"))?;
    }
    if path.is_file() {
        fs::copy(&path, path.with_extension("toml.urgs-backup"))
            .map_err(|error| format!("备份 Grok 配置失败: {error}"))?;
    }
    fs::write(&path, serialize_grok_toml(config)?)
        .map_err(|error| format!("保存 Grok 配置失败: {error}"))
}

fn update_grok_string_list(
    config: &mut toml::Value,
    section_name: &str,
    key: &str,
    value: &str,
    included: bool,
) -> Result<(), String> {
    let root = config
        .as_table_mut()
        .ok_or_else(|| "Grok 配置根节点必须是对象".to_string())?;
    let section = root
        .entry(section_name.to_string())
        .or_insert_with(|| toml::Value::Table(toml::map::Map::new()))
        .as_table_mut()
        .ok_or_else(|| "Grok 扩展配置必须是对象".to_string())?;
    let values = section
        .entry(key.to_string())
        .or_insert_with(|| toml::Value::Array(Vec::new()))
        .as_array_mut()
        .ok_or_else(|| format!("Grok 扩展配置 {section_name}.{key} 必须是数组"))?;
    values.retain(|item| item.as_str() != Some(value));
    if included {
        values.push(toml::Value::String(value.to_string()));
    }
    Ok(())
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
    sync_provider_reasoning_capability(entry, provider.supports_reasoning_effort);
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

fn sync_provider_reasoning_capability(
    entry: &mut toml::map::Map<String, toml::Value>,
    supports_reasoning_effort: bool,
) {
    if supports_reasoning_effort {
        entry.insert(
            "supports_reasoning_effort".to_string(),
            toml::Value::Boolean(true),
        );
        entry.insert(
            "reasoning_efforts".to_string(),
            toml::Value::Array(
                CUSTOM_MODEL_REASONING_EFFORTS
                    .iter()
                    .map(|value| toml::Value::String((*value).to_string()))
                    .collect(),
            ),
        );
        entry.insert(
            "reasoning_effort".to_string(),
            toml::Value::String(CUSTOM_MODEL_DEFAULT_REASONING_EFFORT.to_string()),
        );
    } else {
        entry.remove("supports_reasoning_effort");
        entry.remove("reasoning_efforts");
        entry.remove("reasoning_effort");
    }
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
            && entry
                .get("supports_reasoning_effort")
                .and_then(toml::Value::as_bool)
                .unwrap_or(false)
                == provider.supports_reasoning_effort
            && (!provider.supports_reasoning_effort
                || (toml_string_list(entry.get("reasoning_efforts"))
                    == CUSTOM_MODEL_REASONING_EFFORTS
                    && entry.get("reasoning_effort").and_then(toml::Value::as_str)
                        == Some(CUSTOM_MODEL_DEFAULT_REASONING_EFFORT)))
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
        "du",
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
    let message = error
        .get("message")
        .and_then(Value::as_str)
        .map(str::trim)
        .filter(|value| !value.is_empty());
    let detail = error
        .get("data")
        .and_then(|data| match data {
            Value::String(value) => Some(value.trim()),
            Value::Object(_) => data
                .get("message")
                .or_else(|| data.get("detail"))
                .and_then(Value::as_str)
                .map(str::trim),
            _ => None,
        })
        .filter(|value| !value.is_empty());

    match (message, detail) {
        (Some(message), Some(detail)) if detail != message => {
            format!("{message}: {detail}")
        }
        (Some(message), _) => message.to_string(),
        (None, Some(detail)) => detail.to_string(),
        (None, None) => error.to_string(),
    }
}

fn is_method_not_found_error(error: &str) -> bool {
    error.to_ascii_lowercase().contains("method not found")
}

fn is_unsupported_acp_method_error(error: &str) -> bool {
    let error = error.to_ascii_lowercase();
    error.contains("method not found")
        || error.contains("unknown method")
        || error.contains("unsupported method")
        || error.contains("not implemented")
        || error.contains("-32601")
}

fn session_attach_method(attach_mode: Option<&str>) -> Result<&'static str, String> {
    match attach_mode.map(str::trim).filter(|mode| !mode.is_empty()) {
        None | Some("load") => Ok("session/load"),
        Some("resume") => Ok("session/resume"),
        Some(mode) => Err(format!("不支持的 Grok 会话挂载模式: {mode}")),
    }
}

async fn request_session_attach(
    process: &GrokProcess,
    method: &str,
    session_id: &str,
    workspace: &Path,
    mcp_payload: &[Value],
    rules: Option<&str>,
) -> (Result<Value, String>, Vec<Value>) {
    process.replaying_session.store(true, Ordering::Relaxed);
    let result = process
        .request_with_meta(
            method,
            json!({
                "sessionId": session_id,
                "cwd": workspace.to_string_lossy().to_string(),
                "mcpServers": mcp_payload,
            }),
            Some(session_request_meta(rules)),
        )
        .await;
    process.replaying_session.store(false, Ordering::Relaxed);
    let replayed_events = process.take_replayed_events();
    (result, replayed_events)
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
        "_x.ai/session_notification" => {
            if params.get("method").and_then(Value::as_str) == Some("x.ai/session_notification") {
                params.get("params")?
            } else {
                params
            }
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
            desktop_log::error(
                "grok.protocol",
                &format!(
                    "Unable to parse ACP stdout: process={} error={error}",
                    process.process_id
                ),
            );
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
            desktop_log::warn(
                "grok.protocol",
                &format!(
                    "Scheduled prompt event missing identifiers: process={}",
                    process.process_id
                ),
            );
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
            desktop_log::info(
                "grok.session",
                &format!(
                    "Scheduled prompt started: process={} session={} task={}",
                    process.process_id, session_id, task_id
                ),
            );
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
                desktop_log::info(
                    "grok.permission",
                    &format!(
                        "Permission request received: process={} session={}",
                        process.process_id, session_id
                    ),
                );
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
                    desktop_log::warn(
                        "grok.protocol",
                        &format!(
                            "AskUserQuestion missing session id: process={}",
                            process.process_id
                        ),
                    );
                    let _ = process.write_json(json!({
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "error": { "code": -32602, "message": "AskUserQuestion 缺少 sessionId" }
                    }));
                    return;
                }
                desktop_log::info(
                    "grok.user_question",
                    &format!(
                        "User question received: process={} session={}",
                        process.process_id, session_id
                    ),
                );
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
                    desktop_log::warn(
                        "grok.protocol",
                        &format!(
                            "ExitPlanMode missing session id: process={}",
                            process.process_id
                        ),
                    );
                    let _ = process.write_json(json!({
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "error": { "code": -32602, "message": "ExitPlanMode 缺少 sessionId" }
                    }));
                    return;
                }
                desktop_log::info(
                    "grok.plan",
                    &format!(
                        "Plan approval received: process={} session={}",
                        process.process_id, session_id
                    ),
                );
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
            let log_message = format!(
                "Unhandled ACP notification: process={} method={method}",
                process.process_id
            );
            if method.starts_with("_x.ai/") || method.starts_with("x.ai/") {
                desktop_log::debug("grok.protocol", &log_message);
            } else {
                desktop_log::warn("grok.protocol", &log_message);
            }
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
    desktop_log::info(
        "grok.process",
        &format!(
            "Starting Grok sidecar: workspace={} custom_model={} argument_count={}",
            workspace.display(),
            uses_custom_model,
            arguments.len()
        ),
    );
    let mut process_envs = offline_runtime_envs(&home);
    process_envs.extend(model_envs);
    let (mut receiver, child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| {
            desktop_log::error("grok.process", &format!("Grok sidecar not found: {error}"));
            format!("无法定位内置 Grok Build: {error}")
        })?
        .args(arguments)
        .current_dir(workspace)
        .env_clear()
        .env("GROK_HOME", &home)
        .envs(process_envs)
        .spawn()
        .map_err(|error| {
            desktop_log::error(
                "grok.process",
                &format!("Grok sidecar spawn failed: {error}"),
            );
            format!("启动本地 Grok Build 失败: {error}")
        })?;
    let process = Arc::new(GrokProcess::new(
        child,
        launch_key,
        workspace.to_path_buf(),
        uses_custom_model,
    ));
    desktop_log::info(
        "grok.process",
        &format!(
            "Grok sidecar started: process={} workspace={}",
            process.process_id,
            process.workspace.display()
        ),
    );
    let reader_process = Arc::clone(&process);
    let reader_app = app.clone();
    tauri::async_runtime::spawn(async move {
        while let Some(event) = receiver.recv().await {
            match event {
                CommandEvent::Stdout(line) => handle_stdout(&reader_app, &reader_process, line),
                CommandEvent::Stderr(line) => {
                    let message = String::from_utf8_lossy(&line).trim().to_string();
                    reader_process.remember_stderr(&message);
                    if !message.is_empty() {
                        desktop_log::warn(
                            "grok.stderr",
                            &format!(
                                "Sidecar stderr: process={} message={message}",
                                reader_process.process_id
                            ),
                        );
                    }
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
                    desktop_log::error(
                        "grok.process",
                        &format!(
                            "Sidecar runtime error: process={} error={error}",
                            reader_process.process_id
                        ),
                    );
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
                    desktop_log::warn(
                        "grok.process",
                        &format!(
                            "Sidecar terminated: process={} code={:?}",
                            reader_process.process_id, status.code
                        ),
                    );
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

fn workflow_listings_from_response(response: &Value) -> Result<Vec<GrokWorkflowListing>, String> {
    if let Some(error) = response.get("error").filter(|value| !value.is_null()) {
        return Err(format!("Grok Workflow 目录获取失败: {error}"));
    }

    let payload = response
        .get("result")
        .filter(|value| !value.is_null())
        .unwrap_or(response);
    let workflows = payload
        .get("workflows")
        .or_else(|| {
            payload
                .get("inner")
                .and_then(|value| value.get("workflows"))
        })
        .and_then(Value::as_array)
        .ok_or_else(|| "Grok 未返回 Workflow 目录".to_string())?;

    workflows
        .iter()
        .cloned()
        .map(|item| {
            serde_json::from_value(item).map_err(|error| format!("解析 Workflow 目录失败: {error}"))
        })
        .collect()
}

async fn fetch_workflow_list(
    process: &GrokProcess,
    session_id: &str,
) -> Result<Vec<GrokWorkflowListing>, String> {
    let params = json!({ "sessionId": session_id });
    let response = match process.request("x.ai/workflows/list", params.clone()).await {
        Ok(response) => response,
        Err(error) if is_method_not_found_error(&error) => {
            process.request("_x.ai/workflows/list", params).await?
        }
        Err(error) => return Err(error),
    };
    workflow_listings_from_response(&response)
}

fn workflow_project_root(workspace: &Path) -> PathBuf {
    let mut current = workspace;
    loop {
        if current.join(".git").exists() {
            return current.to_path_buf();
        }
        let Some(parent) = current.parent() else {
            return workspace.to_path_buf();
        };
        current = parent;
    }
}

fn trusted_workflow_path(
    app: &AppHandle,
    workspace: &Path,
    raw_path: &str,
) -> Result<PathBuf, String> {
    let candidate = PathBuf::from(raw_path.trim());
    if !candidate.is_absolute() {
        return Err("Workflow 源文件必须是本地绝对路径".to_string());
    }
    if candidate
        .extension()
        .and_then(|extension| extension.to_str())
        != Some("rhai")
    {
        return Err("Workflow 源文件必须是 .rhai 文件".to_string());
    }

    let metadata = fs::symlink_metadata(&candidate)
        .map_err(|error| format!("无法读取 Workflow 源文件: {error}"))?;
    if metadata.file_type().is_symlink() || !metadata.is_file() {
        return Err("Workflow 源文件不是受信任的普通文件".to_string());
    }
    if metadata.len() > MAX_WORKFLOW_SOURCE_BYTES {
        return Err("Workflow 源文件超过 1 MB 限制".to_string());
    }

    let canonical = candidate
        .canonicalize()
        .map_err(|error| format!("无法解析 Workflow 源文件: {error}"))?;
    let project_workflow_dir = workflow_project_root(workspace)
        .join(".grok")
        .join("workflows");
    let user_workflow_dir = grok_home(app)?.join("workflows");
    let trusted_dirs = [project_workflow_dir, user_workflow_dir]
        .into_iter()
        .filter_map(|directory| directory.canonicalize().ok())
        .collect::<Vec<_>>();
    if !trusted_dirs
        .iter()
        .any(|directory| canonical.parent() == Some(directory.as_path()))
    {
        return Err("Workflow 源文件不在项目或用户 Workflow 目录中".to_string());
    }
    Ok(canonical)
}

#[tauri::command]
pub async fn grok_runtime_status(app: AppHandle) -> Result<GrokRuntimeStatus, String> {
    desktop_log::info("grok.runtime", "Checking bundled Grok runtime status.");
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
    if available {
        desktop_log::info(
            "grok.runtime",
            &format!("Bundled Grok runtime available: version={version}"),
        );
    } else {
        desktop_log::error(
            "grok.runtime",
            &format!(
                "Bundled Grok runtime unavailable: stderr={}",
                String::from_utf8_lossy(&output.stderr).trim()
            ),
        );
    }

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
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: String,
) -> Result<Vec<GrokAvailableCommand>, String> {
    let workspace = resolve_task_workspace(&app, &workspace)?;
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
pub async fn grok_workflow_list(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<Vec<GrokWorkflowListing>, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let process = session_process(&state, session_id)?;
    fetch_workflow_list(&process, session_id).await
}

#[tauri::command]
pub async fn grok_workflow_read(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    name: String,
) -> Result<GrokWorkflowFile, String> {
    let session_id = session_id.trim();
    let name = name.trim();
    if session_id.is_empty() || name.is_empty() {
        return Err("会话和 Workflow 名称不能为空".to_string());
    }

    let process = session_process(&state, session_id)?;
    let listing = fetch_workflow_list(&process, session_id)
        .await?
        .into_iter()
        .find(|workflow| workflow.name == name)
        .ok_or_else(|| format!("未找到 Workflow：{name}"))?;
    let content = listing
        .path
        .as_deref()
        .map(|path| {
            let trusted_path = trusted_workflow_path(&app, &process.workspace, path)?;
            fs::read_to_string(&trusted_path)
                .map_err(|error| format!("读取 Workflow 源文件失败: {error}"))
        })
        .transpose()?;

    Ok(GrokWorkflowFile {
        name: listing.name,
        description: listing.description,
        when_to_use: listing.when_to_use,
        source: listing.source,
        path: listing.path,
        content,
    })
}

#[tauri::command]
pub async fn grok_model_catalog(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: String,
) -> Result<Option<GrokModelCatalog>, String> {
    let workspace = resolve_task_workspace(&app, &workspace)?;
    Ok(workspace_process(&state, &workspace)?.model_catalog())
}

#[tauri::command]
pub async fn grok_session_search(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: String,
    query: String,
    limit: Option<usize>,
) -> Result<Value, String> {
    let workspace = resolve_task_workspace(&app, &workspace)?;
    let query = query.trim();
    if query.is_empty() {
        return Ok(json!({ "results": [], "nextOffset": null, "totalEstimate": 0 }));
    }
    let process = workspace_process(&state, &workspace)?;
    let params = json!({
        "query": query,
        "cwd": workspace.to_string_lossy(),
        "limit": limit.unwrap_or(20).clamp(1, 100),
        "offset": 0,
        "includeContent": true,
    });
    match process.request("x.ai/session/search", params).await {
        Ok(value) => Ok(value),
        Err(error) if is_method_not_found_error(&error) => {
            let value = process
                .request(
                    "session/list",
                    json!({
                        "cwd": workspace.to_string_lossy(),
                        "query": query,
                        "limit": limit.unwrap_or(20).clamp(1, 100),
                    }),
                )
                .await?;
            let results = value.get("sessions").cloned().unwrap_or_else(|| json!([]));
            let total_estimate = results
                .as_array()
                .map(|items| items.len())
                .unwrap_or_default();
            Ok(json!({
                "results": results,
                "nextOffset": null,
                "totalEstimate": total_estimate,
                "bootstrapping": false,
            }))
        }
        Err(error) => Err(error),
    }
}

#[tauri::command]
pub async fn grok_session_info(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let request = match session_process(&state, session_id) {
        Ok(process) => {
            process
                .request("x.ai/session/info", json!({ "sessionId": session_id }))
                .await
        }
        Err(error) => Err(error),
    };
    match request {
        Ok(value) => Ok(value),
        Err(error) => read_persisted_session_info(&app, session_id)?.ok_or(error),
    }
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
    let compact_prompt = user_context
        .map(|context| context.trim().to_string())
        .filter(|context| !context.is_empty())
        .map_or_else(
            || "/compact".to_string(),
            |context| format!("/compact {context}"),
        );
    session_process(&state, session_id)?
        .request_with_meta(
            "session/prompt",
            json!({
                "sessionId": session_id,
                "prompt": [{ "type": "text", "text": compact_prompt }],
            }),
            Some(json!({ "clientIdentifier": "urgs-desktop" })),
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
    // x.ai/recap is an ACP extension. The outer stdio wire uses the
    // underscore-prefixed method name; the Grok agent strips the prefix before
    // dispatching to the built-in recap handler.
    session_process(&state, session_id)?
        .request_with_meta(
            GROK_RECAP_METHOD,
            json!({
                "sessionId": session_id,
                "auto": false,
            }),
            Some(json!({ "clientIdentifier": "urgs-desktop" })),
        )
        .await
}

#[tauri::command]
pub async fn grok_session_rename(
    app: AppHandle,
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
    let workspace = workspace
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .map(|workspace| resolve_task_workspace(&app, workspace))
        .transpose()?;
    let process = if let Some(workspace) = workspace.as_ref() {
        workspace_process(&state, workspace)?
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
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    workspace: Option<String>,
) -> Result<Value, String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let workspace = workspace
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .map(|workspace| resolve_task_workspace(&app, workspace))
        .transpose()?;
    let process = if let Some(workspace) = workspace.as_ref() {
        workspace_process(&state, workspace)?
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
    let workspace = resolve_task_workspace(&app, &workspace)?;
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
    let display_workspace = match workspace_path {
        Some(workspace) => workspace,
        None => general_task_workspace(&app)?,
    };
    Ok(configured_mcp_servers(&app, &display_workspace)?.1)
}

#[tauri::command]
pub async fn grok_reload_mcp_servers(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: String,
) -> Result<Value, String> {
    let workspace = resolve_task_workspace(&app, &workspace)?;
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
    let process = session_process(&state, session_id)?;
    match process
        .request("x.ai/memory/flush", json!({ "session_id": session_id }))
        .await
    {
        Ok(value) => Ok(value),
        Err(error) if is_method_not_found_error(&error) => {
            process
                .request_with_meta(
                    "session/prompt",
                    json!({
                        "sessionId": session_id,
                        "prompt": [{ "type": "text", "text": "/flush" }],
                    }),
                    Some(json!({ "clientIdentifier": "urgs-desktop" })),
                )
                .await
        }
        Err(error) => Err(error),
    }
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
    let diagnostics = by_process
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
            agent_capabilities: process.agent_capabilities(),
            stderr: process
                .stderr
                .lock()
                .map(|value| value.clone())
                .unwrap_or_default(),
        })
        .collect::<Vec<_>>();
    desktop_log::debug(
        "grok.diagnostics",
        &format!(
            "Runtime diagnostics read: process_count={}",
            diagnostics.len()
        ),
    );
    Ok(diagnostics)
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
    let workspace = resolve_task_workspace(&app, &workspace)?;
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
    let is_extension_management = matches!(
        arguments.first().map(String::as_str),
        Some("plugin" | "inspect")
    );
    let current_dir = if is_extension_management {
        // Plugin installation and inspection operate on GROK_HOME. Keeping
        // these commands in the app-owned directory avoids macOS GUI children
        // blocking in getcwd() on privacy-managed Documents workspaces.
        general_task_workspace(&app)?
    } else {
        match workspace.filter(|value| !value.trim().is_empty()) {
            Some(workspace) => resolve_task_workspace(&app, &workspace)?,
            None => general_task_workspace(&app)?,
        }
    };
    let mut command_arguments = vec!["--no-auto-update".to_string()];
    command_arguments.extend(arguments.iter().cloned());
    let home = grok_home(&app)?;
    let mut process_envs = offline_runtime_envs(&home);
    process_envs.extend(model_provider_envs(&app, model)?);
    let executable =
        std::env::current_exe().map_err(|error| format!("无法定位 Desktop 可执行文件: {error}"))?;
    let executable_dir = executable
        .parent()
        .ok_or_else(|| "无法定位 Desktop 可执行文件目录".to_string())?;
    #[cfg(windows)]
    let grok_executable = executable_dir.join("grok.exe");
    #[cfg(not(windows))]
    let grok_executable = executable_dir.join("grok");
    if !grok_executable.is_file() {
        return Err(format!(
            "无法定位内置 Grok Build: {}",
            grok_executable.display()
        ));
    }
    let mut command = TokioCommand::new(grok_executable);
    command
        .args(command_arguments)
        // One-shot management commands can start in the validated workspace
        // directly. This avoids Grok's post-launch --cwd transition getting
        // stuck in getcwd() when spawned by a macOS GUI app.
        .current_dir(&current_dir)
        .env_clear()
        .env("GROK_HOME", &home)
        .envs(process_envs)
        // Dropping a timed-out output future must also stop the sidecar;
        // otherwise repeated plugin refreshes leave orphaned CLI processes.
        .kill_on_drop(true);
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
pub async fn terminal_run_command(
    app: AppHandle,
    workspace: Option<String>,
    command: String,
) -> Result<TerminalCommandResult, String> {
    let command = command.trim().to_string();
    if command.is_empty() {
        return Err("请输入要执行的命令".to_string());
    }

    let current_dir = match workspace.filter(|value| !value.trim().is_empty()) {
        Some(workspace) => resolve_task_workspace(&app, &workspace)?,
        None => general_task_workspace(&app)?,
    };

    #[cfg(windows)]
    let (shell, mut process) = {
        let mut process = TokioCommand::new("powershell.exe");
        process.args([
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            &command,
        ]);
        ("PowerShell".to_string(), process)
    };

    #[cfg(not(windows))]
    let (shell, mut process) = {
        let mut process = TokioCommand::new("/bin/sh");
        process.args(["-lc", &command]);
        ("Shell".to_string(), process)
    };

    process.current_dir(&current_dir);
    let output = tokio::time::timeout(TERMINAL_COMMAND_TIMEOUT, process.output())
        .await
        .map_err(|_| {
            format!(
                "终端命令执行超过 {} 秒，已停止等待",
                TERMINAL_COMMAND_TIMEOUT.as_secs()
            )
        })?
        .map_err(|error| format!("启动终端命令失败: {error}"))?;

    Ok(TerminalCommandResult {
        shell,
        cwd: current_dir.to_string_lossy().to_string(),
        command,
        success: output.status.success(),
        exit_code: output.status.code(),
        stdout: String::from_utf8_lossy(&output.stdout).to_string(),
        stderr: String::from_utf8_lossy(&output.stderr).to_string(),
    })
}

fn terminal_shell_command() -> (String, String) {
    #[cfg(windows)]
    {
        ("PowerShell".to_string(), "powershell.exe".to_string())
    }

    #[cfg(not(windows))]
    {
        let command = std::env::var("SHELL")
            .ok()
            .filter(|value| !value.trim().is_empty())
            .unwrap_or_else(|| "/bin/sh".to_string());
        let label = Path::new(&command)
            .file_name()
            .and_then(|value| value.to_str())
            .unwrap_or("Shell")
            .to_string();
        (label, command)
    }
}

#[cfg(windows)]
fn sanitize_windows_terminal_environment(command: &mut CommandBuilder) {
    let environment: Vec<(String, String)> = command
        .iter_full_env_as_str()
        .filter(|(key, _)| !key.is_empty() && !key.starts_with('=') && !key.contains('\0'))
        .map(|(key, value)| {
            (
                key.to_string(),
                value.split('\0').next().unwrap_or_default().to_string(),
            )
        })
        .collect();

    command.env_clear();
    for (key, value) in environment {
        command.env(key, value);
    }
}

fn terminal_pty_size(cols: Option<u16>, rows: Option<u16>) -> PtySize {
    PtySize {
        cols: cols.unwrap_or(100).clamp(20, 400),
        rows: rows.unwrap_or(24).clamp(4, 200),
        pixel_width: 0,
        pixel_height: 0,
    }
}

fn get_terminal_session(
    state: &TerminalState,
    session_id: &str,
) -> Result<Arc<TerminalSession>, String> {
    state
        .sessions
        .lock()
        .map_err(|_| "终端会话锁不可用".to_string())?
        .get(session_id)
        .cloned()
        .ok_or_else(|| "终端会话已关闭".to_string())
}

fn create_terminal_session_blocking(
    app: AppHandle,
    state: TerminalState,
    workspace: Option<String>,
    cols: Option<u16>,
    rows: Option<u16>,
) -> Result<TerminalSessionInfo, String> {
    let current_dir = match workspace.filter(|value| !value.trim().is_empty()) {
        Some(workspace) => resolve_task_workspace(&app, &workspace)?,
        None => general_task_workspace(&app)?,
    };
    let (shell, shell_command) = terminal_shell_command();
    let pty_system = native_pty_system();
    let pair = pty_system
        .openpty(terminal_pty_size(cols, rows))
        .map_err(|error| format!("创建终端会话失败: {error}"))?;

    let mut command = CommandBuilder::new(shell_command);
    #[cfg(windows)]
    sanitize_windows_terminal_environment(&mut command);
    command.cwd(&current_dir);
    command.env("TERM", "xterm-256color");
    command.env("COLORTERM", "truecolor");
    command.env("CLICOLOR", "1");
    #[cfg(windows)]
    {
        command.arg("-NoLogo");
        // 自定义提示符:只显示当前目录最后一段(项目名),避免 UNC 长路径
        // 默认的 FileSystem::\\?\UNC\... 前缀显示过长,截短为 PS 项目名>
        command.arg("-NoExit");
        command.arg("-Command");
        command.arg("function global:prompt { $leaf = Split-Path -Leaf $PWD.ProviderPath; if (-not $leaf) { $leaf = $PWD.Path }; 'PS ' + $leaf + '> ' }");
    }
    #[cfg(not(windows))]
    command.arg("-i");

    let child = pair
        .slave
        .spawn_command(command)
        .map_err(|error| format!("启动终端 Shell 失败: {error}"))?;
    drop(pair.slave);

    let reader = pair
        .master
        .try_clone_reader()
        .map_err(|error| format!("连接终端输出失败: {error}"))?;
    let writer = pair
        .master
        .take_writer()
        .map_err(|error| format!("连接终端输入失败: {error}"))?;
    let session_id = Uuid::new_v4().to_string();
    let session = Arc::new(TerminalSession {
        master: Mutex::new(pair.master),
        writer: Mutex::new(writer),
        child: Mutex::new(child),
    });
    state
        .sessions
        .lock()
        .map_err(|_| "终端会话锁不可用".to_string())?
        .insert(session_id.clone(), session);

    let reader_session_id = session_id.clone();
    let reader_sessions = state.sessions.clone();
    let reader_app = app.clone();
    if std::thread::Builder::new()
        .name(format!("urgs-terminal-{reader_session_id}"))
        .spawn(move || {
            let mut reader = reader;
            let mut buffer = [0_u8; 8192];
            loop {
                match reader.read(&mut buffer) {
                    Ok(0) => break,
                    Ok(length) => {
                        let _ = reader_app.emit(
                            "terminal-output",
                            TerminalOutputEvent {
                                session_id: reader_session_id.clone(),
                                data_base64: BASE64_STANDARD.encode(&buffer[..length]),
                            },
                        );
                    }
                    Err(error) if error.kind() == std::io::ErrorKind::Interrupted => continue,
                    Err(_) => break,
                }
            }

            let _ = reader_app.emit(
                "terminal-exit",
                TerminalExitEvent {
                    session_id: reader_session_id.clone(),
                },
            );
            if let Ok(mut sessions) = reader_sessions.lock() {
                sessions.remove(&reader_session_id);
            }
        })
        .is_err()
    {
        let session = state
            .sessions
            .lock()
            .ok()
            .and_then(|mut sessions| sessions.remove(&session_id));
        if let Some(session) = session {
            if let Ok(mut child) = session.child.lock() {
                let _ = child.kill();
            }
        }
        return Err("启动终端输出线程失败".to_string());
    }

    Ok(TerminalSessionInfo {
        session_id,
        shell,
        cwd: current_dir.to_string_lossy().to_string(),
    })
}

#[tauri::command]
pub async fn terminal_create_session(
    app: AppHandle,
    state: State<'_, TerminalState>,
    workspace: Option<String>,
    cols: Option<u16>,
    rows: Option<u16>,
) -> Result<TerminalSessionInfo, String> {
    let state = state.inner().clone();
    tauri::async_runtime::spawn_blocking(move || {
        create_terminal_session_blocking(app, state, workspace, cols, rows)
    })
    .await
    .map_err(|error| format!("等待终端初始化任务失败: {error}"))?
}

#[tauri::command]
pub fn terminal_write(
    state: State<'_, TerminalState>,
    session_id: String,
    data: String,
) -> Result<(), String> {
    let session = get_terminal_session(&state, &session_id)?;
    let mut writer = session
        .writer
        .lock()
        .map_err(|_| "终端输入锁不可用".to_string())?;
    writer
        .write_all(data.as_bytes())
        .map_err(|error| format!("写入终端失败: {error}"))?;
    writer
        .flush()
        .map_err(|error| format!("刷新终端输入失败: {error}"))
}

#[tauri::command]
pub async fn terminal_resize(
    state: State<'_, TerminalState>,
    session_id: String,
    cols: u16,
    rows: u16,
) -> Result<(), String> {
    let state = state.inner().clone();
    tauri::async_runtime::spawn_blocking(move || {
        let session = get_terminal_session(&state, &session_id)?;
        let result = session
            .master
            .lock()
            .map_err(|_| "终端窗口锁不可用".to_string())?
            .resize(terminal_pty_size(Some(cols), Some(rows)))
            .map_err(|error| format!("调整终端窗口失败: {error}"));
        result
    })
    .await
    .map_err(|error| format!("等待终端缩放任务失败: {error}"))?
}

#[tauri::command]
pub async fn terminal_close(
    state: State<'_, TerminalState>,
    session_id: String,
) -> Result<(), String> {
    let state = state.inner().clone();
    tauri::async_runtime::spawn_blocking(move || {
        let session = state
            .sessions
            .lock()
            .map_err(|_| "终端会话锁不可用".to_string())?
            .remove(&session_id);
        if let Some(session) = session {
            if let Ok(mut child) = session.child.lock() {
                let _ = child.kill();
            }
        }
        Ok(())
    })
    .await
    .map_err(|error| format!("等待终端关闭任务失败: {error}"))?
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

#[tauri::command]
pub fn grok_skill_set_enabled(app: AppHandle, name: String, enabled: bool) -> Result<(), String> {
    let name = name.trim();
    if name.is_empty()
        || name.len() > 256
        || name
            .chars()
            .any(|value| matches!(value, '\n' | '\r' | '\0'))
    {
        return Err("Skill 名称不合法".to_string());
    }
    let path = grok_config_path(&app, "user", "config", None)?;
    let content = if path.is_file() {
        fs::read_to_string(&path).map_err(|error| format!("读取 Grok 配置失败: {error}"))?
    } else {
        String::new()
    };
    let mut config = parse_grok_toml(&content)?;
    update_grok_string_list(&mut config, "skills", "disabled", name, !enabled)?;
    write_grok_user_config(&app, &config)
}

#[tauri::command]
pub fn grok_skill_remove(app: AppHandle, name: String, source_path: String) -> Result<(), String> {
    let name = name.trim();
    let source_path = source_path.trim();
    let path = PathBuf::from(source_path);
    if name.is_empty()
        || source_path.is_empty()
        || source_path.len() > 8_192
        || source_path.contains('\0')
        || !path.is_absolute()
        || path.file_name().and_then(|value| value.to_str()) != Some("SKILL.md")
    {
        return Err("Skill 来源路径不合法".to_string());
    }
    let config_path = grok_config_path(&app, "user", "config", None)?;
    let content = if config_path.is_file() {
        fs::read_to_string(&config_path).map_err(|error| format!("读取 Grok 配置失败: {error}"))?
    } else {
        String::new()
    };
    let mut config = parse_grok_toml(&content)?;
    update_grok_string_list(&mut config, "skills", "ignore", source_path, true)?;
    update_grok_string_list(&mut config, "skills", "disabled", name, false)?;
    write_grok_user_config(&app, &config)
}

#[tauri::command]
pub fn grok_compat_mcp_remove(
    app: AppHandle,
    workspace: Option<String>,
    name: String,
    source_type: String,
    source_path: String,
) -> Result<(), String> {
    let name = name.trim();
    let source_path = PathBuf::from(source_path.trim());
    if name.is_empty()
        || name.len() > 256
        || name
            .chars()
            .any(|value| matches!(value, '\n' | '\r' | '\0'))
    {
        return Err("MCP 服务名称不合法".to_string());
    }
    if !matches!(source_type.as_str(), "claudeJson" | "mcpJson") || !source_path.is_absolute() {
        return Err("仅支持移除 Claude JSON 或 .mcp.json 导入的 MCP 服务".to_string());
    }
    if source_type == "claudeJson" {
        let expected = std::env::var_os("HOME")
            .or_else(|| std::env::var_os("USERPROFILE"))
            .map(PathBuf::from)
            .ok_or_else(|| "无法定位用户目录".to_string())?
            .join(".claude.json");
        if source_path != expected {
            return Err("Claude MCP 来源路径不在允许范围内".to_string());
        }
    } else {
        let workspace = workspace
            .as_deref()
            .filter(|value| !value.trim().is_empty())
            .map(validate_workspace)
            .transpose()?
            .unwrap_or(general_task_workspace(&app)?);
        let canonical_workspace = workspace
            .canonicalize()
            .map_err(|error| format!("无法访问工作区: {error}"))?;
        let parent = source_path
            .parent()
            .ok_or_else(|| "MCP 来源路径无效".to_string())?
            .canonicalize()
            .map_err(|error| format!("无法访问 MCP 来源目录: {error}"))?;
        if source_path.file_name().and_then(|value| value.to_str()) != Some(".mcp.json")
            || !(canonical_workspace.starts_with(&parent)
                || parent.starts_with(&canonical_workspace))
        {
            return Err(".mcp.json 来源路径不在当前工作区层级内".to_string());
        }
    }
    let content = fs::read_to_string(&source_path)
        .map_err(|error| format!("读取 MCP 来源配置失败: {error}"))?;
    let mut root: Value = serde_json::from_str(&content)
        .map_err(|error| format!("MCP 来源配置不是有效 JSON: {error}"))?;
    let servers = root
        .get_mut("mcpServers")
        .and_then(Value::as_object_mut)
        .ok_or_else(|| "MCP 来源配置中不存在 mcpServers".to_string())?;
    if servers.remove(name).is_none() {
        return Err(format!("MCP 来源配置中不存在“{name}”"));
    }
    fs::copy(&source_path, source_path.with_extension("json.urgs-backup"))
        .map_err(|error| format!("备份 MCP 来源配置失败: {error}"))?;
    let output = serde_json::to_string_pretty(&root)
        .map_err(|error| format!("序列化 MCP 来源配置失败: {error}"))?;
    fs::write(&source_path, format!("{output}\n"))
        .map_err(|error| format!("保存 MCP 来源配置失败: {error}"))
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

fn normalize_reasoning_effort(reasoning_effort: Option<String>) -> Result<Option<String>, String> {
    let Some(reasoning_effort) = reasoning_effort else {
        return Ok(None);
    };
    let reasoning_effort = reasoning_effort.trim();
    if reasoning_effort.is_empty() {
        return Ok(None);
    }
    match reasoning_effort {
        "none" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max" => {
            Ok(Some(reasoning_effort.to_string()))
        }
        _ => Err("不支持的模型思考级别".to_string()),
    }
}

fn direct_model_api_endpoint(provider: &GrokModelProvider) -> Result<String, String> {
    let mut endpoint =
        url::Url::parse(&provider.base_url).map_err(|_| "模型服务地址格式不正确".to_string())?;
    if !matches!(endpoint.scheme(), "http" | "https") || endpoint.host_str().is_none() {
        return Err("模型服务地址必须是有效的 HTTP 或 HTTPS 地址".to_string());
    }
    let suffix = match provider.api_backend.as_str() {
        "chat_completions" => "/chat/completions",
        "responses" => "/responses",
        "messages" => "/messages",
        _ => return Err("暂不支持该模型 API 协议".to_string()),
    };
    let current_path = endpoint.path().trim_end_matches('/');
    if !current_path.ends_with(suffix) {
        let path = if current_path.is_empty() {
            suffix.to_string()
        } else {
            format!("{current_path}{suffix}")
        };
        endpoint.set_path(&path);
    }
    Ok(endpoint.to_string())
}

fn direct_model_api_payload(provider: &GrokModelProvider, prompt: &str) -> Value {
    let mut payload = match provider.api_backend.as_str() {
        "responses" => json!({
            "model": provider.model,
            "input": prompt,
            "max_output_tokens": 256,
        }),
        "messages" => json!({
            "model": provider.model,
            "max_tokens": 256,
            "messages": [{ "role": "user", "content": prompt }],
        }),
        _ => json!({
            "model": provider.model,
            "temperature": 0.2,
            "max_tokens": 256,
            "messages": [{ "role": "user", "content": prompt }],
        }),
    };
    if provider.api_backend == "chat_completions"
        && provider.model.to_ascii_lowercase().contains("deepseek")
    {
        payload["thinking"] = json!({ "type": "disabled" });
    }
    payload
}

fn text_from_model_value(value: &Value) -> Option<String> {
    match value {
        Value::String(text) if !text.trim().is_empty() => Some(text.trim().to_string()),
        Value::Array(items) => {
            let text = items
                .iter()
                .filter_map(text_from_model_value)
                .collect::<Vec<_>>()
                .join("");
            (!text.trim().is_empty()).then_some(text)
        }
        Value::Object(object) => [
            "text",
            "content",
            "output_text",
            "message",
            "completion",
            "delta",
            "choices",
            "output",
            "response",
            "result",
            "data",
        ]
        .into_iter()
        .find_map(|key| object.get(key).and_then(text_from_model_value)),
        _ => None,
    }
}

fn direct_model_api_response_text(provider: &GrokModelProvider, body: &Value) -> Option<String> {
    let candidates = match provider.api_backend.as_str() {
        "responses" => vec![
            body.get("output_text"),
            body.pointer("/output/0/content"),
            body.get("output"),
        ],
        "messages" => vec![body.get("content"), body.get("completion")],
        _ => vec![
            body.pointer("/choices/0/message/content"),
            body.pointer("/choices/0/text"),
            body.get("content"),
        ],
    };
    candidates
        .into_iter()
        .flatten()
        .find_map(text_from_model_value)
        .or_else(|| text_from_model_value(body))
}

fn direct_model_api_error(body: &str) -> String {
    let detail = serde_json::from_str::<Value>(body)
        .ok()
        .and_then(|value| {
            value
                .get("error")
                .and_then(text_from_model_value)
                .or_else(|| value.get("message").and_then(text_from_model_value))
        })
        .unwrap_or_else(|| body.trim().to_string());
    let detail = detail.chars().take(1_000).collect::<String>();
    if detail.is_empty() {
        "未返回错误详情".to_string()
    } else {
        detail
    }
}

#[tauri::command]
pub async fn llm_generate_text(
    app: AppHandle,
    input: LlmTextGenerationInput,
) -> Result<LlmTextGenerationResult, String> {
    let provider_id = normalize_provider_id(&input.provider_id)?;
    let prompt = input.prompt.trim();
    if prompt.is_empty() {
        return Err("请输入要发送给模型的内容".to_string());
    }
    if prompt.as_bytes().len() > MAX_LLM_PROMPT_BYTES {
        return Err("模型请求内容过大，请缩小 Diff 后重试".to_string());
    }

    let mut providers = read_model_providers(&app)?;
    let provider_index = providers
        .iter()
        .position(|provider| provider.id == provider_id)
        .ok_or_else(|| format!("模型连接“{provider_id}”不存在"))?;
    let provider = providers[provider_index].clone();
    if !provider.enabled {
        return Err(format!(
            "模型连接“{}”已停用，请在设置中启用后再使用",
            provider.name
        ));
    }
    let api_key = read_provider_api_key(&provider.id, true)?
        .ok_or_else(|| format!("模型连接“{}”尚未配置 API Key", provider.name))?;
    if !provider.has_api_key {
        providers[provider_index].has_api_key = true;
        let _ = write_model_providers(&app, &providers);
    }

    let endpoint = direct_model_api_endpoint(&provider)?;
    let mut headers = HeaderMap::new();
    headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    match provider.auth_scheme.as_str() {
        "bearer" => {
            let value = HeaderValue::from_str(&format!("Bearer {api_key}"))
                .map_err(|_| "模型 API Key 包含非法字符".to_string())?;
            headers.insert(AUTHORIZATION, value);
        }
        "x_api_key" => {
            let value = HeaderValue::from_str(&api_key)
                .map_err(|_| "模型 API Key 包含非法字符".to_string())?;
            headers.insert("x-api-key", value);
        }
        _ => return Err("暂不支持该认证方案".to_string()),
    }
    if provider.api_backend == "messages" {
        headers.insert("anthropic-version", HeaderValue::from_static("2023-06-01"));
    }

    let client = Client::builder()
        .timeout(LLM_REQUEST_TIMEOUT)
        .build()
        .map_err(|error| format!("初始化模型 API 客户端失败: {error}"))?;
    let response = client
        .post(endpoint)
        .headers(headers)
        .json(&direct_model_api_payload(&provider, prompt))
        .send()
        .await
        .map_err(|error| format!("调用模型 API 失败: {error}"))?;
    let status = response.status();
    let body = response
        .text()
        .await
        .map_err(|error| format!("读取模型 API 响应失败: {error}"))?;
    if body.as_bytes().len() > MAX_LLM_RESPONSE_BYTES {
        return Err("模型 API 响应过大，未读取其内容".to_string());
    }
    if !status.is_success() {
        return Err(format!(
            "模型 API 请求失败（HTTP {}）：{}",
            status.as_u16(),
            direct_model_api_error(&body)
        ));
    }
    let response_json = serde_json::from_str::<Value>(&body)
        .map_err(|error| format!("模型 API 返回不是有效 JSON: {error}"))?;
    let text = direct_model_api_response_text(&provider, &response_json)
        .ok_or_else(|| "模型 API 返回中没有可用文本".to_string())?;
    Ok(LlmTextGenerationResult {
        provider_id: provider.id,
        model: provider.model,
        text,
    })
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
        Some(workspace) => resolve_task_workspace(&app, &workspace)?,
        None => general_task_workspace(&app)?,
    };
    let mut command_arguments = vec![
        "--no-auto-update".to_string(),
        "--cwd".to_string(),
        current_dir.to_string_lossy().to_string(),
    ];
    command_arguments.extend(arguments.iter().cloned());
    let home = grok_home(&app)?;
    let mut process_envs = offline_runtime_envs(&home);
    process_envs.extend(model_provider_envs(&app, model)?);
    let (mut receiver, child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(command_arguments)
        // Keep the sidecar in the app directory and let Grok apply the
        // selected workspace after its launch-directory initialization.
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
    let workspace = resolve_task_workspace(&app, &workspace)?;
    desktop_log::info(
        "grok.session",
        &format!(
            "Creating session: workspace={} model={}",
            workspace.display(),
            model.as_deref().unwrap_or_default()
        ),
    );
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
        .request_with_meta(
            "session/new",
            json!({
                "cwd": workspace,
                "mcpServers": mcp_payload,
            }),
            Some(session_request_meta(rules.as_deref())),
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
    desktop_log::info(
        "grok.session",
        &format!(
            "Session created: session={} process={} workspace={}",
            session_id,
            process.process_id,
            workspace.display()
        ),
    );
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
    attach_mode: Option<String>,
) -> Result<GrokSession, String> {
    let session_id = session_id.trim().to_string();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let attach_method = session_attach_method(attach_mode.as_deref())?;
    let workspace = resolve_task_workspace(&app, &workspace)?;
    desktop_log::info(
        "grok.session",
        &format!(
            "Loading session: session={} attach_method={} workspace={} model={}",
            session_id,
            attach_method,
            workspace.display(),
            model.as_deref().unwrap_or_default()
        ),
    );
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
            desktop_log::debug(
                "grok.session",
                &format!(
                    "Session already mounted: session={} process={}",
                    session_id, process.process_id
                ),
            );
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
    let (attach_result, replayed_events) = request_session_attach(
        &process,
        attach_method,
        &session_id,
        &workspace,
        &mcp_payload,
        rules.as_deref(),
    )
    .await;
    let (attach_result, replayed_events) = if attach_method == "session/resume" {
        match attach_result {
            Err(error) if is_unsupported_acp_method_error(&error) => {
                request_session_attach(
                    &process,
                    "session/load",
                    &session_id,
                    &workspace,
                    &mcp_payload,
                    rules.as_deref(),
                )
                .await
            }
            result => (result, replayed_events),
        }
    } else {
        (attach_result, replayed_events)
    };
    if let Err(error) = attach_result {
        process.stop();
        return Err(error);
    }
    if let Err(error) = register_session_process(&state, &session_id, Arc::clone(&process)) {
        process.stop();
        return Err(error);
    }
    desktop_log::info(
        "grok.session",
        &format!(
            "Session loaded: session={} process={} replayed_events={}",
            session_id,
            process.process_id,
            replayed_events.len()
        ),
    );
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
    session_mode: Option<String>,
    client_prompt_id: Option<String>,
) -> Result<(), String> {
    let grants_to_consume = attachment_grants.clone().unwrap_or_default();
    let attachments = authorize_prompt_attachments(&state, attachments, attachment_grants)?;
    desktop_log::info(
        "grok.session",
        &format!(
            "Prompt requested: session={} queued={} prompt_chars={} attachments={}",
            session_id.trim(),
            queued.unwrap_or(false),
            prompt.chars().count(),
            attachments.len()
        ),
    );
    let content = build_prompt_content(&prompt, attachments)?;
    let process = session_process(&state, &session_id)?;
    let session_mode = validate_session_mode(session_mode.as_deref().unwrap_or("default"))?;
    let prompt_meta = Some(json!({
        "clientIdentifier": "urgs-desktop",
        "mode": session_mode,
    }));
    if queued.unwrap_or(false) {
        let queued_session_id = session_id.clone();
        let queued_process = Arc::clone(&process);
        let queued_client_prompt_id = client_prompt_id.clone();
        emit_process_event(
            &app,
            &queued_process,
            "queued_prompt",
            json!({
                "sessionId": queued_session_id,
                "clientPromptId": queued_client_prompt_id,
                "phase": "accepted"
            }),
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
                Ok(_) => {
                    desktop_log::info(
                        "grok.session",
                        &format!(
                            "Queued prompt completed: session={} process={}",
                            queued_session_id, queued_process.process_id
                        ),
                    );
                    emit_process_event(
                        &app,
                        &queued_process,
                        "queued_prompt",
                        json!({
                            "sessionId": queued_session_id,
                            "clientPromptId": queued_client_prompt_id,
                            "phase": "completed"
                        }),
                    )
                }
                Err(error) => {
                    desktop_log::error(
                        "grok.session",
                        &format!(
                            "Queued prompt failed: session={} process={} error={error}",
                            queued_session_id, queued_process.process_id
                        ),
                    );
                    emit_process_event(
                        &app,
                        &queued_process,
                        "queued_prompt",
                        json!({
                            "sessionId": queued_session_id,
                            "clientPromptId": queued_client_prompt_id,
                            "phase": "failed",
                            "message": error,
                        }),
                    )
                }
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
    desktop_log::info(
        "grok.session",
        &format!(
            "Prompt completed: session={} process={}",
            session_id, process.process_id
        ),
    );
    consume_prompt_attachment_grants(&state, &grants_to_consume);
    Ok(())
}

#[tauri::command]
pub async fn grok_session_set_mode(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    mode: String,
) -> Result<(), String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话 ID 不能为空".to_string());
    }
    let mode = validate_session_mode(&mode)?;
    let process = session_process(&state, session_id)?;
    process
        .request(
            "session/set_mode",
            json!({ "sessionId": session_id, "modeId": mode }),
        )
        .await?;
    Ok(())
}

#[tauri::command]
pub async fn grok_session_fork(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    source_session_id: String,
    source_cwd: String,
    new_cwd: Option<String>,
    target_prompt_index: Option<u64>,
    new_model_id: Option<String>,
) -> Result<Value, String> {
    let source_session_id = source_session_id.trim();
    if source_session_id.is_empty() {
        return Err("源会话 ID 不能为空".to_string());
    }
    let source_cwd = resolve_task_workspace(&app, &source_cwd)?;
    let new_cwd = match new_cwd.filter(|value| !value.trim().is_empty()) {
        Some(workspace) => resolve_task_workspace(&app, &workspace)?,
        None => source_cwd.clone(),
    };
    let process = session_process(&state, source_session_id)?;
    process
        .request(
            "x.ai/session/fork",
            json!({
                "sourceSessionId": source_session_id,
                "sourceCwd": source_cwd,
                "newCwd": new_cwd,
                "newModelId": new_model_id.and_then(|value| {
                    let value = value.trim().to_string();
                    (!value.is_empty()).then_some(value)
                }),
                "targetPromptIndex": target_prompt_index,
                "sessionKind": "fork",
                "sourceWorkspaceDir": source_cwd,
            }),
        )
        .await
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
    let mut params = json!({ "sessionId": session_id });
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
    reasoning_effort: Option<String>,
) -> Result<(), String> {
    let model = normalize_model_id(&model)?;
    let reasoning_effort = normalize_reasoning_effort(reasoning_effort)?;
    ensure_model_provider_ready(&app, Some(&model))?;
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let process = session_process(&state, session_id)?;
    process
        .request_with_meta(
            "session/set_model",
            json!({ "sessionId": session_id, "modelId": model }),
            reasoning_effort.map(|reasoning_effort| json!({ "reasoningEffort": reasoning_effort })),
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

fn rewind_model_provider<'a>(
    providers: &'a [GrokModelProvider],
    requested_model: &str,
) -> Result<&'a GrokModelProvider, String> {
    providers
        .iter()
        .find(|provider| provider.id == requested_model && provider.enabled)
        .or_else(|| providers.iter().find(|provider| provider.enabled))
        .ok_or_else(|| "没有可用于加载历史文件检查点的模型连接".to_string())
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
    let workspace = resolve_task_workspace(&app, &workspace)?;
    let requested_model = normalize_model_id(&model)?;
    let (process, transient) = match session_process(&state, session_id) {
        Ok(process) => (process, false),
        Err(_) => {
            enforce_offline_config(&app)?;
            let providers = read_model_providers(&app)?;
            let model = rewind_model_provider(&providers, &requested_model)?
                .id
                .clone();
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
    desktop_log::info(
        "grok.session",
        &format!("Cancelling session: session={}", session_id.trim()),
    );
    let process = session_process(&state, &session_id)?;
    process.notify("_x.ai/queue/clear", json!({ "sessionId": session_id }))?;
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
    desktop_log::info(
        "grok.session",
        &format!(
            "Session cancellation sent: session={} process={}",
            session_id, process.process_id
        ),
    );
    Ok(())
}

#[tauri::command]
pub async fn grok_release_session(
    state: State<'_, GrokRuntimeState>,
    session_id: String,
) -> Result<(), String> {
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    desktop_log::info(
        "grok.session",
        &format!("Releasing session: session={session_id}"),
    );
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
        desktop_log::debug(
            "grok.session",
            &format!(
                "Releasing session from process: session={} process={} shared={shared}",
                session_id, process.process_id
            ),
        );
        let _ = process
            .request("session/close", json!({ "sessionId": session_id }))
            .await;
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
    desktop_log::info(
        "grok.session",
        &format!("Session released: session={session_id}"),
    );
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
    desktop_log::info("grok.runtime", "Shutting down Grok runtime.");
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
    desktop_log::info("grok.runtime", "Grok runtime shutdown completed.");
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
        cache_provider_api_key, consume_prompt_attachment_grants, direct_model_api_endpoint,
        direct_model_api_payload, direct_model_api_response_text, forget_cached_provider_api_key,
        format_rpc_error, general_session_key, grok_agent_arguments, initialize_client_meta,
        is_unsupported_acp_method_error, model_key_env_name, normalize_model_id,
        normalize_model_provider, normalize_reasoning_effort, normalized_interjection_params,
        normalized_queue_changed_params, normalized_session_update_message, parse_grok_toml,
        plan_approval_params, process_launch_key, read_provider_api_key, request_timeout,
        rewind_model_provider, scheduled_prompt_injection, select_auth_method, serialize_grok_toml,
        session_attach_method, session_request_meta, sync_provider_reasoning_capability,
        update_grok_string_list, user_question_params, validate_cli_arguments,
        validate_persisted_session_id, validate_service_arguments, validate_session_mode,
        workflow_listings_from_response, GrokAcpOptions, GrokCliService, GrokModelProvider,
        GrokModelProviderInput, GrokRuntimeState, PromptAttachmentGrant, AUTHENTICATE_TIMEOUT,
        CUSTOM_MODEL_DEFAULT_REASONING_EFFORT, CUSTOM_MODEL_REASONING_EFFORTS,
        GROK_INTERJECT_METHOD, GROK_RECAP_METHOD, INITIALIZE_TIMEOUT, MAX_PROMPT_ATTACHMENT_BYTES,
        REQUEST_TIMEOUT, SESSION_CLOSE_TIMEOUT, SESSION_START_TIMEOUT,
    };
    use serde_json::json;
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::sync::Mutex;

    #[test]
    fn updates_skill_disabled_and_ignore_lists_without_duplicates() {
        let mut config = parse_grok_toml(
            r#"[skills]
disabled = ["review"]
ignore = []
"#,
        )
        .unwrap();

        update_grok_string_list(&mut config, "skills", "disabled", "review", true).unwrap();
        update_grok_string_list(
            &mut config,
            "skills",
            "ignore",
            "/tmp/review/SKILL.md",
            true,
        )
        .unwrap();
        update_grok_string_list(&mut config, "skills", "disabled", "review", false).unwrap();

        let skills = config
            .get("skills")
            .and_then(toml::Value::as_table)
            .unwrap();
        assert!(skills
            .get("disabled")
            .and_then(toml::Value::as_array)
            .unwrap()
            .is_empty());
        assert_eq!(
            skills
                .get("ignore")
                .and_then(toml::Value::as_array)
                .unwrap(),
            &[toml::Value::String("/tmp/review/SKILL.md".to_string())]
        );
    }

    #[test]
    fn validates_supported_session_modes() {
        assert_eq!(validate_session_mode("default").unwrap(), "default");
        assert_eq!(validate_session_mode(" plan ").unwrap(), "plan");
        assert_eq!(validate_session_mode("ask").unwrap(), "ask");
        assert!(validate_session_mode("unsafe").is_err());
    }

    #[test]
    fn validates_isolated_general_session_workspace_keys() {
        assert_eq!(
            general_session_key("urgs-general-session://task-123_ab").unwrap(),
            Some("task-123_ab")
        );
        assert_eq!(general_session_key("/tmp/project").unwrap(), None);
        assert!(general_session_key("urgs-general-session://").is_err());
        assert!(general_session_key("urgs-general-session://../escape").is_err());
        assert!(general_session_key("urgs-general-session://task/name").is_err());
    }

    #[test]
    fn validates_supported_reasoning_efforts() {
        assert_eq!(
            normalize_reasoning_effort(Some(" high ".to_string())).unwrap(),
            Some("high".to_string())
        );
        assert_eq!(
            normalize_reasoning_effort(Some(" ".to_string())).unwrap(),
            None
        );
        assert_eq!(normalize_reasoning_effort(None).unwrap(), None);
        assert!(normalize_reasoning_effort(Some("ultra".to_string())).is_err());
    }

    #[test]
    fn rejects_session_ids_that_can_escape_storage() {
        assert_eq!(
            validate_persisted_session_id("session-123").unwrap(),
            "session-123"
        );
        for unsafe_id in [
            "",
            ".",
            "..",
            "../outside",
            "workspace/session",
            "workspace\\session",
        ] {
            assert!(validate_persisted_session_id(unsafe_id).is_err());
        }
    }

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
    fn reports_json_rpc_detail_for_generic_error() {
        assert_eq!(
            format_rpc_error(&json!({
                "message": "Internal error",
                "data": {
                    "message": "API error (status 400 Bad Request): image_url is not supported"
                }
            })),
            "Internal error: API error (status 400 Bad Request): image_url is not supported"
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
    fn parses_direct_and_wrapped_workflow_catalogs() {
        let direct = workflow_listings_from_response(&json!({
            "workflows": [{
                "name": "deep-research",
                "description": "Research a question",
                "whenToUse": "Use for multi-source research",
                "source": "builtin"
            }]
        }))
        .unwrap();
        assert_eq!(direct.len(), 1);
        assert_eq!(direct[0].name, "deep-research");
        assert_eq!(
            direct[0].when_to_use.as_deref(),
            Some("Use for multi-source research")
        );
        assert_eq!(direct[0].source, "builtin");

        let wrapped = workflow_listings_from_response(&json!({
            "inner": { "workflows": [{
                "name": "project-review",
                "description": "Review a project",
                "source": "project",
                "path": "/workspace/.grok/workflows/project-review.rhai"
            }] }
        }))
        .unwrap();
        assert_eq!(wrapped[0].name, "project-review");
        assert_eq!(
            wrapped[0].path.as_deref(),
            Some("/workspace/.grok/workflows/project-review.rhai")
        );

        let official = workflow_listings_from_response(&json!({
            "result": { "workflows": [{
                "name": "release-check",
                "description": "Check a release",
                "source": "user"
            }] },
            "error": null
        }))
        .unwrap();
        assert_eq!(official[0].name, "release-check");

        let failed = workflow_listings_from_response(&json!({
            "result": null,
            "error": "unknown session id"
        }))
        .unwrap_err();
        assert!(failed.contains("unknown session id"));

        assert!(workflow_listings_from_response(&json!({ "workflows": {} })).is_err());
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
        let direct_xai = normalized_session_update_message(&json!({
            "jsonrpc": "2.0",
            "method": "_x.ai/session_notification",
            "params": {
                "sessionId": "session-3",
                "update": {
                    "sessionUpdate": "retry_state",
                    "type": "retrying",
                    "attempt": 5,
                    "max_retries": 15
                }
            }
        }))
        .unwrap();
        assert_eq!(direct_xai["params"]["sessionId"], "session-3");
        assert_eq!(
            direct_xai["params"]["update"]["sessionUpdate"],
            "retry_state"
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
        assert_eq!(GROK_RECAP_METHOD, "_x.ai/recap");
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
        assert_eq!(request_timeout("session/resume"), SESSION_START_TIMEOUT);
        assert_eq!(request_timeout("session/close"), SESSION_CLOSE_TIMEOUT);
        assert_eq!(request_timeout("_x.ai/commands/list"), REQUEST_TIMEOUT);
        assert!(request_timeout("authenticate") > request_timeout("session/new"));
        assert!(request_timeout("session/new") > request_timeout("_x.ai/commands/list"));
    }

    #[test]
    fn session_requests_repeat_the_interactive_startup_policy() {
        let initialize_meta = initialize_client_meta(Some("workspace rules"));
        let session_meta = session_request_meta(Some("workspace rules"));
        let expected_hints = json!({
            "nonInteractive": false,
            "skipGitStatus": true,
            "skipProjectLayout": true,
            "deliveryTools": []
        });

        assert_eq!(initialize_meta["startupHints"], expected_hints);
        assert_eq!(session_meta["startupHints"], expected_hints);
        assert_eq!(initialize_meta["rules"], "workspace rules");
        assert_eq!(session_meta["rules"], "workspace rules");
        assert!(session_request_meta(None).get("rules").is_none());
    }

    #[test]
    fn session_attach_modes_are_explicit_and_backward_compatible() {
        assert_eq!(session_attach_method(None).unwrap(), "session/load");
        assert_eq!(session_attach_method(Some("")).unwrap(), "session/load");
        assert_eq!(session_attach_method(Some("load")).unwrap(), "session/load");
        assert_eq!(
            session_attach_method(Some("resume")).unwrap(),
            "session/resume"
        );
        assert!(session_attach_method(Some("fork")).is_err());
    }

    #[test]
    fn unsupported_acp_method_errors_are_detected_for_resume_fallback() {
        assert!(is_unsupported_acp_method_error("Method not found"));
        assert!(is_unsupported_acp_method_error(
            "unknown method session/resume"
        ));
        assert!(is_unsupported_acp_method_error("ACP error -32601"));
        assert!(!is_unsupported_acp_method_error("session resume failed"));
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
        assert!(validate_cli_arguments(&["du".to_string(), "--json".to_string()]).is_ok());
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
    fn rewind_uses_an_enabled_provider_when_historical_provider_is_missing() {
        let current = test_model_provider("chat_completions", "https://example.test/v1");
        let providers = vec![current];

        let selected = rewind_model_provider(&providers, "removed-historical-provider").unwrap();

        assert_eq!(selected.id, "test-provider");
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
            supports_reasoning_effort: true,
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
        assert!(provider.supports_reasoning_effort);
    }

    #[test]
    fn legacy_model_provider_without_reasoning_flag_remains_selectable() {
        let legacy_provider = serde_json::from_value::<GrokModelProvider>(json!({
            "id": "legacy-provider",
            "name": "旧版连接",
            "model": "deepseek-v4-flash-dspark",
            "baseUrl": "http://127.0.0.1:18080/v1",
            "apiBackend": "chat_completions",
            "authScheme": "bearer",
            "contextWindow": 256000,
            "enabled": true,
            "hasApiKey": true
        }))
        .unwrap();
        assert!(legacy_provider.supports_reasoning_effort);

        let mut explicitly_disabled_value = serde_json::to_value(&legacy_provider).unwrap();
        explicitly_disabled_value["supportsReasoningEffort"] = json!(false);
        let explicitly_disabled =
            serde_json::from_value::<GrokModelProvider>(explicitly_disabled_value).unwrap();
        assert!(!explicitly_disabled.supports_reasoning_effort);
    }

    #[test]
    fn syncs_custom_model_reasoning_capability_to_grok_config() {
        let mut entry = toml::map::Map::new();
        sync_provider_reasoning_capability(&mut entry, true);

        assert_eq!(
            entry
                .get("supports_reasoning_effort")
                .and_then(toml::Value::as_bool),
            Some(true)
        );
        assert_eq!(
            super::toml_string_list(entry.get("reasoning_efforts")),
            CUSTOM_MODEL_REASONING_EFFORTS
        );
        assert_eq!(
            entry.get("reasoning_effort").and_then(toml::Value::as_str),
            Some(CUSTOM_MODEL_DEFAULT_REASONING_EFFORT)
        );

        sync_provider_reasoning_capability(&mut entry, false);
        assert!(!entry.contains_key("supports_reasoning_effort"));
        assert!(!entry.contains_key("reasoning_efforts"));
        assert!(!entry.contains_key("reasoning_effort"));
    }

    fn test_model_provider(api_backend: &str, base_url: &str) -> GrokModelProvider {
        GrokModelProvider {
            id: "test-provider".into(),
            name: "测试连接".into(),
            model: "test-model".into(),
            base_url: base_url.into(),
            api_backend: api_backend.into(),
            auth_scheme: "bearer".into(),
            context_window: 128_000,
            enabled: true,
            supports_reasoning_effort: false,
            has_api_key: true,
        }
    }

    #[test]
    fn builds_direct_model_api_endpoints_and_protocol_payloads() {
        let chat = test_model_provider("chat_completions", "https://example.test/v1/");
        assert_eq!(
            direct_model_api_endpoint(&chat).unwrap(),
            "https://example.test/v1/chat/completions"
        );
        assert_eq!(
            direct_model_api_payload(&chat, "生成提交信息")["messages"][0]["content"],
            "生成提交信息"
        );
        let mut deepseek = chat.clone();
        deepseek.model = "deepseek-v4-flash".into();
        assert_eq!(
            direct_model_api_payload(&deepseek, "生成提交信息")["thinking"]["type"],
            "disabled"
        );

        let responses = test_model_provider("responses", "https://example.test/v1/responses");
        assert_eq!(
            direct_model_api_endpoint(&responses).unwrap(),
            "https://example.test/v1/responses"
        );
        assert_eq!(
            direct_model_api_payload(&responses, "生成提交信息")["input"],
            "生成提交信息"
        );

        let messages = test_model_provider("messages", "https://example.test/v1");
        assert_eq!(
            direct_model_api_endpoint(&messages).unwrap(),
            "https://example.test/v1/messages"
        );
        assert_eq!(
            direct_model_api_payload(&messages, "生成提交信息")["messages"][0]["content"],
            "生成提交信息"
        );
    }

    #[test]
    fn extracts_text_from_supported_direct_model_api_responses() {
        let chat = test_model_provider("chat_completions", "https://example.test/v1");
        assert_eq!(
            direct_model_api_response_text(
                &chat,
                &json!({ "choices": [{ "message": { "content": "feat: update" } }] }),
            )
            .as_deref(),
            Some("feat: update")
        );

        let responses = test_model_provider("responses", "https://example.test/v1");
        assert_eq!(
            direct_model_api_response_text(
                &responses,
                &json!({ "output_text": "fix: handle diff" }),
            )
            .as_deref(),
            Some("fix: handle diff")
        );

        let messages = test_model_provider("messages", "https://example.test/v1");
        assert_eq!(
            direct_model_api_response_text(
                &messages,
                &json!({ "content": [{ "type": "text", "text": "chore: refresh" }] }),
            )
            .as_deref(),
            Some("chore: refresh")
        );
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
