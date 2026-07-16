[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$CodexHome,
    [switch]$Force
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
$repoRoot = Split-Path -Parent $PSScriptRoot
$packageDir = Join-Path $repoRoot 'pet'
$sourceManifestPath = Join-Path $packageDir 'pet.json'
$sourceSpritesheetPath = Join-Path $packageDir 'spritesheet.webp'

if (-not (Test-Path -LiteralPath $sourceManifestPath) -or -not (Test-Path -LiteralPath $sourceSpritesheetPath)) {
    throw '仓库中的 pet 安装包不完整。'
}

$sourceManifest = Get-Content -Raw -Encoding utf8 -LiteralPath $sourceManifestPath | ConvertFrom-Json
if ($sourceManifest.id -ne 'xiaocheng' -or $sourceManifest.spritesheetPath -ne 'spritesheet.webp') {
    throw 'pet.json 不是预期的小澄清单。'
}
if (
    -not ($sourceManifest.PSObject.Properties.Name -contains 'spriteVersionNumber') -or
    [int]$sourceManifest.spriteVersionNumber -ne 2
) {
    throw 'pet.json 不是小澄 V2 清单，要求 spriteVersionNumber=2。'
}

$petsDir = Join-Path $CodexHome 'pets'
$targetDir = Join-Path $petsDir 'xiaocheng'
$targetDir = [System.IO.Path]::GetFullPath($targetDir)

if ((Split-Path -Parent $targetDir) -ne [System.IO.Path]::GetFullPath($petsDir)) {
    throw '安装目标未位于 Codex Pets 目录中。'
}

if (Test-Path -LiteralPath $targetDir) {
    if (-not $Force) {
        throw "目标已存在：$targetDir。确认是小澄后使用 -Force 覆盖。"
    }

    $existingManifestPath = Join-Path $targetDir 'pet.json'
    if (-not (Test-Path -LiteralPath $existingManifestPath)) {
        throw '目标目录缺少 pet.json，为避免覆盖未知文件已停止。'
    }
    $existingManifest = Get-Content -Raw -Encoding utf8 -LiteralPath $existingManifestPath | ConvertFrom-Json
    if ($existingManifest.id -ne 'xiaocheng') {
        throw '目标目录属于其他宠物，拒绝覆盖。'
    }
}

if ($PSCmdlet.ShouldProcess($targetDir, '安装小澄·薄荷助手')) {
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Copy-Item -LiteralPath $sourceManifestPath -Destination (Join-Path $targetDir 'pet.json') -Force
    Copy-Item -LiteralPath $sourceSpritesheetPath -Destination (Join-Path $targetDir 'spritesheet.webp') -Force

    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceSpritesheetPath).Hash
    $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $targetDir 'spritesheet.webp')).Hash
    if ($sourceHash -ne $targetHash) {
        throw '安装后的图集哈希不一致。'
    }

    Write-Host "已安装到：$targetDir"
    Write-Host '请在 Settings → Pets 中点击 Refresh，然后选择“小澄·薄荷助手”。'
}
