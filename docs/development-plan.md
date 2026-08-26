# Contoso Ticketing Development Plan

This plan converts the approved [architecture](architecture.md) and passing-for-planning
[architecture review](architecture-review.md) into implementation tasks. It does not authorize a
design change. Final acceptance remains pending until the workload is deployed to the existing
subscription and every live check passes.

## Implementation rules

- Keep reusable Bicep in `infra/main.bicep` and `infra/modules/`; keep environment values in
  `.bicepparam` files or interactive deployment inputs.
- Use Azure Verified Modules for every resource, pinned to the exact versions in the module
  contracts below. Never use `latest` or an unversioned reference.
- Pass one shared tag object containing `environment`, `workload`, `owner`, and `costCenter` to every
  module and every taggable resource, including the resource group.
- Use CAF names shaped as `<type>-<workload>-<environment>-<region>`, except for the approved storage
  convention `st<workload-short><environment><hash6>`. Derive `<hash6>` deterministically with
  `uniqueString`; do not include or reveal subscription IDs, tenant IDs, resource IDs, personal
  accounts, credentials, or other sensitive inputs.
- Preserve SQL private-only access, same-scope automatic private endpoint approval, managed identity
  authentication, parameterized SQL, TLS 1.2 or higher, HTTPS-only App Service, disabled FTPS, and
  explicit deny-all inbound rules at priority 4096.
- Do not put passwords, keys, connection secrets, or credentials in templates, outputs, app
  settings, scripts, parameter files, workflows, or documentation.
- Treat every warning as a failure. Complete each task's focused gate before starting a dependent
  task.

## Shared composition contract

`infra/main.bicep` remains subscription-scoped and owns the resource group, shared tags, module
ordering, and non-secret top-level outputs.

| Input | Type | Source and rule |
|---|---|---|
| `workload` | `string` | `.bicepparam`; lowercase CAF workload token |
| `environment` | `string` | `.bicepparam`; development baseline uses the approved development token |
| `location` | `string` | `.bicepparam`; use the lowercase Azure location token |
| `owner` | `string` | `.bicepparam` or interactive input; team identifier, not a personal credential |
| `costCenter` | `string` | `.bicepparam` or interactive input |
| `vnetAddressPrefix` | `string` | `.bicepparam`; development baseline value comes from the architecture |
| `appSubnetPrefix` | `string` | `.bicepparam`; must be contained by the VNet prefix |
| `privateEndpointSubnetPrefix` | `string` | `.bicepparam`; must be contained by the VNet prefix and not overlap another subnet |
| `deployScriptSubnetPrefix` | `string` | `.bicepparam`; must be contained by the VNet prefix and not overlap another subnet |

The composition layer builds `suffix = <workload>-<environment>-<location>` and the shared tags once.
Modules receive values; they must not reconstruct partial tag sets or define environment defaults.
Top-level outputs are limited to resource names, host names, and monitoring identifiers needed for
deployment verification. Do not output credentials, keys, tokens, or credential-bearing connection
strings.

## Module contracts

### Monitoring

**File:** `infra/modules/monitoring.bicep`

**Pinned AVM:** `operational-insights/workspace:0.16.1`, `insights/component:0.8.0`

| Inputs | Outputs |
|---|---|
| `workload`, `environment`, `location`, `tags` | `logAnalyticsWorkspaceId`, `logAnalyticsWorkspaceName`, `applicationInsightsName`, `applicationInsightsConnectionString` |

Create a `PerGB2018` Log Analytics workspace with 30-day retention and no daily cap. Create
workspace-based Application Insights with default sampling. The Application Insights connection
string is endpoint configuration, not an authentication credential; pass it only to the web app and
do not expose it at subscription composition output.

**Dependencies:** resource group only.

### Networking

**File:** `infra/modules/networking.bicep`

**Pinned AVM:** `network/network-security-group:0.5.3`,
`network/virtual-network:0.10.0`

| Inputs | Outputs |
|---|---|
| `workload`, `environment`, `location`, `tags` | `virtualNetworkId` |
| `vnetAddressPrefix`, `appSubnetPrefix`, `privateEndpointSubnetPrefix`, `deployScriptSubnetPrefix` | `appSubnetId`, `privateEndpointSubnetId`, `deployScriptSubnetId` |
| `logAnalyticsWorkspaceId` | n/a |

Create `snet-app`, `snet-privateendpoints`, and `snet-deployscript`. Delegate the app subnet to
`Microsoft.Web/serverFarms` and the deployment-script subnet to
`Microsoft.ContainerInstance/containerGroups`. Attach an NSG to every subnet. Permit only required
flows, including app-to-private-endpoint SQL traffic on TCP 1433, and end every NSG with explicit
deny-all inbound at priority 4096. Keep diagnostics connected to Log Analytics.

**Dependencies:** monitoring for diagnostics.

### Database bootstrap identity

**File:** `infra/modules/identity-bootstrap.bicep`

**Pinned AVM:** `managed-identity/user-assigned-identity:0.6.0`

| Inputs | Outputs |
|---|---|
| `workload`, `environment`, `location`, `tags` | `resourceId`, `principalId`, `clientId`, `name` |

Create the user-assigned identity used by the private deployment script and configure it as the sole
Microsoft Entra administrator of SQL through the database module. Do not create or retain
`infra/modules/identity-app.bicep`; the application identity contract is system-assigned.

**Dependencies:** resource group only.

### Database

**File:** `infra/modules/database.bicep`

**Pinned AVM:** `sql/server:0.22.0`, `network/private-dns-zone:0.8.1`

| Inputs | Outputs |
|---|---|
| `workload`, `environment`, `location`, `tags` | `sqlServerName`, `databaseName`, `connectionString` |
| `privateEndpointSubnetId`, `virtualNetworkId` | `privateEndpointName` |
| `sqlAdminObjectId`, `sqlAdminLogin` | `privateDnsZoneName` |

Create the SQL logical server with public network access disabled, Entra-only authentication, and
TLS 1.2 minimum. Configure the bootstrap identity as the sole Entra administrator. Create the
serverless General Purpose database with the approved development sizing and service-default PITR,
with no long-term retention. Create the SQL private endpoint in the same administrative scope so its
connection is automatically approved. Link `privatelink.database.windows.net` to the workload VNet.

The output connection string contains only the SQL FQDN, database, encryption settings, and
`Authentication=Active Directory Default`; it contains no user name, password, key, or token.

**Dependencies:** networking and database bootstrap identity.

### Web app

**File:** `infra/modules/webapp.bicep`

**Pinned AVM:** `web/serverfarm:0.7.0`, `web/site:0.24.0`

| Inputs | Outputs |
|---|---|
| `workload`, `environment`, `location`, `tags` | `webAppResourceId`, `webAppName`, `defaultHostName` |
| `appSubnetId` | `principalId` |
| `applicationInsightsConnectionString`, `sqlConnectionString` | n/a |

Create one Linux P0v3 worker and a .NET 8 web app. Enable only the system-assigned managed identity;
remove user-assigned app identity inputs and remove `AZURE_CLIENT_ID` from app settings. Configure
regional VNet integration with all outbound traffic routed through the VNet. Set `httpsOnly: true`,
minimum TLS 1.2, FTPS disabled, always-on, and `/healthz` as the health-check path. Keep the approved
public HTTPS endpoint and add no private app endpoint or corporate connectivity integration.

Output the web app system-assigned `principalId` from the deployed site identity for database
bootstrap. Do not output an identity token or credential.

**Dependencies:** networking, database, and monitoring.

### Database bootstrap

**Files:** `infra/modules/database-bootstrap.bicep`,
`scripts/bootstrap-ticketing-database-deploymentscript.sh`

**Pinned AVM:** `storage/storage-account:0.33.0`,
`resources/deployment-script:0.5.2`

| Inputs | Outputs |
|---|---|
| `workload`, `environment`, `location`, `tags` | `deploymentScriptName` |
| `deployScriptSubnetId` | n/a |
| `managedIdentityResourceId`, `managedIdentityPrincipalId`, `managedIdentityClientId` | n/a |
| `sqlServerName`, `databaseName` | n/a |
| `webAppName`, `webAppPrincipalId` | n/a |
| `baseTime` | n/a |

Generate the storage account name with the approved constrained-resource convention and a
deterministic six-character `uniqueString` suffix. Restrict storage network access to the deployment
script subnet, require TLS 1.2, and grant the bootstrap identity only the storage role required by
the deployment script.

Run the Azure CLI deployment script in `snet-deployscript` with no public IP, using only the
bootstrap user-assigned identity. Set `cleanupPreference: OnExpiration`, `retentionInterval: P1D`,
and a bounded timeout. The script creates the app's contained database principal, grants only
`db_datareader`, and creates `dbo.Tickets` idempotently.

The current script depends on a user-assigned app client ID. Replace that contract. Starting from
`webAppPrincipalId`, resolve the system-assigned service principal's application/client ID through an
authorized Microsoft Entra lookup at runtime, then convert that public identifier to the SQL SID.
Do not persist it as a secret. Before completing this module, prove the lookup works for the
bootstrap identity in the target tenant; if an additional directory permission is required, stop
and obtain owner approval for the least-privilege permission rather than adding a broad directory
role silently.

**Dependencies:** networking, database bootstrap identity, database, and web app. This dependency
ensures the system-assigned principal exists before the bootstrap runs.

### Alerts

**File:** `infra/modules/alerts.bicep`

**Pinned AVM:** `insights/webtest:0.3.2`, `insights/metric-alert:0.4.1`

| Inputs | Outputs |
|---|---|
| `workload`, `environment`, `location`, `tags` | none required |
| `webAppName`, `webAppHostName` | none required |
| `sqlServerName`, `databaseName` | none required |
| `applicationInsightsName` | none required |

Create the `/readyz` standard availability test and the approved readiness, health, HTTP 5xx,
response-time, and SQL CPU alerts. Do not attach an action group; alert routing belongs to Expert
Lab 3.

**Dependencies:** monitoring, database, and web app. The availability alert also depends on the web
test resource.

## Ordered implementation tasks

1. **Parameter and naming foundation**
   - Update `infra/main.bicep` to require the shared inputs and build the required tags once.
   - Move all development values, including address and subnet prefixes, to
     `infra/main.bicepparam`; remove reusable-template defaults for environment values.
   - Implement the approved deterministic storage naming helper and document its exception.
   - Gate: build `infra/main.bicep` and `infra/main.bicepparam` with zero warnings.
2. **Monitoring module**
   - Implement the monitoring contract and exact AVM versions.
   - Gate: build `infra/modules/monitoring.bicep` with zero warnings.
3. **Networking module**
   - Implement parameterized address ranges, subnet delegations, NSGs, diagnostics, and outputs.
   - Gate: build `infra/modules/networking.bicep` with zero warnings and inspect all three deny rules.
4. **Bootstrap identity module**
   - Preserve the sole SQL administrator identity contract.
   - Remove the obsolete app user-assigned identity module and all composition references to it.
   - Gate: build the identity module and confirm no app identity dependency remains.
5. **Database module**
   - Implement private-only SQL, database sizing, private DNS, and same-scope private endpoint.
   - Gate: build the database module and inspect the generated template for disabled public access,
     Entra-only authentication, and no firewall rule.
6. **Web app module**
   - Implement the system-assigned identity, App Service controls, VNet integration, and non-secret
     settings; expose its principal ID.
   - Gate: build the web app module and confirm no `AZURE_CLIENT_ID`, user-assigned app identity, or
     credential-bearing setting remains.
7. **Database bootstrap module and script**
   - Implement private execution, storage restriction, system-assigned app principal handling,
     idempotent SQL, and retained logs.
   - Gate: build the module; lint the shell script; prove the Entra ID-to-client-ID lookup; inspect
     generated properties for `OnExpiration`, `P1D`, and VNet-only execution.
8. **Alerts module**
   - Implement web test and alerts without an action group.
   - Gate: build the alerts module and verify `/readyz` is the availability target.
9. **Composition**
   - Wire modules in dependency order: monitoring; networking and bootstrap identity; database;
     web app; database bootstrap; alerts.
   - Keep top-level outputs non-secret and sufficient for acceptance checks.
   - Gate: run the full repository infrastructure validation command.
10. **Application build and security check**
    - Preserve `/healthz`, `/readyz`, and `/api/tickets`; retain parameterized `SqlCommand` usage and
      `Authentication=Active Directory Default`.
    - Gate: run the exact application build command and treat warnings as failures.
11. **Pre-deployment review and deployment handoff**
    - Run subscription-scope what-if against the selected parameter inputs.
    - Confirm no delete or replacement outside the workload resource group and no credential output.
    - Hand the validated artifacts to the deployment step; do not claim acceptance before live
      checks complete.
12. **Live acceptance and documentation**
    - Deploy to the existing subscription and collect the evidence listed below.
    - Update operational documentation with resource discovery and verification procedures using
      placeholders or deployment outputs, never fixed IDs or credentials.

## Validation gates

### Build gates

Run from the repository root:

```bash
./scripts/validate-infra.sh
dotnet build src/ContosoTicketing
```

Both commands must exit zero with no warnings. Also scan Bicep for unpinned AVM references,
credential-bearing outputs or settings, hardcoded environment values outside `.bicepparam`, SQL
public access, and missing required tags.

### Pre-deployment gate

Use interactive values or environment variables for deployment identity and location; do not write
subscription or tenant identifiers into the repository.

```bash
az deployment sub what-if \
  --location <deployment-location> \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

The what-if must show only the intended workload resources and no secret-valued properties.

### Deployment and live gates

Deployment is performed by the deployment owner, not by the planner. Use a non-sensitive deployment
name supplied interactively:

```bash
az deployment sub create \
  --name <deployment-name> \
  --location <deployment-location> \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

az deployment sub show \
  --name <deployment-name> \
  --query properties.provisioningState \
  --output tsv
```

The second command must return `Succeeded`. Then collect evidence that:

- all resources have approved names and all four required tags;
- SQL public network access is `Disabled` and its private endpoint connection is `Approved`;
- SQL DNS resolves from the app execution context to the private endpoint subnet;
- every subnet has its NSG and deny-all inbound rule at priority 4096;
- the bootstrap identity is the sole Entra SQL administrator;
- the deployment script has no public IP, runs in the workload VNet, and retains resources and logs
  with `OnExpiration` and `P1D`;
- the web app has only its system-assigned identity, no password or connection secret setting,
  HTTPS-only enabled, TLS 1.2 or higher, and FTPS disabled;
- workspace-based Application Insights contains recent application telemetry;
- `GET https://<webapp-host>/healthz` returns `200`;
- `GET https://<webapp-host>/readyz` returns `200` and telemetry shows the private managed-identity
  SQL dependency succeeded.

Final acceptance requires every item above plus both build gates. A template assertion is not a
substitute for live evidence.

## Documentation tasks

1. Update `docs/architecture.md` only if implementation reveals an approved contract change; do not
   silently change architecture from Bicep.
2. Update the naming skill or workload naming section with the approved constrained storage-account
   convention and deterministic suffix rule.
3. Update `docs/operations-runbook.md` with deployment discovery, private DNS, endpoint approval,
   bootstrap-log, identity, health, readiness, and telemetry checks.
4. Keep `src/ContosoTicketing/README.md` aligned with the passwordless connection setting and the
   three required routes.
5. Record validation evidence without subscription IDs, tenant IDs, resource IDs, personal account
   names, credentials, keys, or tokens.

## Handover to `@implementer`

Implement tasks 1 through 10 in order and stop on the first failed focused gate. Preserve every
module interface and dependency above. Do not deploy as part of implementation; after build gates
and what-if pass, hand the artifacts to the deployment owner for tasks 11 and 12.

The implementer output contract is:

- changed files grouped by module and composition task;
- exact pinned AVM versions used;
- confirmation that the obsolete app user-assigned identity contract was removed;
- results of `./scripts/validate-infra.sh` and `dotnet build src/ContosoTicketing`;
- any required directory permission for resolving the system-assigned identity client ID;
- remaining live checks that require deployment.