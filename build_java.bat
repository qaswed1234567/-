@echo off
chcp 65001 >nul
setlocal

rem 兼容入口：调用新的脚本目录；避免根目录脚本长期失效。
set "ROOT=%~dp0"
set "TARGET=%ROOT%scripts\build\build_java.bat"
if not exist "%TARGET%" (
    echo [X] 未找到目标脚本：%TARGET%
    exit /b 1
)
call "%TARGET%" %*
exit /b %ERRORLEVEL%
