#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-/home/hendrik/smarthome}"
REMOTE_NAME="${RCLONE_REMOTE:-gdrive}"
REMOTE_DIR="${RCLONE_REMOTE_DIR:-smarthome-backups}"
STOP_STACK="${STOP_STACK:-1}"

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

cd "${REPO_DIR}"

if [ "${STOP_STACK}" = "1" ]; then
  docker compose down
fi

paths=(
  home-assistant-config
  mosquitto
  zigbee2mqtt
  home-assistant-matter-hub
)

tar -czf "${tmp_archive}" "${paths[@]}"

if [ "${STOP_STACK}" = "1" ]; then
  docker compose up -d
fi

rclone copy "${tmp_archive}" "${REMOTE_NAME}:${REMOTE_DIR}/"
