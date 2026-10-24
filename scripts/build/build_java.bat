@echo off
chcp 65001 >nul
rem 鸭子工具箱 Java 扩展编译脚本（把 java\ 编成 smali 回填到 smali\）
rem 用法：双击本文件；或 build_java.bat <模板apk路径>
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_java.ps1" %*
echo.
pause
