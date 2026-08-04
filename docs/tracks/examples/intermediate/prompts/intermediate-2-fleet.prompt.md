---
mode: agent
description: Fan out the approved plan with `/fleet` and merge the result.
---

## Inputs

- `plan.md`
- `docs/plan-review.md`
- `docs/concepts/workload.md`
- `.github/skills/contoso-baseline-guardrails/SKILL.md`

## Task

Use `/fleet` with networking, database, web app, monitoring and app deployment subagents, then act as `@fleet-orchestrator` to merge and validate the result.

## Expected output

- `infra/main.bicep`
- `infra/main.bicepparam`
- `infra/modules/**/*.bicep`
- `docs/fleet-merge-summary.md`

## Done when

- `./scripts/validate-infra.sh` exits 0 with no warnings.
- `dotnet build src/ContosoTicketing` exits 0.
- `docs/fleet-merge-summary.md` lists subagent outputs and unresolved live checks.
