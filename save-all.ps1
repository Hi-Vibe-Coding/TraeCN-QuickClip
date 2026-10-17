# ============================================================
#  QuickClip — 批量落盘
#  作用：把后台收集器缓存的多张图片，一次性保存到目标文件夹，
#        命名 图片_<时间戳>-01.png / -02.png / ...
#  由右键菜单调用，参数 -OutDir 来自 %V/%1（当前文件夹）
# ============================================================
param(
    [string]$OutDir = "",
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

$staging = Join-Path $env:LOCALAPPDATA "QuickClip\staging"

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path ([Environment]::GetFolderPath("MyPictures")) "QuickClip"
}
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$files = @(Get-ChildItem -LiteralPath $staging -Filter *.png -ErrorAction SilentlyContinue | Sort-Object Name)

if ($files.Count -eq 0) {
    # 待存区为空：先尝试直接读剪贴板（兜底，例如收集器未运行、或尚未收集到图片时）
    Add-Type -AssemblyName PresentationCore
    $img = $null
    for ($t = 0; $t -lt 5; $t++) {
        try {
            if ([System.Windows.Clipboard]::ContainsImage()) {
                $img = [System.Windows.Clipboard]::GetImage()
            }
            break
        }
        catch { Start-Sleep -Milliseconds 100 }
    }

    if ($null -ne $img) {
        # 剪贴板里有图，直接保存单张
        $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $name  = "图片_${stamp}-01.png"
        $dest  = Join-Path $OutDir $name
        $j = 2
        while (Test-Path -LiteralPath $dest) {
            $name = "图片_${stamp}-01_$j.png"
            $dest = Join-Path $OutDir $name
            $j++
        }
        $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $frame   = [System.Windows.Media.Imaging.BitmapFrame]::Create($img)
        $encoder.Frames.Add($frame)
        $stream  = [System.IO.File]::Create($dest)
        try { $encoder.Save($stream) } finally { $stream.Close() }
        try { [System.Windows.Clipboard]::Clear() } catch { }
        exit 0
    }

    # 剪贴板里也没有图片 -> 弹出提示
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show(
        "当前剪切板没有图片",
        "QuickClip",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
        [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly
    )
    exit 0
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$count = 0
foreach ($f in $files) {
    $count++
    $name = "图片_${stamp}-{0:d2}.png" -f $count
    $dest = Join-Path $OutDir $name
    $j = 2
    while (Test-Path -LiteralPath $dest) {
        $name = "图片_${stamp}-{0:d2}_{1}.png" -f $count, $j
        $dest = Join-Path $OutDir $name
        $j++
    }
    Move-Item -LiteralPath $f.FullName -Destination $dest
}

# 批量保存后清空剪贴板，避免最后一张残留导致重复
Add-Type -AssemblyName PresentationCore
try { [System.Windows.Clipboard]::Clear() } catch { }

if (-not $Silent) {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show(
        "已保存 $count 张图片到：`n$OutDir",
        "QuickClip",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
        [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly
    )
}