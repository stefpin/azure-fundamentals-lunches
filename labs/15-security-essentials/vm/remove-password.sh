#!/bin/sh
# =============================================================================
# Lab 15 · runs INSIDE vm-app-1 through Run Command. Do not run it in Cloud Shell.
#
#   az vm run-command invoke --resource-group "$RG" --name vm-app-1 \
#     --command-id RunShellScript --scripts @vm/remove-password.sh \
#     --parameters "$KV_NAME"
#
# Replaces the connection string (and its password) in /etc/nusa/appsettings.json
# with a pointer to the secret in Key Vault: the vault URI and the secret name.
# Written for POSIX sh on purpose: Run Command may run scripts with /bin/sh.
# =============================================================================
VAULT="$1"
CONFIG=/etc/nusa/appsettings.json

if [ -z "$VAULT" ]; then
  echo "Usage: remove-password.sh <vault-name>"
  echo "RESULT: NO VAULT NAME"
  exit 0
fi

mkdir -p /etc/nusa
cat > "$CONFIG" <<EOF
{
  "Storefront": {
    "Name": "Nusantara Retail storefront",
    "Environment": "lab"
  },
  "KeyVault": {
    "VaultUri": "https://${VAULT}.vault.azure.net/",
    "OrdersConnectionSecretName": "sql-connection"
  }
}
EOF
chmod 644 "$CONFIG"

echo "New ${CONFIG}:"
cat "$CONFIG"
if grep -q "Password=" "$CONFIG"; then
  echo "RESULT: PASSWORD STILL PRESENT"
else
  echo "RESULT: CONFIG CLEAN"
fi
exit 0
