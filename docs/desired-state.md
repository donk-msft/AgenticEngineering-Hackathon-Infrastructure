# Contoso Ticketing Desired State

`infra/` is the authoritative desired state. The checks below verify the live deployment rather
than assuming a successful template deployment means the workload is compliant.

## Resolve deployment outputs

Set the subscription deployment name used during deployment:

```bash
deployment_name=ticketing-baseline
resource_group="$(az deployment sub show --name "$deployment_name" \
  --query properties.outputs.resourceGroupName.value -o tsv)"
web_app="$(az deployment sub show --name "$deployment_name" \
  --query properties.outputs.webAppName.value -o tsv)"
sql_server="$(az deployment sub show --name "$deployment_name" \
  --query properties.outputs.sqlServerName.value -o tsv)"
database="$(az deployment sub show --name "$deployment_name" \
  --query properties.outputs.databaseName.value -o tsv)"
```

## Live invariants

| Invariant | Required state | Live verification | Drift response |
|---|---|---|---|
| Deployment | `Succeeded` | `az deployment sub show --name "$deployment_name" --query properties.provisioningState -o tsv` | Stop; inspect deployment operations before any reconciliation. |
| SQL network access | `Disabled` | `az sql server show -g "$resource_group" -n "$sql_server" --query publicNetworkAccess -o tsv` | Critical: disable immediately, preserve activity logs, then reconcile from Bicep. |
| SQL private endpoint | `Approved` | `az network private-endpoint-connection list -g "$resource_group" -n "$sql_server" --type Microsoft.Sql/servers --query "[].properties.privateLinkServiceConnectionState.status" -o tsv` | Restore the approved private endpoint from Bicep; never enable public access as a workaround. |
| App identity | System-assigned principal present | `az webapp identity show -g "$resource_group" -n "$web_app" --query principalId -o tsv` | Redeploy identity, then rerun the private SQL bootstrap if Azure assigned a new principal. |
| App HTTPS | `true` | `az webapp show -g "$resource_group" -n "$web_app" --query httpsOnly -o tsv` | Critical: set HTTPS-only immediately and reconcile. |
| App TLS | `1.2` or higher | `az webapp config show -g "$resource_group" -n "$web_app" --query minTlsVersion -o tsv` | Restore from Bicep; investigate who changed the configuration. |
| App FTPS | `Disabled` | `az webapp config show -g "$resource_group" -n "$web_app" --query ftpsState -o tsv` | Disable and reconcile from Bicep. |
| NSG deny-all | Both NSGs contain inbound deny priority `4096` | ``az network nsg list -g "$resource_group" --query '[].{nsg:name,deny:securityRules[?direction==`Inbound` && access==`Deny` && priority==`4096`].name}' -o json`` | Restore the rule from Bicep and review activity logs for exposure. |
| Required tags | Every resource has `environment`, `workload`, `owner`, `costCenter` | `az resource list -g "$resource_group" --query "[?tags.environment==null || tags.workload==null || tags.owner==null || tags.costCenter==null].{name:name,type:type}" -o table` | Open an ownership issue; reconcile tags through Bicep. |
| Secretless app settings | No password, key, or token setting | `az webapp config appsettings list -g "$resource_group" -n "$web_app" --query "[?contains(to_lower(name),'password') || contains(to_lower(name),'secret') || contains(to_lower(name),'token') || contains(to_lower(name),'key')].name" -o tsv` | Treat discovered credentials as compromised, rotate them, remove them, and restore managed identity. |
| Monitoring | Five alert rules enabled | `az monitor metrics alert list -g "$resource_group" --query "[].{name:name,enabled:enabled,severity:severity}" -o table` | Redeploy `infra/modules/alerts.bicep`; configure environment-specific notification routing separately. |
| Application | `/healthz`, `/readyz`, `/api/tickets` return `200` | `host="$(az deployment sub show --name "$deployment_name" --query properties.outputs.webAppHostName.value -o tsv)"; for path in healthz readyz api/tickets; do curl -sS -o /dev/null -w "$path %{http_code}\\n" "https://${host}/${path}"; done` | Use the HTTP 500 runbook; do not weaken network or identity controls. |

An empty table or output is the expected result for the required-tag and secret-name checks.

## Detect drift

Preview changes using the same parameter file and location as the deployment:

```bash
deployment_location="$(az deployment sub show --name "$deployment_name" --query location -o tsv)"

az deployment sub what-if \
  --name "${deployment_name}-drift" \
  --location "$deployment_location" \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam \
  --result-format ResourceIdOnly
```

Classify differences before acting:

- **Critical security drift**: public SQL, HTTPS/TLS/FTPS, identity, or NSG changes. Contain first,
  retain activity logs, then reconcile from source.
- **Expected platform noise**: read-only/defaulted properties that Bicep does not control. Record
  the reason; do not edit the template merely to silence noise.
- **Intentional change**: open a pull request and update this contract before deployment.
- **Unexplained change**: open an incident with the what-if output, resource activity log, actor,
  and timestamp.

## Reconcile

After review and approval, redeploy the committed desired state:

```bash
az deployment sub create \
  --name "$deployment_name" \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

Run the live invariants again, then rerun what-if. A changed App Service principal requires the
manual SQL bootstrap from [`docs/operations-runbook.md`](operations-runbook.md).
