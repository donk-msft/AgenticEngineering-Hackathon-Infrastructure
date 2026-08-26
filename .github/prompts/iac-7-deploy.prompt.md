---
agent: deployer
description: Deploy the validated workload and collect sanitized evidence.
---

## Inputs

- `docs/deployment-guide.md`
- `docs/test-results.md`
- `infra/main.bicep`
- `infra/main.bicepparam`
- `src/ContosoTicketing/`

## Task

Acting as `@deployer`, ask interactively for environment values, run what-if, deploy after approval and record sanitized evidence.

## Expected output

- Updated `docs/test-results.md`

## Done when

- Deployment status is recorded as succeeded or failed without exposing subscription ids, tenant ids or host names.
- `/healthz` and `/readyz` evidence is recorded with redacted URLs.
- Acceptance criteria in `docs/concepts/workload.md` are marked pass/fail.
