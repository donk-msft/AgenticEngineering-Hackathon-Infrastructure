---
mode: agent
description: Implement the approved Contoso Ticketing Bicep plan.
---

## Inputs

- `docs/development-plan.md`
- `docs/concepts/workload.md`
- `infra/`
- `src/ContosoTicketing/`

## Task

Acting as `@implementer`, implement the Bicep files and app configuration described by the plan.

## Expected output

- `infra/main.bicep`
- `infra/main.bicepparam`
- `infra/modules/**/*.bicep`

## Done when

- `./scripts/validate-infra.sh` exits 0 with no warnings.
- `dotnet build src/ContosoTicketing` exits 0.
- No template outputs, app settings or source files contain passwords, keys or client secrets.
