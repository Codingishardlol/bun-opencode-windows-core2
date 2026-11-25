# Build status and resume notes

## Current release

- **2.4.1:** [v1.4.4-opencode-2.4.1-penryn](https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/tag/v1.4.4-opencode-2.4.1-penryn)
  built by run [45511288412](https://github.com/Codingishardlol/bun-opencode-windows-core2/actions/runs/45511288412) from commit `9a7e1eb`.
- **2.3.1:** [v1.4.4-opencode-2.3.1-penryn](https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/tag/v1.4.4-opencode-2.3.1-penryn)
- **2.1.2:** [v1.4.4-opencode-2.1.2-penryn](https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/tag/v1.4.4-opencode-2.1.2-penryn)

All releases target Penryn and remain available separately. 2.1.2 and 2.4.1
were run on a real Q9550; 2.3.1 passed the same checks on the Windows CI runner.

## Install

PowerShell:

```powershell
irm https://raw.githubusercontent.com/Codingishardlol/bun-opencode-windows-core2/main/install.ps1 | iex
```

The installer downloads from the 2.4.1 release, verifies SHA-256, runs
`bun --version`, `runtime-smoke.mjs` and `opencode --version` on the PC, then
adds `%LOCALAPPDATA%\core2\bin` to PATH and sets
`OPENCODE_DISABLE_AUTOUPDATE=1`.

Expected:

```text
1.4.4
CORE2_RUNTIME_OK: unicode, crypto, hash, compression, JIT, WASM popcnt, sqlite, HTTP, subprocess
opencode v2.4.1
```

Then open a new PowerShell window and run `opencode`.

## OpenChamber

OpenChamber 2.8.0 requires OpenCode 2.2.4 or newer, so 2.4.1 works. Point
OpenChamber at the Penryn binary under **Settings → General → OpenCode CLI →
Binary path** (`%LOCALAPPDATA%\core2\bin\opencode.exe`) or set
`OPENCODE_BINARY`, then restart OpenChamber.

## If something fails

- `0xC000001D` (illegal instruction): the CPU target is wrong. Stop and report
  the exact command.
- A failed installer check does not modify PATH; rerunning it is safe.
- Any older release can be downloaded from GitHub and used manually.

## What changed for 2.4.1

- OpenCode pinned to `v2.4.1` (commit `6f051405…`).
- `patches/opencode.patch` regenerated for 2.4.1; the
  `BUN_COMPILE_EXECUTABLE_PATH` override remains one line.
- 2.4.1 adds the Iroh machine-link native binding
  (`@number0/iroh-win32-x64-msvc`) and moves OpenTUI to 0.9.4; both are x64
  baseline assets.
- The photon-node patch repair only runs when the old bad spacing is present,
  and fails fast on unexpected content.

The Penryn changes themselves are still in
`patches/bun-windows-penryn.patch` and `patches/webkit-penryn-icu.patch`.
