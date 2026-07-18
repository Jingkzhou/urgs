use serde::Serialize;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;
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
}

impl Default for GrokRuntimeState {
    fn default() -> Self {
        Self {
            process: Mutex::new(None),
        }
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

fn spawn_grok_process(
    app: &AppHandle,
    workspace: &Path,
    model: Option<&str>,
) -> Result<Arc<GrokProcess>, String> {
    let home = grok_home(app)?;
    let mut arguments = vec!["--no-auto-update".to_string(), "agent".to_string()];
    if let Some(model) = model.filter(|value| !value.trim().is_empty()) {
        arguments.push("--model".to_string());
        arguments.push(model.trim().to_string());
    }
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
pub async fn grok_create_session(
    app: AppHandle,
    state: State<'_, GrokRuntimeState>,
    workspace: String,
    rules: Option<String>,
    model: Option<String>,
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
    let process = spawn_grok_process(&app, &workspace, model.as_deref())?;
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
pub fn grok_start_login(app: AppHandle, state: State<'_, GrokRuntimeState>) -> Result<(), String> {
    grok_shutdown(state)?;
    let home = grok_home(&app)?;
    let (mut receiver, _child) = app
        .shell()
        .sidecar("grok")
        .map_err(|error| format!("无法定位内置 Grok Build: {error}"))?
        .args(["--no-auto-update", "login"])
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
    use super::{format_rpc_error, select_auth_method};
    use serde_json::json;

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
}
