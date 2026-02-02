#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-/home/hendrik/smarthome}"
REMOTE_NAME="${RCLONE_REMOTE:-gdrive}"
REMOTE_DIR="${RCLONE_REMOTE_DIR:-smarthome-backups}"
STOP_STACK="${STOP_STACK:-1}"

log() {
  printf "[%s] %s\n" "$(date '+%F %T')" "$*"
}

timestamp="$(date +%F)"
git_ref="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
archive="smarthome-backup-${timestamp}-${git_ref}.tar.gz"
tmp_archive="/tmp/${archive}"

cleanup() {
  if [ -f "${tmp_archive}" ]; then
    rm -f "${tmp_archive}"
  fi
}

restart_stack() {
  if [ "${STOP_STACK}" = "1" ]; then
    docker compose up -d
  fi
}

trap cleanup EXIT
trap restart_stack ERR

log "backup start"
log "repo: ${REPO_DIR}"
log "remote: ${REMOTE_NAME}:${REMOTE_DIR}"
log "stop_stack: ${STOP_STACK}"

cd "${REPO_DIR}"

paths=(
  home-assistant-config
  mosquitto
  zigbee2mqtt
  home-assistant-matter-hub
)

for path in "${paths[@]}"; do
  if [ ! -r "${path}" ]; then
    echo "error: ${path} is not readable by $(whoami). Fix permissions or run with sudo." >&2
    exit 1
  fi
done

if [ "${STOP_STACK}" = "1" ]; then
  log "stopping compose stack"
  docker compose down
fi

log "creating archive ${tmp_archive}"
tar -czf "${tmp_archive}" "${paths[@]}"

if [ "${STOP_STACK}" = "1" ]; then
  log "starting compose stack"
  docker compose up -d
fi

log "uploading to ${REMOTE_NAME}:${REMOTE_DIR}/"
rclone copy "${tmp_archive}" "${REMOTE_NAME}:${REMOTE_DIR}/"
log "backup complete"
