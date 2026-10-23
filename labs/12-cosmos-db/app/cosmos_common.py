"""Shared helpers for the Lab 12 scripts: connect to Azure Cosmos DB and read request charges.

Authentication
  * Default: Microsoft Entra ID with the identity you are signed in with in the Azure CLI
    (`az login`, or automatically in Azure Cloud Shell). Your identity needs a Cosmos DB
    data-plane role such as "Cosmos DB Built-in Data Contributor" (Lab 12, Task 3).
  * Fallback: an account key in the COSMOS_KEY environment variable. Only use it if Entra ID
    access is blocked for you, and read the trade-off in the lab guide first.

Environment variables
  COSMOS_ENDPOINT   https://<account>.documents.azure.com:443/   (required)
  COSMOS_DATABASE   database name   (default: catalog)
  COSMOS_CONTAINER  container name  (default: products)
  COSMOS_KEY        account key     (optional fallback; never commit or print it)
"""
import os
import sys

DATABASE = os.environ.get("COSMOS_DATABASE", "catalog")
CONTAINER = os.environ.get("COSMOS_CONTAINER", "products")
CONSISTENCY_LEVELS = ["Strong", "BoundedStaleness", "Session", "ConsistentPrefix", "Eventual"]

EXIT_ERROR = 1        # anything unexpected
EXIT_SETUP = 2        # missing package or environment variable
EXIT_AUTH = 3         # signed out, or no data-plane permission (yet)


def fail(message, code=EXIT_ERROR):
    print(message, file=sys.stderr)
    sys.exit(code)


def _import_sdk():
    try:
        from azure.cosmos import CosmosClient  # noqa: F401
    except ImportError:
        fail("The Azure Cosmos DB SDK for Python is not installed. Install it with:\n"
             "    pip install --user azure-cosmos azure-identity", EXIT_SETUP)
    from azure.cosmos import CosmosClient
    return CosmosClient


def _credential():
    """Return (credential, human-readable description)."""
    key = os.environ.get("COSMOS_KEY", "").strip()
    if key:
        return key, "account key from COSMOS_KEY (fallback mode)"
    try:
        from azure.identity import AzureCliCredential, ChainedTokenCredential, ManagedIdentityCredential
    except ImportError:
        fail("The azure-identity package is not installed. Install it with:\n"
             "    pip install --user azure-cosmos azure-identity", EXIT_SETUP)
    try:
        cli = AzureCliCredential(process_timeout=30)
    except TypeError:  # older azure-identity versions have no process_timeout
        cli = AzureCliCredential()
    # Azure CLI sign-in first; in Azure Cloud Shell the managed identity endpoint also acts as you.
    credential = ChainedTokenCredential(cli, ManagedIdentityCredential())
    return credential, "Microsoft Entra ID (your Azure CLI / Cloud Shell sign-in)"


def explain_and_exit(exc):
    """Turn the most common SDK errors into a short, actionable message."""
    status = getattr(exc, "status_code", None)
    name = type(exc).__name__
    text = str(exc).splitlines()[0] if str(exc) else name
    if name in ("ClientAuthenticationError", "CredentialUnavailableError"):
        fail("Could not get a Microsoft Entra token from the Azure CLI.\n"
             "  - Run 'az account show' to check that you are signed in (run 'az login' if not).\n"
             f"  - Details: {text}", EXIT_AUTH)
    if status in (401, 403):
        fail(f"Cosmos DB refused the request (HTTP {status}).\n"
             "  - Using Entra ID? Your identity needs the data-plane role 'Cosmos DB Built-in Data Contributor'\n"
             "    on this account (Task 3). New role assignments can take a few minutes to apply: wait and retry.\n"
             "  - Using COSMOS_KEY? Check that the key belongs to this account.\n"
             f"  - Details: {text[:300]}", EXIT_AUTH)
    if status == 404:
        fail(f"Not found (HTTP 404): check that database '{DATABASE}' and container '{CONTAINER}' exist,\n"
             "and that the id and partition key value you asked for are spelled exactly right.", EXIT_ERROR)
    if status == 400 and "consistency" in text.lower():
        fail("Cosmos DB rejected the consistency level. A client may only ask for the account's default level\n"
             "or a WEAKER one (Strong > BoundedStaleness > Session > ConsistentPrefix > Eventual).\n"
             f"  - Details: {text[:300]}", EXIT_ERROR)
    if name in ("ServiceRequestError", "ServiceResponseError"):
        fail(f"Could not reach the Cosmos DB endpoint. Check COSMOS_ENDPOINT.\n  - Details: {text}", EXIT_ERROR)
    fail(f"{name}: {text[:500]}", EXIT_ERROR)


def connect(consistency=None):
    """Return (client, container, auth_description). Exits with a clear message on failure."""
    CosmosClient = _import_sdk()
    endpoint = os.environ.get("COSMOS_ENDPOINT", "").strip()
    if not endpoint:
        fail("Set COSMOS_ENDPOINT first, for example:\n"
             "    export COSMOS_ENDPOINT=$(az cosmosdb show -g \"$RG\" -n \"$ACCOUNT\" "
             "--query documentEndpoint -o tsv)", EXIT_SETUP)
    credential, description = _credential()
    kwargs = {}
    if consistency:
        kwargs["consistency_level"] = consistency
    try:
        client = CosmosClient(endpoint, credential, **kwargs)
        container = client.get_database_client(DATABASE).get_container_client(CONTAINER)
    except Exception as exc:  # pylint: disable=broad-except
        explain_and_exit(exc)
    return client, container, description


def account_default_consistency(client):
    """Best effort: the account's default consistency level, or None if the SDK doesn't expose it."""
    try:
        account = client.get_database_account()
        policy = getattr(account, "ConsistencyPolicy", None) or {}
        return policy.get("defaultConsistencyLevel")
    except Exception:  # pylint: disable=broad-except
        return None


def last_headers(container):
    headers = getattr(container.client_connection, "last_response_headers", None)
    return headers or {}


def request_charge(container):
    """Request units (RU) charged for the last operation the container client ran."""
    try:
        return float(last_headers(container).get("x-ms-request-charge", 0) or 0)
    except (TypeError, ValueError):
        return 0.0


def rupiah(value):
    try:
        return "Rp " + f"{int(value):,}".replace(",", ".")
    except (TypeError, ValueError):
        return str(value)
