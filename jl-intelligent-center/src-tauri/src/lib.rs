mod desktop_log;
mod grok_git;
mod grok_runtime;

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Emitter, Manager, WindowEvent,
};
use tauri_plugin_deep_link::DeepLinkExt;

const SHOW_MAIN_WINDOW_MENU_ID: &str = "show-main-window";
const QUIT_APPLICATION_MENU_ID: &str = "quit-application";
const LEGACY_IDENTIFIER: &str = "com.jilinbank.urgs";
const LEGACY_HANDOFF_FILE: &str = "task-center/handoff-v1.json";
const LEGACY_MIGRATION_MARKER: &str = "legacy-urgs-migration-v1.json";

fn write_startup_log(message: &str) {
    desktop_log::info("startup", message);
}

fn show_main_window(app: &AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.unminimize();
        let _ = window.show();
        let _ = window.set_focus();
    }
}

fn shutdown_runtime(app: &AppHandle) {
    let _ = app.state::<grok_runtime::TerminalState>().close_all();
    let _ = grok_runtime::grok_shutdown(app.state::<grok_runtime::GrokRuntimeState>());
}

fn initialize_system_tray(app: &tauri::App) -> Result<(), Box<dyn std::error::Error>> {
    let show_main_window_item = MenuItem::with_id(
        app,
        SHOW_MAIN_WINDOW_MENU_ID,
        "显示主窗口",
        true,
        None::<&str>,
    )?;
    let quit_application =
        MenuItem::with_id(app, QUIT_APPLICATION_MENU_ID, "退出", true, None::<&str>)?;
    let tray_menu = Menu::with_items(app, &[&show_main_window_item, &quit_application])?;
    let tray_icon = app
        .default_window_icon()
        .cloned()
        .ok_or_else(|| "未找到应用图标，无法创建系统托盘".to_string())?;

    TrayIconBuilder::with_id("jl-intelligent-center-tray")
        .icon(tray_icon)
        .tooltip("吉林银行智能任务中心")
        .menu(&tray_menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app, event| match event.id.as_ref() {
            SHOW_MAIN_WINDOW_MENU_ID => show_main_window(app),
            QUIT_APPLICATION_MENU_ID => {
                shutdown_runtime(app);
                app.exit(0);
            }
            _ => {}
        })
        .on_tray_icon_event(|tray, event| match event {
            TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            }
            | TrayIconEvent::DoubleClick {
                button: MouseButton::Left,
                ..
            } => show_main_window(tray.app_handle()),
            _ => {}
        })
        .build(app)?;

    Ok(())
}

#[derive(Debug, Default, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct LegacyTaskCenterHandoff {
    snapshot: Option<String>,
    auth_user: Option<String>,
    #[serde(default)]
    migrated_paths: Vec<String>,
}

fn legacy_app_data_dir(app: &AppHandle) -> Result<PathBuf, String> {
    let current = app
        .path()
        .app_data_dir()
        .map_err(|error| format!("无法定位智能任务中心数据目录: {error}"))?;
    let parent = current
        .parent()
        .ok_or_else(|| "无法定位旧 URGS 数据目录".to_string())?;
    Ok(parent.join(LEGACY_IDENTIFIER))
}

fn should_skip_legacy_entry(relative: &Path) -> bool {
    let mut components = relative.components().filter_map(|value| value.as_os_str().to_str());
    let root = components.next();
    let child = components.next();
    if root == Some("grok-build")
        && matches!(child, Some("logs" | "debug" | "memtrace" | "marketplace-cache" | "bundled" | "vendor"))
    {
        return true;
    }
    let name = relative.file_name().and_then(|value| value.to_str()).unwrap_or_default();
    name.ends_with(".lock") || matches!(name, "active_sessions.json")
}

fn copy_legacy_tree(source: &Path, target: &Path, relative: &Path) -> Result<(), String> {
    if should_skip_legacy_entry(relative) {
        return Ok(());
    }
    let metadata = fs::symlink_metadata(source)
        .map_err(|error| format!("读取旧数据项 {} 失败: {error}", source.to_string_lossy()))?;
    if metadata.file_type().is_symlink() {
        return Ok(());
    }
    if metadata.is_dir() {
        fs::create_dir_all(target).map_err(|error| {
            format!("创建迁移目录 {} 失败: {error}", target.to_string_lossy())
        })?;
        for entry in fs::read_dir(source)
            .map_err(|error| format!("读取旧数据目录 {} 失败: {error}", source.to_string_lossy()))?
        {
            let entry = entry.map_err(|error| format!("读取旧数据项失败: {error}"))?;
            let child_relative = relative.join(entry.file_name());
            copy_legacy_tree(&entry.path(), &target.join(entry.file_name()), &child_relative)?;
        }
    } else if metadata.is_file() && !target.exists() {
        if let Some(parent) = target.parent() {
            fs::create_dir_all(parent).map_err(|error| {
                format!("创建迁移文件目录 {} 失败: {error}", parent.to_string_lossy())
            })?;
        }
        fs::copy(source, target).map_err(|error| {
            format!(
                "迁移文件 {} 到 {} 失败: {error}",
                source.to_string_lossy(),
                target.to_string_lossy()
            )
        })?;
    }
    Ok(())
}

fn migrate_legacy_task_center_data(app: &AppHandle) -> Result<Vec<String>, String> {
    let source_root = legacy_app_data_dir(app)?;
    let target_root = app
        .path()
        .app_data_dir()
        .map_err(|error| format!("无法定位智能任务中心数据目录: {error}"))?;
    let marker = target_root.join(LEGACY_MIGRATION_MARKER);
    if marker.is_file() || !source_root.is_dir() {
        return Ok(Vec::new());
    }

    fs::create_dir_all(&target_root)
        .map_err(|error| format!("创建智能任务中心数据目录失败: {error}"))?;
    let candidates = [
        ("grok-build", "grok-build"),
        ("task-center", "task-center"),
        ("grok-git-worktrees.json", "grok-git-worktrees.json"),
        ("grok-git-audit.jsonl", "grok-git-audit.jsonl"),
    ];
    let mut migrated_paths = Vec::new();
    for (source_name, target_name) in candidates {
        let source = source_root.join(source_name);
        if !source.exists() {
            continue;
        }
        copy_legacy_tree(&source, &target_root.join(target_name), Path::new(source_name))?;
        migrated_paths.push(source_name.to_string());
    }
    let marker_content = serde_json::to_string_pretty(&serde_json::json!({
        "source": source_root,
        "migratedPaths": migrated_paths,
        "migratedAt": chrono::Utc::now().to_rfc3339(),
    }))
    .map_err(|error| format!("生成迁移记录失败: {error}"))?;
    fs::write(marker, marker_content).map_err(|error| format!("保存迁移记录失败: {error}"))?;
    Ok(migrated_paths)
}

#[tauri::command]
fn load_legacy_task_center_handoff(app: AppHandle) -> Result<LegacyTaskCenterHandoff, String> {
    let handoff_path = legacy_app_data_dir(&app)?.join(LEGACY_HANDOFF_FILE);
    if !handoff_path.is_file() {
        return Ok(LegacyTaskCenterHandoff::default());
    }
    let content = fs::read_to_string(&handoff_path)
        .map_err(|error| format!("读取旧 URGS 任务中心交接数据失败: {error}"))?;
    let mut handoff = serde_json::from_str::<LegacyTaskCenterHandoff>(&content)
        .map_err(|error| format!("解析旧 URGS 任务中心交接数据失败: {error}"))?;
    let marker_path = app
        .path()
        .app_data_dir()
        .map_err(|error| format!("无法定位智能任务中心数据目录: {error}"))?
        .join(LEGACY_MIGRATION_MARKER);
    if let Ok(marker) = fs::read_to_string(marker_path) {
        if let Ok(value) = serde_json::from_str::<serde_json::Value>(&marker) {
            handoff.migrated_paths = value
                .get("migratedPaths")
                .and_then(|paths| paths.as_array())
                .map(|paths| paths.iter().filter_map(|path| path.as_str().map(str::to_string)).collect())
                .unwrap_or_default();
        }
    }
    Ok(handoff)
}

#[tauri::command]
fn desktop_log_read(
    app: AppHandle,
    max_lines: Option<usize>,
) -> Result<desktop_log::DesktopLogSnapshot, String> {
    desktop_log::read_tail(&app, max_lines)
}

#[tauri::command]
fn desktop_log_clear(app: AppHandle) -> Result<desktop_log::DesktopLogSnapshot, String> {
    desktop_log::clear(&app)
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct DesktopLogWriteRequest {
    level: String,
    component: String,
    message: String,
}

#[tauri::command]
fn desktop_log_write(request: DesktopLogWriteRequest) -> Result<(), String> {
    let component = request.component.trim();
    if component.is_empty() || component.len() > 80 {
        return Err("客户端日志组件名无效".to_string());
    }
    let level = match request.level.trim().to_ascii_uppercase().as_str() {
        "DEBUG" => "DEBUG",
        "INFO" => "INFO",
        "WARN" => "WARN",
        "ERROR" => "ERROR",
        _ => return Err("客户端日志级别无效".to_string()),
    };
    let message = request.message.chars().take(16_000).collect::<String>();
    desktop_log::log(level, component, &message);
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    std::panic::set_hook(Box::new(|panic_info| {
        write_startup_log(&format!("Rust panic: {panic_info}"));
    }));
    write_startup_log("JLIntelligentCenter process started.");

    let run_result = tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            show_main_window(app);
        }))
        .plugin(tauri_plugin_deep_link::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .manage(grok_runtime::GrokRuntimeState::default())
        .manage(grok_runtime::TerminalState::default())
        .manage(grok_git::GrokGitWatchState::default())
        .invoke_handler(tauri::generate_handler![
            load_legacy_task_center_handoff,
            desktop_log_read,
            desktop_log_clear,
            desktop_log_write,
            grok_runtime::grok_runtime_status,
            grok_runtime::grok_available_commands,
            grok_runtime::grok_workflow_list,
            grok_runtime::grok_workflow_read,
            grok_runtime::grok_model_catalog,
            grok_runtime::grok_session_search,
            grok_runtime::grok_session_info,
            grok_runtime::grok_compact_session,
            grok_runtime::grok_recap_session,
            grok_runtime::grok_session_rename,
            grok_runtime::grok_session_delete,
            grok_runtime::grok_list_background_tasks,
            grok_runtime::grok_kill_background_task,
            grok_runtime::grok_get_subagent,
            grok_runtime::grok_cancel_subagent,
            grok_runtime::grok_session_update_mcp_servers,
            grok_runtime::grok_mcp_list,
            grok_runtime::grok_mcp_set_enabled,
            grok_runtime::grok_reload_mcp_servers,
            grok_runtime::grok_memory_flush,
            grok_runtime::grok_runtime_diagnostics,
            grok_runtime::grok_runtime_prepare,
            grok_runtime::grok_cli_run,
            grok_runtime::terminal_run_command,
            grok_runtime::terminal_create_session,
            grok_runtime::terminal_write,
            grok_runtime::terminal_resize,
            grok_runtime::terminal_close,
            grok_runtime::grok_cli_service_start,
            grok_runtime::grok_cli_service_list,
            grok_runtime::grok_cli_service_stop,
            grok_runtime::grok_config_read,
            grok_runtime::grok_config_save,
            grok_runtime::grok_skill_set_enabled,
            grok_runtime::grok_skill_remove,
            grok_runtime::grok_compat_mcp_remove,
            grok_runtime::grok_model_apply,
            grok_runtime::grok_model_provider_list,
            grok_runtime::grok_model_provider_authorize,
            grok_runtime::grok_model_provider_save,
            grok_runtime::grok_model_provider_delete,
            grok_runtime::llm_generate_text,
            grok_runtime::grok_create_session,
            grok_runtime::grok_load_session,
            grok_runtime::grok_pick_prompt_attachments,
            grok_runtime::grok_send_prompt,
            grok_runtime::grok_session_set_mode,
            grok_runtime::grok_session_plan,
            grok_runtime::grok_session_fork,
            grok_runtime::grok_queue_action,
            grok_runtime::grok_session_set_model,
            grok_runtime::grok_rewind_points,
            grok_runtime::grok_rewind_files,
            grok_runtime::grok_scheduled_task_delete,
            grok_runtime::grok_cancel,
            grok_runtime::grok_release_session,
            grok_runtime::grok_respond_permission,
            grok_runtime::grok_respond_user_question,
            grok_runtime::grok_respond_plan_approval,
            grok_runtime::grok_runtime_invalidate_prepared,
            grok_runtime::grok_shutdown,
            grok_runtime::grok_start_login,
            grok_git::grok_git_prepare_task,
            grok_git::grok_git_status,
            grok_git::grok_git_watch_start,
            grok_git::grok_git_watch_stop,
            grok_git::grok_git_diff,
            grok_git::grok_git_open_file,
            grok_git::grok_git_reveal_file,
            grok_git::grok_git_add_to_ignore,
            grok_git::grok_git_stage,
            grok_git::grok_git_unstage,
            grok_git::grok_git_stash,
            grok_git::grok_git_discard,
            grok_git::grok_git_commit,
            grok_git::grok_git_fetch,
            grok_git::grok_git_pull,
            grok_git::grok_git_branch_list,
            grok_git::grok_git_branch_switch,
            grok_git::grok_git_sync_base,
            grok_git::grok_git_abort_operation,
            grok_git::grok_git_push,
            grok_git::grok_git_remote_list,
            grok_git::grok_git_worktree_list,
            grok_git::grok_git_worktree_remove,
            grok_git::grok_git_worktree_gc,
            grok_git::grok_git_apply_worktree,
            grok_git::grok_git_audit_list
        ])
        .setup(|app| {
            if let Err(error) = desktop_log::configure(app.handle()) {
                write_startup_log(&format!("Desktop log initialization failed: {error}"));
            }
            write_startup_log("Tauri setup started.");
            match migrate_legacy_task_center_data(app.handle()) {
                Ok(paths) if !paths.is_empty() => write_startup_log(&format!(
                    "Legacy URGS task-center data migrated: {}",
                    paths.join(", ")
                )),
                Ok(_) => {}
                Err(error) => write_startup_log(&format!(
                    "Legacy URGS task-center data migration skipped after error: {error}"
                )),
            }
            let handle = app.handle().clone();
            app.deep_link().on_open_url(move |_| {
                show_main_window(&handle);
                let _ = handle.emit("task-center-handoff-requested", ());
            });
            if let Err(error) = initialize_system_tray(app) {
                write_startup_log(&format!("System tray disabled: {error}"));
            } else {
                write_startup_log("System tray initialized.");
            }
            Ok(())
        })
        .on_window_event(|window, event| {
            if window.label() == "main" {
                if let WindowEvent::CloseRequested { api, .. } = event {
                    desktop_log::info("window", "Main window close requested; hiding instead.");
                    api.prevent_close();
                    let _ = window.hide();
                }
            }
        })
        .run(tauri::generate_context!());

    if let Err(error) = run_result {
        write_startup_log(&format!("Tauri runtime exited with an error: {error}"));
    }
}
