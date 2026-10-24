@echo off
chcp 65001 >nul
setlocal
rem 真正的构建入口：统一打包流程
set "ROOT=%~dp0.."
set "WORK=%ROOT%\app"
set "SRC=%ROOT%"
set "STAGE=C:\apkbuild"
set "OUTPUT=%USERPROFILE%\Desktop\鸭子工具箱-新包.apk"

set "SDKBT=D:\Android\Sdk\build-tools"
set "BT="
if exist "%SDKBT%\35.0.0\zipalign.exe" set "BT=%SDKBT%\35.0.0"
if not defined BT (
  for /f "delims=" %%D in ('dir /b /ad /o-n "%SDKBT%" 2^>nul') do (
    if not defined BT if exist "%SDKBT%\%%D\zipalign.exe" set "BT=%SDKBT%\%%D"
  )
)
if not defined BT (
  echo [X] 未找到 build-tools
  exit /b 1
)

echo [1/5] 刷新组件基线
powershell -NoProfile -ExecutionPolicy Bypass -File "%SRC%\scripts\packaging\gen_baseline.ps1"
if errorlevel 1 goto fail

echo [2/5] 确认工程目录
if not exist "%WORK%\assets" mkdir "%WORK%\assets"
if not exist "%WORK%\res" mkdir "%WORK%\res"
if not exist "%WORK%\smali" mkdir "%WORK%\smali"
if not exist "%WORK%\java" mkdir "%WORK%\java"

echo [3/5] 组装打包目录
if exist "%STAGE%\src" rmdir /s /q "%STAGE%\src"
mkdir "%STAGE%\src"
robocopy "%ROOT%\app\assets" "%STAGE%\src\assets" /E /R:0 /W:0 /NFL /NDL /NJH /NJS /NP >nul
robocopy "%ROOT%\app\smali" "%STAGE%\src\smali" /E /R:0 /W:0 /NFL /NDL /NJH /NJS /NP >nul
robocopy "%ROOT%\app\res" "%STAGE%\src\res" /E /R:0 /W:0 /NFL /NDL /NJH /NJS /NP >nul
copy /y "%ROOT%\AndroidManifest.xml" "%STAGE%\src\" >nul
copy /y "%ROOT%\apktool.yml" "%STAGE%\src\" >nul
copy /y "%ROOT%\apktool.jar" "%STAGE%\src\" >nul

echo [4/5] 执行 apktool 构建
cd /d "%STAGE%\src"
java -jar apktool.jar build "%STAGE%\src" -o "%STAGE%\unsigned.apk" -f
if errorlevel 1 goto fail

echo [5/5] 对齐 + 签名
"%BT%\zipalign.exe" -f 4 "%STAGE%\unsigned.apk" "%STAGE%\aligned.apk"
if errorlevel 1 goto fail
call "%BT%\apksigner.bat" sign --ks "%ROOT%\yazi.keystore" --ks-key-alias yazi --ks-pass pass:yazi2026 --key-pass pass:yazi2026 --out "%STAGE%\signed.apk" "%STAGE%\aligned.apk"
if errorlevel 1 goto fail
copy /y "%STAGE%\signed.apk" "%OUTPUT%" >nul
if errorlevel 1 goto fail

echo.
echo 完成：APK 已输出到 %OUTPUT%
goto end

:fail
echo.
echo [X] 打包失败：工程目录或签名工具缺失。
goto end

:end
pause
