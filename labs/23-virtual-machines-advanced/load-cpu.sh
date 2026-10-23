#!/bin/sh
# =============================================================================
# Lab 23 · load-cpu.sh — runs INSIDE a scale-set instance through Run Command.
# Keeps every vCPU busy for a number of seconds, then stops by itself.
#
#   az vm run-command invoke -g "$RG" -n <vm> --command-id RunShellScript \
#     --scripts @load-cpu.sh --parameters 900     # 15 minutes of load
#   ... --parameters stop                         # stop the load now
#
# The load runs as a temporary systemd unit (nusa-load), so Run Command returns
# straight away instead of waiting for the load to finish.
# =============================================================================
ARG="${1:-900}"

systemctl stop nusa-load.service >/dev/null 2>&1
systemctl reset-failed nusa-load.service >/dev/null 2>&1

if [ "$ARG" = "stop" ]; then
  echo "CPU load stopped on $(hostname)."
  exit 0
fi

case "$ARG" in
  '' | *[!0-9]*)
    echo "Usage: load-cpu.sh <seconds> | stop"
    exit 1
    ;;
esac

systemd-run --unit=nusa-load --collect -p RuntimeMaxSec="$ARG" \
  /bin/sh -c 'for i in $(seq "$(nproc)"); do yes > /dev/null & done; wait' >/dev/null 2>&1

if systemctl is-active --quiet nusa-load.service; then
  echo "CPU load started on $(hostname): $(nproc) vCPU busy for ${ARG} seconds."
else
  echo "Could not start the CPU load on $(hostname)."
  exit 1
fi
