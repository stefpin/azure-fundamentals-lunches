#!/usr/bin/env bash
# =============================================================================
# Lab 06 · Partition, format and mount the data disk at LUN 0 on /datadrive.
#
# This script runs INSIDE the VM, as root. Send it with Run Command:
#   az vm run-command invoke -g "$RG" -n vm-web-1 --command-id RunShellScript \
#     --scripts @mount-data-disk.sh --query "value[0].message" -o tsv
# or copy it to the VM and run: sudo bash mount-data-disk.sh
#
# Safe to run more than once: it never reformats a disk that already has a
# filesystem, and it only adds the /etc/fstab line once.
# =============================================================================
set -euo pipefail

MOUNT_POINT="${MOUNT_POINT:-/datadrive}"
LUN="${LUN:-0}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Please run as root (Run Command does this for you, or use: sudo bash $0)."
  exit 1
fi

if findmnt -rn "$MOUNT_POINT" >/dev/null 2>&1; then
  echo "Nothing to do: ${MOUNT_POINT} is already mounted."
  df -h "$MOUNT_POINT"
  exit 0
fi

# Find the block device of the data disk at the requested LUN.
find_disk() {
  local link dev name type hctl root_part root_disk
  local -a candidates=()
  # 1) Stable Azure symlinks (Azure Linux agent udev rules, or the azure-vm-utils package on newer images).
  for link in "/dev/disk/azure/scsi1/lun${LUN}" "/dev/disk/azure/data/by-lun/${LUN}"; do
    if [[ -e "$link" ]]; then
      readlink -f "$link"
      return 0
    fi
  done
  # 2) A filesystem this script labelled on an earlier run.
  dev="$(blkid -L datadrive 2>/dev/null || true)"
  if [[ -n "$dev" ]]; then
    echo "/dev/$(lsblk -no PKNAME "$dev" | head -n 1)"
    return 0
  fi
  # 3) An empty whole disk (no partitions, no filesystem) that is not the OS disk.
  #    Prefer the one whose SCSI address (HCTL) ends with the LUN; otherwise accept a single candidate.
  root_part="$(findmnt -no SOURCE /)"
  root_disk="/dev/$(lsblk -no PKNAME "$root_part" 2>/dev/null | head -n 1)"
  while read -r name type hctl; do
    [[ "$type" == "disk" && "$name" != "$root_disk" ]] || continue
    [[ "$(lsblk -nro TYPE "$name" | grep -c part || true)" -eq 0 ]] || continue
    blkid "$name" >/dev/null 2>&1 && continue
    if [[ "${hctl:-}" == *":${LUN}" ]]; then
      echo "$name"
      return 0
    fi
    candidates+=("$name")
  done < <(lsblk -dnpo NAME,TYPE,HCTL)
  if [[ "${#candidates[@]}" -eq 1 ]]; then
    echo "${candidates[0]}"
    return 0
  fi
  return 1
}

if ! DISK="$(find_disk)"; then
  echo "No data disk found at LUN ${LUN}. Attach one first, for example:"
  echo "  az vm disk attach -g <resource-group> --vm-name vm-web-1 --name disk-web-1-data --new --size-gb 8 --lun ${LUN}"
  exit 1
fi
echo "Data disk at LUN ${LUN}: ${DISK}"

# NVMe devices name their partitions with a 'p' (nvme0n2p1); SCSI devices don't (sdc1).
if [[ "$DISK" == *nvme* ]]; then PART="${DISK}p1"; else PART="${DISK}1"; fi

if [[ ! -b "$PART" ]]; then
  if blkid "$DISK" >/dev/null 2>&1; then
    echo "Refusing to continue: ${DISK} already contains data but has no partition 1. Check it by hand with lsblk."
    exit 1
  fi
  echo "Creating a GPT partition table with one partition on ${DISK}..."
  if command -v parted >/dev/null 2>&1; then
    parted --script "$DISK" mklabel gpt mkpart primary ext4 0% 100%
  else
    printf 'label: gpt\n,,L\n' | sfdisk --quiet "$DISK"
  fi
  udevadm settle || true
  for _ in $(seq 1 15); do [[ -b "$PART" ]] && break; sleep 1; done
fi

if ! blkid -s TYPE -o value "$PART" >/dev/null 2>&1; then
  echo "Formatting ${PART} as ext4..."
  mkfs.ext4 -q -L datadrive "$PART"
fi

mkdir -p "$MOUNT_POINT"
UUID="$(blkid -s UUID -o value "$PART")"
if ! grep -q "UUID=${UUID}" /etc/fstab; then
  # nofail: the VM still boots if this disk is ever detached.
  echo "UUID=${UUID} ${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab
  echo "Added ${MOUNT_POINT} to /etc/fstab."
fi
systemctl daemon-reload || true
mount "$MOUNT_POINT"
mkdir -p "${MOUNT_POINT}/images"

echo "Mounted ${PART} on ${MOUNT_POINT}:"
df -h "$MOUNT_POINT"
