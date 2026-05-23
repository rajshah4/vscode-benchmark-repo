# OpenHands VS Code Benchmark

This repository snapshot is used to benchmark OpenHands stock sandboxes against prewarmed custom sandbox images.

## Target task

Investigate the behavior for excluded restricted properties in configuration models and make the narrow verification command pass.

## Repo area

- Source: `src/vs/platform/configuration/common/configurationModels.ts`
- Tests: `src/vs/platform/configuration/test/common/configurationModels.test.ts`

## Narrow verification command

```bash
./scripts/test.sh --run src/vs/platform/configuration/test/common/configurationModels.test.ts --grep "excluded restricted properties"
```

There is also a repo-local wrapper for that exact command:

```bash
./scripts/openhands-benchmark-verify.sh
```

## Stock sandbox bootstrap

For stock-image comparisons, use the helper script below before running the narrow verification command:

```bash
./scripts/openhands-stock-bootstrap.sh
```

What it does:

- installs the known Linux system dependencies needed by this benchmark:
  - `xvfb`
  - `libkrb5-dev`
  - `pkg-config`
  - `libx11-dev`
  - `libxkbfile-dev`
- runs:
  - `npm install --verbose`
  - a constrained-heap transpile step:
    - `node --experimental-strip-types --max-old-space-size=4096 ./node_modules/gulp/bin/gulp.js transpile-client-esbuild transpile-extensions`
  - `npm run electron`
- emits phase markers and per-phase logs
- is safe to rerun:
  - completed phases are skipped unless `OPENHANDS_BENCHMARK_FORCE=1`

This is intentionally procedural. The goal is to measure stock-sandbox bootstrap cost directly rather than forcing the agent to rediscover the setup path on every run.

Why the helper does not use `npm run gulp` directly:

- this repository's `package.json` defines `gulp` with `--max-old-space-size=8192`
- that is reasonable on a large developer machine, but too aggressive for smaller sandbox limits
- the helper runs gulp directly with a lower heap cap so stock-image benchmarking is less likely to OOM during transpilation

The heap can be overridden with:

```bash
OPENHANDS_GULP_MAX_OLD_SPACE_SIZE_MB=6144 ./scripts/openhands-stock-bootstrap.sh
```

Logs and phase markers land under:

- `.openhands-benchmark/state/`
- `.openhands-benchmark/logs/latest/`

If the sandbox appears stuck or the conversation loses track, inspect status with:

```bash
./scripts/openhands-benchmark-status.sh
```
## What the benchmark is measuring

- how long it takes to get the repo into a runnable state
- how long it takes to reach the first useful failing test
- how long it takes to make the targeted verification pass

## Important note

The benchmark branch contains a small intentional regression for this task. The goal is to compare setup and debugging time, not to hunt for an unknown bug somewhere in the repo.

## Recommended benchmark prompt

For a stock-sandbox benchmark run, use a procedural prompt like this:

```text
Clone https://github.com/rajshah4/vscode-benchmark-repo.git into /workspace/project/vscode-benchmark, checkout branch openhands-benchmark-01, and work there.

Do not guess at bootstrap steps. Run them explicitly from the repo-local helper:

./scripts/openhands-stock-bootstrap.sh

If progress looks unclear, check:

./scripts/openhands-benchmark-status.sh

After bootstrap finishes, run:

./scripts/openhands-benchmark-verify.sh

Fix the bug in src/vs/platform/configuration/common/configurationModels.ts, then rerun ./scripts/openhands-benchmark-verify.sh until it passes.

Before finishing, summarize:
- time spent in bootstrap phases
- time to first useful failing test
- time spent after the first failing test on the actual code fix
```
