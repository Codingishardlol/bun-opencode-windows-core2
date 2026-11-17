param(
    [string]$Work = $(if ($env:CORE2_WORK) { $env:CORE2_WORK } else { "C:\b" })
)

$ErrorActionPreference = "Stop"

function Assert-PenrynFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Expected build file is missing: $Path"
    }
    if (Select-String -Path $Path -Pattern "-march=nehalem" -SimpleMatch -Quiet) {
        throw "Found -march=nehalem in $Path"
    }
    if (-not (Select-String -Path $Path -Pattern "-march=penryn" -SimpleMatch -Quiet)) {
        throw "Found no -march=penryn in $Path"
    }
    Write-Host "Penryn OK: $Path"
}

$build = Join-Path $Work "bun\build\release"
Assert-PenrynFile (Join-Path $build "compile_commands.json")
Assert-PenrynFile (Join-Path $build "deps\WebKit\compile_commands.json")

$icu = Join-Path $build "deps\WebKit\icu"
Assert-PenrynFile (Join-Path $icu "source\common\common.vcxproj")
foreach ($lib in @("sicudt.lib", "icuin.lib", "icuuc.lib")) {
    $path = Join-Path $icu "lib\$lib"
    if (-not (Test-Path $path)) {
        throw "ICU library is missing: $path"
    }
    if ((Get-Item $path).Length -eq 0) {
        throw "ICU library is empty: $path"
    }
    Write-Host "ICU OK: $path"
}
