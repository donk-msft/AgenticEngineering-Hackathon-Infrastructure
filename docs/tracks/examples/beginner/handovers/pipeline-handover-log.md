# Beginner Pipeline Handover Log

Use this as a template while running `iac-1-architect` through `iac-7-deploy`. Keep values sanitized before committing.

| Step | From | To | Artifact | Review decision | Notes |
|---|---|---|---|---|---|
| 1 | `@architect` | `@reviewer` | `docs/architecture.md` | `<approved / needs changes>` | `<open assumptions>` |
| 2 | `@reviewer` | `@planner` | `docs/architecture-review.md` | `<approved / needs changes>` | `<must-fix findings>` |
| 3 | `@planner` | `@implementer` | `docs/development-plan.md` | `<approved / needs changes>` | `<module contracts>` |
| 4 | `@implementer` | `@tester` | `infra/` | `<approved / needs changes>` | `<commands run>` |
| 5 | `@tester` | `@documenter` | `docs/test-results.md` | `<approved / needs changes>` | `<pending live checks>` |
| 6 | `@documenter` | `@deployer` | `docs/deployment-guide.md`, `docs/operations-runbook.md` | `<approved / needs changes>` | `<deployment prerequisites>` |
| 7 | `@deployer` | Track closeout | `docs/test-results.md` | `<passed / failed>` | `<sanitized evidence>` |

## Redaction rule

Do not store credentials, tokens, subscription ids, tenant ids, resource ids, host names or personal account names. Use placeholders such as `<subscription>`, `<tenant>`, `<resource-group>` and `<webapp-host>`.
