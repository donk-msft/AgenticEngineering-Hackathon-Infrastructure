# Expert Example Assets

This folder shows how day-2 reliability and security work hands back into the day-1 agentic pipeline:

- [`agents/`](agents/) — SRE triage, remediation planning and security finding review roles.
- [`prompts/`](prompts/) — drift, incident and security finding workflows.
- [`skills/operations-feedback-loop/SKILL.md`](skills/operations-feedback-loop/SKILL.md) — shared response policy.
- [`handovers/`](handovers/) — issue-style handovers from operations signals to Copilot.
- [`outputs/`](outputs/) — written examples of correctly implemented lab output (CI jobs, `what-if`
  diffs, CodeQL gates, Defender connector state) so participants can validate their own steps.

The examples are sanitized and use placeholders for all environment values.

These files demonstrate the conceptual handover chain that participants can trace when stuck. Lab 7 may consolidate parts of this chain into a single `.github/agents/sre.agent.md`; the examples keep the triage, planning, review and implementation responsibilities separate so the learning path is visible.
