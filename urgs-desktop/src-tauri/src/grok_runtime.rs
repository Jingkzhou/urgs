use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tauri::{AppHandle, Emitter, Manager, State};
use tauri_plugin_shell::process::{CommandChild, CommandEvent};
use tauri_plugin_shell::ShellExt;
use tokio::sync::{oneshot, Mutex as AsyncMutex};

const GROK_EVENT_NAME: &str = "grok-event";
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);

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
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct GrokAcpOptions {
    pub reasoning_effort: Option<String>,
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

pub struct GrokRuntimeState {
    process: Mutex<Option<Arc<GrokProcess>>>,
    cli_services: Mutex<HashMap<String, Arc<GrokCliService>>>,
    cli_service_sequence: AtomicU64,
}

impl Default for GrokRuntimeState {
    fn default() -> Self {
        Self {
            process: Mutex::new(None),
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
    child: Mutex<Option<CommandChild>>,
    pending_requests: Mutex<HashMap<u64, oneshot::Sender<Result<Value, String>>>>,
    pending_permissions: Mutex<Vec<PendingPermission>>,
    request_sequence: AtomicU64,
    initialized: AsyncMutex<bool>,
    alive: AtomicBool,
}

impl GrokProcess {
    fn new(child: CommandChild) -> Self {
        Self {
            child: Mutex::new(Some(child)),
            pending_requests: Mutex::new(HashMap::new()),
            pending_permissions: Mutex::new(Vec::new()),
            request_sequence: AtomicU64::new(1),
            initialized: AsyncMutex::new(false),
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

        let timeout = if method == "session/prompt" {
            Duration::from_secs(60 * 60)
        } else {
            REQUEST_TIMEOUT
        };
        match tokio::time::timeout(timeout, receiver).await {
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

        let response = self
            .request(
                "initialize",
                json!({
                    "protocolVersion": 1,
                    "clientCapabilities": {
                        "fs": {},
                        "terminal": false
                    },
                    "_meta": meta
                }),
            )
            .await?;
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

    fn stop(&self) {
        self.alive.store(false, Ordering::Relaxed);
        let child = self.child.lock().ok().and_then(|mut child| child.take());
        if let Some(child) = child {
            let _ = child.kill();
        }
    }
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

fn handle_stdout(app: &AppHandle, process: &Arc<GrokProcess>, line: Vec<u8>) {
    let line = String::from_utf8_lossy(&line).trim().to_string();
    if line.is_empty() {
        return;
    }
    let message = match serde_json::from_str::<Value>(&line) {
        Ok(message) => message,
        Err(error) => {
            emit_event(
                app,
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
        "session/update" | "sessionUpdate" => emit_event(app, "session_update", message),
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
                emit_event(app, "permission_request", message);
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
            emit_event(app, "agent_event", message);
        }
    }
}

fn push_optional_argument(arguments: &mut Vec<String>, flag: &str, value: Option<&String>) {
    if let Some(value) = value.filter(|value| !value.trim().is_empty()) {
        arguments.push(flag.to_string());
        arguments.push(value.trim().to_string());
    }
}

fn spawn_grok_process(
    app: &AppHandle,
    workspace: &Path,
    model: Option<&str>,
    options: &GrokAcpOptions,
) -> Result<Arc<GrokProcess>, String> {
    let home = grok_home(app)?;
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
    if options.always_approve.unwrap_or(false) {
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
    let (mut receiver, child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(arguments)
        .current_dir(workspace)
        .env("GROK_HOME", &home)
        .spawn()
        .map_err(|error| format!("启动本地 Grok Build 失败: {error}"))?;
    let process = Arc::new(GrokProcess::new(child));
    let reader_process = Arc::clone(&process);
    let reader_app = app.clone();
    tauri::async_runtime::spawn(async move {
        while let Some(event) = receiver.recv().await {
            match event {
                CommandEvent::Stdout(line) => handle_stdout(&reader_app, &reader_process, line),
                CommandEvent::Stderr(line) => emit_event(
                    &reader_app,
                    "stderr",
                    json!({ "message": String::from_utf8_lossy(&line).trim() }),
                ),
                CommandEvent::Error(error) => {
                    emit_event(&reader_app, "runtime_error", json!({ "message": error }))
                }
                CommandEvent::Terminated(status) => {
                    reader_process.alive.store(false, Ordering::Relaxed);
                    emit_event(&reader_app, "terminated", json!({ "code": status.code }));
                }
                _ => {}
            }
        }
    });
    Ok(process)
}

fn active_process(state: &GrokRuntimeState) -> Result<Arc<GrokProcess>, String> {
    state
        .process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .as_ref()
        .filter(|process| process.alive.load(Ordering::Relaxed))
        .cloned()
        .ok_or_else(|| "Grok 本地会话尚未启动".to_string())
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
pub async fn grok_cli_run(
    app: AppHandle,
    workspace: Option<String>,
    arguments: Vec<String>,
    timeout_seconds: Option<u64>,
) -> Result<GrokCliResult, String> {
    validate_cli_arguments(&arguments)?;
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
        .env("GROK_HOME", grok_home(&app)?);
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
        content
            .parse::<toml::Value>()
            .map_err(|error| format!("Grok TOML 配置无效: {error}"))?;
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
    if model.len() > 128 || model.chars().any(char::is_control) {
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
    let mut config = if content.trim().is_empty() {
        toml::Value::Table(toml::map::Map::new())
    } else {
        content
            .parse::<toml::Value>()
            .map_err(|error| format!("Grok TOML 配置无效: {error}"))?
    };
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
    fs::write(&path, config.to_string()).map_err(|error| format!("保存 Grok 配置失败: {error}"))?;
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
    let current_dir = match workspace.filter(|value| !value.trim().is_empty()) {
        Some(workspace) => validate_workspace(&workspace)?,
        None => grok_home(&app)?,
    };
    let mut command_arguments = vec!["--no-auto-update".to_string()];
    command_arguments.extend(arguments.iter().cloned());
    let (mut receiver, child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(command_arguments)
        .current_dir(current_dir)
        .env("GROK_HOME", grok_home(&app)?)
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
    let previous = state
        .process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .take();
    if let Some(previous) = previous {
        previous.stop();
    }
    let process = spawn_grok_process(
        &app,
        &workspace,
        model.as_deref(),
        &options.unwrap_or_default(),
    )?;
    *state
        .process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())? = Some(Arc::clone(&process));
    process.initialize(rules.as_deref()).await?;
    let response = process
        .request(
            "session/new",
            json!({
                "cwd": workspace,
                "mcpServers": [],
            }),
        )
        .await?;
    let session_id = response
        .get("sessionId")
        .and_then(Value::as_str)
        .ok_or_else(|| "Grok 未返回会话标识".to_string())?
        .to_string();
    Ok(GrokSession {
        session_id,
        workspace: workspace.to_string_lossy().to_string(),
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
    let process = active_process(&state)?;
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
    state: State<'_, GrokRuntimeState>,
    session_id: String,
    model: String,
) -> Result<(), String> {
    let model = normalize_model_id(&model)?;
    let session_id = session_id.trim();
    if session_id.is_empty() {
        return Err("会话标识不能为空".to_string());
    }
    let process = active_process(&state)?;
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
    let process = active_process(&state)?;
    process.notify("session/cancel", json!({ "sessionId": session_id }))?;
    for request_id in process.cancel_permissions(&session_id) {
        process.write_json(json!({
            "jsonrpc": "2.0",
            "id": request_id,
            "result": { "outcome": { "outcome": "cancelled" } }
        }))?;
    }
    Ok(())
}

#[tauri::command]
pub fn grok_respond_permission(
    state: State<'_, GrokRuntimeState>,
    request_id: Value,
    option_id: Option<String>,
) -> Result<(), String> {
    let process = active_process(&state)?;
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
pub fn grok_shutdown(state: State<'_, GrokRuntimeState>) -> Result<(), String> {
    let process = state
        .process
        .lock()
        .map_err(|_| "Grok 运行时锁不可用".to_string())?
        .take();
    if let Some(process) = process {
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
        format_rpc_error, select_auth_method, validate_cli_arguments, validate_service_arguments,
        GrokCliService,
    };
    use serde_json::json;
    use std::sync::Mutex;

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
