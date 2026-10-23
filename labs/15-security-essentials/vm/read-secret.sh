#!/bin/sh
# =============================================================================
# Lab 15 · runs INSIDE vm-app-1 through Run Command. Do not run it in Cloud Shell.
#
#   az vm run-command invoke --resource-group "$RG" --name vm-app-1 \
#     --command-id RunShellScript --scripts @vm/read-secret.sh \
#     --parameters "$KV_NAME" [audience] [secret-name]
#
# Step 1: ask the VM's managed identity endpoint (IMDS) for an access token.
# Step 2: call the Key Vault REST API with that token and report the HTTP status.
# The token and the secret value are never printed (only a masked preview).
# Written for POSIX sh on purpose: Run Command may run scripts with /bin/sh.
# =============================================================================
VAULT="$1"
AUDIENCE="${2:-https://vault.azure.net}"
SECRET="${3:-sql-connection}"
KV_API_VERSION="2025-07-01"

if [ -z "$VAULT" ]; then
  echo "Usage: read-secret.sh <vault-name> [audience] [secret-name]"
  echo "RESULT: NO VAULT NAME"
  exit 0
fi

echo "Step 1: ask the managed identity endpoint (IMDS) for a token, audience ${AUDIENCE}"
TOKEN_JSON=$(curl -s --max-time 10 -H "Metadata: true" -G \
  "http://169.254.169.254/metadata/identity/oauth2/token" \
  --data-urlencode "api-version=2018-02-01" \
  --data-urlencode "resource=${AUDIENCE}")
TOKEN=$(printf '%s' "$TOKEN_JSON" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("access_token", ""))
except Exception:
    print("")')

if [ -z "$TOKEN" ]; then
  echo "  no token. IMDS answered: $(printf '%s' "$TOKEN_JSON" | head -c 300)"
  echo "  hint: does vm-app-1 have a managed identity yet? (az vm identity show)"
  echo "RESULT: NO TOKEN"
  exit 0
fi

echo "  got a token (${#TOKEN} characters); the token itself is never printed"
printf '%s' "$TOKEN" | python3 -c 'import sys, json, base64
try:
    part = sys.stdin.read().split(".")[1]
    part += "=" * (-len(part) % 4)
    claims = json.loads(base64.urlsafe_b64decode(part))
    print("  token audience (aud):     " + str(claims.get("aud")))
    print("  identity object ID (oid): " + str(claims.get("oid")))
except Exception:
    print("  (could not decode the token claims)")'

echo "Step 2: GET https://${VAULT}.vault.azure.net/secrets/${SECRET}"
RESPONSE=$(curl -s --max-time 15 -w '\nHTTP_STATUS:%{http_code}' \
  -H "Authorization: Bearer ${TOKEN}" \
  "https://${VAULT}.vault.azure.net/secrets/${SECRET}?api-version=${KV_API_VERSION}")
CODE=$(printf '%s\n' "$RESPONSE" | sed -n 's/^HTTP_STATUS://p')
BODY=$(printf '%s\n' "$RESPONSE" | sed '/^HTTP_STATUS:/d')
CODE="${CODE:-000}"
echo "  HTTP ${CODE}"

printf '%s' "$BODY" | python3 -c 'import sys, json
code = sys.argv[1]
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    if code == "000":
        print("  no response: the VM could not reach the vault (network path, DNS or vault name)")
    else:
        print("  (the response was not JSON)")
    sys.exit(0)
if code == "200":
    value = data.get("value", "")
    print("  secret value (masked):    " + value[:26] + "... (" + str(len(value)) + " characters)")
else:
    err = data.get("error", {})
    inner = (err.get("innererror") or {}).get("code", "")
    print("  error:   " + err.get("code", "") + (" / " + inner if inner else ""))
    message = err.get("message", "").replace("\r", "").split("\n")[0]
    print("  message: " + message[:200])' "$CODE"

echo "RESULT: HTTP ${CODE}"
exit 0
