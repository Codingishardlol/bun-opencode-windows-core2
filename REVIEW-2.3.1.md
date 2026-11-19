# OpenCode 2.3.1 Penryn build — independent review

## What this is

Preflight review of a version bump for the Windows x64 Penryn build.

- Repo: https://github.com/Codingishardlol/bun-opencode-windows-core2
- Branch: `opencode-2.3.1-penryn`
- Diff: https://github.com/Codingishardlol/bun-opencode-windows-core2/compare/main...opencode-2.3.1-penryn
- Previous successful run (2.1.2): https://github.com/Codingishardlol/bun-opencode-windows-core2/actions/runs/44469769664
- The 2.1.2 binaries were run on the target Q9550: `bun 1.4.4`, `CORE2_RUNTIME_OK`, `opencode v2.1.2`.

**Do not dispatch the workflow.** It is `workflow_dispatch` only, so pushing
or reviewing the branch cannot start it. Review first, then dispatch.

## Why 2.3.1

OpenChamber 2.7.2 requires OpenCode **2.2.4 or newer**; the 2.1.2 build cannot
drive it. OpenCode 2.3.1 declares `bun@1.4.4`, the same runtime already built
and verified for Penryn, and OpenChamber 2.7.2 uses the 2.3.0 client. This must
be a **new release** (`v1.4.4-opencode-2.3.1-penryn`), not a replacement for
the 2.1.2 release.

## Changes on the branch

1. `patches/opencode.patch` regenerated against OpenCode `v2.3.1`
   (commit `c769de83007e3584b5b395176c9fcde2d3231e88`). The change is still one
   line in `packages/cli/script/build.ts`:
   `process.env.BUN_COMPILE_EXECUTABLE_PATH ?? (await compileExecutable(item))`.
2. `.github/workflows/build.yml`:
   - `OPENCODE_TAG` is `v2.3.1`;
   - the workflow and artifact names say 2.3.1;
   - the build sets `OPENCODE_TARGET=windows-x64` instead of `--target=...`
     (2.3.x reads the target from the environment);
   - the artifact check requires the output to contain `2.3.1`.
3. `scripts/prepare-opencode.ps1`:
   - pins `v2.3.1` / `c769de83…`;
   - the photon-node patch repair is now conditional. 2.1.2 shipped that patch
     with bad context spacing; 2.3.1 ships it correctly, so it must be left
     alone.

## Preflight already done (Linux, Bun 1.4.4)

- `git apply` of the regenerated patch to a clean `v2.3.1` checkout: passed.
- `bun install --frozen-lockfile --ignore-scripts`: passed (1594 packages).
- `OPENCODE_TARGET=linux-x64` build with
  `BUN_COMPILE_EXECUTABLE_PATH` set: passed.
- The resulting Linux binary printed `opencode v2.3.1`.
- `actionlint`: passed.
- PowerShell parser check of `prepare-opencode.ps1`: passed.

The Windows-specific compile was **not** run locally. It relies on the same
Bun `compile` path and target structure that succeeded for 2.1.2.

## Review questions

Be skeptical and verify these against the actual 2.3.1 source, not just this
summary:

1. Is `OPENCODE_TARGET=windows-x64` exactly right for 2.3.1? In
   `packages/cli/script/build.ts`, the filter is
   `` `${binary}-${requestedTarget}` `` with `binary = "opencode"`. Confirm the
   target list and `targetName()` still produce `opencode-windows-x64`.
2. Does bypassing `compileExecutable(item)` lose anything besides the
   executable path (cache setup, download verification, env vars, post-copy
   steps)? Inspect the whole function, not just line 170.
3. Is the output still
   `dist/opencode/cli-windows-x64/bin/opencode.exe`? The verify step depends on
   that path.
4. Are there Windows-specific 2.3.1 build changes that did not exist in 2.1.2
   (new native assets, pty packages, Bun APIs, app assets, patches) that the
   Linux preflight would not catch?
5. Is the conditional photon-node repair safe? Confirm 2.3.1 ships the fixed
   patch and that no other bundled patch needs the old repair.
6. Does `OPENCODE_VERSION=2.3.1` actually override the version used by the
   build, or does 2.3.1 read only `package.json`? If it is ignored, is that
   harmless?
7. Will `opencode.exe --version` contain `2.3.1` on Windows? The check uses
   `-notmatch "2\.3\.1"`.
8. Does the 2.1.2 WebKit/Bun cache still restore for this branch? The cache
   key hashes only `patches/bun-windows-penryn.patch` and
   `patches/webkit-penryn-icu.patch`, which are unchanged.
9. For OpenChamber: confirm 2.3.1 meets the 2.7.2 minimum and that pointing it
   at `%LOCALAPPDATA%\core2\bin\opencode.exe` via Settings → OpenCode CLI is
   supported (the desktop app otherwise uses its bundled stock OpenCode).
10. Anything that could fail before the OpenCode step that changed since run
    `44469769664` (toolchain, cache, Windows runner image)?

## Constraints

- Do not bypass or stub the Penryn compile flags or the runtime smoke test.
- Do not touch provider, account, quota, identity, or update logic.
- Do not overwrite or retag the existing
  `v1.4.4-opencode-2.1.2-penryn` release.
- Do not merge to `main` or dispatch the workflow without approval.

## If approved

1. Dispatch `build.yml` on `opencode-2.3.1-penryn` (or merge to `main` first).
2. If it passes, create the new release
   `v1.4.4-opencode-2.3.1-penryn` with `bun.exe`, `opencode.exe`, and
   `runtime-smoke.mjs`.
3. Update `install.ps1` hashes/tag and the README for 2.3.1, leaving the 2.1.2
   release intact.
4. Point OpenChamber at the new `opencode.exe` and retest.

## Output wanted

List findings by severity (`blocker`, `should-fix`, `nit`), with file:line and
an exact fix for each. End with **READY TO DISPATCH** or **NOT READY** and the
reasons.
