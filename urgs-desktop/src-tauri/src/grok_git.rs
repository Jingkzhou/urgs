use serde::{Deserialize, Serialize};
use std::collections::hash_map::DefaultHasher;
use std::fs::{self, OpenOptions};
use std::hash::{Hash, Hasher};
use std::io::{Read, Write};
#[cfg(windows)]
use std::os::windows::process::CommandExt;
use std::path::{Component, Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use tauri::{AppHandle, Manager};
use tauri_plugin_opener::OpenerExt;

const WORKTREE_RECORDS_FILE: &str = "grok-git-worktrees.json";
const AUDIT_FILE: &str = "grok-git-audit.jsonl";
const MAX_COMMAND_OUTPUT: usize = 2_000_000;
const MAX_DIFF_OUTPUT: usize = 500_000;
const LOCAL_GIT_TIMEOUT: Duration = Duration::from_secs(30);
const LONG_GIT_TIMEOUT: Duration = Duration::from_secs(120);
const GIT_WAIT_POLL_INTERVAL: Duration = Duration::from_millis(25);
const SLOW_GIT_COMMAND_THRESHOLD: Duration = Duration::from_millis(500);

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitFile {
    pub path: String,
    pub index_status: String,
    pub worktree_status: String,
    pub additions: u32,
    pub deletions: u32,
    pub staged: bool,
    pub modified: bool,
    pub untracked: bool,
    pub conflicted: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitStatus {
    pub repo_root: String,
    pub workspace_path: String,
    pub is_repository: bool,
    pub branch: Option<String>,
    pub upstream: Option<String>,
    pub ahead: u32,
    pub behind: u32,
    pub head_commit: Option<String>,
    pub is_dirty: bool,
    pub is_detached: bool,
    pub staged_count: u32,
    pub modified_count: u32,
    pub untracked_count: u32,
    pub conflict_count: u32,
    pub additions: u32,
    pub deletions: u32,
    pub files: Vec<GrokGitFile>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitTaskWorkspace {
    pub task_id: String,
    pub mode: String,
    pub repo_root: String,
    pub workspace_path: String,
    pub worktree_id: Option<String>,
    pub branch: Option<String>,
    pub base_ref: Option<String>,
    pub base_commit: Option<String>,
    pub head_commit: Option<String>,
    pub status: GrokGitStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitDiff {
    pub workspace_path: String,
    pub path: Option<String>,
    pub staged: bool,
    pub patch: String,
    pub truncated: bool,
    pub files: Vec<GrokGitFile>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitMutationResult {
    pub success: bool,
    pub operation: String,
    pub message: String,
    pub output: Option<String>,
    pub audit_id: String,
    pub status: GrokGitStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitWorktree {
    pub path: String,
    pub head_commit: Option<String>,
    pub branch: Option<String>,
    pub detached: bool,
    pub locked: bool,
    pub prunable: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitRemote {
    pub name: String,
    pub fetch_url: Option<String>,
    pub push_url: Option<String>,
    pub provider: String,
    pub host: Option<String>,
    pub repository: Option<String>,
    pub web_url: Option<String>,
    pub capabilities: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitAuditEntry {
    pub id: String,
    pub task_id: Option<String>,
    pub operation: String,
    pub workspace: String,
    pub target: Option<String>,
    pub summary: String,
    pub success: bool,
    pub created_at: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GrokGitApplyResult {
    pub success: bool,
    pub message: String,
    pub conflict_paths: Vec<String>,
    pub audit_id: String,
    pub source_status: GrokGitStatus,
    pub target_status: GrokGitStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct WorktreeRecord {
    task_id: String,
    #[serde(default = "default_worktree_mode")]
    mode: String,
    repo_root: String,
    worktree_path: String,
    branch: String,
    base_ref: String,
    created_at: u64,
}

fn default_worktree_mode() -> String {
    "worktree".to_string()
}

#[derive(Debug, Clone)]
struct CommandResult {
    stdout: String,
    stderr: String,
    success: bool,
}

#[derive(Debug)]
struct RawCommandResult {
    stdout: Vec<u8>,
    stderr: Vec<u8>,
    status: ExitStatus,
}

fn new_git_command(workspace: &Path) -> Command {
    let mut command = Command::new("git");
    command
        .arg("-C")
        .arg(workspace)
        .env("GIT_TERMINAL_PROMPT", "0")
        .env("GCM_INTERACTIVE", "Never")
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    #[cfg(windows)]
    command.creation_flags(0x08000000);
    command
}

fn git_command_timeout(args: &[String]) -> Duration {
    if args.iter().any(|argument| {
        matches!(
            argument.as_str(),
            "fetch" | "push" | "rebase" | "merge" | "worktree" | "stash" | "commit"
        )
    }) {
        LONG_GIT_TIMEOUT
    } else {
        LOCAL_GIT_TIMEOUT
    }
}

fn git_command_name(args: &[String]) -> &str {
    args.iter()
        .find(|argument| {
            matches!(
                argument.as_str(),
                "add"
                    | "check-ignore"
                    | "commit"
                    | "diff"
                    | "fetch"
                    | "merge"
                    | "push"
                    | "rebase"
                    | "remote"
                    | "reset"
                    | "rev-parse"
                    | "show"
                    | "stash"
                    | "status"
                    | "symbolic-ref"
                    | "worktree"
            )
        })
        .map(String::as_str)
        .unwrap_or("command")
}

fn read_process_output(
    stream: Option<impl Read + Send + 'static>,
) -> thread::JoinHandle<Result<Vec<u8>, String>> {
    thread::spawn(move || {
        let mut bytes = Vec::new();
        if let Some(mut stream) = stream {
            stream
                .read_to_end(&mut bytes)
                .map_err(|error| format!("读取 Git 进程输出失败: {error}"))?;
        }
        Ok(bytes)
    })
}

fn join_process_output(
    reader: thread::JoinHandle<Result<Vec<u8>, String>>,
) -> Result<Vec<u8>, String> {
    reader
        .join()
        .map_err(|_| "读取 Git 进程输出的线程异常退出".to_string())?
}

fn terminate_git_process(child: &mut std::process::Child) {
    #[cfg(windows)]
    {
        let pid = child.id().to_string();
        let mut taskkill = Command::new("taskkill");
        taskkill
            .args(["/PID", pid.as_str(), "/T", "/F"])
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .creation_flags(0x08000000);
        let _ = taskkill.status();
    }
    let _ = child.kill();
    let _ = child.wait();
}

fn wait_for_git_process(
    child: &mut std::process::Child,
    args: &[String],
    timeout: Duration,
) -> Result<ExitStatus, String> {
    let started_at = Instant::now();
    loop {
        match child.try_wait() {
            Ok(Some(status)) => return Ok(status),
            Ok(None) if started_at.elapsed() < timeout => thread::sleep(GIT_WAIT_POLL_INTERVAL),
            Ok(None) => {
                terminate_git_process(child);
                return Err(format!(
                    "git {} 执行超时（{} 秒），已终止进程",
                    git_command_name(args),
                    timeout.as_secs()
                ));
            }
            Err(error) => {
                terminate_git_process(child);
                return Err(format!(
                    "等待 git {} 执行失败: {error}",
                    git_command_name(args)
                ));
            }
        }
    }
}

fn execute_git_raw(workspace: &Path, args: &[String]) -> Result<RawCommandResult, String> {
    let timeout = git_command_timeout(args);
    let started_at = Instant::now();
    let mut child = new_git_command(workspace)
        .args(args)
        .spawn()
        .map_err(|error| format!("无法启动 git，请确认已安装 Git: {error}"))?;
    let stdout_reader = read_process_output(child.stdout.take());
    let stderr_reader = read_process_output(child.stderr.take());
    let status_result = wait_for_git_process(&mut child, args, timeout);
    let stdout = join_process_output(stdout_reader)?;
    let stderr = join_process_output(stderr_reader)?;
    let status = status_result?;
    let elapsed = started_at.elapsed();
    if elapsed >= SLOW_GIT_COMMAND_THRESHOLD {
        eprintln!(
            "[urgs-git] slow command: git {} took {} ms",
            git_command_name(args),
            elapsed.as_millis()
        );
    }
    Ok(RawCommandResult {
        stdout,
        stderr,
        status,
    })
}

fn execute_git(workspace: &Path, args: &[String]) -> Result<CommandResult, String> {
    let output = execute_git_raw(workspace, args)?;
    let (stdout, _) = trim_output(
        String::from_utf8_lossy(&output.stdout).to_string(),
        MAX_COMMAND_OUTPUT,
    );
    let (stderr, _) = trim_output(
        String::from_utf8_lossy(&output.stderr).to_string(),
        MAX_COMMAND_OUTPUT,
    );
    Ok(CommandResult {
        stdout,
        stderr,
        success: output.status.success(),
    })
}

fn now_millis() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis() as u64)
        .unwrap_or_default()
}

fn trim_output(value: String, limit: usize) -> (String, bool) {
    if value.len() <= limit {
        return (value, false);
    }
    let mut end = limit;
    while end > 0 && !value.is_char_boundary(end) {
        end -= 1;
    }
    (format!("{}\n\n[输出已截断]", &value[..end]), true)
}

fn command_error(args: &[String], result: &CommandResult) -> String {
    let detail = result.stderr.trim();
    if detail.is_empty() {
        format!("git {} 执行失败", args.join(" "))
    } else {
        format!("git {} 执行失败: {detail}", args.join(" "))
    }
}

fn run_git(workspace: &Path, args: &[String]) -> Result<CommandResult, String> {
    let result = execute_git(workspace, args)?;
    if !result.success {
        return Err(command_error(args, &result));
    }
    Ok(result)
}

fn run_git_allow_failure(workspace: &Path, args: &[String]) -> Result<CommandResult, String> {
    execute_git(workspace, args)
}

fn canonical_directory(value: &str) -> Result<PathBuf, String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return Err("工作区路径不能为空".to_string());
    }
    let path = PathBuf::from(trimmed);
    if !path.exists() {
        return Err(format!("工作区不存在: {trimmed}"));
    }
    if !path.is_dir() {
        return Err(format!("工作区不是目录: {trimmed}"));
    }
    fs::canonicalize(&path).map_err(|error| format!("无法解析工作区路径: {error}"))
}

fn git_root(workspace: &Path) -> Result<PathBuf, String> {
    let args = vec!["rev-parse".to_string(), "--show-toplevel".to_string()];
    let result = run_git(workspace, &args)?;
    canonical_directory(result.stdout.trim())
}

fn is_not_git_repository_error(message: &str) -> bool {
    let normalized = message.to_ascii_lowercase();
    normalized.contains("not a git repository")
        || message.contains("不是 git 仓库")
        || message.contains("不是一个 git 仓库")
}

fn is_git_unavailable_error(message: &str) -> bool {
    let normalized = message.to_ascii_lowercase();
    message.contains("无法启动 git")
        || normalized.contains("program not found")
        || normalized.contains("executable file not found")
        || normalized.contains("os error 2")
        || message.contains("系统找不到指定的文件")
}

fn non_repository_status(workspace: &Path) -> GrokGitStatus {
    let workspace_path = workspace.to_string_lossy().to_string();
    GrokGitStatus {
        repo_root: workspace_path.clone(),
        workspace_path,
        is_repository: false,
        branch: None,
        upstream: None,
        ahead: 0,
        behind: 0,
        head_commit: None,
        is_dirty: false,
        is_detached: false,
        staged_count: 0,
        modified_count: 0,
        untracked_count: 0,
        conflict_count: 0,
        additions: 0,
        deletions: 0,
        files: Vec::new(),
    }
}

fn git_common_root(workspace: &Path) -> Result<PathBuf, String> {
    let args = vec![
        "rev-parse".to_string(),
        "--path-format=absolute".to_string(),
        "--git-common-dir".to_string(),
    ];
    let result = run_git(workspace, &args)?;
    let common_dir = PathBuf::from(result.stdout.trim());
    if common_dir.file_name().and_then(|item| item.to_str()) == Some(".git") {
        return common_dir
            .parent()
            .map(Path::to_path_buf)
            .ok_or_else(|| "无法定位 Git 仓库根目录".to_string());
    }
    git_root(workspace)
}

fn git_head(workspace: &Path) -> Option<String> {
    let args = vec!["rev-parse".to_string(), "HEAD".to_string()];
    run_git_allow_failure(workspace, &args)
        .ok()
        .filter(|result| result.stderr.trim().is_empty())
        .map(|result| result.stdout.trim().to_string())
        .filter(|value| !value.is_empty())
}

fn branch_name(workspace: &Path) -> Option<String> {
    let args = vec![
        "symbolic-ref".to_string(),
        "--quiet".to_string(),
        "--short".to_string(),
        "HEAD".to_string(),
    ];
    run_git_allow_failure(workspace, &args)
        .ok()
        .map(|result| result.stdout.trim().to_string())
        .filter(|value| !value.is_empty())
}

fn relative_path(value: &str) -> Result<String, String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return Err("文件路径不能为空".to_string());
    }
    let path = Path::new(trimmed);
    if path.is_absolute() {
        return Err("Git 文件操作只允许仓库内相对路径".to_string());
    }
    if path.components().any(|component| {
        matches!(
            component,
            Component::ParentDir | Component::RootDir | Component::Prefix(_)
        )
    }) {
        return Err("Git 文件路径不能越过工作区根目录".to_string());
    }
    Ok(trimmed.replace('\\', "/"))
}

fn parse_tracking(value: &str) -> (Option<String>, u32, u32) {
    let Some((branch, tracking)) = value.split_once("...") else {
        return (None, 0, 0);
    };
    let tracking = tracking
        .split_whitespace()
        .next()
        .unwrap_or(tracking)
        .to_string();
    let detail = value
        .split_once('[')
        .and_then(|(_, value)| value.split_once(']'))
        .map(|(value, _)| value)
        .unwrap_or_default();
    let mut ahead = 0;
    let mut behind = 0;
    for item in detail.split(',') {
        let item = item.trim();
        if let Some(value) = item.strip_prefix("ahead ") {
            ahead = value.trim().parse().unwrap_or_default();
        }
        if let Some(value) = item.strip_prefix("behind ") {
            behind = value.trim().parse().unwrap_or_default();
        }
    }
    (Some(format!("{branch}...{tracking}")), ahead, behind)
}

fn parse_numstat(workspace: &Path) -> std::collections::HashMap<String, (u32, u32)> {
    let args = vec![
        "diff".to_string(),
        "--no-ext-diff".to_string(),
        "--numstat".to_string(),
        "HEAD".to_string(),
        "--".to_string(),
    ];
    let Ok(result) = run_git_allow_failure(workspace, &args) else {
        return std::collections::HashMap::new();
    };
    result
        .stdout
        .lines()
        .filter_map(|line| {
            let mut fields = line.split('\t');
            let additions = fields.next()?.parse::<u32>().ok()?;
            let deletions = fields.next()?.parse::<u32>().ok()?;
            let path = fields.collect::<Vec<_>>().join("\t");
            if path.is_empty() {
                None
            } else {
                Some((path, (additions, deletions)))
            }
        })
        .collect()
}

fn git_status_at_with_stats(
    workspace: &Path,
    include_stats: bool,
) -> Result<GrokGitStatus, String> {
    let workspace =
        fs::canonicalize(workspace).map_err(|error| format!("无法解析 Git 工作区: {error}"))?;
    let repo_root = git_common_root(&workspace)?;
    let args = vec![
        "-c".to_string(),
        "color.ui=false".to_string(),
        "status".to_string(),
        "--porcelain=v1".to_string(),
        "-b".to_string(),
    ];
    let result = run_git(&workspace, &args)?;
    let mut branch = None;
    let mut upstream = None;
    let mut ahead = 0;
    let mut behind = 0;
    let numstat = if include_stats {
        parse_numstat(&workspace)
    } else {
        std::collections::HashMap::new()
    };
    let mut files = Vec::new();

    for line in result.stdout.lines() {
        if let Some(header) = line.strip_prefix("## ") {
            if header.contains("...") {
                let (tracking, next_ahead, next_behind) = parse_tracking(header);
                upstream = tracking;
                ahead = next_ahead;
                behind = next_behind;
                branch = header.split_once("...").map(|(value, _)| value.to_string());
            } else {
                branch = Some(header.to_string());
            }
            continue;
        }
        if line.len() < 3 {
            continue;
        }
        let index_status = line[0..1].to_string();
        let worktree_status = line[1..2].to_string();
        let mut path = line[3..].to_string();
        if let Some((_, renamed)) = path.rsplit_once(" -> ") {
            path = renamed.to_string();
        }
        let is_untracked = index_status == "?" && worktree_status == "?";
        let is_conflicted = matches!(
            format!("{index_status}{worktree_status}").as_str(),
            "DD" | "AU" | "UD" | "UA" | "DU" | "AA" | "UU"
        ) || index_status == "U"
            || worktree_status == "U";
        let staged = index_status != " " && index_status != "?";
        let modified = worktree_status != " " && worktree_status != "?";
        let (additions, deletions) = numstat.get(&path).copied().unwrap_or_default();
        files.push(GrokGitFile {
            path,
            index_status,
            worktree_status,
            additions,
            deletions,
            staged,
            modified,
            untracked: is_untracked,
            conflicted: is_conflicted,
        });
    }

    let staged_count = files.iter().filter(|file| file.staged).count() as u32;
    let modified_count = files
        .iter()
        .filter(|file| file.modified && !file.untracked)
        .count() as u32;
    let untracked_count = files.iter().filter(|file| file.untracked).count() as u32;
    let conflict_count = files.iter().filter(|file| file.conflicted).count() as u32;
    let additions = files.iter().map(|file| file.additions).sum();
    let deletions = files.iter().map(|file| file.deletions).sum();
    Ok(GrokGitStatus {
        repo_root: repo_root.to_string_lossy().to_string(),
        workspace_path: workspace.to_string_lossy().to_string(),
        is_repository: true,
        branch: branch.clone(),
        upstream,
        ahead,
        behind,
        head_commit: git_head(&workspace),
        is_dirty: !files.is_empty(),
        is_detached: branch.is_none(),
        staged_count,
        modified_count,
        untracked_count,
        conflict_count,
        additions,
        deletions,
        files,
    })
}

fn git_status_at(workspace: &Path) -> Result<GrokGitStatus, String> {
    git_status_at_with_stats(workspace, true)
}

fn repo_hash(repo_root: &Path) -> String {
    let mut hasher = DefaultHasher::new();
    repo_root.to_string_lossy().hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

fn safe_segment(value: &str, fallback: &str) -> String {
    let result: String = value
        .chars()
        .map(|character| {
            if character.is_ascii_alphanumeric() || character == '-' || character == '_' {
                character
            } else {
                '-'
            }
        })
        .take(64)
        .collect();
    if result.is_empty() {
        fallback.to_string()
    } else {
        result
    }
}

fn records_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_data_dir()
        .map(|directory| directory.join(WORKTREE_RECORDS_FILE))
        .map_err(|error| format!("无法定位 Worktree 记录目录: {error}"))
}

fn load_records(app: &AppHandle) -> Result<Vec<WorktreeRecord>, String> {
    let path = records_path(app)?;
    if !path.exists() {
        return Ok(Vec::new());
    }
    let content =
        fs::read_to_string(path).map_err(|error| format!("读取 Worktree 记录失败: {error}"))?;
    serde_json::from_str(&content).map_err(|error| format!("解析 Worktree 记录失败: {error}"))
}

fn save_records(app: &AppHandle, records: &[WorktreeRecord]) -> Result<(), String> {
    let path = records_path(app)?;
    let parent = path
        .parent()
        .ok_or_else(|| "Worktree 记录目录无效".to_string())?;
    fs::create_dir_all(parent).map_err(|error| format!("创建 Worktree 记录目录失败: {error}"))?;
    let content = serde_json::to_string_pretty(records)
        .map_err(|error| format!("序列化 Worktree 记录失败: {error}"))?;
    fs::write(path, content).map_err(|error| format!("保存 Worktree 记录失败: {error}"))
}

fn audit_path(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_config_dir()
        .map(|directory| directory.join(AUDIT_FILE))
        .map_err(|error| format!("无法定位 Git 审计目录: {error}"))
}

fn append_audit(
    app: &AppHandle,
    task_id: Option<&str>,
    operation: &str,
    workspace: &Path,
    target: Option<&str>,
    summary: &str,
    success: bool,
) -> Result<String, String> {
    let id = format!("git-audit-{}-{}", now_millis(), std::process::id());
    let entry = GrokGitAuditEntry {
        id: id.clone(),
        task_id: task_id.map(str::to_string),
        operation: operation.to_string(),
        workspace: workspace.to_string_lossy().to_string(),
        target: target.map(str::to_string),
        summary: summary.to_string(),
        success,
        created_at: now_millis(),
    };
    let path = audit_path(app)?;
    let parent = path
        .parent()
        .ok_or_else(|| "Git 审计目录无效".to_string())?;
    fs::create_dir_all(parent).map_err(|error| format!("创建 Git 审计目录失败: {error}"))?;
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
        .map_err(|error| format!("写入 Git 审计日志失败: {error}"))?;
    let line = serde_json::to_string(&entry)
        .map_err(|error| format!("序列化 Git 审计日志失败: {error}"))?;
    writeln!(file, "{line}").map_err(|error| format!("写入 Git 审计日志失败: {error}"))?;
    Ok(id)
}

fn mutation_result(
    app: &AppHandle,
    task_id: Option<&str>,
    operation: &str,
    workspace: &Path,
    target: Option<&str>,
    message: String,
    output: Option<String>,
    success: bool,
) -> Result<GrokGitMutationResult, String> {
    let audit_id = append_audit(
        app, task_id, operation, workspace, target, &message, success,
    )?;
    Ok(GrokGitMutationResult {
        success,
        operation: operation.to_string(),
        message,
        output,
        audit_id,
        status: git_status_at(workspace)?,
    })
}

fn validate_expected_branch(workspace: &Path, expected_branch: Option<&str>) -> Result<(), String> {
    let Some(expected_branch) = expected_branch
        .map(str::trim)
        .filter(|value| !value.is_empty())
    else {
        return Ok(());
    };
    let actual = branch_name(workspace).unwrap_or_default();
    if actual != expected_branch {
        return Err(format!(
            "分支已变化，当前为 {actual}，期望为 {expected_branch}。请刷新后重试。"
        ));
    }
    Ok(())
}

fn validate_git_paths(paths: &[String]) -> Result<Vec<String>, String> {
    paths.iter().map(|path| relative_path(path)).collect()
}

fn existing_workspace_file(workspace: &Path, relative: &str) -> Result<PathBuf, String> {
    let candidate = workspace.join(Path::new(relative));
    if !candidate.is_file() {
        return Err(format!("工作区文件不存在: {relative}"));
    }
    let canonical =
        fs::canonicalize(&candidate).map_err(|error| format!("无法解析工作区文件: {error}"))?;
    if !canonical.starts_with(workspace) {
        return Err("文件路径不能越过工作区根目录".to_string());
    }
    Ok(canonical)
}

fn materialize_head_file(
    app: &AppHandle,
    workspace: &Path,
    repo_root: &Path,
    relative: &str,
) -> Result<PathBuf, String> {
    let spec = format!("HEAD:{relative}");
    let args = vec!["show".to_string(), spec];
    let output = execute_git_raw(workspace, &args)?;
    if !output.status.success() {
        let detail = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(if detail.is_empty() {
            format!("HEAD 中不存在文件: {relative}")
        } else {
            format!("读取 HEAD 文件失败: {detail}")
        });
    }

    let cache_root = app
        .path()
        .app_cache_dir()
        .map_err(|error| format!("无法定位 HEAD 文件缓存目录: {error}"))?
        .join("grok-git-head")
        .join(repo_hash(repo_root));
    let target = cache_root.join(Path::new(relative));
    let parent = target
        .parent()
        .ok_or_else(|| "HEAD 文件缓存路径无效".to_string())?;
    fs::create_dir_all(parent).map_err(|error| format!("创建 HEAD 文件缓存目录失败: {error}"))?;
    fs::write(&target, output.stdout)
        .map_err(|error| format!("写入 HEAD 文件缓存失败: {error}"))?;
    Ok(target)
}

fn worktree_result(
    task_id: &str,
    mode: &str,
    repo_root: &Path,
    workspace_path: &Path,
    worktree_id: Option<String>,
    branch: Option<String>,
    base_ref: Option<String>,
    base_commit: Option<String>,
) -> Result<GrokGitTaskWorkspace, String> {
    let status = git_status_at(workspace_path)?;
    Ok(GrokGitTaskWorkspace {
        task_id: task_id.to_string(),
        mode: mode.to_string(),
        repo_root: repo_root.to_string_lossy().to_string(),
        workspace_path: workspace_path.to_string_lossy().to_string(),
        worktree_id,
        branch,
        base_ref,
        base_commit,
        head_commit: status.head_commit.clone(),
        status,
    })
}

#[tauri::command(async)]
pub fn grok_git_prepare_task(
    app: AppHandle,
    workspace: String,
    task_id: String,
    mode: String,
    worktree_name: Option<String>,
    worktree_ref: Option<String>,
) -> Result<GrokGitTaskWorkspace, String> {
    let mode = mode.trim().to_lowercase();
    let source_path = canonical_directory(&workspace)?;
    let repo_root = git_root(&source_path)?;
    if mode == "workspace" {
        return worktree_result(
            &task_id,
            &mode,
            &repo_root,
            &source_path,
            None,
            branch_name(&source_path),
            None,
            git_head(&source_path),
        );
    }
    if mode != "worktree" {
        if mode != "readonly" {
            return Err("未知的 Git 执行模式，请选择 Worktree、当前工作区或只读分析".to_string());
        }
    }

    let task_id = safe_segment(&task_id, "task");
    let records = load_records(&app)?;
    if let Some(existing) = records.iter().find(|record| {
        record.task_id == task_id
            && record.mode == mode
            && Path::new(&record.worktree_path).exists()
    }) {
        return worktree_result(
            &task_id,
            &existing.mode,
            Path::new(&existing.repo_root),
            Path::new(&existing.worktree_path),
            Some(existing.worktree_path.clone()),
            (!existing.branch.is_empty()).then_some(existing.branch.clone()),
            Some(existing.base_ref.clone()),
            git_head(Path::new(&existing.worktree_path)),
        );
    }

    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| format!("无法定位 Worktree 数据目录: {error}"))?;
    let worktree_path = data_dir
        .join("worktrees")
        .join(repo_hash(&repo_root))
        .join(&task_id);
    if worktree_path.exists() {
        return Err(format!(
            "Worktree 目标路径已存在: {}",
            worktree_path.to_string_lossy()
        ));
    }
    if let Some(parent) = worktree_path.parent() {
        fs::create_dir_all(parent).map_err(|error| format!("创建 Worktree 目录失败: {error}"))?;
    }

    let base_ref = worktree_ref.unwrap_or_default().trim().to_string();
    let base_ref = if base_ref.is_empty() {
        branch_name(&repo_root).unwrap_or_else(|| "HEAD".to_string())
    } else {
        base_ref
    };
    if base_ref.starts_with('-') {
        return Err("Worktree 基准不能以 - 开头".to_string());
    }
    let branch = (mode == "worktree").then(|| {
        format!(
            "urgs/task-{}-{}",
            safe_segment(worktree_name.as_deref().unwrap_or("task"), "task"),
            task_id
        )
    });
    let base_commit_args = vec!["rev-parse".to_string(), base_ref.clone()];
    let base_commit = run_git(&repo_root, &base_commit_args)?
        .stdout
        .trim()
        .to_string();
    let mut args = vec!["worktree".to_string(), "add".to_string()];
    if let Some(branch) = branch.as_ref() {
        args.extend(["-b".to_string(), branch.clone()]);
    } else {
        args.push("--detach".to_string());
    }
    args.extend([
        worktree_path.to_string_lossy().to_string(),
        base_ref.clone(),
    ]);
    if let Err(error) = run_git(&repo_root, &args) {
        let _ = fs::remove_dir_all(&worktree_path);
        return Err(error);
    }
    let mut records = records;
    records.push(WorktreeRecord {
        task_id: task_id.clone(),
        mode: mode.clone(),
        repo_root: repo_root.to_string_lossy().to_string(),
        worktree_path: worktree_path.to_string_lossy().to_string(),
        branch: branch.clone().unwrap_or_default(),
        base_ref: base_ref.clone(),
        created_at: now_millis(),
    });
    save_records(&app, &records)?;
    let _ = append_audit(
        &app,
        Some(&task_id),
        "worktree.create",
        &repo_root,
        Some(worktree_path.to_string_lossy().as_ref()),
        &format!(
            "创建{}，基于 {base_ref}{}",
            if mode == "readonly" {
                "只读审查快照"
            } else {
                "Worktree"
            },
            branch
                .as_deref()
                .map(|value| format!("，分支 {value}"))
                .unwrap_or_default()
        ),
        true,
    );
    worktree_result(
        &task_id,
        &mode,
        &repo_root,
        &worktree_path,
        Some(worktree_path.to_string_lossy().to_string()),
        branch,
        Some(base_ref),
        Some(base_commit),
    )
}

#[tauri::command(async)]
pub fn grok_git_status(
    workspace: String,
    include_stats: Option<bool>,
) -> Result<GrokGitStatus, String> {
    let workspace = canonical_directory(&workspace)?;
    match git_status_at_with_stats(&workspace, include_stats.unwrap_or(false)) {
        Ok(status) => Ok(status),
        Err(error) if is_not_git_repository_error(&error) || is_git_unavailable_error(&error) => {
            Ok(non_repository_status(&workspace))
        }
        Err(error) => Err(error),
    }
}

#[tauri::command(async)]
pub fn grok_git_diff(
    workspace: String,
    path: Option<String>,
    staged: bool,
    include_status: Option<bool>,
) -> Result<GrokGitDiff, String> {
    let workspace = canonical_directory(&workspace)?;
    let relative = path.map(|value| relative_path(&value)).transpose()?;
    let mut args = vec![
        "diff".to_string(),
        "--no-ext-diff".to_string(),
        "--unified=3".to_string(),
    ];
    if staged {
        args.push("--cached".to_string());
    }
    args.push("--".to_string());
    if let Some(path) = relative.as_ref() {
        args.push(path.clone());
    }
    let result = match run_git(&workspace, &args) {
        Ok(result) => result,
        Err(error) if is_not_git_repository_error(&error) || is_git_unavailable_error(&error) => {
            return Ok(GrokGitDiff {
                workspace_path: workspace.to_string_lossy().to_string(),
                path: relative,
                staged,
                patch: String::new(),
                truncated: false,
                files: Vec::new(),
            });
        }
        Err(error) => return Err(error),
    };
    let (patch, truncated) = trim_output(result.stdout, MAX_DIFF_OUTPUT);
    let files = if include_status.unwrap_or(true) {
        git_status_at(&workspace)?.files
    } else {
        Vec::new()
    };
    Ok(GrokGitDiff {
        workspace_path: workspace.to_string_lossy().to_string(),
        path: relative,
        staged,
        patch,
        truncated,
        files,
    })
}

#[tauri::command(async)]
pub fn grok_git_open_file(
    app: AppHandle,
    workspace: String,
    path: String,
    revision: Option<String>,
) -> Result<(), String> {
    let workspace = canonical_directory(&workspace)?;
    let repo_root = git_root(&workspace)?;
    let relative = relative_path(&path)?;
    let target = match revision.as_deref().map(str::trim) {
        None => existing_workspace_file(&workspace, &relative)?,
        Some("HEAD") => materialize_head_file(&app, &workspace, &repo_root, &relative)?,
        Some(_) => return Err("只支持打开当前文件或 HEAD 版本".to_string()),
    };
    app.opener()
        .open_path(target.to_string_lossy().to_string(), None::<String>)
        .map_err(|error| format!("打开文件失败: {error}"))
}

#[tauri::command(async)]
pub fn grok_git_reveal_file(app: AppHandle, workspace: String, path: String) -> Result<(), String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let relative = relative_path(&path)?;
    let candidate = workspace.join(Path::new(&relative));
    let target = if candidate.is_file() {
        existing_workspace_file(&workspace, &relative)?
    } else {
        candidate
            .parent()
            .map(Path::to_path_buf)
            .unwrap_or_else(|| workspace.clone())
    };
    app.opener()
        .reveal_item_in_dir(target)
        .map_err(|error| format!("在查找器中显示文件失败: {error}"))
}

#[tauri::command(async)]
pub fn grok_git_add_to_ignore(
    app: AppHandle,
    workspace: String,
    path: String,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let relative = relative_path(&path)?;
    let ignore_path = workspace.join(".gitignore");
    if ignore_path.exists() {
        let canonical_ignore = fs::canonicalize(&ignore_path)
            .map_err(|error| format!("无法解析 .gitignore: {error}"))?;
        if !canonical_ignore.starts_with(&workspace) {
            return Err(".gitignore 路径不能越过工作区根目录".to_string());
        }
        if !canonical_ignore.is_file() {
            return Err(".gitignore 不是文件".to_string());
        }
    }

    let mut content = if ignore_path.exists() {
        fs::read_to_string(&ignore_path)
            .map_err(|error| format!("读取 .gitignore 失败: {error}"))?
    } else {
        String::new()
    };
    let rooted = format!("/{relative}");
    let already_ignored = content
        .lines()
        .map(str::trim)
        .any(|line| line == relative || line == rooted);
    let message = if already_ignored {
        format!("{relative} 已在 .gitignore 中")
    } else {
        if !content.is_empty() && !content.ends_with('\n') {
            content.push('\n');
        }
        content.push_str(&relative);
        content.push('\n');
        fs::write(&ignore_path, content)
            .map_err(|error| format!("写入 .gitignore 失败: {error}"))?;
        format!("已将 {relative} 添加到 .gitignore")
    };
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.add_to_ignore",
        &workspace,
        Some(&relative),
        message,
        None,
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_stage(
    app: AppHandle,
    workspace: String,
    paths: Vec<String>,
    all: bool,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let mut args = vec!["add".to_string()];
    if all {
        args.push("-A".to_string());
    } else {
        let paths = validate_git_paths(&paths)?;
        if paths.is_empty() {
            return Err("请选择要暂存的文件".to_string());
        }
        args.push("--".to_string());
        args.extend(paths);
    }
    let result = run_git(&workspace, &args)?;
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.stage",
        &workspace,
        None,
        if all {
            "已暂存全部变更".to_string()
        } else {
            "已暂存所选变更".to_string()
        },
        (!result.stdout.trim().is_empty()).then_some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_unstage(
    app: AppHandle,
    workspace: String,
    paths: Vec<String>,
    all: bool,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let mut args = vec!["reset".to_string()];
    if !all {
        let paths = validate_git_paths(&paths)?;
        if paths.is_empty() {
            return Err("请选择要取消暂存的文件".to_string());
        }
        args.push("HEAD".to_string());
        args.push("--".to_string());
        args.extend(paths);
    }
    let result = run_git(&workspace, &args)?;
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.unstage",
        &workspace,
        None,
        if all {
            "已取消全部暂存".to_string()
        } else {
            "已取消所选文件暂存".to_string()
        },
        (!result.stdout.trim().is_empty()).then_some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_stash(
    app: AppHandle,
    workspace: String,
    message: Option<String>,
    include_untracked: bool,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let mut args = vec!["stash".to_string(), "push".to_string()];
    if include_untracked {
        args.push("-u".to_string());
    }
    args.push("-m".to_string());
    args.push(message.unwrap_or_else(|| "URGS Desktop 任务变更".to_string()));
    let result = run_git(&workspace, &args)?;
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.stash",
        &workspace,
        None,
        "已将当前变更收入 Stash".to_string(),
        Some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_discard(
    app: AppHandle,
    workspace: String,
    paths: Vec<String>,
    include_untracked: bool,
    confirmed: bool,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    if !confirmed {
        return Err("丢弃变更必须由用户明确确认".to_string());
    }
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let paths = validate_git_paths(&paths)?;
    if paths.is_empty() {
        return Err("请选择要丢弃的文件".to_string());
    }
    let mut tracked_paths = Vec::new();
    let mut untracked_paths = Vec::new();
    for path in &paths {
        let status = run_git_allow_failure(
            &workspace,
            &vec![
                "ls-files".to_string(),
                "--error-unmatch".to_string(),
                "--".to_string(),
                path.clone(),
            ],
        )?;
        if status.success {
            tracked_paths.push(path.clone());
        } else {
            untracked_paths.push(path.clone());
        }
    }
    let result = if tracked_paths.is_empty() {
        CommandResult {
            stdout: String::new(),
            stderr: String::new(),
            success: true,
        }
    } else {
        let mut args = vec![
            "restore".to_string(),
            "--worktree".to_string(),
            "--".to_string(),
        ];
        args.extend(tracked_paths);
        run_git(&workspace, &args)?
    };
    if include_untracked {
        for path in &untracked_paths {
            let candidate = workspace.join(path);
            if candidate.exists() && !candidate.is_dir() {
                fs::remove_file(&candidate)
                    .map_err(|error| format!("删除未跟踪文件失败: {error}"))?;
            }
        }
    }
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.discard",
        &workspace,
        None,
        "已丢弃所选工作区变更".to_string(),
        (!result.stdout.trim().is_empty()).then_some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_commit(
    app: AppHandle,
    workspace: String,
    message: String,
    amend: bool,
    signoff: bool,
    stage_all: bool,
    expected_branch: Option<String>,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    validate_expected_branch(&workspace, expected_branch.as_deref())?;
    let message = message.trim();
    if message.is_empty() {
        return Err("Commit message 不能为空".to_string());
    }
    let mut output = String::new();
    if stage_all {
        let add_result = run_git(&workspace, &vec!["add".to_string(), "-A".to_string()])?;
        output.push_str(&add_result.stdout);
    }
    let mut args = vec!["commit".to_string()];
    if amend {
        args.push("--amend".to_string());
    }
    if signoff {
        args.push("--signoff".to_string());
    }
    args.push("-m".to_string());
    args.push(message.to_string());
    let result = run_git(&workspace, &args)?;
    output.push_str(&result.stdout);
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.commit",
        &workspace,
        branch_name(&workspace).as_deref(),
        format!("已提交变更：{message}"),
        Some(output),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_fetch(
    app: AppHandle,
    workspace: String,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let result = run_git(
        &workspace,
        &vec![
            "fetch".to_string(),
            "--prune".to_string(),
            "--all".to_string(),
        ],
    )?;
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.fetch",
        &workspace,
        None,
        "已刷新远端分支信息".to_string(),
        Some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_sync_base(
    app: AppHandle,
    workspace: String,
    base_ref: String,
    expected_branch: Option<String>,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    validate_expected_branch(&workspace, expected_branch.as_deref())?;
    let base_ref = base_ref.trim();
    if base_ref.is_empty() || base_ref.starts_with('-') {
        return Err("同步基线必须填写有效的分支、远端分支或提交号".to_string());
    }
    let status = git_status_at(&workspace)?;
    if status.is_dirty {
        return Err("同步基线前必须先提交或 Stash 当前变更".to_string());
    }
    let result = run_git_allow_failure(
        &workspace,
        &vec!["rebase".to_string(), base_ref.to_string()],
    )?;
    if !result.success {
        let conflict_paths = git_status_at(&workspace)
            .map(|value| {
                value
                    .files
                    .into_iter()
                    .filter(|file| file.conflicted)
                    .map(|file| file.path)
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();
        let message = format!("同步基线失败：{}", result.stderr.trim());
        let audit_id = append_audit(
            &app,
            task_id.as_deref(),
            "git.sync-base",
            &workspace,
            Some(base_ref),
            &message,
            false,
        )?;
        return Ok(GrokGitMutationResult {
            success: false,
            operation: "git.sync-base".to_string(),
            message: format!(
                "{message}{}",
                if conflict_paths.is_empty() {
                    String::new()
                } else {
                    format!(" 冲突文件：{}", conflict_paths.join("、"))
                }
            ),
            output: Some(result.stdout),
            audit_id,
            status: git_status_at(&workspace)?,
        });
    }
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.sync-base",
        &workspace,
        Some(base_ref),
        format!("已将当前分支同步到 {base_ref}"),
        Some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_abort_operation(
    app: AppHandle,
    workspace: String,
    operation: String,
    confirmed: bool,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    if !confirmed {
        return Err("中止 Git 操作必须由用户明确确认".to_string());
    }
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let operation = operation.trim().to_lowercase();
    let command = match operation.as_str() {
        "rebase" => "rebase",
        "merge" => "merge",
        _ => return Err("只支持中止 rebase 或 merge".to_string()),
    };
    let result = run_git(
        &workspace,
        &vec![command.to_string(), "--abort".to_string()],
    )?;
    mutation_result(
        &app,
        task_id.as_deref(),
        &format!("git.{command}-abort"),
        &workspace,
        None,
        format!("已中止当前 {command} 操作"),
        Some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_push(
    app: AppHandle,
    workspace: String,
    set_upstream: bool,
    expected_branch: Option<String>,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    validate_expected_branch(&workspace, expected_branch.as_deref())?;
    let branch = branch_name(&workspace).ok_or_else(|| "当前不是可推送的本地分支".to_string())?;
    let mut args = vec!["push".to_string()];
    if set_upstream {
        args.extend(["-u".to_string(), "origin".to_string(), branch.clone()]);
    }
    let result = run_git(&workspace, &args)?;
    mutation_result(
        &app,
        task_id.as_deref(),
        "git.push",
        &workspace,
        Some(&branch),
        "已推送当前分支到远端".to_string(),
        Some(result.stdout),
        true,
    )
}

fn remote_parts(url: &str) -> (Option<String>, Option<String>) {
    let value = url.trim().trim_end_matches('/');
    if value.is_empty() || value.starts_with('.') || value.starts_with('/') {
        return (None, None);
    }
    let (host, repository) =
        if let Some(authority) = value.split_once("://").map(|(_, value)| value) {
            let authority = authority.split_once('/');
            let raw_host = authority
                .map(|(host, _)| host)
                .unwrap_or_else(|| value.split_once("://").unwrap().1);
            let host = raw_host
                .rsplit_once('@')
                .map(|(_, value)| value)
                .unwrap_or(raw_host);
            let repository = authority.and_then(|(_, path)| Some(path.to_string()));
            (host.to_string(), repository)
        } else if let Some((authority, path)) = value.split_once(':') {
            let host = authority
                .rsplit_once('@')
                .map(|(_, value)| value)
                .unwrap_or(authority);
            (host.to_string(), Some(path.to_string()))
        } else {
            return (None, None);
        };
    let host = host
        .split('@')
        .next_back()
        .unwrap_or(&host)
        .split(':')
        .next()
        .unwrap_or(&host)
        .trim()
        .to_string();
    let repository = repository
        .map(|path| path.trim_matches('/').trim_end_matches(".git").to_string())
        .filter(|path| !path.is_empty());
    if host.is_empty() {
        (None, repository)
    } else {
        (Some(host), repository)
    }
}

fn remote_provider(host: Option<&str>, url: &str) -> String {
    let value = format!("{} {}", host.unwrap_or_default(), url).to_lowercase();
    if value.contains("github.com") {
        "GitHub".to_string()
    } else if value.contains("gitlab") {
        "GitLab".to_string()
    } else if value.contains("gitee.com") {
        "Gitee".to_string()
    } else if value.contains("gitea") {
        "Gitea".to_string()
    } else if value.contains("bitbucket") {
        "Bitbucket".to_string()
    } else {
        "Git".to_string()
    }
}

fn remote_metadata(url: &str) -> (String, Option<String>, Option<String>, Option<String>) {
    let (host, repository) = remote_parts(url);
    let provider = remote_provider(host.as_deref(), url);
    let web_url = match (&host, &repository) {
        (Some(host), Some(repository)) if provider != "Git" => {
            Some(format!("https://{host}/{repository}"))
        }
        _ => None,
    };
    (provider, host, repository, web_url)
}

fn parse_remotes(output: &str) -> Vec<GrokGitRemote> {
    let mut remotes = Vec::new();
    for line in output.lines() {
        let fields = line.split_whitespace().collect::<Vec<_>>();
        if fields.len() < 3 {
            continue;
        }
        let name = fields[0];
        let url = fields[1].to_string();
        let is_push = fields.last() == Some(&"(push)");
        if let Some(remote) = remotes
            .iter_mut()
            .find(|item: &&mut GrokGitRemote| item.name == name)
        {
            if is_push {
                remote.push_url = Some(url);
            } else {
                remote.fetch_url = Some(url);
            }
            let metadata_url = remote.fetch_url.clone().or_else(|| remote.push_url.clone());
            if let Some(metadata_url) = metadata_url {
                let (provider, host, repository, web_url) = remote_metadata(&metadata_url);
                remote.provider = provider;
                remote.host = host;
                remote.repository = repository;
                remote.web_url = web_url;
                remote.capabilities = vec!["fetch".to_string(), "push".to_string()];
            }
            continue;
        }
        let (provider, host, repository, web_url) = remote_metadata(&url);
        remotes.push(GrokGitRemote {
            name: name.to_string(),
            fetch_url: (!is_push).then_some(url.clone()),
            push_url: is_push.then_some(url.clone()),
            provider,
            host,
            repository,
            web_url,
            capabilities: vec!["fetch".to_string(), "push".to_string()],
        });
    }
    remotes
}

#[tauri::command(async)]
pub fn grok_git_remote_list(workspace: String) -> Result<Vec<GrokGitRemote>, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let result = run_git(&workspace, &vec!["remote".to_string(), "-v".to_string()])?;
    Ok(parse_remotes(&result.stdout))
}

fn parse_worktrees(output: &str) -> Vec<GrokGitWorktree> {
    let mut result = Vec::new();
    let mut current: Option<GrokGitWorktree> = None;
    for line in output.lines() {
        if line == "worktree" || line.starts_with("worktree ") {
            if let Some(item) = current.take() {
                result.push(item);
            }
            let path = line
                .strip_prefix("worktree ")
                .unwrap_or_default()
                .to_string();
            current = Some(GrokGitWorktree {
                path,
                head_commit: None,
                branch: None,
                detached: false,
                locked: false,
                prunable: false,
            });
        } else if let Some(item) = current.as_mut() {
            if let Some(value) = line.strip_prefix("HEAD ") {
                item.head_commit = Some(value.to_string());
            } else if let Some(value) = line.strip_prefix("branch refs/heads/") {
                item.branch = Some(value.to_string());
            } else if line == "detached" {
                item.detached = true;
            } else if line == "locked" || line.starts_with("locked ") {
                item.locked = true;
            } else if line == "prunable" || line.starts_with("prunable ") {
                item.prunable = true;
            }
        }
    }
    if let Some(item) = current {
        result.push(item);
    }
    result
}

#[tauri::command(async)]
pub fn grok_git_worktree_list(workspace: String) -> Result<Vec<GrokGitWorktree>, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let result = run_git(
        &workspace,
        &vec![
            "worktree".to_string(),
            "list".to_string(),
            "--porcelain".to_string(),
        ],
    )?;
    Ok(parse_worktrees(&result.stdout))
}

#[tauri::command(async)]
pub fn grok_git_worktree_remove(
    app: AppHandle,
    workspace: String,
    worktree_path: String,
    force: bool,
    confirmed: bool,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    if !confirmed {
        return Err("删除 Worktree 必须由用户明确确认".to_string());
    }
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let raw_target = worktree_path.trim();
    if raw_target.is_empty() {
        return Err("Worktree 路径不能为空".to_string());
    }
    let target = PathBuf::from(raw_target);
    if !target.is_absolute() {
        return Err("Worktree 路径必须是绝对路径".to_string());
    }
    let target = if target.exists() {
        fs::canonicalize(&target).map_err(|error| format!("无法解析 Worktree 路径: {error}"))?
    } else {
        target
    };
    let known_worktree = grok_git_worktree_list(workspace.to_string_lossy().to_string())?
        .iter()
        .any(|item| item.path == target.to_string_lossy());
    let known_record = load_records(&app)?
        .iter()
        .any(|record| record.worktree_path == target.to_string_lossy());
    if !known_worktree && !known_record {
        return Err("目标路径不是当前仓库登记的 Worktree".to_string());
    }
    let result = if target.exists() {
        let mut args = vec!["worktree".to_string(), "remove".to_string()];
        if force {
            args.push("--force".to_string());
        }
        args.push(target.to_string_lossy().to_string());
        run_git(&workspace, &args)?
    } else {
        run_git(
            &workspace,
            &vec!["worktree".to_string(), "prune".to_string()],
        )?
    };
    let mut records = load_records(&app)?;
    records.retain(|record| record.worktree_path != target.to_string_lossy());
    save_records(&app, &records)?;
    mutation_result(
        &app,
        task_id.as_deref(),
        "worktree.remove",
        &workspace,
        Some(target.to_string_lossy().as_ref()),
        "已删除 Worktree".to_string(),
        Some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_worktree_gc(
    app: AppHandle,
    workspace: String,
    task_id: Option<String>,
) -> Result<GrokGitMutationResult, String> {
    let workspace = canonical_directory(&workspace)?;
    git_root(&workspace)?;
    let result = run_git(
        &workspace,
        &vec!["worktree".to_string(), "prune".to_string()],
    )?;
    let existing = grok_git_worktree_list(workspace.to_string_lossy().to_string())?;
    let existing_paths = existing
        .into_iter()
        .map(|item| item.path)
        .collect::<std::collections::HashSet<_>>();
    let mut records = load_records(&app)?;
    records.retain(|record| existing_paths.contains(&record.worktree_path));
    save_records(&app, &records)?;
    mutation_result(
        &app,
        task_id.as_deref(),
        "worktree.gc",
        &workspace,
        None,
        "已清理失效 Worktree 记录".to_string(),
        Some(result.stdout),
        true,
    )
}

#[tauri::command(async)]
pub fn grok_git_apply_worktree(
    app: AppHandle,
    source_workspace: String,
    target_workspace: String,
    expected_source_branch: Option<String>,
    expected_target_branch: Option<String>,
    task_id: Option<String>,
) -> Result<GrokGitApplyResult, String> {
    let source = canonical_directory(&source_workspace)?;
    let target = canonical_directory(&target_workspace)?;
    git_root(&source)?;
    git_root(&target)?;
    if source == target {
        return Err("源 Worktree 与目标工作区不能相同".to_string());
    }
    validate_expected_branch(&source, expected_source_branch.as_deref())?;
    validate_expected_branch(&target, expected_target_branch.as_deref())?;
    let source_status = git_status_at(&source)?;
    if source_status.is_dirty {
        return Err(
            "当前 Worktree 还有未提交变更，请先在审查面板完成 Commit，再应用到主工作区".to_string(),
        );
    }
    let target_status = git_status_at(&target)?;
    if target_status.is_dirty {
        return Err("目标工作区存在未提交变更，已阻止应用 Worktree，避免覆盖本地工作".to_string());
    }
    let branch = branch_name(&source).ok_or_else(|| "源 Worktree 没有可应用的分支".to_string())?;
    let args = vec![
        "merge".to_string(),
        "--no-ff".to_string(),
        branch.clone(),
        "-m".to_string(),
        format!(
            "Merge URGS task {}",
            task_id.as_deref().unwrap_or("worktree")
        ),
    ];
    let merge_result = run_git_allow_failure(&target, &args)?;
    if !merge_result.success {
        let conflict_paths = git_status_at(&target)
            .map(|status| {
                status
                    .files
                    .into_iter()
                    .filter(|file| file.conflicted)
                    .map(|file| file.path)
                    .collect()
            })
            .unwrap_or_default();
        let audit_id = append_audit(
            &app,
            task_id.as_deref(),
            "worktree.apply",
            &source,
            Some(&target.to_string_lossy()),
            &format!("应用分支 {branch} 失败: {}", merge_result.stderr.trim()),
            false,
        )?;
        return Ok(GrokGitApplyResult {
            success: false,
            message: format!("应用 Worktree 失败：{}", merge_result.stderr.trim()),
            conflict_paths,
            audit_id,
            source_status,
            target_status: git_status_at(&target)?,
        });
    }
    let audit_id = append_audit(
        &app,
        task_id.as_deref(),
        "worktree.apply",
        &source,
        Some(&target.to_string_lossy()),
        &format!("已将分支 {branch} 应用到目标工作区"),
        true,
    )?;
    Ok(GrokGitApplyResult {
        success: true,
        message: format!("已将 {branch} 应用到目标工作区"),
        conflict_paths: Vec::new(),
        audit_id,
        source_status,
        target_status: git_status_at(&target)?,
    })
}

#[tauri::command(async)]
pub fn grok_git_audit_list(
    app: AppHandle,
    workspace: Option<String>,
) -> Result<Vec<GrokGitAuditEntry>, String> {
    let path = audit_path(&app)?;
    if !path.exists() {
        return Ok(Vec::new());
    }
    let filter = workspace
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty());
    let content =
        fs::read_to_string(path).map_err(|error| format!("读取 Git 审计日志失败: {error}"))?;
    let mut entries = content
        .lines()
        .filter_map(|line| serde_json::from_str::<GrokGitAuditEntry>(line).ok())
        .filter(|entry| {
            filter
                .as_ref()
                .map(|value| entry.workspace == *value || entry.target.as_deref() == Some(value))
                .unwrap_or(true)
        })
        .collect::<Vec<_>>();
    entries.sort_by(|left, right| right.created_at.cmp(&left.created_at));
    entries.truncate(100);
    Ok(entries)
}

#[cfg(test)]
mod tests {
    use super::{
        git_command_timeout, is_git_unavailable_error, parse_remotes, parse_tracking,
        parse_worktrees, relative_path, LOCAL_GIT_TIMEOUT, LONG_GIT_TIMEOUT,
    };

    #[test]
    fn uses_short_timeouts_for_reads_and_long_timeouts_for_mutations() {
        assert_eq!(
            git_command_timeout(&["status".to_string(), "--porcelain=v1".to_string()]),
            LOCAL_GIT_TIMEOUT
        );
        assert_eq!(
            git_command_timeout(&["fetch".to_string(), "--all".to_string()]),
            LONG_GIT_TIMEOUT
        );
        assert_eq!(
            git_command_timeout(&["worktree".to_string(), "add".to_string()]),
            LONG_GIT_TIMEOUT
        );
    }

    #[test]
    fn parses_branch_tracking_counts() {
        let (tracking, ahead, behind) = parse_tracking("main...origin/main [ahead 2, behind 1]");
        assert_eq!(tracking.as_deref(), Some("main...origin/main"));
        assert_eq!(ahead, 2);
        assert_eq!(behind, 1);
    }

    #[test]
    fn treats_missing_git_executable_as_optional_integration() {
        assert!(is_git_unavailable_error(
            "无法启动 git，请确认已安装 Git: program not found"
        ));
        assert!(is_git_unavailable_error(
            "系统找不到指定的文件。 (os error 2)"
        ));
        assert!(!is_git_unavailable_error("fatal: not a git repository"));
    }

    #[test]
    fn rejects_paths_that_escape_the_workspace() {
        assert!(relative_path("../secrets.txt").is_err());
        assert!(relative_path("/tmp/secrets.txt").is_err());
        assert_eq!(relative_path("src\\main.rs").unwrap(), "src/main.rs");
    }

    #[test]
    fn parses_porcelain_worktree_output() {
        let worktrees = parse_worktrees(
            "worktree /tmp/main\nHEAD abc\nbranch refs/heads/main\n\nworktree /tmp/task\nHEAD def\ndetached\n",
        );
        assert_eq!(worktrees.len(), 2);
        assert_eq!(worktrees[0].branch.as_deref(), Some("main"));
        assert!(worktrees[1].detached);
    }

    #[test]
    fn parses_remote_provider_without_faking_pr_capabilities() {
        let remotes = parse_remotes(
            "origin git@github.com:example/urgs.git (fetch)\norigin git@github.com:example/urgs.git (push)\n",
        );
        assert_eq!(remotes.len(), 1);
        assert_eq!(remotes[0].provider, "GitHub");
        assert!(remotes[0].fetch_url.is_some());
        assert!(remotes[0].push_url.is_some());
        assert_eq!(remotes[0].host.as_deref(), Some("github.com"));
        assert_eq!(remotes[0].repository.as_deref(), Some("example/urgs"));
        assert_eq!(
            remotes[0].web_url.as_deref(),
            Some("https://github.com/example/urgs")
        );
        assert_eq!(remotes[0].capabilities, vec!["fetch", "push"]);

        let hosted = parse_remotes(
            "gitlab https://gitlab.example.com/group/project.git (fetch)\ngitlab https://gitlab.example.com/group/project.git (push)\ngitea ssh://git@gitea.example.com/team/service.git (fetch)\ngitea ssh://git@gitea.example.com/team/service.git (push)\n",
        );
        assert_eq!(hosted[0].provider, "GitLab");
        assert_eq!(hosted[0].repository.as_deref(), Some("group/project"));
        assert_eq!(hosted[1].provider, "Gitea");
        assert_eq!(hosted[1].host.as_deref(), Some("gitea.example.com"));
    }
}
