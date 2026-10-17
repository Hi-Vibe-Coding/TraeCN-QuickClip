# ============================================================
#  QuickClip — 安装后台收集器（待存区 + 开机自启 + 立即启动）
# ============================================================
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$collector = Join-Path $scriptDir "collector.ps1"
$saveAll   = Join-Path $scriptDir "save-all.ps1"

foreach ($f in @($collector, $saveAll)) {
    if (-not (Test-Path -LiteralPath $f)) {
        throw "缺少脚本：$f"
    }
}

$baseDir = Join-Path $env:LOCALAPPDATA "QuickClip"
$staging = Join-Path $baseDir "staging"
New-Item -ItemType Directory -Path $staging -Force | Out-Null

$psExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path -LiteralPath $psExe)) { $psExe = "powershell.exe" }

# 1) 开机自启（当前用户 Run 键）
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (-not (Test-Path $runKey)) { New-Item -Path $runKey -Force | Out-Null }
Set-ItemProperty -Path $runKey -Name "QuickClipCollector" -Value ("`"$psExe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$collector`"")

# 2) 立即启动一次（后台隐藏窗口）
Start-Process -FilePath $psExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$collector`"" -WindowStyle Hidden

Write-Host ""
Write-Host "=============== QuickClip 后台收集器已安装 ===============" -ForegroundColor Green
Write-Host "  待存区   : $staging"
Write-Host "  开机自启 : 已写入（下次登录自动运行，现已尝试立即启动）"
Write-Host ""
Write-Host "使用流程："
Write-Host "  1. 浏览器里复制图片（可连续复制多张，会自动收集）"
Write-Host "  2. 到目标文件夹右键 -> 保存收集的图片到此处"
Write-Host "  3. 一次性落盘为 图片_时间戳-01.png / -02.png ..."
Write-Host ""
Write-Host "手动启动收集器 : .\collector.ps1"
Write-Host "卸载收集器     : .\uninstall-collector.ps1"
Write-Host ""