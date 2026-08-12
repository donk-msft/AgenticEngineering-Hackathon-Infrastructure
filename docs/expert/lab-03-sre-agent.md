# Expert Lab 3 — Onboard the Azure SRE Agent

**Time**: 60 min · **Prerequisite**: [Lab 2 — Desired state & drift](lab-02-desired-state.md)

This lab is **self-contained**: every step is described here, either as an Azure portal click-path or
as an Azure CLI / Bicep command. The SRE Agent setup experience changes regularly, so use the
current portal flow and preserve the least-privilege and approval rules below.

## Objective

The Azure SRE Agent monitors the workload, investigates alerts autonomously, proposes remediation
behind an approval gate, and can hand work to GitHub Copilot when the fix belongs in code.

```mermaid
flowchart LR
    m["Azure Monitor alert"] --> s["SRE Agent<br/>investigate"]
    k["knowledge/<br/>runbooks"] --> s
    s --> a{"Approval gate"}
    a -->|approve| r["Remediate in Azure"]
    a -->|code fix needed| g["GitHub issue → Copilot"]
```

## 1. Concepts (10 min)

The Azure SRE Agent is a managed Azure resource that watches a set of resource groups, correlates
Azure Monitor alerts, logs, Resource Graph and Service Health, and proposes or performs remediation.
Its permission level per resource group decides whether it may only read (**Reader**) or also act
(**Privileged**) — and even when privileged, actions surface as an approval request unless you
explicitly allow them.

Answer as a team before touching the portal:

- What does the SRE Agent do **without** approval, and what requires approval?
- Which data sources does it investigate with? (Azure Monitor, Resource Graph, Service Health, activity logs)
- Why does giving it *your* runbooks change the quality of its investigations?

Reference reading: [Azure SRE Agent overview](https://sre.azure.com/docs/overview) and
[What is Azure SRE Agent](https://learn.microsoft.com/azure/sre-agent/overview).

## 2. Check prerequisites (5 min)

The SRE Agent is available in a limited set of regions — `swedencentral`, `eastus2`,
`australiaeast`. Run in **Bash with the Azure CLI**, from the **repository root** (dev container,
local VS Code or Cloud Shell — see [Execution Environments](../concepts/environment-options.md)):

```bash
az group show --name rg-ticketing-dev-swedencentral --query location -o tsv
```

If the resource group is not in a supported region, redeploy from source into one.

You also need, on the subscription:

- **Owner** or **User Access Administrator** — the agent's managed identity needs role assignments.
- The resource providers listed as prerequisites in
  [Create an Azure SRE Agent](https://learn.microsoft.com/azure/sre-agent/create-agent) registered.
  The portal offers to register any that are missing; to check or register one yourself:

```bash
az provider show --namespace <provider-namespace> --query registrationState -o tsv
az provider register --namespace <provider-namespace>
```

If your network is restricted, allow outbound access to `*.azuresre.ai`.

## 3. Create the agent and scope it (15 min)

Do this **in the Azure portal**. Nothing here depends on any other repository.

1. Open <https://sre.azure.com>, select **Create**, and select **Set up your agent**.
2. Select the subscription where the SRE Agent resource will be created. This does not grant the
   agent's managed identity access to the workload.
3. Create the agent with a CAF-compliant name and a supported region. Keep the agent resource in a
   separate resource group so it is outside the workload's desired state and blast radius.
4. On the **Azure Resources** card, add **only** `rg-ticketing-dev-swedencentral`, review the
   **Reader** role grant and finish the permission setup. Do not grant subscription-wide access.
5. Connect monitoring and the repository, then select **Done and go to agent**.
6. Keep the agent at **Reader** for this track. Runtime changes are executed by an authorised human
   after approval and recorded in the autonomy matrix in [Lab 7](lab-07-close-the-loop.md); do not
   grant the SRE Agent write access.

After deployment, open the agent → **Settings → Managed resources** and confirm the scope. Record
two values — [Lab 4](lab-04-incident-handover.md) needs both:

| Value | Where to find it |
|---|---|
| Agent name | Agent overview blade |
| Agent managed identity (object ID) | Agent → **Settings → Basics → Managed identity** |

Verify the identity's role assignments from the CLI, from any Bash shell with the Azure CLI:

```bash
az role assignment list \
  --assignee <agent-managed-identity-object-id> \
  --all -o table
```

Expect a scope ending in `/resourceGroups/rg-ticketing-dev-swedencentral` and nothing broader. If a
subscription-scoped assignment appears, delete it:

```bash
az role assignment delete \
  --assignee <agent-managed-identity-object-id> \
  --scope /subscriptions/<subscription-id>
```

✅ **Checkpoint**: the agent lists your web app, SQL server and Log Analytics workspace as in-scope
resources, and holds no role above the workload resource group.

> 📚 Portal screens change. If a step above no longer matches, follow
> [Create an Azure SRE Agent](https://learn.microsoft.com/azure/sre-agent/create-agent) and
> [Manage permissions](https://learn.microsoft.com/azure/sre-agent/manage-permissions), then keep
> the same two rules: scope to the workload resource group only, and start read-only.

### Confirm the SQL data-plane bootstrap

Before asking the agent to investigate readiness, complete the private-network bootstrap described
in [`docs/operations-runbook.md`](../operations-runbook.md). Run it in **Bash with the Azure CLI**,
from the **repository root**, on a host connected to the workload VNet, signed in as the configured
Microsoft Entra SQL administrator. Pass the **subscription deployment name** used with
`az deployment sub create --name`; this is how the script resolves the workload outputs:

```bash
./scripts/bootstrap-ticketing-database.sh --deployment-name ticketing-baseline
```

Ordinary Cloud Shell and a default dev container cannot reach the SQL private endpoint — see
[Execution Environments](../concepts/environment-options.md). The App Service managed identity
cannot create its own contained database user: it has no SQL authorization until the administrator
creates that principal. Never enable public SQL access or introduce a password to bypass this
bootstrap.

## 4. Give it signals (15 min)

An agent with no alerts has nothing to investigate. The reference baseline already includes
[`infra/modules/alerts.bicep`](../../infra/modules/alerts.bicep); verify that your rolled-up
implementation has equivalent rules, then customise it **as code** to route the alerts to the SRE
Agent or an approved action group:

| Alert | Signal | Severity |
|---|---|---|
| App HTTP 5xx | `Http5xx` > 5 in 5 min | 2 |
| App response time | Average > 3 s over 5 min | 3 |
| App availability | App Service health check (`/healthz`) failing | 1 |
| App readiness | Availability test against `/readyz` failing | 1 |
| SQL DTU/CPU | > 85%; 15 min (nearest Azure Monitor-supported window to the 10 min lab target) | 3 |

The `/healthz` and `/readyz` routes come from [`src/ContosoTicketing`](../../src/ContosoTicketing/),
which every track deploys, so these alerts work on any team's baseline. The readiness alert is the
**working SRE check** that [Lab 4](lab-04-incident-handover.md) then breaks — see
[the fault and vulnerability contract](../concepts/fault-and-vulnerability.md).

Have your [`@implementer`](../../.github/agents/implementer.agent.md) agent write the module in
**Copilot Chat in VS Code**, then validate in **Bash with the Azure CLI**, from the **repository
root**:

```bash
./scripts/validate-infra.sh
```

Deploy it with the same subscription-scope deployment you use everywhere else:

```bash
az deployment sub create \
  --name ticketing-baseline \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

The reference module intentionally leaves `actions` empty because action-group destinations are
environment-specific. Connect the rules to the SRE Agent or an approved action group after
deployment, in **Azure portal → Monitor → Alerts → Alert rules**.

✅ **Checkpoint**: alert rules are deployed and visible to the SRE Agent.

## 5. Give it knowledge (10 min)

Create a `knowledge/` directory in **your own repository** and add the operational context the agent
should use:

- `knowledge/architecture.md` — a short version of your architecture and dependencies
- `knowledge/runbook-http-500.md` — how to diagnose a 5xx from `/api/tickets` and a 503 from `/readyz` in this workload
- `knowledge/escalation.md` — what may be auto-remediated and what must page a human

Commit and push them, then attach the repository as a knowledge source in step 6 below. This is
exactly the beginner track's **skill** concept, applied to an operations agent.

## 6. Connect GitHub (5 min)

Without this connection, [Lab 4](lab-04-incident-handover.md)'s handover to Copilot cannot happen.
In the SRE Agent:

1. On the agent's **Code** card, select **+ → GitHub**, authenticate, and select the repository
   containing `knowledge/`, `infra/` and `src/`.
2. For an existing agent, use **Builder → Knowledge base → Add repository** instead. Wait for the
   repository connection to show as indexed; a temporary chat attachment is not persistent.
3. Open **Builder → Connectors** and configure the **GitHub OAuth connector** for issue handoff.
   Use a fine-grained PAT scoped only to this repository when OAuth is not suitable. Grant repository
   metadata and contents read access, issues read/write, and pull requests/actions read-only.
   Enable only the operations needed to read evidence and create an approved issue; explicitly
   disable pull-request and workflow write operations.
4. Verify the connector with: *"List the open issues in `<owner>/<repo>` and summarise them."*
5. In **GitHub → repository Settings → Copilot → Coding agent**, make sure the Copilot coding agent
   is enabled so the learner can assign the reviewed issue to `copilot-swe-agent`.

See [Connect GitHub to the Azure SRE Agent](../connect-github-to-sre-agent.md) for the least-privilege
connector setup and token-handling rules.

Verify by asking the agent, in its chat: *"List the open issues in `<owner>/<repo>` and summarise
them."* A correct answer proves both the connector and its permissions.

> 📚 If the portal wording differs, see
> [Connect source code to Azure SRE Agent](https://learn.microsoft.com/azure/sre-agent/connect-source-code)
> and [Set up the GitHub connector](https://learn.microsoft.com/azure/sre-agent/setup-github-connector).

---

## Definition of Done

- [ ] SRE Agent created, scoped to the workload resource group only, starting at least privilege
- [ ] Agent name and managed identity object ID recorded for [Lab 4](lab-04-incident-handover.md)
- [ ] [`infra/modules/alerts.bicep`](../../infra/modules/alerts.bicep) deployed and part of the desired state
- [ ] `knowledge/` contains architecture, at least one runbook and an escalation policy
- [ ] The agent is connected to your GitHub repository and can list its issues

➡️ Next: [Lab 4 — Incident → agent handover](lab-04-incident-handover.md)
