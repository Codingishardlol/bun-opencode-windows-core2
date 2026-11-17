param(
    [string]$Work = $(if ($env:CORE2_WORK) { $env:CORE2_WORK } else { "C:\b" })
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "patch-helpers.ps1")

$Root = Split-Path -Parent $PSScriptRoot
$OpenCodeTag = "v2.1.2"
$OpenCodeCommit = "a517687fde98a7329ada3ae644a01a9fc6c4e99e"

New-Item -ItemType Directory -Force $Work | Out-Null
$opencode = Join-Path $Work "opencode"

if (-not (Test-Path (Join-Path $opencode ".git"))) {
    if (Test-Path $opencode) {
        Remove-Item -Recurse -Force $opencode
    }
    git clone --depth 1 --branch $OpenCodeTag https://github.com/anomalyco/opencode.git $opencode
    if ($LASTEXITCODE -ne 0) { throw "git clone opencode failed" }
}

$head = (git -C $opencode rev-parse HEAD).Trim()
if ($head -ne $OpenCodeCommit) {
    throw "OpenCode is at $head, expected $OpenCodeCommit"
}

Invoke-GitPatch -Repo $opencode -Patch (Join-Path $Root "patches\opencode.patch")
Write-Host "OpenCode: $head"
