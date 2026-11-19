# Build status and resume notes

## Current release

- **2.3.1:** [v1.4.4-opencode-2.3.1-penryn](https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/tag/v1.4.4-opencode-2.3.1-penryn)
  built by run [44581342871](https://github.com/Codingishardlol/bun-opencode-windows-core2/actions/runs/44581342871) from commit `387c109`.
- **2.1.2:** [v1.4.4-opencode-2.1.2-penryn](https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/tag/v1.4.4-opencode-2.1.2-penryn)
  remains available as a separate release.

Both releases target Penryn. The 2.1.2 build was run on a real Q9550; the 2.3.1
build passed the same checks on the Windows CI runner.

## Install

PowerShell:

```powershell
irm https://raw.githubusercontent.com/Codingishardlol/bun-opencode-windows-core2/main/install.ps1 | iex
```

The installer downloads from the 2.3.1 release, verifies SHA-256, runs
`bun --version`, `runtime-smoke.mjs` and `opencode --version` on the PC, then
adds `%LOCALAPPDATA%\core2\bin` to PATH and sets
`OPENCODE_DISABLE_AUTOUPDATE=1`.

Expected:

```text
1.4.4
CORE2_RUNTIME_OK: unicode, crypto, hash, compression, JIT, WASM popcnt, sqlite, HTTP, subprocess
opencode v2.3.1
```

Then open a new PowerShell window and run `opencode`.

## OpenChamber

OpenChamber 2.7.2 requires OpenCode 2.2.4 or newer, so 2.1.2 cannot drive it.
Point OpenChamber at the Penryn binary under **Settings → General → OpenCode
CLI → Binary path** (`%LOCALAPPDATA%\core2\bin\opencode.exe`) or set
`OPENCODE_BINARY`, then restart OpenChamber.

## If something fails

- `0xC000001D` (illegal instruction): the CPU target is wrong. Stop and report
  the exact command.
- A failed installer check does not modify PATH; rerunning it is safe.
- To go back to 2.1.2, download that release and run its files manually, or
  point `OPENCODE_BINARY` at the 2.1.2 `opencode.exe`.

## What changed for 2.3.1

- OpenCode pinned to `v2.3.1` (commit `c769de83…`), which meets OpenChamber
  2.7.2's minimum.
- `patches/opencode.patch` regenerated for 2.3.1; the
  `BUN_COMPILE_EXECUTABLE_PATH` override remains one line.
- OpenCode 2.3.x selects its target with `OPENCODE_TARGET=windows-x64`, not
  `--target=`.
- The photon-node patch repair now only runs when the old bad spacing is
  present, and fails fast on unexpected content.

The Penryn changes themselves are still in
`patches/bun-windows-penryn.patch` and `patches/webkit-penryn-icu.patch`.
