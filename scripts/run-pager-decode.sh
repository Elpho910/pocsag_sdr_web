#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE=${CONFIG_FILE:-/etc/pager-sdr-web/pager.env}
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

: "${RTL_DEVICE:=0}"
: "${RTL_FREQUENCY:=148.7125M}"
: "${RTL_SAMPLE_RATE:=22050}"
: "${RTL_AGC_MODE:=fast}"
: "${RTL_GAIN:=}"
: "${POCSAG_MODES:=POCSAG512 POCSAG1200 POCSAG2400}"
: "${MULTIMON_BATCH:=1}"
: "${DEDUP_WINDOW:=60}"
: "${LOG_DIR:=/var/lib/pager}"
: "${LOG_FILE:=/var/lib/pager/messages.log}"
: "${RTL_ERROR_LOG:=/var/lib/pager/rtl_fm.err}"
: "${RESTART_DELAY:=1}"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 664 "$LOG_FILE" || true

export DEDUP_WINDOW

rtl_cmd=(rtl_fm -d "$RTL_DEVICE" -E dc -F 0 -A "$RTL_AGC_MODE" -f "$RTL_FREQUENCY" -s "$RTL_SAMPLE_RATE" -)
if [[ -n "$RTL_GAIN" ]]; then
  rtl_cmd+=(-g "$RTL_GAIN")
fi

mm_cmd=(/usr/bin/multimon-ng -q -b "$MULTIMON_BATCH" -c -f alpha -t raw /dev/stdin)
for mode in $POCSAG_MODES; do
  mm_cmd+=( -a "$mode" )
done

while true; do
  "${rtl_cmd[@]}" 2>>"$RTL_ERROR_LOG" | "${mm_cmd[@]}" | /usr/local/bin/pager-clean-filter.py >> "$LOG_FILE"
  sleep "$RESTART_DELAY"
done
