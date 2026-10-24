# gen_baseline.ps1 —— 生成组件基线，确保 assets/components 版本一致
#
# 稳定性改造：
# - 通过 repo root 解析，不依赖固定工作目录
# - 适合脚本统一目录布局

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
while ($root -and -not (Test-Path (Join-Path $root ".git"))) {
    $parent = Split-Path -Parent $root
    if ($parent -eq $root) { break }
    $root = $parent
}
if (-not $root) { $root = (Get-Location).Path }

$dirs = @(
    (Join-Path $root "assets\components"),
    (Join-Path $root "assets\components_Perfect"),
    (Join-Path $root "app\assets\components"),
    (Join-Path $root "app\assets\components_Perfect")
)
$out = Join-Path $root "assets\components\components.sha256"
if (-not (Test-Path (Split-Path -Parent $out))) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $out) | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { continue }
    Get-ChildItem -LiteralPath $d -File | Sort-Object Name | ForEach-Object {
        if ($_.Name -eq "components.sha256") { return }
        if ($_.Name -like "*.part") { return }
        $h = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower()
        $lines.Add("$h $($_.Name)")
    }
}

if ($lines.Count -eq 0) { throw "未在组件目录中发现任何文件，无法生成基线。" }
$bytes = [System.Text.Encoding]::ASCII.GetBytes(($lines -join "`n") + "`n")
[System.IO.File]::WriteAllBytes($out, $bytes)
Write-Host ("组件基线已生成：" + $out + "（" + $lines.Count + " 项）")
