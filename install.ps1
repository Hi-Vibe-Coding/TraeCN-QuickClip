# ============================================================
#  QuickClip — 一键安装（配置目录 + 桌面快捷方式 + 全局热键）
#  作用：
#    1) 把 save-image.ps1 的保存目录写入 QuickClip.config
#    2) 在桌面创建快捷方式，绑定全局热键（默认 Ctrl+Alt+S）
#
#  用法：
#    .\install.ps1                             # 默认目录 图片\QuickClip
#    .\install.ps1 -OutDir "D:\我的图片"        # 指定保存目录
#    .\install.ps1 -Hotkey "Ctrl+Alt+S"        # 自定义热键
# ============================================================
param(
    [string]$OutDir = "",
    [string]$Hotkey = "Ctrl+Alt+S"
)

$ErrorActionPreference = "Stop"

$scriptDir  = $PSScriptRoot
$saveScript = Join-Path $scriptDir "save-image.ps1"
$configFile = Join-Path $scriptDir "QuickClip.config"

if (-not (Test-Path -LiteralPath $saveScript)) {
    throw "未找到 save-image.ps1，请确保它与 install.ps1 在同一目录：$scriptDir"
}

# ---------- 1. 确定输出目录 ----------
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path ([Environment]::GetFolderPath("MyPictures")) "QuickClip"
}
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

# ---------- 2. 写配置文件（UTF-8） ----------
Set-Content -LiteralPath $configFile -Value $OutDir -Encoding UTF8

# ---------- 3. 定位 Windows PowerShell ----------
$psExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path -LiteralPath $psExe)) { $psExe = "powershell.exe" }

# ---------- 4. 创建桌面快捷方式 ----------
$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop "QuickClip-保存图片.lnk"

$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnkPath)
$sc.TargetPath       = $psExe
$sc.Arguments        = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$saveScript`""
$sc.WorkingDirectory = $scriptDir
$sc.Description      = "把剪贴板里的图片保存到 $OutDir"
$sc.IconLocation     = "$psExe,0"

try {
    $sc.Hotkey = $Hotkey
}
catch {
    Write-Warning "热键 '$Hotkey' 无效，已改为不绑定(仍可双击快捷方式使用)。有效格式如 Ctrl+Alt+S。"
    $sc.Hotkey = ""
}
$sc.Save()

# ---------- 5. 输出结果 ----------
Write-Host ""
Write-Host "================= QuickClip 安装完成 =================" -ForegroundColor Green
Write-Host "  保存目录 : $OutDir"
Write-Host "  桌面快捷 : $lnkPath"
Write-Host "  全局热键 : $Hotkey"
Write-Host ""
Write-Host "使用步骤："
Write-Host "  1. 浏览器里右键点击图片 -> 复制图片"
Write-Host "  2. 按下 $Hotkey"
Write-Host "  3. 图片即以 PNG 自动保存到上述目录"
Write-Host ""
Write-Host "提示："
Write-Host "  - 若热键不生效，注销并重新登录一次即可"
Write-Host "  - 修改保存目录： .\install.ps1 -OutDir '你的文件夹'"
Write-Host "  - 修改热键    ： .\install.ps1 -Hotkey 'Ctrl+Alt+S'"
Write-Host ""