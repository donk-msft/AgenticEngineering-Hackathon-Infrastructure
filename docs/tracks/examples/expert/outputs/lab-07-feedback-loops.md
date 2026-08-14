# Example Output — Lab 7: `docs/feedback-loops.md`

A filled-in example of the signal-mapping table from Lab 7 §1, including how to record a lane your
team skipped because it ran the optional Labs 5–6, or did not.

## Example: both reliability and security lanes completed

| Signal source | Trigger | Lands as | Handled by | Human gate |
|---|---|---|---|---|
| Azure SRE Agent | Alert → investigation | Structured GitHub issue | Copilot coding agent | Approve handover |
| Drift check (Lab 2) | Scheduled what-if diff | GitHub issue (label `drift`) | `@implementer` agent | PR review |
| CodeQL (Lab 5) | High/Critical finding | Failed check + alert | Copilot autofix / `@implementer` | PR review |
| Secret scanning | Push protection block | Blocked push | Developer | Immediate |
| Defender for Cloud (Lab 6) | New recommendation | GitHub issue (via `@sre` agent) | `@sre` agent → `@implementer` | PR review |
| Dependabot | Vulnerable dependency | PR | Automated | PR review |

## Example: security lane (optional Labs 5–6) skipped

If your team did not have GHAS access or Defender budget, record the gap explicitly rather than
leaving the rows blank:

| Signal source | Trigger | Lands as | Handled by | Human gate |
|---|---|---|---|---|
| Azure SRE Agent | Alert → investigation | Structured GitHub issue | Copilot coding agent | Approve handover |
| Drift check (Lab 2) | Scheduled what-if diff | GitHub issue (label `drift`) | `@implementer` agent | PR review |
| CodeQL (Lab 5) | — | *Skipped — optional Lab 5 not run (no GHAS-enabled repository)* | — | — |
| Secret scanning | — | *Skipped — optional Lab 5 not run* | — | — |
| Defender for Cloud (Lab 6) | — | *Skipped — optional Lab 6 not run (no Defender budget approved)* | — | — |
| Dependabot | Vulnerable dependency | PR | Automated | PR review |

Either shape satisfies the Lab 7 Definition of Done bullet "maps every signal source with no
unowned rows" — an explicitly documented skip is not an unowned row.

✅ Checkpoint met when: your `docs/feedback-loops.md` matches one of the two shapes above (adjusted
for the agents and labels your team actually used), and every row has either a real handler or an
explicit, reasoned "skipped" entry.
