---
mode: agent
description: Verify, deploy and document the intermediate-track result.
---

## Inputs

- `docs/fleet-merge-summary.md`
- `infra/main.bicep`
- `infra/main.bicepparam`
- `src/ContosoTicketing/`
- `docs/concepts/workload.md`

## Task

Acting as `@verification-lead`, re-run validation, request interactive environment values, deploy after approval and capture sanitized evidence.

## Expected output

- `docs/test-results.md`
- `docs/operations-runbook.md`

## Done when

- Validation passes before deployment.
- Live acceptance checks are recorded without exposing environment identifiers.
- The runbook explains how findings roll forward into the expert track.
