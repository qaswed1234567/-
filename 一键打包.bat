# 兼容入口：统一打包脚本
#
# 由于历史脚本路径已迁移，保留这层分发，避免老脚本失效。

@echo off
chcp 65001 >nul
setlocal
set "ROOT=%~dp0"
set "TARGET=%ROOT%packaging\一键打包.bat"
if not exist "%TARGET%" (
    echo [X] 未找到目标脚本：%TARGET%
    exit /b 1
)
call "%TARGET%" %*
exit /b %ERRORLEVEL%
