# ============================================================
#  QuickClip — 方案① 零依赖 PowerShell 版
#  功能：把 Windows 剪贴板里的图片，快速保存为 PNG 到指定文件夹
#
#  用法：
#    直接运行           -> 保存到配置目录(QuickClip.config)，默认 图片\QuickClip
#    -OutDir 路径       -> 本次覆盖保存目录
#    -Silent            -> 不弹窗，仅输出结果(0=成功, 1=剪贴板无图片)
#  由 install.ps1 创建桌面快捷方式并绑定全局热键(默认 Ctrl+Alt+S)
# ============================================================
param(
    [string]$OutDir = "",
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

# ---------- 1. 解析输出目录：参数 > 配置文件 > 默认目录 ----------
$scriptDir  = $PSScriptRoot
$configFile = Join-Path $scriptDir "QuickClip.config"

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    if (Test-Path -LiteralPath $configFile) {
        $line = Get-Content -LiteralPath $configFile -Encoding UTF8 |
                Where-Object { $_.Trim() -ne "" } | Select-Object -First 1
        if ($null -ne $line) { $OutDir = $line.Trim() }
    }
}
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path ([Environment]::GetFolderPath("MyPictures")) "QuickClip"
}

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

# ---------- 2. 读取剪贴板图片（带重试，应对浏览器短暂占用剪贴板） ----------
Add-Type -AssemblyName PresentationCore

$image = $null
$maxTries = 6
for ($i = 0; $i -lt $maxTries; $i++) {
    try {
        if (-not [System.Windows.Clipboard]::ContainsImage()) { break }
        $image = [System.Windows.Clipboard]::GetImage()
        break
    }
    catch {
        if ($i -eq $maxTries - 1) { throw }
        Start-Sleep -Milliseconds 100
    }
}

if ($null -eq $image) {
    if ($Silent) {
        Write-Output "NO_IMAGE"
        exit 1
    }
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show(
        "剪贴板里没有图片，请先在浏览器里右键点击图片并选择『复制图片』。",
        "QuickClip",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
        [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly
    )
    exit 1
}

# ---------- 3. 生成不重名文件名并保存为 PNG ----------
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$name  = "图片_$stamp.png"
$path  = Join-Path $OutDir $name

$i = 2
while (Test-Path -LiteralPath $path) {
    $name = "图片_${stamp}_${i}.png"
    $path = Join-Path $OutDir $name
    $i++
}

$encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
$frame   = [System.Windows.Media.Imaging.BitmapFrame]::Create($image)
$encoder.Frames.Add($frame)
$stream  = [System.IO.File]::Create($path)
try {
    $encoder.Save($stream)
}
finally {
    $stream.Close()
}

# ---------- 3.5 保存成功后清除剪贴板里的图片，避免重复粘贴 ----------
for ($i = 0; $i -lt 3; $i++) {
    try { [System.Windows.Clipboard]::Clear(); break }
    catch { Start-Sleep -Milliseconds 80 }
}

# ---------- 4. 反馈 ----------
if ($Silent) {
    Write-Output $path
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
$result = [System.Windows.Forms.MessageBox]::Show(
    "图片已保存：`n$path`n`n是否打开所在文件夹？",
    "QuickClip",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Information,
    [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
    [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly
)
if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    Start-Process "explorer.exe" "/select,`"$path`""
}
exit 0