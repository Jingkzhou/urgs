[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InstallerPath,
    [string]$ExpectedVersion
)

$ErrorActionPreference = "Stop"
$installer = (Resolve-Path -LiteralPath $InstallerPath).Path
$installRoot = Join-Path $env:TEMP ("urgs-grok-install-smoke-" + [guid]::NewGuid().ToString("N"))
$stdoutPath = Join-Path $installRoot "grok.stdout.txt"
$stderrPath = Join-Path $installRoot "grok.stderr.txt"

New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

try {
    Write-Host "安装 NSIS 客户端：$installer"
    $installerProcess = Start-Process `
        -FilePath $installer `
        -ArgumentList @("/S", "/D=$installRoot") `
        -Wait `
        -PassThru
    if ($installerProcess.ExitCode -ne 0) {
        throw "NSIS 安装失败，退出码：$($installerProcess.ExitCode)"
    }

    $appExecutables = @(
        Get-ChildItem -LiteralPath $installRoot -Filter "urgs-desktop*.exe" -File -Recurse
    )
    if ($appExecutables.Count -eq 0) {
        throw "安装目录中未找到 URGS Desktop 可执行文件：$installRoot"
    }

    $sidecars = @(
        Get-ChildItem -LiteralPath $installRoot -Filter "grok*.exe" -File -Recurse |
            Where-Object { $_.Name -match '^grok(?:-.*)?\.exe$' }
    )
    if ($sidecars.Count -eq 0) {
        throw "安装目录中未找到内置 Grok sidecar：$installRoot"
    }
    $sidecar = $sidecars[0]

    Write-Host "运行安装后的 Grok：$($sidecar.FullName)"
    $grokProcess = Start-Process `
        -FilePath $sidecar.FullName `
        -ArgumentList @("--no-auto-update", "--version") `
        -Wait `
        -PassThru `
        -NoNewWindow `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath
    $versionOutput = (Get-Content -LiteralPath $stdoutPath -Raw).Trim()
    $errorOutput = (Get-Content -LiteralPath $stderrPath -Raw).Trim()
    if ($grokProcess.ExitCode -ne 0) {
        throw "安装后的 Grok 无法启动，退出码 $($grokProcess.ExitCode)：$errorOutput"
    }
    if ([string]::IsNullOrWhiteSpace($versionOutput)) {
        throw "安装后的 Grok 未返回版本信息"
    }
    if ($ExpectedVersion -and $versionOutput -notmatch [regex]::Escape($ExpectedVersion)) {
        throw "安装后的 Grok 版本不匹配：期望 $ExpectedVersion，实际 $versionOutput"
    }

    Write-Host "Windows 安装后 Grok 冒烟验证通过：$versionOutput"
}
finally {
    if (Test-Path -LiteralPath $installRoot) {
        Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
