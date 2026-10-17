@echo off
chcp 65001 >nul
title QuickClip 启动

echo.
echo 正在启动后台收集器...
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0collector.ps1"

echo 后台收集器已启动（在后台运行）。
echo 之后复制图片会自动收集，到目标文件夹右键即可保存。
echo 本窗口 3 秒后自动关闭。
timeout /t 3 >nul