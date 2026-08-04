---
mode: agent
description: Implement the approved architecture as validated Bicep.
---

# Inputs

- `docs/architecture.md` — the approved design.
- `docs/concepts/workload.md` — the standards and acceptance criteria.

# Task

Acting as `@implementer`, write `infra/main.bicep`, `infra/main.bicepparam` and one module per
concern under `infra/modules/`, composed from version-pinned Azure Verified Modules. Then run
`./scripts/validate-infra.sh` and `dotnet build src/ContosoTicketing`, and fix everything they report.

# Expected output

- `infra/main.bicep`, `infra/main.bicepparam`
- `infra/modules/networking.bicep`, `database.bicep`, `webapp.bicep`, `monitoring.bicep`

# Done when

- `./scripts/validate-infra.sh` exits 0 with no warnings.
- `dotnet build src/ContosoTicketing` succeeds.
- Every module references an AVM module at a pinned version — no `latest`.
- No password, key or connection secret appears anywhere in `infra/`.
- Every resource uses CAF naming and carries all four required tags.
