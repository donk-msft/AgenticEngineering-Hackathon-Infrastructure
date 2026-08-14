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
Service managed identity. Azure Resource Manager cannot create the contained database user. The
App Service identity also **cannot create its own SQL principal**: until an Entra SQL administrator
creates that principal, the identity has no database authorization with which to execute `CREATE
USER`. This bootstrap is a one-time data-plane trust establishment and must be performed by the
configured Microsoft Entra SQL administrator.

The baseline deploys a private, burstable `Standard_B1s` bootstrap VM with Azure Bastion Developer.
It has no public IP address and cloud-init installs Azure CLI and Go-based `sqlcmd`. Use this VM
for the bootstrap; it is connected to the workload VNet and can resolve the SQL private endpoint.

Before deployment, set `bootstrapVmSshPublicKey` in `infra/main.bicepparam` to the contents of a
new or existing SSH public key. Keep the matching private key outside source control and never put
it in a template or a GitHub secret:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ticketing-bootstrap
```

After the deployment completes, open the deployed Key Vault (`kv-...` from the subscription outputs),
create or reuse a secret named `bootstrap-vm-ssh-private-key`, and upload the matching private key:

```bash
az keyvault secret set \
  --vault-name <kv-name> \
  --name bootstrap-vm-ssh-private-key \
  --file ~/.ssh/ticketing-bootstrap
```

The operator who uploads the secret and then opens the VM via Bastion needs the vault permissions to
write and read the secret. The usual pattern is:

```bash
# upload access
az role assignment create \
  --assignee <your-object-id> \
  --role "Key Vault Secrets Officer" \
  --scope "$(az keyvault show --name <kv-name> --query id -o tsv)"

# read access for portal SSH selection
az role assignment create \
  --assignee <your-object-id> \
  --role "Key Vault Secrets User" \
  --scope "$(az keyvault show --name <kv-name> --query id -o tsv)"
```

Then find `vm-bootstrap-...` in the resource group, select **Connect** > **Bastion**, and choose
**SSH Private Key from Azure Key Vault**. Sign in as the username `azureuser` (the value of
`bootstrapVmAdminUsername` in `infra/main.bicepparam`, `azureuser` unless you changed it), and
pick the `bootstrap-vm-ssh-private-key` secret; Bastion
retrieves the private key from Key Vault at the moment of the SSH session. Azure Bastion Developer
provides browser SSH and clipboard copy/paste, but not native-client file transfer. In the Bastion
terminal, run `cloud-init status --wait`, then create `~/bootstrap-ticketing-database.sh` with
`nano`, paste the contents of [`scripts/bootstrap-ticketing-database.sh`](../scripts/bootstrap-ticketing-database.sh)
from your local checkout, save it, and make it executable.

```bash
cloud-init status --wait
az --version
sqlcmd --version
chmod 700 ~/bootstrap-ticketing-database.sh
az login
az account show --query "{subscription:name, user:user.name, tenant:tenantId}" -o table

~/bootstrap-ticketing-database.sh \
  --deployment-name ticketing-baseline
```

The script:

1. Reads the resource group, app, SQL server, and database from deployment outputs.
2. Refuses to continue unless the SQL hostname resolves to an RFC 1918 private address.
3. Uses `sqlcmd -G` and the signed-in Entra SQL administrator; it uses no SQL password.
4. Idempotently creates the App Service identity as a contained user, grants `db_datareader`, and
   creates `dbo.Tickets`.

Do not temporarily enable SQL public access. Do not put an administrator token, password, SQL
connection secret, or generated access token in a workflow or repository variable.

Verify the bootstrap from the same private host:

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
