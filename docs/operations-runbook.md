# Contoso Ticketing Operations Runbook

This runbook covers the reference deployment in `infra/`. Source control is the desired state; make
persistent changes through Bicep and use the live checks in
[`docs/desired-state.md`](desired-state.md) after every deployment or incident.

The validated composition parameters, module inputs, outputs, dependencies, and pinned AVM versions
are documented in the [deployment guide](deployment-guide.md#validated-module-interfaces). The
following controls are mandatory during every operation: managed identity, private-only SQL,
required tags, exact AVM pinning, HTTPS only, TLS 1.2 or higher, disabled FTPS, least-privilege NSGs,
and explicit deny-all inbound rules.

## Deployment context

The operational scripts read resource names from the outputs of the **subscription deployment**.
Use the same deployment name that was passed to `az deployment sub create --name`:

```bash
deployment_name="${DEPLOYMENT_NAME:?Set DEPLOYMENT_NAME}"
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

1. Reads the SQL server, database, web app, web app system-assigned principal ID, and bootstrap
   identity client ID from environment variables the Bicep module injects.
2. Resolves the web app service principal's application (client) ID through Microsoft Graph. The
   bootstrap identity needs the Microsoft Graph `Application.Read.All` application permission,
   approved by a Microsoft Entra administrator for the target tenant. The template does not silently
   grant a tenant-wide directory role.
3. Installs `go-sqlcmd`, verifies it is on `PATH`, and authenticates with
   `--authentication-method=ActiveDirectoryManagedIdentity` using the deployment script's own
   managed identity — no SQL password, no human sign-in.
4. Idempotently creates the App Service identity as a contained user, grants `db_datareader`, and
   creates `dbo.Tickets`.

The contained user is created with the App Service managed identity **application (client) ID**
encoded as little-endian binary for `SID` (`TYPE = E`), instead of requiring the SQL server identity
to resolve the display name through Microsoft Entra.
This avoids granting the SQL server identity the tenant-wide Directory Readers role.

Before deployment, confirm the bootstrap identity can read the web app service principal:

```bash
web_app_principal_id="${WEB_APP_PRINCIPAL_ID:?Set WEB_APP_PRINCIPAL_ID}"
az ad sp show --id "$web_app_principal_id" --query appId --output tsv
```

Run this check using the bootstrap identity's permissions. A failure is a directory authorization
prerequisite failure; obtain owner approval and Entra administrator consent for
`Application.Read.All`. Do not work around it by enabling SQL public access, granting
`Directory.Read.All`, or adding a credential.

Re-running `az deployment sub create` with the same parameters re-runs the deployment script
idempotently (increment the module's `baseTime` parameter or delete the prior
`Microsoft.Resources/deploymentScripts` resource to force a re-run if you change the script logic).
Do not temporarily enable SQL public access. Do not put an administrator token, password, SQL
connection secret, or generated access token in a workflow or repository variable.

Verify the bootstrap from anywhere with network access to the public app routes:

```bash
deployment_name="${DEPLOYMENT_NAME:?Set DEPLOYMENT_NAME}"
web_app_host="$(az deployment sub show --name "$deployment_name" \
  --query properties.outputs.webAppHostName.value -o tsv)"

curl --fail-with-body "https://${web_app_host}/healthz"
curl --fail-with-body "https://${web_app_host}/readyz"
curl --fail-with-body "https://${web_app_host}/api/tickets"
```

Expected results are HTTP `200` for all three routes. A `503` from `/readyz` or `500` from
`/api/tickets` after bootstrap should be investigated with
[`knowledge/runbook-http-500.md`](../knowledge/runbook-http-500.md).

## Routine validation

Run local validation before every infrastructure or application release:

```bash
./scripts/validate-infra.sh
dotnet build src/ContosoTicketing
```

Both commands must finish with zero warnings. After deployment, derive resource names from outputs:

```bash
deployment_name="${DEPLOYMENT_NAME:?Set DEPLOYMENT_NAME}"
resource_group="$(az deployment sub show --name "$deployment_name" \
  --query properties.outputs.resourceGroupName.value --output tsv)"
web_app_name="$(az deployment sub show --name "$deployment_name" \
  --query properties.outputs.webAppName.value --output tsv)"
sql_server_name="$(az deployment sub show --name "$deployment_name" \
  --query properties.outputs.sqlServerName.value --output tsv)"
```

Do not paste the resulting live values into source control. Collect redacted evidence for each
check:

| Check | Expected result |
|---|---|
| Subscription deployment state | `Succeeded` |
| Resource names and tags | Approved naming; `environment`, `workload`, `owner`, `costCenter` present |
| SQL public network access | `Disabled` |
| SQL private endpoint | Connection state `Approved` |
| SQL private DNS from app context | SQL FQDN resolves to the private endpoint subnet |
| Subnet NSGs | Every subnet attached; deny-all inbound at priority 4096 |
| SQL administrator | Bootstrap identity is the sole Microsoft Entra administrator |
| Deployment script network | No public IP; delegated workload subnet only |
| Deployment script retention | `cleanupPreference: OnExpiration`; `retentionInterval: P1D` |
| Web app identity | System-assigned identity enabled; no credential-bearing setting |
| App Service transport | HTTPS only; TLS 1.2 or higher; FTPS disabled |
| Monitoring | Application Insights is workspace-based and receives recent telemetry |
| Application routes | `/healthz`, `/readyz`, and `/api/tickets` return HTTP `200` |

Inspect settings without printing their values:

```bash
az webapp config appsettings list \
  --resource-group "$resource_group" \
  --name "$web_app_name" \
  --query "[].name" \
  --output tsv

az sql server show \
  --resource-group "$resource_group" \
  --name "$sql_server_name" \
  --query publicNetworkAccess \
  --output tsv
```

The settings list must contain no password, key, token, or connection secret. The passwordless SQL
connection configuration and Application Insights connection string are endpoint configuration;
do not print or persist their values in evidence.

## Alert triage

The deployment defines alerts for App Service HTTP 5xx responses, response time, health-check
status, `/readyz` availability, and SQL CPU. Alert rules intentionally have no notification action
group because notification destinations are environment-specific. Add an approved action group in
the consuming environment or connect the rules to an Azure SRE Agent scoped to the workload
resource group.

Never inject a lab fault into Bicep or `main`. Expert Lab 4 faults are temporary, manually recorded
drift and must be reconciled from source after the exercise.

## Rollback

### Infrastructure update

1. Stop further rollout and preserve the failed deployment record and retained deployment-script
  logs.
2. Identify the last known-good Bicep revision and parameter set. Keep all live values outside the
  repository.
3. Run `./scripts/validate-infra.sh`, the .NET build, subscription validation, and what-if against
  that revision.
4. Confirm what-if affects only the workload scope and does not delete required data.
5. Redeploy the known-good revision, then repeat every routine validation check.

Do not use public SQL access, SQL passwords, stored Azure client secrets, broad NSG rules, lower TLS,
or unpinned AVM versions as rollback shortcuts.

### Application update

Redeploy the last known-good application artifact to the web app discovered from deployment outputs.
The baseline has no deployment slots, so record the artifact identifier before every release. Verify
`/healthz`, `/readyz`, `/api/tickets`, and recent Application Insights telemetry after rollback.

### Failed initial deployment

Diagnose the failed nested deployment before cleanup. Deleting the workload resource group is
destructive and requires workload-owner approval plus confirmation that it contains no shared
resources or evidence that must be retained.

## Troubleshooting

| Symptom | Evidence to inspect | Resolution |
|---|---|---|
| Subscription deployment failed | Failed nested deployment operation and correlation details | Correct the owning module or prerequisite, rerun local validation and what-if, then redeploy |
| What-if reports `NestedDeploymentShortCircuited` | Subscription validation result and visible resource scope | If validation succeeds, treat it as initial-output evaluation limitation; otherwise fix the template error |
| Bootstrap reports a Graph authorization failure | Retained deployment-script logs | Obtain Entra administrator consent for `Application.Read.All` on the bootstrap identity; never add `Directory.Read.All` or a credential |
| Bootstrap cannot resolve SQL privately | Private DNS VNet link, endpoint approval, subnet delegation, and NSG TCP 1433 rule | Restore the private path through Bicep; keep SQL public access disabled |
| Bootstrap container or logs disappeared | Deployment-script cleanup and retention properties | Restore `OnExpiration` and `P1D`, redeploy, and retain logs before further changes |
| `/healthz` is not `200` | App deployment status, .NET runtime, App Service logs | Redeploy the known-good artifact and verify the `/healthz` platform path |
| `/readyz` is `503` | SQL dependency telemetry, DNS result, contained database user, managed identity | Repair the private data path or bootstrap authorization; do not add a password |
| `/api/tickets` is `500` | Application exception and SQL dependency telemetry | Follow `knowledge/runbook-http-500.md`; preserve parameterized SQL |
| Application Insights has no telemetry | App setting name, workspace link, application startup logs | Restore the module-managed configuration without exposing its value |
| NSG validation fails | Effective NSG association and rule priorities | Restore least-privilege rules and explicit deny-all inbound at priority 4096 |

## Evidence and escalation

Record timestamps, deployment name, command result, HTTP status, and redacted diagnostic excerpts in
`docs/test-results.md`. Do not record subscription IDs, tenant IDs, resource IDs, live host names,
personal accounts, tokens, keys, passwords, or connection values.

Escalate directory-consent changes to a Microsoft Entra administrator, destructive rollback to the
workload owner, and unresolved availability or data-path incidents through the process in
[`knowledge/escalation.md`](../knowledge/escalation.md).
