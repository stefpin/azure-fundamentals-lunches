#!/usr/bin/env bash
# =============================================================================
# azsql — run sqlcmd against Azure SQL with YOUR Microsoft Entra identity.
#
# Load it once per Cloud Shell session, from this lab folder:
#     source azsql.sh
# Then call it like sqlcmd, with the server name and the database first:
#     azsql "$SQL_FQDN" sqldb-orders -Q "SELECT SUSER_SNAME();"
#     azsql "$SQL_FQDN" sqldb-orders -i orders.sql
#
# How it works
#   Azure Cloud Shell includes the ODBC-based sqlcmd (package mssql-tools18). When you
#   use its -G option without -U, the -P option takes the PATH of a file that holds a
#   Microsoft Entra access token, encoded as UTF-16LE without a byte-order mark.
#   azsql asks the Azure CLI for a fresh token for Azure SQL, writes it to a private
#   file in your home folder, runs sqlcmd and deletes the file again. No password is
#   stored or typed anywhere.
#   If your machine has the newer Go-based sqlcmd instead, azsql uses that tool's
#   built-in ActiveDirectoryDefault authentication method.
# =============================================================================

# Converts stdin (ASCII) to UTF-16LE without a byte-order mark; falls back to Python without iconv.
_azsql_utf16le() {
  if command -v iconv >/dev/null 2>&1; then
    iconv -f ascii -t UTF-16LE
  else
    python3 -c 'import sys; sys.stdout.buffer.write(sys.stdin.buffer.read().decode("ascii").encode("utf-16-le"))'
  fi
}

# Returns 0 when the sqlcmd on the PATH is the ODBC-based variant.
_azsql_is_odbc() {
  local bin
  bin="$(command -v sqlcmd 2>/dev/null)"
  [[ "$bin" == *mssql-tools* ]] && return 0
  sqlcmd '-?' 2>&1 | grep -Eq 'Version 1[3-9]\.'
}

azsql() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: azsql <server>.database.windows.net <database> [sqlcmd options]" >&2
    return 2
  fi
  local server="$1" database="$2" rc=0
  shift 2

  if ! command -v sqlcmd >/dev/null 2>&1; then
    echo "sqlcmd was not found. Use Azure Cloud Shell (Bash), or install sqlcmd first." >&2
    return 127
  fi

  if ! _azsql_is_odbc; then
    sqlcmd -S "$server" -d "$database" --authentication-method ActiveDirectoryDefault -l 60 "$@" || rc=$?
    return "$rc"
  fi

  local token_file="${HOME}/.azsql-token-$$"
  ( umask 077
    az account get-access-token --resource https://database.windows.net \
      --query accessToken --output tsv 2>/dev/null \
      | tr -d '\r\n' | _azsql_utf16le > "$token_file" ) || true
  if [[ ! -s "$token_file" ]]; then
    rm -f "$token_file"
    echo "Could not get a Microsoft Entra access token for Azure SQL. Run 'az login' and try again." >&2
    return 1
  fi

  # -G = Microsoft Entra authentication, -P = token file, -I = QUOTED_IDENTIFIER ON, -l = login timeout (s)
  sqlcmd -S "$server" -d "$database" -G -P "$token_file" -I -l 60 "$@" || rc=$?
  rm -f "$token_file"
  return "$rc"
}
