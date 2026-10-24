# gen_baseline.ps1 —— 生成 assets\components\components.sha256（组件完整性基线）
# 每行格式：<sha256小写> <文件名>（单空格分隔，文件名不含路径）
# 由 一键打包.bat 在打包前自动调用，保证基线始终与包内组件一致。

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dirs = @(
    (Join-Path $root "assets\components"),
    (Join-Path $root "assets\components_Perfect")
)
$out = Join-Path $root "assets\components\components.sha256"
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

if ($lines.Count -eq 0) { throw "两个组件目录里都没有文件" }
$bytes = [System.Text.Encoding]::ASCII.GetBytes(($lines -join "`n") + "`n")
[System.IO.File]::WriteAllBytes($out, $bytes)
Write-Host ("组件基线已生成：" + $out + "（" + $lines.Count + " 项）")
