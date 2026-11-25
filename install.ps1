# Installs the Penryn (Core 2) build of Bun 1.4.4 + OpenCode 2.4.1.
# Usage: irm https://raw.githubusercontent.com/Codingishardlol/bun-opencode-windows-core2/main/install.ps1 | iex
$ErrorActionPreference = "Stop"

$tag = "v1.4.4-opencode-2.4.1-penryn"
$base = "https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/download/$tag"
$dir = Join-Path $env:LOCALAPPDATA "core2\bin"
New-Item -ItemType Directory -Force $dir | Out-Null

$files = [ordered]@{
    "bun.exe"           = "076ba81d8197bd0cf2c584890598228fab9cd4736612cc702cdabef1573c78e7"
    "opencode.exe"      = "90b7561dad6aa27e1464d5e3bb6888171ac07796889a03e748b819ce7e24a9d1"
    "runtime-smoke.mjs" = "2ae7fce6ee469b801aead420505a012fa919de144e5713c003176afcb89141ec"
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

$oldProgress = $ProgressPreference
$ProgressPreference = "SilentlyContinue"
try {
    foreach ($name in $files.Keys) {
        $dest = Join-Path $dir $name
        Write-Host "Downloading $name ..."
        Invoke-WebRequest -Uri "$base/$name" -OutFile $dest -UseBasicParsing
        Unblock-File -Path $dest -ErrorAction SilentlyContinue
        $hash = (Get-FileHash -Path $dest -Algorithm SHA256).Hash.ToLower()
        if ($hash -ne $files[$name]) {
            throw "SHA-256 mismatch for $name`n  expected $($files[$name])`n  actual   $hash"
        }
    }
} finally {
    $ProgressPreference = $oldProgress
}

Write-Host ""
Write-Host "Testing the downloaded binaries ..."

$bun = Join-Path $dir "bun.exe"
$oc = Join-Path $dir "opencode.exe"
$smokeFile = Join-Path $dir "runtime-smoke.mjs"

$version = (& $bun --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $version -ne "1.4.4") {
    throw "bun.exe --version failed (exit $LASTEXITCODE): $version"
}
Write-Host "bun --version: $version"

$smoke = (& $bun $smokeFile 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $smoke -notmatch "CORE2_RUNTIME_OK") {
    throw "runtime-smoke.mjs failed (exit $LASTEXITCODE):`n$smoke"
}
Write-Host $smoke

$ocVersion = (& $oc --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "opencode.exe --version failed (exit $LASTEXITCODE): $ocVersion"
}
Write-Host "opencode --version: $ocVersion"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
$parts = @($userPath -split ";" | Where-Object { $_ -ne "" })
$already = $parts | Where-Object { $_.TrimEnd("\") -ieq $dir.TrimEnd("\") }
if (-not $already) {
    $newPath = (@($parts) + $dir) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added $dir to the user PATH."
} else {
    Write-Host "$dir is already on the user PATH."
}

[Environment]::SetEnvironmentVariable("OPENCODE_DISABLE_AUTOUPDATE", "1", "User")
$env:OPENCODE_DISABLE_AUTOUPDATE = "1"

Write-Host ""
Write-Host "Installed to $dir"
Write-Host "Open a NEW PowerShell window, then run: opencode"
Write-Host "Do not run 'bun upgrade' or 'opencode upgrade'."
