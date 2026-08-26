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

for var in SQL_SERVER_NAME DATABASE_NAME WEB_APP_NAME WEB_APP_PRINCIPAL_ID MANAGED_IDENTITY_CLIENT_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "Required environment variable '${var}' was not set." >&2
    exit 1
  fi
done

if [[ ! "${WEB_APP_PRINCIPAL_ID}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
  echo "WEB_APP_PRINCIPAL_ID must be a Microsoft Entra object ID." >&2
  exit 1
fi

if ! web_app_client_id="$(az ad sp show --id "${WEB_APP_PRINCIPAL_ID}" --query appId --output tsv)"; then
  echo "The bootstrap identity could not read the web app service principal. An Entra administrator must approve Microsoft Graph Application.Read.All for this identity before deployment." >&2
  exit 1
fi
if [[ ! "${web_app_client_id}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
  echo "Could not resolve the web app system-assigned identity client ID." >&2
  exit 1
fi

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

if ! command -v sqlcmd >/dev/null 2>&1; then
  echo "sqlcmd was not found in PATH after extraction. Listing /tmp/sqlcmd:" >&2
  ls -la /tmp/sqlcmd >&2 || true
  exit 1
fi

sqlcmd --version

sql_host="${SQL_SERVER_NAME}.database.windows.net"
app_principal="${WEB_APP_NAME}"
app_principal_sid="$(python3 -c 'import sys, uuid; print(f"0x{uuid.UUID(sys.argv[1]).bytes_le.hex().upper()}")' "${web_app_client_id}")"

sql=$(cat <<EOF
DECLARE @ExpectedSid VARBINARY(16) = CONVERT(VARBINARY(16), ${app_principal_sid}, 1);

IF DATABASE_PRINCIPAL_ID(N'${app_principal}') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.database_principals
        WHERE name = N'${app_principal}' AND type = 'E' AND sid <> @ExpectedSid
    )
    BEGIN
        DROP USER [${app_principal}];
    END;
END;

IF DATABASE_PRINCIPAL_ID(N'${app_principal}') IS NULL
BEGIN
    CREATE USER [${app_principal}] WITH SID = @ExpectedSid, TYPE = E;
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

SELECT name, type_desc, CONVERT(varchar(100), sid, 1) AS sid_hex
FROM sys.database_principals
WHERE name = N'${app_principal}';
EOF
)

echo "Bootstrapping ${DATABASE_NAME} for managed identity ${app_principal}."
sqlcmd -S "tcp:${sql_host},1433" -d "${DATABASE_NAME}" \
  --authentication-method=ActiveDirectoryManagedIdentity -U "${MANAGED_IDENTITY_CLIENT_ID}" \
  -b -l 30 -Q "$sql"

echo '{"result":"bootstrap completed"}' > "$AZ_SCRIPTS_OUTPUT_PATH"
echo "Database bootstrap completed."
