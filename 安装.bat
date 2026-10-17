@echo off
chcp 65001 >nul
title QuickClip 安装

echo.
echo ==============================================
echo    QuickClip 一键安装
echo    将会完成：
echo      1) 添加右键菜单
echo      2) 安装后台收集器
echo ==============================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-menu.ps1"
if errorlevel 1 (
    echo.
    echo [失败] 添加右键菜单时出错，请检查文件是否完整。
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-collector.ps1"
if errorlevel 1 (
    echo.
    echo [失败] 安装后台收集器时出错，请检查文件是否完整。
    echo.
    pause
    exit /b 1
)

echo.
echo 安装完成！
echo 建议注销重登一次。之后即可正常使用。
echo （Win11 右键菜单需点「显示更多选项」查看）
echo.
pause