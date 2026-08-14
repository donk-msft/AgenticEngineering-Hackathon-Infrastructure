# Example Output — Lab 3: Azure SRE Agent Onboarding

What a successfully onboarded Azure SRE Agent looks like, so you can confirm your own setup before
moving on to Lab 4.

## Onboarding confirmation (Azure CLI / portal summary)

```text
SRE Agent name:        sre-ticketing-dev
Resource group scope:  rg-ticketing-dev-swedencentral
Permission level:      Privileged (approval required for all actions)
Data sources:          Azure Monitor alerts, Resource Graph, Service Health, Activity Log
GitHub connection:     <owner>/<repo> (repo-admin authorized)
Status:                Active — monitoring
```

## Expected knowledge ingestion result

After pointing the agent at [`knowledge/`](../../../../../knowledge/), a query such as *"what is
the escalation policy for a failed readiness probe?"* should return an answer that **cites your
runbook**, not a generic one:

```text
Q: What should happen if /readyz starts failing?
A: Per docs/operations-runbook.md § Rollback: first check Application Insights for the failing
   dependency, then attempt an app restart. If it does not recover within 10 minutes, roll back
   to the previous deployment slot/publish and open an incident per the escalation policy in
   knowledge/escalation-policy.md.
```

## Approval-gate behaviour (example)

A **Reader**-only agent must never show an "Approve" button for a remediation — only an
investigation summary. A **Privileged** agent proposing a remediation should surface something like:

```text
Proposed action: Restart App Service app-ticketing-dev-swedencentral
Reason: /healthz has returned 5xx for 6 consecutive checks (12 min)
Risk: Low — stateless restart, no data impact
Requires approval: Yes
[ Approve ] [ Reject ] [ Hand off to GitHub Copilot instead ]
```

✅ Checkpoint met when: your agent shows a similar status summary, its permission level matches what
your team agreed, and a test alert produces an investigation you can read end-to-end.
