param(
    [string]$Work = $(if ($env:CORE2_WORK) { $env:CORE2_WORK } else { "C:\b" })
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "patch-helpers.ps1")

$Root = Split-Path -Parent $PSScriptRoot
$BunTag = "bun-v1.4.4"
$BunCommit = "38afee6c84fcf48c0edb2466aa4b27d287a59c30"
$WebKitCommit = "d6375c72affe0f70222cdcb45012b10f0bf3a9d5"

New-Item -ItemType Directory -Force $Work | Out-Null
$bun = Join-Path $Work "bun"

if (-not (Test-Path (Join-Path $bun ".git"))) {
    if (Test-Path $bun) {
        Remove-Item -Recurse -Force $bun
    }
    git clone --depth 1 --branch $BunTag https://github.com/oven-sh/bun.git $bun
    if ($LASTEXITCODE -ne 0) { throw "git clone bun failed" }
}

$bunHead = (git -C $bun rev-parse HEAD).Trim()
if ($bunHead -ne $BunCommit) {
    Write-Host "Bun is at $bunHead, fetching $BunTag"
    git -C $bun fetch --depth 1 origin "refs/tags/$BunTag"
    if ($LASTEXITCODE -ne 0) { throw "git fetch bun $BunTag failed" }
    git -C $bun checkout --detach $BunCommit
    if ($LASTEXITCODE -ne 0) { throw "git checkout bun $BunCommit failed" }
}

$webkit = Join-Path $bun "vendor\WebKit"
if (-not (Test-Path (Join-Path $webkit ".git"))) {
    if (Test-Path $webkit) {
        Remove-Item -Recurse -Force $webkit
    }
    New-Item -ItemType Directory -Force $webkit | Out-Null
    git -C $webkit init
    git -C $webkit fetch --depth 1 https://github.com/oven-sh/WebKit.git $WebKitCommit
    if ($LASTEXITCODE -ne 0) { throw "git fetch WebKit $WebKitCommit failed" }
    git -C $webkit checkout --detach FETCH_HEAD
    if ($LASTEXITCODE -ne 0) { throw "git checkout WebKit failed" }
}

$webkitHead = (git -C $webkit rev-parse HEAD).Trim()
if ($webkitHead -ne $WebKitCommit) {
    Write-Host "WebKit is at $webkitHead, fetching $WebKitCommit"
    git -C $webkit fetch --depth 1 https://github.com/oven-sh/WebKit.git $WebKitCommit
    if ($LASTEXITCODE -ne 0) { throw "git fetch WebKit $WebKitCommit failed" }
    git -C $webkit checkout --detach $WebKitCommit
    if ($LASTEXITCODE -ne 0) { throw "git checkout WebKit $WebKitCommit failed" }
}

Invoke-GitPatch -Repo $bun -Patch (Join-Path $Root "patches\bun-windows-penryn.patch")
Invoke-GitPatch -Repo $webkit -Patch (Join-Path $Root "patches\webkit-penryn-icu.patch")

Write-Host "Bun:    $bunHead"
Write-Host "WebKit: $webkitHead"
