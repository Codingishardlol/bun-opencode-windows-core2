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
    git clone -c core.autocrlf=false -c core.eol=lf --depth 1 --branch $OpenCodeTag https://github.com/anomalyco/opencode.git $opencode
    if ($LASTEXITCODE -ne 0) { throw "git clone opencode failed" }
}

$head = (git -C $opencode rev-parse HEAD).Trim()
if ($head -ne $OpenCodeCommit) {
    throw "OpenCode is at $head, expected $OpenCodeCommit"
}

Invoke-GitPatch -Repo $opencode -Patch (Join-Path $Root "patches\opencode.patch")

# OpenCode v2.1.2 ships patches/@silvia-odwyer%2Fphoton-node@0.3.4.patch with one extra leading space on the three
# context lines of its last hunk, so `bun install` stops with "hunk #10 does not apply to photon_rs.js". Stock Bun
# 1.4.4 on Linux fails the same way against the published package, so this is not specific to our Bun or to Windows.
# Repair the three context lines (the +/- lines are untouched) so the patch applies as intended.
$photonPatch = Join-Path $opencode "patches\@silvia-odwyer%2Fphoton-node@0.3.4.patch"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$photonText = [System.IO.File]::ReadAllText($photonPatch).Replace("`r`n", "`n")
$photonBad  = "`n      ;`n  };`n  `n-const path = require('path').join(__dirname, 'photon_rs_bg.wasm');"
$photonGood = "`n     ;`n };`n `n-const path = require('path').join(__dirname, 'photon_rs_bg.wasm');"
if ($photonText.Contains($photonBad)) {
    $photonText = $photonText.Replace($photonBad, $photonGood)
    Write-Host "Repaired photon-node patch context"
} elseif (-not $photonText.Contains($photonGood)) {
    throw "photon-node patch has unexpected content; cannot repair hunk 10"
}
[System.IO.File]::WriteAllText($photonPatch, $photonText, $utf8NoBom)
Write-Host "OpenCode: $head"
