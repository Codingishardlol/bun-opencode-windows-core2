# Bun 1.4.4 + OpenCode 2.3.1 for Windows x64 (Penryn / Core 2)

Unofficial Windows x64 build of Bun **1.4.4** and OpenCode **2.3.1** for Intel
Core 2 CPUs with SSE4.1 but no SSE4.2, POPCNT or AVX — for example the Intel
Core 2 Quad Q9550. Stock Bun targets Nehalem and crashes with
`0xC000001D` (illegal instruction) on these CPUs.

The 2.1.2 build was confirmed on a real Q9550. The 2.3.1 build passed the same
checks on the Windows CI runner; the installer below runs them again on your PC
before it changes PATH.

## Install

PowerShell:

```powershell
irm https://raw.githubusercontent.com/Codingishardlol/bun-opencode-windows-core2/main/install.ps1 | iex
```

The installer:

1. downloads `bun.exe`, `opencode.exe` and `runtime-smoke.mjs` from the
   [2.3.1 release](https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/tag/v1.4.4-opencode-2.3.1-penryn);
2. verifies their SHA-256 hashes;
3. runs `bun --version`, the runtime smoke test and `opencode --version` on the
   local CPU;
4. only if all three pass, adds `%LOCALAPPDATA%\core2\bin` to the user PATH and
   sets `OPENCODE_DISABLE_AUTOUPDATE=1`.

Expected during install:

```text
1.4.4
CORE2_RUNTIME_OK: unicode, crypto, hash, compression, JIT, WASM popcnt, sqlite, HTTP, subprocess
opencode v2.3.1
```

Open a **new** PowerShell window afterwards, then run:

```powershell
opencode
```

### Manual download and test

Download the three files from the
[2.3.1 release](https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/tag/v1.4.4-opencode-2.3.1-penryn)
into one folder, open Command Prompt there, and run:

```bat
bun.exe --version
bun.exe runtime-smoke.mjs
opencode.exe --version
```

If any command fails with `0xC000001D`, stop: the CPU target is wrong.

### SHA-256

```text
3d20cff2ff2d31306e788542f59972c83c7bd5703bc808c64cba3e90c67f87c2  bun.exe
f7f9cf916b080853b1eaa609029fb794f810d16ebee7cc63add44e252d468fee  opencode.exe
2ae7fce6ee469b801aead420505a012fa919de144e5713c003176afcb89141ec  runtime-smoke.mjs
```

## OpenChamber

OpenChamber **2.7.2** requires OpenCode **2.2.4 or newer**, so 2.1.2 could not
drive it; 2.3.1 can. The desktop app otherwise uses its bundled stock OpenCode,
which crashes on a Q9550. Point it at the Penryn binary:

- **Settings → General → OpenCode CLI → Binary path** →
  `%LOCALAPPDATA%\core2\bin\opencode.exe`
- or set `OPENCODE_BINARY` to that path, then restart OpenChamber.

## Previous release

The 2.1.2 build remains available separately:
[v1.4.4-opencode-2.1.2-penryn](https://github.com/Codingishardlol/bun-opencode-windows-core2/releases/tag/v1.4.4-opencode-2.1.2-penryn).
Releases are independent; publishing 2.3.1 does not replace or retag 2.1.2.

## Do not upgrade

Do not run `bun upgrade` or `opencode upgrade`, and do not install stock Bun or
OpenCode over this folder. Those fetch Nehalem builds that crash on the Q9550.
`install.ps1` sets `OPENCODE_DISABLE_AUTOUPDATE=1` for normal use.

If an upgrade does replace the binaries, rerun the install command above.

## What the workflow does

1. Clones `oven-sh/bun` at `bun-v1.4.4` (commit `38afee6c…`) and
   `anomalyco/opencode` at `v2.3.1` (commit `c769de83…`).
2. Applies:
   - `patches/bun-windows-penryn.patch`: makes `BUN_CORE2_BUILD=1` change the
     x64 CPU target from `-march=nehalem` to `-march=penryn` for Linux and
     Windows. Bun's C/C++, Rust (`-Ctarget-cpu=penryn`) and the local WebKit
     build all read this target.
   - `patches/webkit-penryn-icu.patch`: WebKit's Windows ICU helper hardcodes
     `-march=nehalem`; with `BUN_CORE2_BUILD=1` it uses `-march=penryn`.
     Without this, ICU could contain POPCNT/SSE4.2 code. The same patch fixes
     an upstream PowerShell parse error in that helper (`$ICU_VERSION:` must
     be `${ICU_VERSION}:`), which otherwise stops the local Windows WebKit
     build before ICU is compiled.
   - `patches/opencode.patch`: lets the OpenCode build honor
     `BUN_COMPILE_EXECUTABLE_PATH`, so `opencode.exe` embeds the Penryn Bun
     runtime instead of downloading a stock one. The patch is regenerated for
     OpenCode 2.3.1; the change is one line in
     `packages/cli/script/build.ts`.
3. Fetches `oven-sh/WebKit` at `d6375c72affe0f70222cdcb45012b10f0bf3a9d5`
   into `bun/vendor/WebKit`.
4. Builds WebKit from source in its own job (`--target=WebKit`), so the slow
   JavaScriptCore/ICU build is not tied to one 6-hour job. The prebuilt WebKit
   is Nehalem, so it cannot be used.
5. Builds Bun with `BUN_CORE2_BUILD=1` and
   `bun scripts/build.ts --profile=release-local --webkit=local`.
6. Builds OpenCode with `BUN_COMPILE_EXECUTABLE_PATH` pointing at the new
   `bun.exe`. OpenCode 2.3.x selects its target with `OPENCODE_TARGET=windows-x64`
   (the older `--target=` flag is no longer read), with `--skip-web-ui`.
7. Uploads `bun.exe`, `opencode.exe` and `runtime-smoke.mjs`.

No runtime CPU check is bypassed or stubbed. The compiler target really is
Penryn. Provider, account, quota, identity and update logic are not patched.

## Verify the Penryn target

`scripts/verify-penryn.ps1` checks the generated build files:

- `-march=penryn` is present and `-march=nehalem` is absent in Bun's and
  WebKit's `compile_commands.json`;
- the ICU `common.vcxproj` uses `-march=penryn`;
- `sicudt.lib`, `icuin.lib` and `icuuc.lib` exist and are non-empty.

`tests/runtime-smoke.mjs` then exercises Unicode, crypto/hash, compression,
JIT, WASM POPCNT lowering, SQLite, a loopback HTTP server and subprocesses.

## Toolchain

Pinned from Bun's `docs/project/building-windows.mdx` and
`scripts/build/ci-images/spec.ts`:

- LLVM **23.1.1** (clang-cl, lld-link, llvm-lib, llvm-rc)
- Rust **nightly-2026-09-15** with `rust-src`
- Visual Studio 2022 with Desktop C++ and Clang components (runner image)
- CMake, Ninja, NASM, Perl, Ruby, Python, Go, Cygwin, make
- Build-time Bun **1.4.4**

## Build it yourself

```bash
gh workflow run build.yml --repo Codingishardlol/bun-opencode-windows-core2
gh run watch --repo Codingishardlol/bun-opencode-windows-core2
```

Download the artifact:

```bash
gh run download --repo Codingishardlol/bun-opencode-windows-core2 \
  -n bun-1.4.4-opencode-2.3.1-windows-x64-penryn -D ./penryn-build
```

## Limits

- CI proves the code builds, the runner's CPU executes it, the Penryn compile
  flags appear in the Bun/WebKit/ICU build inputs, and the smoke test passes.
- The 2.1.2 binaries were run on a real Q9550. The 2.3.1 binaries passed CI but
  have not yet been run on a Q9550; `install.ps1` performs that final check on
  the target PC before adding them to PATH.
- Penryn requires SSE4.1. This is not for older Core 2 CPUs without SSE4.1.
- The build intentionally omits OpenCode's embedded browser UI; the CLI/TUI is
  included.
- This is a community workaround, not an upstream support commitment.
