#!/usr/bin/env bash
#
# Creates the application database principal, grants its read permission, and creates
# the Tickets table. Run this from a private-network-connected host as the configured
# Microsoft Entra SQL administrator after the subscription deployment succeeds.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bootstrap-ticketing-database.sh --deployment-name <name>

Options:
  --deployment-name <name>  Subscription deployment name that created the workload.
  --help                    Show this help.

Requirements:
  - Azure CLI signed in as the Microsoft Entra SQL administrator configured for the deployment.
  - Go-based sqlcmd authenticated with Azure CLI credentials (-G).
  - Network access to the SQL private endpoint. Public SQL access remains disabled.
EOF
}

deployment_name=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --deployment-name)
      [[ $# -ge 2 ]] || { echo "Missing value for --deployment-name." >&2; exit 2; }
      deployment_name="$2"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$deployment_name" ]] || { usage >&2; exit 2; }

for command in az sqlcmd getent; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command '$command' was not found." >&2
    exit 1
  }
done

resource_group="$(az deployment sub show --name "$deployment_name" --query 'properties.outputs.resourceGroupName.value' --output tsv)"
web_app_name="$(az deployment sub show --name "$deployment_name" --query 'properties.outputs.webAppName.value' --output tsv)"
sql_server_name="$(az deployment sub show --name "$deployment_name" --query 'properties.outputs.sqlServerName.value' --output tsv)"
database_name="$(az deployment sub show --name "$deployment_name" --query 'properties.outputs.databaseName.value' --output tsv)"

for value in "$resource_group" "$web_app_name" "$sql_server_name" "$database_name"; do
  [[ "$value" =~ ^[a-z0-9-]+$ ]] || {
    echo "Deployment outputs contain an unexpected resource name." >&2
    exit 1
  }
done

sql_host="${sql_server_name}.database.windows.net"
if ! getent ahostsv4 "$sql_host" | awk '{ print $1 }' | grep -Eq '^(10|172\.(1[6-9]|2[0-9]|3[0-1])|192\.168)\.'; then
  echo "SQL host '$sql_host' does not resolve to a private address from this host." >&2
  echo "Run this script from a network connected to the workload VNet." >&2
  exit 1
fi

app_principal="$web_app_name"
sql=$(cat <<EOF
IF DATABASE_PRINCIPAL_ID(N'${app_principal}') IS NULL
BEGIN
    CREATE USER [${app_principal}] FROM EXTERNAL PROVIDER;
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members AS role_members
    INNER JOIN sys.database_principals AS roles ON roles.principal_id = role_members.role_principal_id
    INNER JOIN sys.database_principals AS members ON members.principal_id = role_members.member_principal_id
    WHERE roles.name = N'db_datareader' AND members.name = N'${app_principal}'
)
BEGIN
    ALTER ROLE db_datareader ADD MEMBER [${app_principal}];
END;

IF OBJECT_ID(N'dbo.Tickets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Tickets (
        Id INT IDENTITY PRIMARY KEY,
        Title NVARCHAR(200) NOT NULL,
        Status NVARCHAR(50) NOT NULL
    );
END;
EOF
)

echo "Bootstrapping ${database_name} for managed identity ${app_principal}."
sqlcmd -S "tcp:${sql_host},1433" -d "$database_name" -G -b -l 30 -Q "$sql"
echo "Database bootstrap completed. Deploy the application and verify /readyz returns 200."
