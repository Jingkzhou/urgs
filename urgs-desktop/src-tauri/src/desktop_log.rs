use chrono::Local;
use serde::Serialize;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};
use tauri::{AppHandle, Manager};

const LOG_DIRECTORY_NAME: &str = "logs";
const LOG_FILE_NAME: &str = "desktop.log";
const LOG_BACKUP_FILE_NAME: &str = "desktop.log.1";
const MAX_LOG_BYTES: u64 = 5 * 1024 * 1024;
const DEFAULT_TAIL_LINES: usize = 200;
const MAX_TAIL_LINES: usize = 1000;

static LOG_PATH: OnceLock<Mutex<Option<PathBuf>>> = OnceLock::new();
static LOG_WRITE_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub(crate) struct DesktopLogSnapshot {
    pub path: String,
    pub lines: Vec<String>,
}

fn configured_path() -> &'static Mutex<Option<PathBuf>> {
    LOG_PATH.get_or_init(|| Mutex::new(None))
}

fn write_lock() -> &'static Mutex<()> {
    LOG_WRITE_LOCK.get_or_init(|| Mutex::new(()))
}

fn fallback_log_path() -> Option<PathBuf> {
    if let Some(local_app_data) = std::env::var_os("LOCALAPPDATA") {
        return Some(
            PathBuf::from(local_app_data)
                .join("URGS")
                .join(LOG_DIRECTORY_NAME)
                .join(LOG_FILE_NAME),
        );
    }

    let home = std::env::var_os("HOME")?;
    let base = if cfg!(target_os = "macos") {
        PathBuf::from(home)
            .join("Library")
            .join("Logs")
            .join("URGS")
    } else {
        PathBuf::from(home)
            .join(".local")
            .join("share")
            .join("URGS")
    };
    Some(base.join(LOG_DIRECTORY_NAME).join(LOG_FILE_NAME))
}

fn app_log_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_data_dir()
        .map(|directory| directory.join(LOG_DIRECTORY_NAME).join(LOG_FILE_NAME))
        .map_err(|error| format!("无法定位客户端日志目录: {error}"))
}

pub(crate) fn configure(app: &AppHandle) -> Result<PathBuf, String> {
    let path = app_log_path(app)?;
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|error| format!("创建客户端日志目录失败: {error}"))?;
    }
    *configured_path()
        .lock()
        .map_err(|_| "客户端日志路径锁不可用".to_string())? = Some(path.clone());
    Ok(path)
}

fn current_log_path() -> Option<PathBuf> {
    configured_path()
        .lock()
        .ok()
        .and_then(|path| path.clone())
        .or_else(fallback_log_path)
}

fn timestamp() -> String {
    Local::now().format("%Y-%m-%d %H:%M:%S%.3f %:z").to_string()
}

fn strip_ansi_codes(message: &str) -> String {
    let mut result = String::with_capacity(message.len());
    let mut characters = message.chars();
    while let Some(character) = characters.next() {
        if character != '\u{1b}' {
            result.push(character);
            continue;
        }
        if characters.next() != Some('[') {
            continue;
        }
        for character in characters.by_ref() {
            if character.is_ascii_alphabetic() {
                break;
            }
        }
    }
    result
}

fn redact_message(message: &str) -> String {
    let mut result = strip_ansi_codes(message)
        .replace('\r', "")
        .replace('\n', "\\n");
    for prefix in ["Bearer ", "bearer "] {
        let mut search_from = 0;
        while let Some(relative_start) = result[search_from..].find(prefix) {
            let start = search_from + relative_start;
            let value_start = start + prefix.len();
            let end = result[value_start..]
                .find(|character: char| {
                    character.is_whitespace() || matches!(character, '\\' | ',' | ';')
                })
                .map(|offset| value_start + offset)
                .unwrap_or(result.len());
            result.replace_range(value_start..end, "[REDACTED]");
            search_from = value_start + "[REDACTED]".len();
        }
    }
    for key in [
        "api_key",
        "apikey",
        "api-key",
        "access_token",
        "accesstoken",
        "authorization",
        "x-api-key",
    ] {
        let mut search_from = 0;
        loop {
            let lowercase = result.to_ascii_lowercase();
            let Some(relative_start) = lowercase[search_from..].find(key) else {
                break;
            };
            let start = search_from + relative_start;
            let mut value_start = start + key.len();
            while value_start < result.len()
                && matches!(
                    result.as_bytes()[value_start],
                    b' ' | b'\t' | b'\n' | b'\"' | b'\'' | b':' | b'='
                )
            {
                value_start += 1;
            }
            if key == "authorization"
                && result[value_start..]
                    .to_ascii_lowercase()
                    .starts_with("bearer ")
            {
                value_start += "bearer ".len();
            }
            let end = result[value_start..]
                .find(|character: char| {
                    character.is_whitespace()
                        || matches!(character, '\\' | '"' | '\'' | ',' | ';' | '}')
                })
                .map(|offset| value_start + offset)
                .unwrap_or(result.len());
            if value_start < end {
                result.replace_range(value_start..end, "[REDACTED]");
                search_from = value_start + "[REDACTED]".len();
            } else {
                search_from = start + key.len();
            }
        }
    }
    result
}

fn append_line(path: &PathBuf, line: &str) {
    let Some(parent) = path.parent() else {
        return;
    };
    if fs::create_dir_all(parent).is_err() {
        return;
    }

    let _guard = write_lock().lock().ok();
    if fs::metadata(path)
        .map(|metadata| metadata.len() >= MAX_LOG_BYTES)
        .unwrap_or(false)
    {
        let backup = parent.join(LOG_BACKUP_FILE_NAME);
        let _ = fs::remove_file(&backup);
        let _ = fs::rename(path, backup);
    }
    if let Ok(mut file) = OpenOptions::new().create(true).append(true).open(path) {
        let _ = writeln!(file, "{line}");
    }
}

pub(crate) fn log(level: &str, component: &str, message: &str) {
    let Some(path) = current_log_path() else {
        return;
    };
    let line = format!(
        "[{}] [{}] [{}] {}",
        timestamp(),
        level,
        component,
        redact_message(message)
    );
    append_line(&path, &line);
}

pub(crate) fn info(component: &str, message: &str) {
    log("INFO", component, message);
}

pub(crate) fn error(component: &str, message: &str) {
    log("ERROR", component, message);
}

pub(crate) fn read_tail(
    app: &AppHandle,
    requested_lines: Option<usize>,
) -> Result<DesktopLogSnapshot, String> {
    let path = configure(app)?;
    let line_limit = requested_lines
        .unwrap_or(DEFAULT_TAIL_LINES)
        .clamp(1, MAX_TAIL_LINES);
    let content = match fs::read_to_string(&path) {
        Ok(content) => content,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => String::new(),
        Err(error) => return Err(format!("读取客户端日志失败: {error}")),
    };
    let mut lines = content
        .lines()
        .rev()
        .take(line_limit)
        .map(str::to_string)
        .collect::<Vec<_>>();
    lines.reverse();
    Ok(DesktopLogSnapshot {
        path: path.to_string_lossy().to_string(),
        lines,
    })
}

fn clear_path(path: &Path) -> Result<(), String> {
    let parent = path
        .parent()
        .ok_or_else(|| "客户端日志目录无效".to_string())?;
    fs::create_dir_all(parent).map_err(|error| format!("创建客户端日志目录失败: {error}"))?;
    let _guard = write_lock()
        .lock()
        .map_err(|_| "客户端日志写入锁不可用".to_string())?;
    let backup = parent.join(LOG_BACKUP_FILE_NAME);
    match fs::remove_file(&backup) {
        Ok(()) => {}
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
        Err(error) => return Err(format!("清理客户端历史日志失败: {error}")),
    }
    OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(path)
        .map_err(|error| format!("清空客户端日志失败: {error}"))?;
    Ok(())
}

pub(crate) fn clear(app: &AppHandle) -> Result<DesktopLogSnapshot, String> {
    let path = configure(app)?;
    clear_path(&path)?;
    Ok(DesktopLogSnapshot {
        path: path.to_string_lossy().to_string(),
        lines: Vec::new(),
    })
}

#[cfg(test)]
mod tests {
    use super::{clear_path, redact_message, timestamp, LOG_BACKUP_FILE_NAME};
    use std::fs;
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn timestamp_contains_local_date_time_milliseconds_and_offset() {
        let value = timestamp();

        assert_eq!(value.len(), 30);
        assert_eq!(&value[4..5], "-");
        assert_eq!(&value[7..8], "-");
        assert_eq!(&value[10..11], " ");
        assert_eq!(&value[19..20], ".");
        assert_eq!(&value[23..24], " ");
        assert!(matches!(&value[24..25], "+" | "-"));
        assert_eq!(&value[27..28], ":");
    }

    #[test]
    fn clear_path_truncates_current_log_and_removes_backup() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos();
        let directory = std::env::temp_dir().join(format!(
            "urgs-desktop-log-clear-{}-{unique}",
            std::process::id()
        ));
        let path = directory.join("desktop.log");
        let backup = directory.join(LOG_BACKUP_FILE_NAME);
        fs::create_dir_all(&directory).expect("create temp log directory");
        fs::write(&path, "current log").expect("write current log");
        fs::write(&backup, "backup log").expect("write backup log");

        clear_path(&path).expect("clear desktop logs");

        assert_eq!(fs::read_to_string(&path).expect("read current log"), "");
        assert!(!backup.exists());
        fs::remove_dir_all(directory).expect("remove temp log directory");
    }

    #[test]
    fn redacts_common_credentials_and_flattens_multiline_messages() {
        let message =
            "\u{1b}[31mAuthorization: Bearer secret-token apiKey=secret-key\nnext\u{1b}[0m";
        let redacted = redact_message(message);

        assert_eq!(
            redacted,
            "Authorization: Bearer [REDACTED] apiKey=[REDACTED]\\nnext"
        );
    }
}
