# build_java.ps1 —— 把 java/ 下源码编译成 smali 并回填到 smali/
#
# 稳定性改造：
# - 统一通过 scripts/_common.ps1 解析仓库根目录和 SDK 路径
# - 不再依赖单一硬编码的 Windows 用户目录
# - 兼容历史脚本入口，便于后续迁移到 app/ 目录结构

param([string]$Template = "")

$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "_common.ps1")

$root = Get-RepoRoot
$srcDir = Join-Path $root "app\java"
if (-not (Test-Path $srcDir)) {
    $srcDir = Join-Path $root "java"
}

$work = Join-Path $root "build_java"
$classes = Join-Path $work "classes"
$dexDir = Join-Path $work "dex"
$outDir = Join-Path $work "out"
$fakeApk = Join-Path $work "fake.apk"
$smaliRoot = Join-Path $root "smali\com\yazi\toolbox"
if (-not (Test-Path $smaliRoot)) {
    $smaliRoot = Join-Path $root "app\smali\com\yazi\toolbox"
}
$apktool = Join-Path $root "apktool.jar"
if (-not (Test-Path $apktool)) {
    $apktool = Join-Path $root "tools\apktool.jar"
}

function Say($m) { Write-Host $m }

$androidJar = Find-AndroidJar
$buildTools = Find-BuildTools
$templateApk = ""
if ($Template -ne "" -and (Test-Path $Template)) {
    $templateApk = (Resolve-Path $Template).Path
} else {
    $cands = @(
        (Join-Path $root "_template.apk"),
        (Join-Path $root "assets\_template.apk"),
        (Join-Path $env:USERPROFILE "Desktop\鸭子工具箱-新包.apk"),
        (Join-Path $env:USERPROFILE "Desktop\鸭子工具箱.apk")
    )
    foreach ($c in $cands) {
        if ($c -and (Test-Path $c)) { $templateApk = (Resolve-Path $c).Path; break }
    }
}
if (-not $templateApk) { throw "找不到模板 APK：请提供 _template.apk 或在桌面放置模板包。" }

Say "[1/4] 准备目录"
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $classes, $dexDir | Out-Null

Say "[2/4] 编译 Java"
$javaFiles = Get-ChildItem -Path $srcDir -Recurse -Filter *.java -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
if (-not $javaFiles) { throw "$srcDir 下没有 .java 文件" }
& javac -nowarn -Xlint:none -source 8 -target 8 -bootclasspath $androidJar -d $classes $javaFiles
if ($LASTEXITCODE -ne 0) { throw "javac 失败" }

Say "[3/4] 生成 dex 并回填 smali"
$classFiles = Get-ChildItem -Path $classes -Recurse -Filter *.class | ForEach-Object { $_.FullName }
& (Join-Path $buildTools "d8.bat") --min-api 23 --lib $androidJar --output $dexDir $classFiles
if ($LASTEXITCODE -ne 0) { throw "d8 失败" }
$newDex = Join-Path $dexDir "classes.dex"
if (-not (Test-Path $newDex)) { throw "d8 未产出 classes.dex" }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Copy-Item -LiteralPath $templateApk -Destination $fakeApk -Force
$zip = [System.IO.Compression.ZipFile]::Open($fakeApk, [System.IO.Compression.ZipArchiveMode]::Update)
$old = $zip.GetEntry("classes.dex")
if ($old) { $old.Delete() }
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $newDex, "classes.dex", [System.IO.Compression.CompressionLevel]::NoCompression) | Out-Null
$zip.Dispose()

& java -jar $apktool d -r -f $fakeApk -o $outDir | Out-Null
if ($LASTEXITCODE -ne 0) { throw "apktool 反汇编失败" }
$srcSmali = Join-Path $outDir "smali"
if (-not (Test-Path $srcSmali)) { throw "没有产出 smali 目录" }

New-Item -ItemType Directory -Force -Path $smaliRoot | Out-Null
Get-ChildItem -Path $smaliRoot -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
Get-ChildItem -Path $srcSmali -Recurse -Filter *.smali | ForEach-Object {
    $relative = $_.FullName.Substring($srcSmali.Length + 1)
    $dest = Join-Path $smaliRoot $relative
    $dir = Split-Path -Parent $dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
}

Remove-Item -LiteralPath $fakeApk -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $outDir -Recurse -Force -ErrorAction SilentlyContinue

Say "[4/4] 完成：Smali 已回填到 $smaliRoot"
Say "接下来请重新打包，并根据需要重新执行 RegenIntegrity.java。"
