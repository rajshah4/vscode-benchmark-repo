#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
benchmark_root="${OPENHANDS_BENCHMARK_ROOT:-${repo_root}/.openhands-benchmark}"
state_dir="${benchmark_root}/state"
latest_dir="${benchmark_root}/logs/latest"

echo "Benchmark root: ${benchmark_root}"
echo

for phase in system_packages system_packages_install npm_install transpile electron; do
  if [[ -f "${state_dir}/${phase}.done" ]]; then
    echo "[done]    ${phase}"
  else
    echo "[pending] ${phase}"
  fi
done

echo

if [[ -L "${latest_dir}" || -d "${latest_dir}" ]]; then
  echo "Latest logs: ${latest_dir}"
  echo
  if [[ -f "${latest_dir}/summary.log" ]]; then
    tail -n 20 "${latest_dir}/summary.log"
  else
    echo "No summary.log found yet."
  fi
else
  echo "No benchmark logs found yet."
fi
