---
mode: agent
description: Triage a reliability, drift or security finding for the deployed workload (expert track).
---

# Purpose

This prompt is active training material that can be run from `.github/prompts/` during the hackathon.
Participant-safe prompt examples live under `docs/tracks/examples/`.

# Inputs

- `docs/desired-state.md`, `docs/operations-runbook.md`, `knowledge/`
- The finding and its supporting telemetry (paste it, or reference the GitHub issue).

# Task

Acting as `@sre`, triage the finding: classify it, establish the root cause, propose the fix at the
correct layer, check it against the desired-state contract, and classify its autonomy level.

# Expected output

An update to `docs/feedback-loops.md` and either a handover to `@implementer` with the exact
template change and its acceptance test, or a runtime action with its rollback for a human to run.

# Done when

- The root cause is stated, or the missing evidence is listed.
- Any runtime fix is paired with the template change that stops it recurring.
- The autonomy classification is recorded.
