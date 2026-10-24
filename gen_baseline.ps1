# 兼容入口：旧根目录脚本稳定化
#
# 目的：保留现有调用方式，同时统一转发到新目录结构。

@echo off
chcp 65001 >nul
setlocal
set "ROOT=%~dp0"
set "TARGET=%ROOT%scripts\packaging\gen_baseline.ps1"
if not exist "%TARGET%" (
    echo [X] 未找到目标脚本：%TARGET%
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TARGET%" %*
exit /b %ERRORLEVEL%
