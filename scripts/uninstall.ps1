[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$CodexHome
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $CodexHome = $env:CODEX_HOME
    } else {
        $CodexHome = Join-Path $env:USERPROFILE '.codex'
    }
}

$CodexHome = [System.IO.Path]::GetFullPath($CodexHome)
$petsDir = [System.IO.Path]::GetFullPath((Join-Path $CodexHome 'pets'))
$targetDir = [System.IO.Path]::GetFullPath((Join-Path $petsDir 'xiaocheng'))

if ((Split-Path -Parent $targetDir) -ne $petsDir) {
    throw '卸载目标未位于 Codex Pets 目录中。'
}

if (-not (Test-Path -LiteralPath $targetDir)) {
    Write-Host '未找到已安装的小澄，无需卸载。'
    return
}

$manifestPath = Join-Path $targetDir 'pet.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw '目标目录缺少 pet.json，为避免误删已停止。'
}

$manifest = Get-Content -Raw -Encoding utf8 -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.id -ne 'xiaocheng') {
    throw '目标目录不属于小澄，拒绝删除。'
}

if ($PSCmdlet.ShouldProcess($targetDir, '卸载小澄·薄荷助手')) {
    Remove-Item -LiteralPath $targetDir -Recurse -Force
    Write-Host '小澄已卸载。'
}
