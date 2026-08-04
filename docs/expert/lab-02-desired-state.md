# Expert Lab 2 — Desired State and Drift

**Time**: 45 min · **Prerequisite**: Lab 1

The Azure SRE Agent can only restore a *known good* state. This lab defines what "good" means for
the Contoso Ticketing workload and makes deviation detectable and preventable.

## Objective

Source control is the desired state. Drift is detected automatically, and the most dangerous drift
is prevented outright.

```mermaid
flowchart LR
    src["infra/ in git<br/>desired state"] --> wi["what-if<br/>detect"]
    az["Azure<br/>actual state"] --> wi
    wi -->|difference| iss["GitHub issue"]
    pol["Azure Policy<br/>prevent"] --> az
```

## 1. Write the desired-state contract (10 min)

Create `docs/desired-state.md`. For each invariant, record: the property, its required value, how
to verify it, and what happens if it drifts.

Start from the security requirements in the [workload spec](../concepts/workload.md#standards):

| Invariant | Required | Verify | On drift |
|---|---|---|---|
| SQL public network access | `Disabled` | `az sql server show --query publicNetworkAccess` | Block — auto-revert |
| Web app HTTPS only | `true` | `az webapp show --query httpsOnly` | Block — auto-revert |
| Minimum TLS | `1.2` | `az webapp show --query siteConfig.minTlsVersion` | Block |
| Deny-all NSG rule present | both NSGs | `az network nsg rule list` | Alert |
| Required tags on every resource | 4 tags | `az resource list --query …` | Alert |

Let an agent draft it from `infra/`, then edit it — you own the policy, not the agent.

## 2. Drift detection with what-if (15 min)

`az deployment sub what-if` compares desired against actual. Run it now:

```bash
az deployment sub what-if \
  --name ticketing-drift \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

Then **create real drift** in the Azure portal — for example set the web app's minimum TLS version
to 1.0 — and run it again. The change must show up as a modification.

Automate it: add a scheduled workflow that runs what-if daily and opens a GitHub issue when the
result is non-empty. Reuse the OIDC identity from Lab 1 (it only needs `Reader`).

✅ **Checkpoint**: your manual portal change produced a GitHub issue.

## 3. Prevent the worst drift with Azure Policy (15 min)

Detection is day-2; prevention is better. Assign policies at the resource-group scope so the
dangerous changes cannot happen at all. At minimum:

- **Deny** SQL servers with `publicNetworkAccess` enabled
- **Deny** web apps without HTTPS only
- **Audit** resources missing any required tag

> The [ghas-defender-example](https://github.com/JoranBergfeld/ghas-defender-example) repo does the
> same thing for container images in `infra/modules/policy.bicep` — deny-by-policy after a scanner
> flags a risk. Same pattern, different resource type.

Prove it: try to re-enable public network access on the SQL server. The request must be denied.

## 4. Reconcile (5 min)

Revert the drift the honest way — redeploy from source:

```bash
az deployment sub create \
  --name ticketing-reconcile \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

Re-run what-if. It must report no changes.

---

## Definition of Done

- [ ] `docs/desired-state.md` lists every invariant with verification and drift response
- [ ] A scheduled workflow detects drift and opens a GitHub issue
- [ ] Azure Policy denies at least the two critical misconfigurations
- [ ] A demonstrated drift → detect → reconcile → clean what-if cycle

➡️ Next: [Lab 3 — Onboard the Azure SRE Agent](lab-03-sre-agent.md)
