#!/usr/bin/env bash
# =============================================================================
# Shared settings for every lab.
#
# Load it from inside a lab folder:
#     source ../common/config.sh
#
# Override any value BEFORE sourcing, for example:
#     export LOCATION=indonesiacentral
#     source ../common/config.sh
# (Use "export" on its own line: a prefix such as "LOCATION=x source ..." does not stick.)
# =============================================================================

# Region for all lab resources. Pick one close to you that has availability zones.
# The labs are written for southeastasia (Singapore): 3 availability zones and very
# broad service coverage. indonesiacentral (Jakarta, 3 zones) is a great choice for
# learners in Indonesia — check that every service a lab uses is offered there.
export LOCATION="${LOCATION:-southeastasia}"

# Second region, used only by labs that need two regions (DR, geo-replication,
# global routing). eastasia is the paired region of southeastasia.
export SECONDARY_LOCATION="${SECONDARY_LOCATION:-eastasia}"

# A short random suffix keeps globally unique names (storage accounts, web apps,
# key vaults, SQL servers...) from colliding with other learners. It is generated
# once and remembered in ~/.azlunches-suffix.
_azl_suffix_file="${HOME}/.azlunches-suffix"
if [[ -z "${SUFFIX:-}" ]]; then
  if [[ -s "${_azl_suffix_file}" ]]; then
    SUFFIX="$(cat "${_azl_suffix_file}")"
  else
    SUFFIX="$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
    echo "${SUFFIX}" > "${_azl_suffix_file}"
  fi
fi
export SUFFIX

# Small, low-cost VM sizes. If a size is not offered in your region, list the
# alternatives and set VM_SIZE / VM_SIZE_SMALL before sourcing this file:
#     az vm list-skus --location "$LOCATION" --resource-type virtualMachines --size Standard_B --output table
# Older series such as B-series v1 (Standard_B1s, B1ms...) can't be deployed by NEW subscriptions
# (capacity growth restrictions since July 2026), so the labs use current sizes only. The smallest
# current burstable sizes have 2 vCPUs: Standard_B2ats_v2 (AMD) and Standard_B2pts_v2 (Arm).
export VM_SIZE="${VM_SIZE:-Standard_B2ats_v2}"              # 2 vCPU, 1 GiB, burstable (free-account eligible)
export VM_SIZE_SMALL="${VM_SIZE_SMALL:-Standard_B2ats_v2}"  # for labs that run several VMs at once
export VM_IMAGE="${VM_IMAGE:-Ubuntu2404}"
export ADMIN_USER="${ADMIN_USER:-azureuser}"

# Every resource group a lab creates carries these tags, so cleanup scripts can find them.
export COURSE_TAG="azure-fundamentals-lunches"

# Absolute path of this folder (labs/common), handy for shared files such as cloud-init.
AZL_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AZL_COMMON_DIR

# rg_name <lunch-number> [purpose]  ->  rg-lunch06-ab12c  or  rg-lunch25-hub-ab12c
rg_name() {
  if [[ -n "${2:-}" ]]; then
    echo "rg-lunch${1}-${2}-${SUFFIX}"
  else
    echo "rg-lunch${1}-${SUFFIX}"
  fi
}

# shellcheck source=helpers.sh
source "${AZL_COMMON_DIR}/helpers.sh"

if [[ -z "${AZL_QUIET:-}" ]]; then
  printf 'Lab settings: LOCATION=%s  SECONDARY_LOCATION=%s  SUFFIX=%s  VM_SIZE=%s\n' \
    "$LOCATION" "$SECONDARY_LOCATION" "$SUFFIX" "$VM_SIZE"
fi
