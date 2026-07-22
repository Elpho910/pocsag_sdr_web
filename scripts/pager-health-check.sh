#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE=${CONFIG_FILE:-/etc/pager-sdr-web/pager.env}
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

: "${LOG_FILE:=/var/lib/pager/messages.log}"
: "${HEALTH_FILE:=/var/lib/pager/health.json}"

rtl=0
mm=0
pidof rtl_fm >/dev/null 2>&1 && rtl=1
pidof multimon-ng >/dev/null 2>&1 && mm=1

now=$(date +%s)
last_mod=0
size=0
if [[ -f "$LOG_FILE" ]]; then
  last_mod=$(stat -c %Y "$LOG_FILE" 2>/dev/null || echo 0)
  size=$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)
fi

age=999999
if [[ "$last_mod" -gt 0 ]]; then
  age=$((now-last_mod))
fi

status="degraded"
if [[ "$rtl" -eq 1 && "$mm" -eq 1 ]]; then
  status="running"
fi
if [[ "$status" == "running" && "$size" -gt 0 && "$age" -le 1200 ]]; then
  status="live"
fi

mkdir -p "$(dirname "$HEALTH_FILE")"
printf '{"status":"%s","rtl_fm":%s,"multimon":%s,"log_age_sec":%s,"log_bytes":%s,"updated_at":%s}\n' \
  "$status" "$rtl" "$mm" "$age" "$size" "$now" > "$HEALTH_FILE"
chmod 664 "$HEALTH_FILE" || true
