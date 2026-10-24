# 公共脚本工具库
#
# 说明：
# - 统一解析仓库根目录
# - 统一查找 Android SDK / build-tools
# - 统一返回基于脚本位置的绝对路径

param()

function Get-RepoRoot {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    while ($here -and -not (Test-Path (Join-Path $here ".git"))) {
        $parent = Split-Path -Parent $here
        if ($parent -eq $here) { break }
        $here = $parent
    }
    if (-not $here) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    return (Resolve-Path $here).Path
}

function Find-AndroidSdkRoot {
    $cands = @(
        "D:\Android\Sdk",
        "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk",
        "$env:LOCALAPPDATA\Android\Sdk",
        "$env:ANDROID_HOME"
    )
    foreach ($p in $cands) {
        if ($p -and (Test-Path $p)) { return (Resolve-Path $p).Path }
    }
    throw "未找到 Android SDK，请确认已安装 Android Studio / SDK。"
}

function Find-AndroidJar {
    $sdk = Find-AndroidSdkRoot
    $platforms = Join-Path $sdk "platforms"
    if (-not (Test-Path $platforms)) {
        throw "未找到 SDK 平台目录：$platforms"
    }
    foreach ($v in @("android-36", "android-35", "android-34", "android-33")) {
        $jar = Join-Path $platforms "$v\android.jar"
        if (Test-Path $jar) { return $jar }
    }
    $best = Get-ChildItem $platforms -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($best) {
        $jar = Join-Path $best.FullName "android.jar"
        if (Test-Path $jar) { return $jar }
    }
    throw "未找到 android.jar，请安装 Android SDK Platform。"
}

function Find-BuildTools {
    $sdk = Find-AndroidSdkRoot
    $btRoot = Join-Path $sdk "build-tools"
    if (-not (Test-Path $btRoot)) {
        throw "未找到 build-tools：$btRoot"
    }
    $cands = @(
        (Join-Path $btRoot "35.0.0"),
        (Join-Path $btRoot "34.0.0"),
        (Join-Path $btRoot "33.0.3")
    )
    foreach ($d in $cands) {
        if (Test-Path (Join-Path $d "d8.bat")) { return $d }
        if (Test-Path (Join-Path $d "zipalign.exe")) { return $d }
    }
    $best = Get-ChildItem $btRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($best) { return $best.FullName }
    throw "未找到 build-tools 中的 d8/zipalign/apksigner。"
}

function Resolve-PathInRepo {
    param([string]$RelativePath)
    $root = Get-RepoRoot
    return (Join-Path $root $RelativePath)
}
