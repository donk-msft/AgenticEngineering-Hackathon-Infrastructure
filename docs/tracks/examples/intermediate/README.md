# Intermediate Example Assets

This folder shows the same workload delivered with fewer top-level prompts:

- [`agents/`](agents/) — lightweight reviewer, orchestrator and verification roles.
- [`prompts/`](prompts/) — plan, fleet implementation and verify/deploy prompts.
- [`skills/contoso-baseline-guardrails/SKILL.md`](skills/contoso-baseline-guardrails/SKILL.md) — shared constraints for subagents.
- [`handovers/`](handovers/) — example plan and fleet merge handovers.

The examples keep participant work in the loop: the human reviews the plan before `/fleet` and reviews the merge before deployment.
