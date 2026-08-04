# Contoso Baseline Guardrails Skill

Use this skill in intermediate-track plans, fleet prompts and subagent instructions.

## Non-negotiable workload rules

- Build the same Contoso Ticketing baseline described in `docs/concepts/workload.md`.
- Deploy `src/ContosoTicketing` to the App Service.
- Use Bicep modules under `infra/modules/` and parameters in `.bicepparam`.
- Use Azure Verified Modules pinned to exact versions.
- Apply tags `environment`, `workload`, `owner`, `costCenter` to every resource.
- Keep SQL private through private endpoint and private DNS.
- Use managed identity for app-to-SQL authentication.
- Keep HTTPS on, minimum TLS 1.2 and FTPS disabled.
- Add explicit deny-all inbound NSG rules.

## Fleet coordination rules

- Shared parameter names and module outputs must be agreed before subagents write code.
- If subagents disagree on contracts, stop and revise the plan.
- Validation is part of the implementation task, not a later cleanup step.
- Do not store credentials or live environment identifiers in generated docs.
