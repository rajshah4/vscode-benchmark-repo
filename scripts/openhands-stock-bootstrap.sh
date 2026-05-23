#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

PACKAGES=(
  libkrb5-dev
  xvfb
  pkg-config
  libx11-dev
  libxkbfile-dev
)

timestamp() {
  date +%s
}

print_phase() {
  local phase="$1"
  local started_at="$2"
  local ended_at="$3"
  local elapsed=$((ended_at - started_at))
  printf 'OPENHANDS_BENCHMARK_PHASE %s %ss\n' "${phase}" "${elapsed}"
}

run_with_timing() {
  local phase="$1"
  shift
  local started_at
  local ended_at
  started_at="$(timestamp)"
  printf '\n==> %s\n' "${phase}"
  "$@"
  ended_at="$(timestamp)"
  print_phase "${phase}" "${started_at}" "${ended_at}"
}

apt_prefix=()
if command -v apt-get >/dev/null 2>&1; then
  if [[ "${EUID}" -eq 0 ]]; then
    apt_prefix=(apt-get)
  elif command -v sudo >/dev/null 2>&1; then
    apt_prefix=(sudo apt-get)
  else
    echo "apt-get is available but sudo is not; cannot install required packages" >&2
    exit 1
  fi
fi

if [[ "${#apt_prefix[@]}" -gt 0 ]]; then
  run_with_timing system_packages "${apt_prefix[@]}" update
  run_with_timing system_packages_install "${apt_prefix[@]}" install -y "${PACKAGES[@]}"
else
  echo "Skipping system package installation because apt-get is not available."
fi

if [[ -d node_modules ]]; then
  echo "node_modules already exists; skipping npm install"
else
  run_with_timing npm_install npm install
fi

run_with_timing transpile npm run gulp transpile-client-esbuild transpile-extensions
run_with_timing electron npm run electron

cat <<'EOF'

Bootstrap complete.

Next verification command:
xvfb-run -a ./scripts/test.sh --run src/vs/platform/configuration/test/common/configurationModels.test.ts --grep "excluded restricted properties"
EOF
