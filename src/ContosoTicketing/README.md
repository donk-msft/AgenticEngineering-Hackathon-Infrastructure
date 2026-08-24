# Contoso Ticketing — Reference Application

The minimal .NET 8 web API that runs on the App Service in [`infra/`](../../infra/). It exists so
that **all three tracks share the same technology**, and so the expert labs have real application
telemetry, a real failing route and a real code-scanning target to work with.

It is deliberately small: three routes, no ORM, no UI.

| Route | Purpose | Used by |
|---|---|---|
| `GET /healthz` | Liveness. Always `200` while the process is up. Matches `healthCheckPath` in `infra/modules/webapp.bicep`. | App Service health check |
| `GET /readyz` | Readiness. Opens a SQL connection; `503` when the data path is broken. | Expert Lab 3 availability alert |
| `GET /api/tickets` | Reads tickets over the private endpoint; `500` when the query fails. | Expert Lab 4 incident |

## Authentication

There are **no credentials in this app**. `ConnectionStrings__Default` is injected by
`infra/modules/webapp.bicep` and uses `Authentication=Active Directory Default`, so
`Microsoft.Data.SqlClient` authenticates with the App Service system-assigned managed identity.

The database bootstrap is **automatic**. `infra/modules/database-bootstrap.bicep` runs
[`scripts/bootstrap-ticketing-database-deploymentscript.sh`](../../scripts/bootstrap-ticketing-database-deploymentscript.sh)
inside a VNet-integrated `Microsoft.Resources/deploymentScripts` container during
`az deployment sub create`, authenticating as the user-assigned managed identity that is the sole
Microsoft Entra SQL administrator. It idempotently creates the App Service identity as a contained
database user, grants `db_datareader` and creates `dbo.Tickets`. There is nothing to run by hand;
re-run the infrastructure deployment to repeat it. See
[the operations runbook](../../docs/operations-runbook.md#bootstrap-sql-access).

## Build, run and deploy

```bash
dotnet build src/ContosoTicketing            # also run by the app-ci workflow
dotnet publish src/ContosoTicketing -c Release -o /tmp/publish
cd /tmp/publish && zip -r ../app.zip . && cd -
az webapp deploy --resource-group rg-ticketing-dev-swedencentral \
  --name app-ticketing-dev-swedencentral --src-path /tmp/app.zip --type zip
```

## Why this app is in the repository

| Track | Uses it for |
|---|---|
| 🟢 Beginner | The `@deployer` agent deploys it after the infrastructure; `/healthz` proves the deployment end to end |
| 🟡 Intermediate | Same deliverable — one of the `/fleet` subagents owns the application deployment task |
| 🔴 Expert | Lab 3 alerts on it, Lab 4 breaks and fixes it, Lab 5 scans it with CodeQL, Lab 6 traces the finding to the running resource |

See [`docs/concepts/fault-and-vulnerability.md`](../../docs/concepts/fault-and-vulnerability.md)
for the reproducible fault and the reproducible vulnerability that the expert labs inject into
this application — neither of which ships in the code here.
