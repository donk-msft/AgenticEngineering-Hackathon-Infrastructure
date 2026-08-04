---
applyTo: '**/*.agent.md'
---

# Writing a custom agent

An agent file defines **who** does a piece of work. Keep it to one responsibility.

## Frontmatter

```markdown
---
name: implementer
description: One sentence — what this agent does and what it produces.
tools: ['search', 'edit', 'runCommands']
handoffs: ['tester']
---
```

- `name` — lower-case, matches the filename (`implementer.agent.md`).
- `description` — one sentence, states the output. "Helps with infrastructure" is not a description.
- `tools` — **least privilege**. Only grant what the agent actually needs. An agent that writes
  documentation does not need `runCommands`.
- `handoffs` — the next agent by name. Omit only for a terminal agent.

## Body

Use these sections, in this order:

1. **Role** — one paragraph. State what the agent does *and what it must not do*.
2. **Inputs** — the exact files it reads. This is its contract with the previous agent.
3. **Task** — numbered steps producing a named artifact.
4. **Constraints** — the rules it must not break.
5. **Handover** — when it is finished, who it hands to, and what it must state on handover.

## Rules

- Name the output file explicitly. An agent whose output is not a file cannot hand over.
- Repeat the non-negotiable standards (CAF naming, required tags, no secrets, managed identity)
  in the constraints — do not assume they are inherited.
- Forbid the adjacent responsibilities: an architect that deploys will drift from its design.
