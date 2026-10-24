# build_java.ps1 —— 把 java\ 下的源码编译成 smali 并放回 smali\（鸭子工具箱）
#
# 为什么需要它：本工程是 apktool 反编译产物，只认 smali。新功能用正规 Java 写更好维护，
# 于是用 javac + d8 编出 dex，再借 apktool 反汇编成 smali 回填。
#
# 用法：build_java.bat            （自动找模板 APK）
#       build_java.bat <某个 apk>  （指定模板 APK，需要是一个能正常反编译的完整包）
#
# 注意：改完 smali 后必须重新打包，并用 RegenIntegrity.java 重算 assets/integrity.bin。

param([string]$Template = "")

$ErrorActionPreference = "Stop"

$root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcDir  = Join-Path $root "java"
$work    = Join-Path $root "build_java"
$classes = Join-Path $work "classes"
$dexDir  = Join-Path $work "dex"
$outDir  = Join-Path $work "out"
$fakeApk = Join-Path $work "fake.apk"
$apktool = Join-Path $root "apktool.jar"
$smali   = Join-Path $root "smali\com\yazi\toolbox"

function Say($m) { Write-Host $m }

function Find-AndroidJar {
    $pk = "D:\Android\Sdk\platforms"
    if (-not (Test-Path $pk)) { throw "找不到 $pk，请先安装 Android SDK Platform" }
    foreach ($p in @("android-36", "android-35", "android-34")) {
        $j = Join-Path $pk "$p\android.jar"
        if (Test-Path $j) { return $j }
    }
    $d = Get-ChildItem $pk -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($d) {
        $j = Join-Path $d.FullName "android.jar"
        if (Test-Path $j) { return $j }
    }
    throw "$pk 下没有找到 android.jar"
}

function Find-BuildTools {
    $bt = "D:\Android\Sdk\build-tools"
    if (-not (Test-Path $bt)) { throw "找不到 $bt" }
    if (Test-Path "$bt\35.0.0\d8.bat") { return "$bt\35.0.0" }
    foreach ($d in (Get-ChildItem $bt -Directory | Sort-Object Name -Descending)) {
        if (Test-Path (Join-Path $d.FullName "d8.bat")) { return $d.FullName }
    }
    throw "$bt 下没有找到 d8.bat"
}

function Find-Template([string]$given) {
    if ($given -ne "" -and (Test-Path $given)) { return (Resolve-Path $given).Path }
    $cands = @(
        (Join-Path $root "_template.apk"),
        (Join-Path $env:USERPROFILE "Desktop\鸭子工具箱-新包.apk"),
        (Join-Path $env:USERPROFILE "Desktop\鸭子工具箱.apk")
    )
    foreach ($c in $cands) { if (Test-Path $c) { return (Resolve-Path $c).Path } }
    throw "找不到模板 APK：请先双击 一键打包.bat 生成一个包，或把某个完整 APK 放到工程根目录并命名为 _template.apk"
}

$androidJar = Find-AndroidJar
$buildTools = Find-BuildTools
$templateApk = Find-Template $Template

Say "[1/6] 准备目录"
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $classes, $dexDir | Out-Null

Say "[2/6] javac 编译（android.jar = $androidJar）"
$javaFiles = Get-ChildItem -Path $srcDir -Recurse -Filter *.java | ForEach-Object { $_.FullName }
if (-not $javaFiles) { throw "$srcDir 下没有 .java" }
& javac -nowarn -Xlint:none -source 8 -target 8 -bootclasspath $androidJar -d $classes $javaFiles
if ($LASTEXITCODE -ne 0) { throw "javac 失败" }

Say "[3/6] d8 生成 dex"
$classFiles = Get-ChildItem -Path $classes -Recurse -Filter *.class | ForEach-Object { $_.FullName }
& (Join-Path $buildTools "d8.bat") --min-api 23 --lib $androidJar --output $dexDir $classFiles
if ($LASTEXITCODE -ne 0) { throw "d8 失败" }
$newDex = Join-Path $dexDir "classes.dex"
if (-not (Test-Path $newDex)) { throw "d8 没有产出 classes.dex" }

Say "[4/6] 把新 dex 换进模板包副本（$templateApk）"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Copy-Item -LiteralPath $templateApk -Destination $fakeApk -Force
$zip = [System.IO.Compression.ZipFile]::Open($fakeApk, [System.IO.Compression.ZipArchiveMode]::Update)
$old = $zip.GetEntry("classes.dex")
if ($old) { $old.Delete() }
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $newDex, "classes.dex", [System.IO.Compression.CompressionLevel]::NoCompression) | Out-Null
$zip.Dispose()

Say "[5/6] apktool 反汇编出 smali"
& java -jar $apktool d -r -f $fakeApk -o $outDir | Out-Null
if ($LASTEXITCODE -ne 0) { throw "apktool 反汇编失败" }
$srcSmali = Join-Path $outDir "smali"
if (-not (Test-Path $srcSmali)) { throw "没有产出 smali 目录" }

Say "[6/6] 回填到 $smali"
# 先删掉旧的同名 smali（含内部类），避免留下已改名的残留
Get-ChildItem -Path $smali -Filter "Yazi*.smali" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Force
    Say ("  删除旧文件 " + $_.Name)
}
$copied = 0
Get-ChildItem -Path $srcSmali -Recurse -Filter *.smali | ForEach-Object {
    $dst = Join-Path $smali $_.Name
    Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
    Say ("  写入 " + $_.Name)
    $copied++
}
if ($copied -eq 0) { throw "没有回填任何 smali" }

# 清掉大块中间产物：fake.apk 是模板副本、out 里有整份 assets，加起来 80MB+
Remove-Item -LiteralPath $fakeApk -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $outDir -Recurse -Force -ErrorAction SilentlyContinue

Say ""
Say "完成：共回填 $copied 个 smali 文件。"
Say "接下来请：1) 双击 一键打包.bat 重新打包  2) 用 RegenIntegrity.java 重算 integrity.bin（见 修复说明.md 第 3 节）"
