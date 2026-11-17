function Invoke-GitPatch {
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string]$Patch
    )

    if (-not (Test-Path $Patch)) {
        throw "Patch not found: $Patch"
    }

    # Windows checkouts can convert .patch files to CRLF; git apply rejects
    # CRLF patches. Always feed git an LF-normalized copy.
    $tempRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }
    $normalized = Join-Path $tempRoot ([IO.Path]::GetFileName($Patch) + ".lf")
    $content = [IO.File]::ReadAllText($Patch).Replace("`r`n", "`n")
    [IO.File]::WriteAllText($normalized, $content, [Text.UTF8Encoding]::new($false))

    $check = (git -C $Repo apply --check --whitespace=nowarn $normalized 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -eq 0) {
        $applied = (git -C $Repo apply --whitespace=nowarn $normalized 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to apply $Patch to $Repo`n$applied"
        }
        Write-Host "Applied $Patch"
        return
    }

    $reverse = (git -C $Repo apply --reverse --check --whitespace=nowarn $normalized 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Already applied: $Patch"
        return
    }

    throw "Patch does not apply (and is not already applied): $Patch -> $Repo`n$check`n$reverse"
}
