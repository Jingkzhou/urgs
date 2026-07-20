mod grok_runtime;

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};
use url::Url;

const CONFIG_FILE_NAME: &str = "desktop-config.json";

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
struct DesktopRuntimeConfig {
    vite_api_url: String,
    vite_ws_url: String,
}

fn config_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_config_dir()
        .map(|directory| directory.join(CONFIG_FILE_NAME))
        .map_err(|error| format!("无法定位客户端配置目录: {error}"))
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

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .manage(grok_runtime::GrokRuntimeState::default())
        .invoke_handler(tauri::generate_handler![
            load_desktop_runtime_config,
            save_desktop_runtime_config,
            grok_runtime::grok_runtime_status,
            grok_runtime::grok_available_commands,
            grok_runtime::grok_runtime_prepare,
            grok_runtime::grok_cli_run,
            grok_runtime::grok_cli_service_start,
            grok_runtime::grok_cli_service_list,
            grok_runtime::grok_cli_service_stop,
            grok_runtime::grok_config_read,
            grok_runtime::grok_config_save,
            grok_runtime::grok_model_apply,
            grok_runtime::grok_model_provider_list,
            grok_runtime::grok_model_provider_authorize,
            grok_runtime::grok_model_provider_save,
            grok_runtime::grok_model_provider_delete,
            grok_runtime::grok_create_session,
            grok_runtime::grok_load_session,
            grok_runtime::grok_send_prompt,
            grok_runtime::grok_session_set_model,
            grok_runtime::grok_cancel,
            grok_runtime::grok_respond_permission,
            grok_runtime::grok_shutdown,
            grok_runtime::grok_start_login
        ])
        .run(tauri::generate_context!())
        .expect("error while running URGS desktop application");
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
