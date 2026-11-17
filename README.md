# Bun 1.4.4 + OpenCode 2.1.2 for Windows x64 (Penryn / Core 2)

Unofficial GitHub Actions build of Bun **1.4.4** and OpenCode **2.1.2** for
x86-64 CPUs that have SSE4.1 but lack SSE4.2, POPCNT and AVX — for example the
Intel Core 2 Quad Q9550. Stock Bun targets Nehalem and crashes on those CPUs.

The build is entirely on `windows-latest`; the artifacts are downloadable from
the Actions run. Nothing here is tested on the target CPU by CI, because the
runner has a modern CPU. The final check must be done on the Q9550.

## What the workflow does

1. Clones `oven-sh/bun` at `bun-v1.4.4` (commit `38afee6c…`) and
   `anomalyco/opencode` at `v2.1.2` (commit `a517687f…`).
2. Applies:
   - `patches/bun-windows-penryn.patch`: makes `BUN_CORE2_BUILD=1` change the
     x64 CPU target from `-march=nehalem` to `-march=penryn` for Linux and
     Windows. Bun's own C/C++, Rust (`-Ctarget-cpu=penryn`) and the local
     WebKit build all read this target.
   - `patches/webkit-penryn-icu.patch`: WebKit's Windows ICU helper hardcodes
     `-march=nehalem`; with `BUN_CORE2_BUILD=1` it now uses `-march=penryn`.
     Without this, ICU could contain POPCNT/SSE4.2 code and the final binary
     would not really be Penryn-only. The same patch fixes an upstream
     PowerShell parse error in that helper (`$ICU_VERSION:` must be
     `${ICU_VERSION}:`), which otherwise stops the local Windows WebKit build
     before ICU is compiled.
   - `patches/opencode.patch` (unchanged from
     [`JoeJoeflyn/opencode-core2`](https://github.com/JoeJoeflyn/opencode-core2)):
     lets the OpenCode build honor `BUN_COMPILE_EXECUTABLE_PATH`.
3. Fetches `oven-sh/WebKit` at `d6375c72affe0f70222cdcb45012b10f0bf3a9d5`
   into `bun/vendor/WebKit`.
4. Builds WebKit from source first (`--target=WebKit`) in its own job, so the
   local JavaScriptCore/ICU build is not tied to one 6-hour job.
5. Builds Bun with `BUN_CORE2_BUILD=1` and
   `bun scripts/build.ts --profile=release-local --webkit=local` (the prebuilt
   WebKit is Nehalem, so it cannot be used).
6. Builds OpenCode with `BUN_COMPILE_EXECUTABLE_PATH` pointing at the new
   `bun.exe`, target `opencode-windows-x64`, with `--skip-web-ui`.
7. Uploads `bun.exe`, `opencode.exe`, and `runtime-smoke.mjs`.

No runtime CPU check is bypassed or stubbed. The compiler target really is
Penryn. Provider, account, quota, identity and update logic are not patched.

## Toolchain

Pinned from Bun's `docs/project/building-windows.mdx` and
`scripts/build/ci-images/spec.ts`:

- LLVM **23.1.1** (clang-cl, lld-link, llvm-lib, llvm-rc)
- Rust **nightly-2026-09-15** with `rust-src` (from `rust-toolchain.toml`)
- Visual Studio 2022 with Desktop C++ and Clang components (runner image)
- CMake, Ninja, NASM, Perl (Git for Windows), Ruby, Python, Go, Cygwin, make
- Build-time Bun **1.4.4**

## Run it

```bash
gh workflow run build.yml --repo Codingishardlol/bun-opencode-windows-core2
gh run watch --repo Codingishardlol/bun-opencode-windows-core2
```

Download the result:

```bash
gh run download --repo Codingishardlol/bun-opencode-windows-core2 \
  -n bun-1.4.4-opencode-2.1.2-windows-x64-penryn -D ./penryn-build
```

## Test on the Q9550 (Windows 10)

Use a temporary directory first. Do not overwrite the binaries you currently
use until these pass.

```bat
cd /d C:\path\to\penryn-build
bun.exe --version
bun.exe runtime-smoke.mjs
opencode.exe --version
```

Expected:

- `bun.exe --version` prints `1.4.4` and does not raise an illegal-instruction
  crash (`0xC000001D`).
- `runtime-smoke.mjs` prints
  `CORE2_RUNTIME_OK: unicode, crypto, hash, compression, JIT, WASM popcnt, sqlite, HTTP, subprocess`.
- `opencode.exe --version` prints the 2.1.2 version string.

Then run the interactive TUI in an isolated profile and verify a real completed
reply. Keep a backup of your normal OpenCode data and launcher.

Set `OPENCODE_DISABLE_AUTOUPDATE=1` before normal use. A stock OpenCode update
can replace the custom runtime with a Nehalem build that crashes. Do not run
`bun upgrade`.

## Limits

- CI proves the code builds, the runner's CPU executes it, the Penryn compile
  flags appear in Bun/WebKit/ICU build inputs, and the runtime smoke test
  passes. It cannot prove execution on a Q9550.
- Penryn requires SSE4.1. This is not for older Core 2 CPUs without SSE4.1.
- The build intentionally omits OpenCode's embedded browser UI; the CLI/TUI is
  included.
- This is a community workaround, not an upstream support commitment.
