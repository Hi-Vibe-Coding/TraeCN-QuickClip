# ============================================================
#  QuickClip — 卸载右键菜单
# ============================================================

$ErrorActionPreference = "Stop"

$keys = @(
    "HKCU:\Software\Classes\Directory\Background\shell\QuickClipSave",
    "HKCU:\Software\Classes\Directory\shell\QuickClipSave"
)

foreach ($k in $keys) {
    if (Test-Path $k) {
        Remove-Item -Path $k -Recurse -Force
        Write-Host "已移除：$k"
    }
    else {
        Write-Host "不存在：$k"
    }
}

Write-Host "QuickClip 右键菜单已卸载。"
Write-Host "如菜单仍显示，重启资源管理器(注销重登)即可。"