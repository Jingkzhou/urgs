use serde::{Deserialize, Serialize};
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};
use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Manager, WindowEvent,
};
use url::Url;

const CONFIG_FILE_NAME: &str = "desktop-config.json";
const PREFERENCES_FILE_NAME: &str = "desktop-preferences.json";
const SHOW_MAIN_WINDOW_MENU_ID: &str = "show-main-window";
const QUIT_APPLICATION_MENU_ID: &str = "quit-application";
const STARTUP_LOG_FILE_NAME: &str = "startup.log";

fn write_startup_log(message: &str) {
    let Ok(local_app_data) = std::env::var("LOCALAPPDATA") else {
        return;
    };
    let path = PathBuf::from(local_app_data)
        .join("URGS")
        .join("logs")
        .join(STARTUP_LOG_FILE_NAME);
    let Some(parent) = path.parent() else {
        return;
    };
    if fs::create_dir_all(parent).is_err() {
        return;
    }

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or_default();
    if let Ok(mut file) = fs::OpenOptions::new().create(true).append(true).open(path) {
        let _ = writeln!(file, "[{timestamp}] {message}");
    }
}

fn show_main_window(app: &AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.unminimize();
        let _ = window.show();
        let _ = window.set_focus();
    }
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

    TrayIconBuilder::with_id("urgs-tray")
        .icon(tray_icon)
        .tooltip("监管报送一体化系统")
        .menu(&tray_menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app, event| match event.id.as_ref() {
            SHOW_MAIN_WINDOW_MENU_ID => show_main_window(app),
            QUIT_APPLICATION_MENU_ID => app.exit(0),
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

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
struct DesktopRuntimeConfig {
    vite_api_url: String,
    vite_ws_url: String,
}

#[derive(Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
struct DesktopPreferences {
    auto_start_enabled: Option<bool>,
}

fn config_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_config_dir()
        .map(|directory| directory.join(CONFIG_FILE_NAME))
        .map_err(|error| format!("无法定位客户端配置目录: {error}"))
}

fn preferences_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_config_dir()
        .map(|directory| directory.join(PREFERENCES_FILE_NAME))
        .map_err(|error| format!("无法定位客户端偏好目录: {error}"))
}

fn validate_url(value: &str, allowed_schemes: &[&str], field_name: &str) -> Result<String, String> {
    let normalized = value.trim().trim_end_matches('/').to_string();
    let parsed = Url::parse(&normalized).map_err(|_| format!("{field_name}格式不正确"))?;

    if !allowed_schemes.contains(&parsed.scheme()) {
        return Err(format!(
            "{field_name}仅支持{}协议",
            allowed_schemes.join("/")
        ));
    }

    if parsed.host_str().is_none() {
        return Err(format!("{field_name}缺少服务器地址"));
    }

    Ok(normalized)
}

fn validate_config(config: DesktopRuntimeConfig) -> Result<DesktopRuntimeConfig, String> {
    Ok(DesktopRuntimeConfig {
        vite_api_url: validate_url(&config.vite_api_url, &["http", "https"], "API 服务地址")?,
        vite_ws_url: validate_url(&config.vite_ws_url, &["ws", "wss"], "WebSocket 地址")?,
    })
}

#[tauri::command]
fn load_desktop_runtime_config(app: AppHandle) -> Result<Option<DesktopRuntimeConfig>, String> {
    let path = config_path(&app)?;
    if !path.exists() {
        return Ok(None);
    }

    let content =
        fs::read_to_string(path).map_err(|error| format!("读取客户端配置失败: {error}"))?;
    let config = serde_json::from_str::<DesktopRuntimeConfig>(&content)
        .map_err(|error| format!("解析客户端配置失败: {error}"))?;
    validate_config(config).map(Some)
}

#[tauri::command]
fn save_desktop_runtime_config(
    app: AppHandle,
    config: DesktopRuntimeConfig,
) -> Result<DesktopRuntimeConfig, String> {
    let config = validate_config(config)?;
    let path = config_path(&app)?;
    let directory = path
        .parent()
        .ok_or_else(|| "客户端配置目录无效".to_string())?;

    fs::create_dir_all(directory).map_err(|error| format!("创建客户端配置目录失败: {error}"))?;
    let content = serde_json::to_string_pretty(&config)
        .map_err(|error| format!("序列化客户端配置失败: {error}"))?;
    fs::write(path, content).map_err(|error| format!("保存客户端配置失败: {error}"))?;
    Ok(config)
}

fn load_desktop_preferences(app: &AppHandle) -> Result<DesktopPreferences, String> {
    let path = preferences_path(app)?;
    if !path.exists() {
        return Ok(DesktopPreferences::default());
    }

    let content =
        fs::read_to_string(path).map_err(|error| format!("读取客户端偏好失败: {error}"))?;
    serde_json::from_str(&content).map_err(|error| format!("解析客户端偏好失败: {error}"))
}

fn save_desktop_preferences(
    app: &AppHandle,
    preferences: &DesktopPreferences,
) -> Result<(), String> {
    let path = preferences_path(app)?;
    let directory = path
        .parent()
        .ok_or_else(|| "客户端偏好目录无效".to_string())?;

    fs::create_dir_all(directory).map_err(|error| format!("创建客户端偏好目录失败: {error}"))?;
    let content = serde_json::to_string_pretty(preferences)
        .map_err(|error| format!("序列化客户端偏好失败: {error}"))?;
    fs::write(path, content).map_err(|error| format!("保存客户端偏好失败: {error}"))
}

#[tauri::command]
fn load_desktop_auto_start_enabled(app: AppHandle) -> Result<Option<bool>, String> {
    Ok(load_desktop_preferences(&app)?.auto_start_enabled)
}

#[tauri::command]
fn save_desktop_auto_start_enabled(app: AppHandle, enabled: bool) -> Result<bool, String> {
    let mut preferences = load_desktop_preferences(&app)?;
    preferences.auto_start_enabled = Some(enabled);
    save_desktop_preferences(&app, &preferences)?;
    Ok(enabled)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    std::panic::set_hook(Box::new(|panic_info| {
        write_startup_log(&format!("Rust panic: {panic_info}"));
    }));
    write_startup_log("URGS desktop process started.");

    let run_result = tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            None,
        ))
        .invoke_handler(tauri::generate_handler![
            load_desktop_runtime_config,
            save_desktop_runtime_config,
            load_desktop_auto_start_enabled,
            save_desktop_auto_start_enabled
        ])
        .setup(|app| {
            write_startup_log("Tauri setup started.");
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

#[cfg(test)]
mod tests {
    use super::{validate_config, DesktopRuntimeConfig};

    fn config(api_url: &str, ws_url: &str) -> DesktopRuntimeConfig {
        DesktopRuntimeConfig {
            vite_api_url: api_url.to_string(),
            vite_ws_url: ws_url.to_string(),
        }
    }

    #[test]
    fn accepts_supported_service_urls_and_normalizes_trailing_slashes() {
        let validated = validate_config(config(
            "https://urgs.example.com/",
            "wss://urgs.example.com/ws/im/",
        ))
        .expect("valid desktop config");

        assert_eq!(validated.vite_api_url, "https://urgs.example.com");
        assert_eq!(validated.vite_ws_url, "wss://urgs.example.com/ws/im");
    }

    #[test]
    fn rejects_unsupported_or_incomplete_urls() {
        assert!(
            validate_config(config("file:///tmp/urgs", "wss://urgs.example.com/ws/im",)).is_err()
        );
        assert!(validate_config(config(
            "https://urgs.example.com",
            "https://urgs.example.com/ws/im",
        ))
        .is_err());
    }
}
