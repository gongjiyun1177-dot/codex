# Auto-find and launch WeChat
Write-Host "Searching for WeChat..."

# 1. Try protocol handler
try {
    Start-Process "weixin://" -ErrorAction Stop
    Write-Host "Launched via weixin://"
    exit 0
} catch {}

# 2. Try UWP / Store version
$uwp = Get-StartApps | Where-Object { $_.Name -like "*WeChat*" }
if ($uwp) {
    try {
        Start-Process "shell:AppsFolder\$($uwp.AppID)" -ErrorAction Stop
        Write-Host "Launched via UWP"
        exit 0
    } catch {}
}

# 3. Check common paths
$paths = @(
    "$env:LOCALAPPDATA\Tencent\WeChat\WeChat.exe",
    "$env:ProgramFiles\Tencent\WeChat\WeChat.exe",
    "${env:ProgramFiles(x86)}\Tencent\WeChat\WeChat.exe",
    "$env:APPDATA\Tencent\WeChat\WeChat.exe",
    "D:\Program Files\Tencent\WeChat\WeChat.exe"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Start-Process $p
        Write-Host "Launched: $p"
        exit 0
    }
}

Write-Host "WeChat not found. Download from https://weixin.qq.com"
exit 1
