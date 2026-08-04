# Fleet Merge Handover

| Subagent area | Output | Validation status | Notes |
|---|---|---|---|
| Networking | `infra/modules/networking.bicep` | `<pass / fail>` | `<interfaces>` |
| Database | `infra/modules/database.bicep` | `<pass / fail>` | `<private endpoint evidence>` |
| Web app | `infra/modules/webapp.bicep` | `<pass / fail>` | `<managed identity evidence>` |
| Monitoring | `infra/modules/monitoring.bicep` | `<pass / fail>` | `<workspace-based App Insights>` |
| App deploy | `src/ContosoTicketing` package step | `<pass / fail>` | `<health routes>` |

## Human review gate

Do not deploy until `./scripts/validate-infra.sh` and `dotnet build src/ContosoTicketing` pass and any contract conflicts are resolved in source.
