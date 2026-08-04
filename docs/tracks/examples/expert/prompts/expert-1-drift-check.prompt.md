---
mode: agent
description: Run a desired-state drift check and create a sanitized handover if needed.
---

## Inputs

- `infra/main.bicep`
- `infra/main.bicepparam`
- `docs/operations-runbook.md`
- `docs/concepts/workload.md`

## Task

Acting as `@sre-triage`, run the approved what-if or drift detection workflow, classify differences and write a handover only for actionable drift.

## Expected output

- `docs/sre-handover.md`

## Done when

- Drift is classified as expected, actionable or unknown.
- Evidence is sanitized.
- Any proposed remediation preserves the workload security standards.
