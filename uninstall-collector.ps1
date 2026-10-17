# ============================================================
#  QuickClip — 卸载后台收集器（移除开机自启并停止进程）
# ============================================================
$ErrorActionPreference = "Stop"

$baseDir = Join-Path $env:LOCALAPPDATA "QuickClip"

# 1) 停止正在运行的收集器
$pidFile = Join-Path $baseDir "collector.pid"
if (Test-Path -LiteralPath $pidFile) {
    $cpid = [int](Get-Content -LiteralPath $pidFile -Raw).Trim()
    $proc = Get-Process -Id $cpid -ErrorAction SilentlyContinue
    if ($proc) { Stop-Process -Id $cpid -Force; Write-Host "已停止收集器 (PID $cpid)" }
    Remove-Item -LiteralPath $pidFile -Force
}

# 2) 移除开机自启
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (Get-ItemProperty -Path $runKey -Name "QuickClipCollector" -ErrorAction SilentlyContinue) {
    Remove-ItemProperty -Path $runKey -Name "QuickClipCollector"
    Write-Host "已移除开机自启项 QuickClipCollector"
}

Write-Host "后台收集器已卸载。"
Write-Host "提示：待存区里的缓存图片仍保留在 $baseDir\staging，可手动删除。"