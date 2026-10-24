@echo off
chcp 65001 >nul
setlocal
rem 兼容入口：旧根目录调用方式 -> 新真实 APK 工程目录
set "ROOT=%~dp0"
set "TARGET=%ROOT%packaging\一键打包.bat"
if not exist "%TARGET%" (
    echo [X] 未找到目标入口：%TARGET%
    exit /b 1
)
call "%TARGET%" %*
exit /b %ERRORLEVEL%
