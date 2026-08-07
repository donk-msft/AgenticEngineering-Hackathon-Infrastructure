# Expert Lab 4 — Incident → Agent Handover

**Time**: 75 min · **Prerequisite**: [Lab 3 — Onboard the Azure SRE Agent](lab-03-sre-agent.md)

This lab is **self-contained**: the fault, the checks and the handover are all defined inside this
repository. The scenario is the classic *cloud agent handover* pattern — an App Service based
workload where a runtime failure is investigated by an operations agent and, when the fix belongs
in code, handed to a coding agent as a structured issue.

## Objective

Run a full incident lifecycle where **two agents hand over to each other**: the Azure SRE Agent
investigates a live incident and, when the fix belongs in code, hands a structured GitHub issue to
GitHub Copilot, which produces a pull request that your CI validates and deploys.

This is the beginner track's **handover** concept — but machine-to-machine and in production.

```mermaid
sequenceDiagram
    participant App as Contoso Ticketing
    participant Mon as Azure Monitor
    participant SRE as Azure SRE Agent
    participant You as You
    participant Cop as GitHub Copilot
    participant CI as GitHub Actions

    App->>Mon: HTTP 500 on /api/tickets, 503 on /readyz
    Mon->>SRE: alert fires
    SRE->>SRE: investigate (logs, KQL, Resource Graph)
    SRE->>You: findings + proposed action
    You->>SRE: approve handover
    SRE->>Cop: structured GitHub issue with diagnostics
    Cop->>CI: pull request with the fix
    CI->>App: validated deploy via OIDC
```

## 1. Prepare the fault (20 min)

The fault is defined once, for all tracks, in
[`docs/concepts/fault-and-vulnerability.md`](../concepts/fault-and-vulnerability.md). Read it now.

First confirm the **working** state — this is the SRE check that must pass before you break it. Run
in **Bash** (any shell with `curl`; dev container, local VS Code or Cloud Shell — see
[Execution Environments](../concepts/environment-options.md)), replacing `<webapp>` with your web
app name:

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://<webapp>.azurewebsites.net/readyz   # expect 200
curl -s -o /dev/null -w '%{http_code}\n' https://<webapp>.azurewebsites.net/api/tickets  # expect 200
```

If readiness has never returned `200`, do not inject a fault. Complete the private SQL bootstrap in
[`docs/operations-runbook.md`](../operations-runbook.md), running
[`./scripts/bootstrap-ticketing-database.sh`](../../scripts/bootstrap-ticketing-database.sh) from
the **repository root** on a VNet-connected host, using the original subscription deployment name.
The App Service managed identity cannot create its own SQL principal; the configured Entra SQL
administrator must establish that initial data-plane authorization.

Then inject exactly one of injections **A**, **B** or **C** from that document — a dropped database
role membership, a deleted private DNS virtual network link, or a removed NSG rule. All three make
`/api/tickets` return `500` and `/readyz` return `503`, and each leaves a different trail in
telemetry.

> ⚠️ Do this **outside** your IaC, by hand. Lab 2 taught you that source is the desired state; here
> you are deliberately creating drift so the agents have something real to find. Write down exactly
> what you changed, and do not tell the agent — you will compare your note to its conclusion.

## 2. Trigger and observe (20 min)

Drive traffic to the broken route until the alert fires — from **Bash**, replacing `<webapp>`:

```bash
for i in $(seq 1 60); do
  curl -s -o /dev/null https://<webapp>.azurewebsites.net/api/tickets
  sleep 5
done
```

Then **watch without helping**, in the SRE Agent's chat/incident view in the Azure portal. Record:

| Question | Your observation |
|---|---|
| Time to alert | |
| Data sources the agent used | |
| Did it identify the correct root cause? | |
| What did it propose? | |
| Did it ask for approval before acting? | |

✅ **Checkpoint**: the SRE Agent produced an investigation with a root-cause hypothesis.

## 3. Approve the handover (15 min)

When the agent proposes an action, evaluate it before approving:

- Is this a **runtime** fix (restart, scale, revert a setting) → remediate in Azure, then update IaC so it is not drift.
- Is this a **code or template** fix → hand it to GitHub Copilot as an issue.

Approve, and confirm the GitHub issue that gets created contains: symptom, affected resource,
supporting telemetry, root-cause hypothesis and suggested fix. **A handover without evidence is
just a ticket.**

## 4. Copilot fixes it (15 min)

Assign the issue to GitHub Copilot (**GitHub → Issues → the issue → Assignees → Copilot**). It
should open a pull request. Review it as an engineer:

- [ ] Does it fix the root cause or only the symptom?
- [ ] Does it also fix the **template**, so the fault cannot recur on redeploy?
- [ ] Does [`infra-ci`](../../.github/workflows/infra-ci.yml) ([Lab 1](lab-01-lifecycle.md)) pass on the PR?

Merge it and let CI deploy through the OIDC pipeline.

## 5. Verify and close (5 min)

Run the two `curl` checks from step 1 again, and the drift check from the **repository root** in
**Bash with the Azure CLI**:

```bash
az deployment sub what-if \
  --name ticketing-drift \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

- [ ] `GET /readyz` returns `200` and `GET /api/tickets` returns `200` again
- [ ] The alert has resolved
- [ ] `az deployment sub what-if` reports no drift
- [ ] The incident, investigation and fix are captured in [`docs/operations-runbook.md`](../operations-runbook.md)

## 6. Reflect

1. Where did the SRE Agent's conclusion differ from what you actually broke?
2. What did the handover issue lack that a human would have included?
3. Which knowledge file from [Lab 3](lab-03-sre-agent.md) would have made the investigation faster?
4. Which parts of this loop would you let run without an approval gate — and which never?

---

## Definition of Done

- [ ] An incident was injected, alerted and investigated by the SRE Agent
- [ ] A handover was approved and produced a structured GitHub issue
- [ ] Copilot produced a PR that CI validated and deployed
- [ ] The alert resolved and what-if reports no drift
- [ ] The runbook was updated with what you learned

➡️ Next: [Lab 5 — GHAS on the IaC repo](lab-05-ghas.md)
