---
mode: agent
description: Convert an SRE Agent incident investigation into a Copilot-ready handover.
---

## Inputs

- `docs/operations-runbook.md`
- `docs/concepts/fault-and-vulnerability.md`
- `docs/concepts/workload.md`
- `.github/skills/operations-feedback-loop/SKILL.md`

## Task

Acting as `@sre-triage`, summarize the incident evidence, redact live values and create the remediation handover.

## Expected output

- `docs/sre-handover.md`
- `docs/remediation-plan.md`

## Done when

- The handover states symptom, impact, suspected cause, evidence, affected acceptance criteria and approval state.
- It contains no credentials or environment-specific identifiers.
- `docs/remediation-plan.md` identifies validation and rollback steps.
