#!/bin/sh
# =============================================================================
# Lab 16 · CPU load generator. This script runs INSIDE the VM, sent there by
# Run Command — you don't run it in Cloud Shell:
#
#   az vm run-command invoke -g "$RG" -n vm-nusa-web --command-id RunShellScript \
#     --scripts @cpu-load.sh --parameters 15        # busy for 15 minutes
#   az vm run-command invoke -g "$RG" -n vm-nusa-web --command-id RunShellScript \
#     --scripts @cpu-load.sh --parameters stop      # stop early
#
# It installs nothing. It starts one busy loop per vCPU as a transient systemd
# service, wrapped in `timeout`, so the load stops by itself and keeps running
# after Run Command returns.
# =============================================================================
ACTION="${1:-10}"

stop_load() {
  systemctl stop 'nusa-cpu-*.service' >/dev/null 2>&1 || true
}

if [ "$ACTION" = "stop" ]; then
  stop_load
  echo "CPU load stopped."
  exit 0
fi

case "$ACTION" in
  ''|*[!0-9]*)
    echo "Usage: cpu-load.sh <minutes 1-60> | stop"
    exit 1
    ;;
esac

MINUTES="$ACTION"
if [ "$MINUTES" -lt 1 ] || [ "$MINUTES" -gt 60 ]; then
  echo "Please choose between 1 and 60 minutes."
  exit 1
fi

stop_load
CPUS="$(nproc)"
i=1
while [ "$i" -le "$CPUS" ]; do
  systemd-run --quiet --collect --unit="nusa-cpu-$i" \
    timeout "$((MINUTES * 60))" sh -c 'while :; do :; done'
  i=$((i + 1))
done

echo "CPU load started on ${CPUS} vCPU(s) for ${MINUTES} minute(s). It stops by itself."
echo "Started at $(date -u '+%H:%M:%S') UTC on $(hostname)."
