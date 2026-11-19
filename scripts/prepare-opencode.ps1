param(
    [string]$Work = $(if ($env:CORE2_WORK) { $env:CORE2_WORK } else { "C:\b" })
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "patch-helpers.ps1")

$Root = Split-Path -Parent $PSScriptRoot
$OpenCodeTag = "v2.3.1"
$OpenCodeCommit = "c769de83007e3584b5b395176c9fcde2d3231e88"

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

# OpenCode v2.1.2 shipped patches/@silvia-odwyer%2Fphoton-node@0.3.4.patch with one extra leading space on the
# three context lines of its last hunk, so `bun install` stopped with "hunk #10 does not apply to photon_rs.js".
# v2.3.1 ships that patch correctly, so only repair it when the old bad spacing is actually present.
$photonPatch = Join-Path $opencode "patches\@silvia-odwyer%2Fphoton-node@0.3.4.patch"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$photonText = [System.IO.File]::ReadAllText($photonPatch).Replace("`r`n", "`n")
$photonBad  = "`n      ;`n  };`n  `n-const path = require('path').join(__dirname, 'photon_rs_bg.wasm');"
$photonGood = "`n     ;`n };`n `n-const path = require('path').join(__dirname, 'photon_rs_bg.wasm');"
if ($photonText.Contains($photonBad)) {
    $photonText = $photonText.Replace($photonBad, $photonGood)
    [System.IO.File]::WriteAllText($photonPatch, $photonText, $utf8NoBom)
    Write-Host "Repaired photon-node patch context"
} else {
    Write-Host "photon-node patch needs no repair"
}
Write-Host "OpenCode: $head"
