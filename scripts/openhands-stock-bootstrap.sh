#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
benchmark_root="${OPENHANDS_BENCHMARK_ROOT:-${repo_root}/.openhands-benchmark}"
state_dir="${benchmark_root}/state"
logs_dir="${benchmark_root}/logs"
run_id="$(date -u +%Y%m%dT%H%M%SZ)"
run_dir="${logs_dir}/${run_id}"
summary_log="${run_dir}/summary.log"
force="${OPENHANDS_BENCHMARK_FORCE:-0}"
gulp_heap_mb="${OPENHANDS_GULP_MAX_OLD_SPACE_SIZE_MB:-4096}"

mkdir -p "${state_dir}" "${run_dir}"
ln -sfn "${run_dir}" "${logs_dir}/latest"

phase() {
  local phase_name="$1"
  shift

  local marker="${state_dir}/${phase_name}.done"
  local log_file="${run_dir}/${phase_name}.log"
  local start_ts
  local start_epoch
  local end_ts
  local end_epoch
  local duration
  local status

  if [[ "${force}" != "1" && -f "${marker}" ]]; then
    printf 'OPENHANDS_BENCHMARK_PHASE %s status=skipped reason=already_complete\n' "${phase_name}" | tee -a "${summary_log}"
    return 0
  fi

  start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  start_epoch="$(date -u +%s)"
  printf 'OPENHANDS_BENCHMARK_PHASE %s status=started ts=%s\n' "${phase_name}" "${start_ts}" | tee -a "${summary_log}"

  set +e
  (
    set -x
    "$@"
  ) > >(tee "${log_file}") 2>&1
  status=$?
  set -e

  end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  end_epoch="$(date -u +%s)"
  duration="$(( end_epoch - start_epoch ))"

  if [[ "${status}" -eq 0 ]]; then
    touch "${marker}"
    printf 'OPENHANDS_BENCHMARK_PHASE %s status=completed duration_s=%s finished_at=%s log=%s\n' "${phase_name}" "${duration}" "${end_ts}" "${log_file}" | tee -a "${summary_log}"
  else
    printf 'OPENHANDS_BENCHMARK_PHASE %s status=failed duration_s=%s finished_at=%s log=%s\n' "${phase_name}" "${duration}" "${end_ts}" "${log_file}" | tee -a "${summary_log}"
    return "${status}"
  fi
}

cd "${repo_root}"

phase system_packages sudo apt-get update
phase system_packages_install sudo apt-get install -y xvfb libkrb5-dev pkg-config libx11-dev libxkbfile-dev
phase npm_install npm install --verbose
phase transpile node --experimental-strip-types --max-old-space-size="${gulp_heap_mb}" ./node_modules/gulp/bin/gulp.js transpile-client-esbuild transpile-extensions
phase electron npm run electron

cat <<EOF | tee -a "${summary_log}"
OPENHANDS_BENCHMARK_BOOTSTRAP complete=1 logs=${run_dir}
Configured gulp heap: ${gulp_heap_mb} MB
Next step:
  ./scripts/openhands-benchmark-verify.sh
EOF
