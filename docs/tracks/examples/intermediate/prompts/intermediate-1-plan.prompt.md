---
mode: agent
description: Produce and review the intermediate-track implementation plan.
---

## Inputs

- `docs/concepts/workload.md`
- `docs/concepts/fault-and-vulnerability.md`

## Task

Use `/plan` to produce `plan.md` for the Contoso Ticketing baseline, then act as `@plan-reviewer` to review it before implementation.

## Expected output

- `plan.md`
- `docs/plan-review.md`

## Done when

- Every acceptance criterion maps to plan tasks.
- Parallel batches have explicit dependencies and shared module interfaces.
- The plan contains no subscription ids, tenant ids, resource ids, host names or secrets.
