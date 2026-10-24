@echo off
chcp 65001 >nul
setlocal
rem 鸭子工具箱源码一键打包脚本
rem 双击运行：复制到临时 ASCII 路径 -> apktool 重新打包 -> zipalign + apksigner 签名 -> 输出 APK 到桌面

set "SRC=%~dp0"
set "STAGE=C:\apkbuild"
set "WORK=C:\apkbuild\src"
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
  echo [X] 未找到 build-tools（需要 zipalign.exe 与 apksigner.bat）
  echo     请修改本脚本里的 SDKBT 变量，或用 sdkmanager 安装 build-tools
  goto fail
)
echo 使用 build-tools：%BT%

echo [1/5] 刷新组件完整性基线（assets\components\components.sha256）...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SRC%gen_baseline.ps1"
if errorlevel 1 goto fail

echo [2/5] 准备源码目录（ASCII 路径，避免中文路径编译失败）...
if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%"
if errorlevel 1 goto fail
robocopy "%SRC%assets" "%WORK%\assets" /E /R:0 /W:0 /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto fail
robocopy "%SRC%smali" "%WORK%\smali" /E /R:0 /W:0 /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto fail
robocopy "%SRC%res" "%WORK%\res" /E /R:0 /W:0 /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto fail
copy /y "%SRC%AndroidManifest.xml" "%WORK%\" >nul
if errorlevel 1 goto fail
copy /y "%SRC%apktool.yml" "%WORK%\" >nul
if errorlevel 1 goto fail
copy /y "%SRC%apktool.jar" "%WORK%\" >nul
if errorlevel 1 goto fail

echo [3/5] 重新打包（apktool）...
cd /d "%WORK%"
java -jar apktool.jar build "%WORK%" -o "%STAGE%\unsigned.apk" -f
if errorlevel 1 goto fail

echo [4/5] 对齐 + 签名（zipalign 再 apksigner）...
"%BT%\zipalign.exe" -f 4 "%STAGE%\unsigned.apk" "%STAGE%\aligned.apk"
if errorlevel 1 goto fail
call "%BT%\apksigner.bat" sign --ks "%SRC%yazi.keystore" --ks-key-alias yazi --ks-pass pass:yazi2026 --key-pass pass:yazi2026 --out "%STAGE%\signed.apk" "%STAGE%\aligned.apk"
if errorlevel 1 goto fail
copy /y "%STAGE%\signed.apk" "%OUTPUT%" >nul
if errorlevel 1 goto fail

echo.
echo [5/5] 完成！已签名 APK 输出到：%OUTPUT%
echo       中间产物：%STAGE%\unsigned.apk、%STAGE%\aligned.apk、%STAGE%\signed.apk
goto end

:fail
echo.
echo [X] 打包失败：没有生成可安装的 APK。
echo     注意：签名工具缺失时本脚本不再输出未签名 APK（未签名包无法安装）。
goto end

:end
pause
