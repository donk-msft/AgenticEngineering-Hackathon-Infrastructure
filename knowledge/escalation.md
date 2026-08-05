# Contoso Ticketing Escalation Policy

The Azure SRE Agent may investigate autonomously. Changes remain approval-gated.

| Action | Policy |
|---|---|
| Read metrics, logs, Resource Graph, Resource Health, activity logs, and repository knowledge | Allowed without approval within the workload resource group. |
| Correlate alerts, form a root-cause hypothesis, and draft an incident timeline | Allowed without approval. |
| Restart the web app after evidence of a transient process failure | Human approval required; record reason and outcome. |
| Scale App Service or SQL | Service-owner approval required because it changes cost and capacity. |
| Reconcile reviewed Bicep after confirmed drift | Human approval required; use the existing deployment workflow or documented command. |
| Change SQL database principals or roles | Entra SQL administrator approval and execution required from a private-network-connected host. |
| Modify code, Bicep, workflows, or policy | Create a GitHub issue with evidence and hand over to Copilot; require PR review and CI. |
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

Do not include access tokens, credentials, connection secrets, customer data, or raw sensitive log
payloads.
