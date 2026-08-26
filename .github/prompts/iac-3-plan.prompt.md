---
agent: planner
description: Produce the implementation plan from the reviewed architecture.
---

## Inputs

- `docs/architecture.md`
- `docs/architecture-review.md`
- `docs/concepts/workload.md`

## Task

Acting as `@planner`, create the implementation plan with module contracts and validation gates.

## Expected output

- `docs/development-plan.md`

## Done when

- The plan separates networking, database, web app, monitoring, composition, validation and documentation tasks.
- Dependencies and module interfaces are explicit.
- The plan requires version-pinned AVM modules and no hardcoded environment values.
