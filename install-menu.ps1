# ============================================================
#  QuickClip — 注册「右键菜单」版（批量保存）
#  作用：在资源管理器里加两处右键菜单，右键即可把收集的多张图片批量存到该文件夹
#    1) 文件夹内空白处右键  -> Directory\Background\shell
#    2) 右键某个文件夹本身   -> Directory\shell
#  静默保存（不弹窗），保存为 PNG。仅修改当前用户(HKCU)，无需管理员权限。
# ============================================================

$ErrorActionPreference = "Stop"

$scriptDir  = $PSScriptRoot
$saveScript = Join-Path $scriptDir "save-all.ps1"

if (-not (Test-Path -LiteralPath $saveScript)) {
    throw "未找到 save-all.ps1，请确保它与本脚本在同一目录：$scriptDir"
}

$psExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path -LiteralPath $psExe)) { $psExe = "powershell.exe" }

$menuText = "保存收集的图片到此处"
$icon     = "$psExe,0"

# -Silent 静默保存；-OutDir 目标文件夹；%V/%1 由系统替换为对应文件夹路径
$cmdBg  = "`"$psExe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$saveScript`" -Silent -OutDir `"%V`""
$cmdDir = "`"$psExe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$saveScript`" -Silent -OutDir `"%1`""

# 1) 文件夹内空白处右键
$bgKey = "HKCU:\Software\Classes\Directory\Background\shell\QuickClipSave"
New-Item -Path $bgKey -Force | Out-Null
New-Item -Path "$bgKey\command" -Force | Out-Null
Set-ItemProperty -Path $bgKey -Name "(default)" -Value $menuText
Set-ItemProperty -Path $bgKey -Name "Icon" -Value $icon
Set-ItemProperty -Path "$bgKey\command" -Name "(default)" -Value $cmdBg

# 2) 右键某个文件夹本身
$dirKey = "HKCU:\Software\Classes\Directory\shell\QuickClipSave"
New-Item -Path $dirKey -Force | Out-Null
New-Item -Path "$dirKey\command" -Force | Out-Null
Set-ItemProperty -Path $dirKey -Name "(default)" -Value $menuText
Set-ItemProperty -Path $dirKey -Name "Icon" -Value $icon
Set-ItemProperty -Path "$dirKey\command" -Name "(default)" -Value $cmdDir

Write-Host ""
Write-Host "=============== QuickClip 右键菜单安装完成 ===============" -ForegroundColor Green
Write-Host "  1) 文件夹内空白处右键 -> $menuText"
Write-Host "  2) 右键某个文件夹本身 -> $menuText"
Write-Host "  静默批量保存为 PNG（不弹窗），命名 图片_时间戳-01.png / -02.png ..."
Write-Host ""
Write-Host "使用：浏览器复制图片 -> 到目标文件夹 -> 右键 -> $menuText"
Write-Host "卸载： .\uninstall-menu.ps1"
Write-Host ""
Write-Host "提示："
Write-Host "  - Win11 需在右键菜单里点『显示更多选项』(或 Shift+右键) 才能看到"
Write-Host "  - 若菜单未出现，新开一个资源管理器窗口或注销重登即可"
Write-Host ""