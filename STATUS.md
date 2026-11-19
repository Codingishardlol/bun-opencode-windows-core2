# Build status and resume notes

## Current / most recent run

https://github.com/Codingishardlol/bun-opencode-windows-core2/actions

(Actions run ID is in the URL after opening a run.)

The GitHub Actions run is independent of the Codespace. Closing the Codespace
does not stop it. Each job has a 6-hour limit; the workflow splits WebKit from
Bun/OpenCode and saves the build directory as an Actions cache after each
attempt, so retries resume instead of starting over.

## If the run is green

Open the run page, scroll to **Artifacts**, and download:

`bun-1.4.4-opencode-2.1.2-windows-x64-penryn`

It contains:

- `bun.exe`
- `opencode.exe`
- `runtime-smoke.mjs`

Artifacts are retained for 30 days.

## Test on the Q9550 (Windows 10)

```bat
cd /d C:\path\to\downloaded\artifact
bun.exe --version
bun.exe runtime-smoke.mjs
opencode.exe --version
```

Expected:

- `bun.exe --version` prints `1.4.4` and does not crash with `0xC000001D`
  (illegal instruction).
- `runtime-smoke.mjs` prints
  `CORE2_RUNTIME_OK: unicode, crypto, hash, compression, JIT, WASM popcnt, sqlite, HTTP, subprocess`.
- `opencode.exe --version` prints the OpenCode 2.1.2 version.

Then test the real TUI in an isolated profile before replacing your normal
install. Set `OPENCODE_DISABLE_AUTOUPDATE=1` for normal use and do not run
`bun upgrade`; a stock update can replace the Penryn runtime with a Nehalem
build that crashes.

## Bun-only artifact

If the Bun build and smoke test pass but a later OpenCode step fails, the run
still uploads `bun-1.4.4-windows-x64-penryn-only` (just `bun.exe`). You can test
that on the Q9550 with `bun.exe --version` while the OpenCode step is fixed.

## If the run is red

Do not click "Re-run failed jobs" blindly. Note the run ID and the name of the
failed step, then continue the fix with the AI assistant after reopening the
Codespace. The workflow cache normally preserves the completed WebKit work.

Useful commands after reopening:

```bash
gh run list --repo Codingishardlol/bun-opencode-windows-core2 --limit 5
gh run view <RUN_ID> --repo Codingishardlol/bun-opencode-windows-core2
gh run view <RUN_ID> --repo Codingishardlol/bun-opencode-windows-core2 --log-failed
```

## What has already been fixed

- Patch files are normalized to LF before `git apply` (Windows checkout was
  converting them to CRLF).
- WebKit's `build-icu.ps1` PowerShell parse error (`$ICU_VERSION:`).
- The `py -3` launcher shim.
- Windows PowerShell 5.1 inheriting the PowerShell 7 `PSModulePath`, which
  broke `Get-FileHash`.
- CMake 3.31 is preferred over the VS 2026 shell's CMake 4.x.

The actual Penryn changes are in `patches/bun-windows-penryn.patch` and
`patches/webkit-penryn-icu.patch`.
