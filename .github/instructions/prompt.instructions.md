---
applyTo: '**/*.prompt.md'
---

# Writing a reusable prompt

A prompt file defines **what to do now** — one step of a workflow, reusable and parameterised.

## Naming

`<workflow>-<step>-<verb>.prompt.md`, for example `iac-4-implement.prompt.md`. Number the steps so
the pipeline order is obvious from the file listing.

## Frontmatter

```markdown
---
mode: agent
description: One sentence — the step this prompt performs.
---
```

## Body

Four sections, always:

1. **Inputs** — the files the agent must read first. Be exact; do not say "the relevant docs".
2. **Task** — what to do, naming the agent that should do it (`Acting as @implementer, …`).
3. **Expected output** — the file(s) produced, by path.
4. **Done when** — verifiable conditions, not vibes. "`./scripts/validate-infra.sh` exits 0" is
   verifiable; "the code is good" is not.

## Rules

- One prompt, one step. If your prompt has "and then also", split it.
- State the standards that the output is graded on, or point to the document that holds them.
- Never embed environment-specific values (subscription ids, resource names) in a prompt — take
  them from a parameter file or ask for them.
- If the same paragraph appears in a third prompt, move it into a skill.
