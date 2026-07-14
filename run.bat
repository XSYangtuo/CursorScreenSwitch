@echo off
chcp 65001 >nul
title Screen Switch Launcher

:: 查找 AHK v2 安装路径
set "AHK_PATH=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
if not exist "%AHK_PATH%" set "AHK_PATH=%ProgramFiles%\AutoHotkey\v2\AutoHotkey.exe"
if not exist "%AHK_PATH%" set "AHK_PATH=%ProgramFiles(x86)%\AutoHotkey\v2\AutoHotkey64.exe"
if not exist "%AHK_PATH%" set "AHK_PATH=%ProgramFiles(x86)%\AutoHotkey\v2\AutoHotkey.exe"

:: 如果没找到，提示安装
if not exist "%AHK_PATH%" (
    echo [ERROR] AutoHotkey v2 未找到
    echo.
    echo 请先安装 AutoHotkey v2:
    echo   https://www.autohotkey.com/
    echo.
    pause
    exit /b 1
)

:: 启动脚本
start "" "%AHK_PATH%" "%~dp0screen_switch.ahk"
exit /b 0
