# Contoso Ticketing Escalation Policy

The Azure SRE Agent may investigate autonomously. Mutating actions and issue creation remain
approval-gated, and the agent must not edit code, create branches or deploy changes.

| Action | Policy |
|---|---|
| Read metrics, logs, Resource Graph, Resource Health, activity logs, and repository knowledge | Allowed without approval within the workload resource group. |
| Correlate alerts, form a root-cause hypothesis, and draft an incident timeline | Allowed without approval. |
| Propose a restart, scale operation or runtime setting restoration | Allowed only as a recommendation; an authorised human executes it after approval and records reason, command and rollback. |
| Reconcile reviewed Bicep after confirmed drift | Create an evidence-backed issue or approved change request; the human executes the existing deployment workflow. |
| Change SQL database principals or roles | Entra SQL administrator approval and execution required from a private-network-connected host. |
| Modify code, Bicep, workflows, or policy | After explicit approval, create exactly one unassigned GitHub issue with evidence; the learner reviews and assigns `copilot-swe-agent`, then requires PR review and CI. |
| Enable SQL public access, add credentials, weaken identity/network/TLS controls, bypass CI, inject a fault, or merge a deliberate vulnerability | Prohibited. Page the workload and security owners. |
| Subscription-wide role or policy change, data loss risk, suspected credential exposure, or cross-resource-group impact | Stop automation and page a human immediately. |

## Handover contract

Every escalation or GitHub issue must include:

- UTC incident start and current impact.
- Affected resource IDs and endpoints.
- Alert IDs and supporting telemetry or queries.
- Changes from the activity log and current what-if output.
- Root-cause hypothesis with confidence and alternatives considered.
- Proposed runtime and repository remediation, including rollback.
- Required approver and verification criteria.

The issue must be unassigned when created. The Azure SRE Agent does not create a branch or pull
request, merge changes, deploy code or make direct Azure changes.

Do not include access tokens, credentials, connection secrets, customer data, or raw sensitive log
payloads.
