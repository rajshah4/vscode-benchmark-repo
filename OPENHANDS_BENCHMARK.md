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

## What the benchmark is measuring

- how long it takes to get the repo into a runnable state
- how long it takes to reach the first useful failing test
- how long it takes to make the targeted verification pass

## Important note

The benchmark branch contains a small intentional regression for this task. The goal is to compare setup and debugging time, not to hunt for an unknown bug somewhere in the repo.
