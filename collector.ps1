# ============================================================
#  QuickClip — 后台收集器
#  作用：常驻后台监听剪贴板，把每次新复制的图片缓存到本地待存区，
#        之后用 save-all.ps1 一次性批量落盘。
#  注意：本脚本不清理剪贴板，方便你在别处照常 Ctrl+V 粘贴。
#  待存区：%LOCALAPPDATA%\QuickClip\staging
# ============================================================

$ErrorActionPreference = "Stop"

# ---------- 单实例保护：避免重复启动收集器导致图片被重复收藏 ----------
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, "QuickClip_Collector_Singleton", [ref]$createdNew)
if (-not $createdNew) {
    # 已有收集器在运行，直接退出，不再重复监听
    exit 0
}

Add-Type -AssemblyName PresentationCore

$baseDir = Join-Path $env:LOCALAPPDATA "QuickClip"
$staging = Join-Path $baseDir "staging"
if (-not (Test-Path -LiteralPath $staging)) {
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
}

# 记录自身 PID，便于 uninstall-collector.ps1 停止
[System.IO.File]::WriteAllText((Join-Path $baseDir "collector.pid"), "$PID")

# 剪贴板序号：每次复制 +1，用来判断是否出现了新内容
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Win32Clipboard {
    [DllImport("user32.dll")]
    public static extern uint GetClipboardSequenceNumber();
}
"@

$lastSeq = 0
try { $lastSeq = [Win32Clipboard]::GetClipboardSequenceNumber() } catch { }

while ($true) {
    try {
        $seq = [Win32Clipboard]::GetClipboardSequenceNumber()

        if ($seq -ne $lastSeq) {
            $lastSeq = $seq

            # 读取最新图片（带重试，应对剪贴板被浏览器短暂占用）
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
                $n = (Get-ChildItem -LiteralPath $staging -Filter *.png -ErrorAction SilentlyContinue).Count + 1
                $path = Join-Path $staging ("{0:d5}.png" -f $n)
                $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
                $frame   = [System.Windows.Media.Imaging.BitmapFrame]::Create($img)
                $encoder.Frames.Add($frame)
                $stream  = [System.IO.File]::Create($path)
                try { $encoder.Save($stream) } finally { $stream.Close() }
            }
        }
    }
    catch {
        # 任一步出错（读剪贴板 / PNG 编码 / 落盘）都不终止收集器，睡一觉后继续监听
    }

    Start-Sleep -Milliseconds 200
}