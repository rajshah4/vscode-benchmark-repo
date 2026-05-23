#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

xvfb-run -a -s "-screen 0 1280x1024x24" \
  env VSCODE_SKIP_PRELAUNCH=1 ./scripts/test.sh \
    --run src/vs/platform/configuration/test/common/configurationModels.test.ts \
    --grep "excluded restricted properties"
