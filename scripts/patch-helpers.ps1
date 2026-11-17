function Invoke-GitPatch {
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string]$Patch
    )

    if (-not (Test-Path $Patch)) {
        throw "Patch not found: $Patch"
    }

    git -C $Repo apply --check --whitespace=nowarn $Patch 2>$null
    if ($LASTEXITCODE -eq 0) {
        git -C $Repo apply --whitespace=nowarn $Patch
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to apply $Patch to $Repo"
        }
        Write-Host "Applied $Patch"
        return
    }

    git -C $Repo apply --reverse --check --whitespace=nowarn $Patch 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Already applied: $Patch"
        return
    }

    throw "Patch does not apply (and is not already applied): $Patch -> $Repo"
}
