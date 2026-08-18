#!/usr/bin/env bash
#
# Bootstraps the Contoso Ticketing database automatically from a
# Microsoft.Resources/deploymentScripts container that runs inside the workload
# virtual network. Unlike the interactive scripts/bootstrap-ticketing-database.sh,
# this script reads its inputs from environment variables (populated by Bicep)
# instead of querying `az deployment sub show`, and authenticates to SQL as the
# deployment script's own user-assigned managed identity, which is configured as
# the sole Microsoft Entra administrator on the SQL logical server.
set -euo pipefail

for var in SQL_SERVER_NAME DATABASE_NAME WEB_APP_NAME MANAGED_IDENTITY_CLIENT_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "Required environment variable '${var}' was not set." >&2
    exit 1
  fi
done

echo "Installing go-sqlcmd..."
sqlcmd_version="1.6.0"
sqlcmd_archive="/tmp/sqlcmd.tar.bz2"
sqlcmd_url="https://github.com/microsoft/go-sqlcmd/releases/download/v${sqlcmd_version}/sqlcmd-v${sqlcmd_version}-linux-amd64.tar.bz2"

curl --fail --location --silent --show-error --retry 3 --retry-delay 5 --output "${sqlcmd_archive}" "${sqlcmd_url}"
mkdir -p /tmp/sqlcmd

if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import tarfile
archive = "/tmp/sqlcmd.tar.bz2"
output_dir = "/tmp/sqlcmd"
with tarfile.open(archive, mode="r:bz2") as archive_file:
    archive_file.extractall(output_dir)
PY
else
  echo "python3 is required to extract the go-sqlcmd tarball." >&2
  exit 1
fi

export PATH="/tmp/sqlcmd:${PATH}"

sql_host="${SQL_SERVER_NAME}.database.windows.net"
app_principal="${WEB_APP_NAME}"

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

echo "Bootstrapping ${DATABASE_NAME} for managed identity ${app_principal}."
sqlcmd -S "tcp:${sql_host},1433" -d "${DATABASE_NAME}" \
  --authentication-method=ActiveDirectoryManagedIdentity -U "${MANAGED_IDENTITY_CLIENT_ID}" \
  -b -l 30 -Q "$sql"

echo '{"result":"bootstrap completed"}' > "$AZ_SCRIPTS_OUTPUT_PATH"
echo "Database bootstrap completed."
