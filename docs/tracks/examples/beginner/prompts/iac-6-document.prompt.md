---
mode: agent
description: Document deployment and operations for the validated workload.
---

## Inputs

- `docs/development-plan.md`
- `docs/test-results.md`
- `infra/main.bicep`
- `infra/main.bicepparam`
- `docs/concepts/workload.md`

## Task

Acting as `@documenter`, write deployment and operations guidance for the workload.

## Expected output

- `docs/deployment-guide.md`
- `docs/operations-runbook.md`

## Done when

- The deployment guide uses placeholders for environment values.
- The runbook covers health, readiness, telemetry, rollback and private SQL connectivity.
- No secrets or live environment identifiers are stored.
