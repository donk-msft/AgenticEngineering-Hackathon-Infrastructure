# Contoso Ticketing Operations Runbook

This runbook covers the reference deployment in `infra/`. Source control is the desired state; make
persistent changes through Bicep and use the live checks in
[`docs/desired-state.md`](desired-state.md) after every deployment or incident.

## Deployment context

The operational scripts read resource names from the outputs of the **subscription deployment**.
Use the same deployment name that was passed to `az deployment sub create --name`:

```bash
deployment_name=ticketing-baseline
az deployment sub show \
  --name "$deployment_name" \
  --query "{state:properties.provisioningState, outputs:properties.outputs}" \
  -o json
```

If the name is unknown, list recent deployments rather than guessing:

```bash
az deployment sub list \
  --query "sort_by([].{name:name, timestamp:properties.timestamp, state:properties.provisioningState}, &timestamp)[-10:]" \
  -o table
```

## Bootstrap SQL access

The Bicep deployment creates the SQL server, database, private endpoint, private DNS, and App
Service managed identity. Azure Resource Manager cannot create the contained database user, and the
App Service identity **cannot create its own SQL principal**: until an Entra SQL administrator
creates that principal, the identity has no database authorization with which to execute `CREATE
USER`. This is a one-time data-plane trust establishment.

The baseline automates it end to end. `infra/modules/identity-bootstrap.bicep` creates a
user-assigned managed identity that is the **sole** Microsoft Entra SQL administrator (Azure SQL
only supports one Entra admin principal natively), and `infra/modules/database-bootstrap.bicep`
runs a `Microsoft.Resources/deploymentScripts` (AzureCLI kind) container, integrated into the
workload VNet through the `snet-deployscript` subnet, using that identity. There is no VM, Bastion
session, SSH key or Key Vault secret involved — the deployment script's container image runs
[`scripts/bootstrap-ticketing-database-deploymentscript.sh`](../scripts/bootstrap-ticketing-database-deploymentscript.sh)
automatically as part of `az deployment sub create`.

The script:

1. Reads the SQL server, database, web app, and managed identity client ID from environment
   variables the Bicep module injects.
2. Installs `go-sqlcmd`, verifies it is on `PATH`, and authenticates with
   `--authentication-method=ActiveDirectoryManagedIdentity` using the deployment script's own
   managed identity — no SQL password, no human sign-in.
3. Idempotently creates the App Service identity as a contained user, grants `db_datareader`, and
   creates `dbo.Tickets`.

The contained user is created with the App Service managed identity **application (client) ID**
encoded as little-endian binary for `SID` (`TYPE = E`), instead of requiring the SQL server identity
to resolve the display name through Microsoft Entra.
This avoids granting the SQL server identity the tenant-wide Directory Readers role.

Re-running `az deployment sub create` with the same parameters re-runs the deployment script
idempotently (increment the module's `baseTime` parameter or delete the prior
`Microsoft.Resources/deploymentScripts` resource to force a re-run if you change the script logic).
Do not temporarily enable SQL public access. Do not put an administrator token, password, SQL
connection secret, or generated access token in a workflow or repository variable.

Verify the bootstrap from anywhere with network access to the public app routes:

```bash
web_app_host="$(az deployment sub show --name ticketing-baseline \
  --query properties.outputs.webAppHostName.value -o tsv)"

curl --fail-with-body "https://${web_app_host}/healthz"
curl --fail-with-body "https://${web_app_host}/readyz"
curl --fail-with-body "https://${web_app_host}/api/tickets"
```

Expected results are HTTP `200` for all three routes. A `503` from `/readyz` or `500` from
`/api/tickets` after bootstrap should be investigated with
[`knowledge/runbook-http-500.md`](../knowledge/runbook-http-500.md).

## Alert triage

The deployment defines alerts for App Service HTTP 5xx responses, response time, health-check
status, `/readyz` availability, and SQL CPU. Alert rules intentionally have no notification action
group because notification destinations are environment-specific. Add an approved action group in
the consuming environment or connect the rules to an Azure SRE Agent scoped to the workload
resource group.

Never inject a lab fault into Bicep or `main`. Expert Lab 4 faults are temporary, manually recorded
drift and must be reconciled from source after the exercise.
