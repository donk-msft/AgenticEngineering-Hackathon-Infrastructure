# Expert Lab 1 — Lifecycle Hardening

**Time**: 60 min · **Prerequisite**: a deployed baseline

Before adding day-2 capabilities, make day-1 trustworthy. An SRE Agent that opens a pull request
is worthless if nothing validates that pull request.

## Objective

The workload is **architected, planned, tested, built, deployed and documented** — and every one
of those stages is reproducible by someone who was not in the room.

## 1. Evidence audit (15 min)

Every artifact below must exist in **your own repository**, be committed and match the deployed
reality. Only the last one ships with this repo — the other four are yours to write:

| Artifact | Must contain |
|---|---|
| `docs/architecture.md` (you create) | Mermaid diagram, resource table with CAF names, WAF trade-offs |
| `docs/development-plan.md` (you create) | Task breakdown with dependencies and module interfaces |
| `docs/test-results.md` (you create) | `bicep build`, `bicep lint`, `what-if` output, security checks |
| `docs/deployment-guide.md` (you create) | Exact commands to deploy from a clean subscription |
| [`docs/operations-runbook.md`](../operations-runbook.md) (reference version provided) | How to diagnose, roll back and scale; who to call |

Use an agent for the gap analysis rather than reading everything yourself. Paste the following into
**Copilot Chat in VS Code** (dev container or local — Cloud Shell has no Copilot Chat, see
[Execution Environments](../concepts/environment-options.md)):

```text
Compare docs/architecture.md against the resources actually deployed in <resource-group>
using the Azure MCP server. List every discrepancy in a table, then fix the documentation.
```

✅ **Checkpoint**: zero discrepancies.

## 2. Local validation gate (10 min)

Run in **Bash with the Azure CLI installed**, from the **repository root** (dev container,
local VS Code or Cloud Shell — see [Execution Environments](../concepts/environment-options.md)):

```bash
./scripts/validate-infra.sh
```

It must exit `0` with **no warnings**. Warnings are future incidents.

## 3. CI on every pull request (25 min)

This repo ships [`.github/workflows/infra-ci.yml`](../../.github/workflows/infra-ci.yml), which
runs `bicep build` and `bicep lint` on every PR touching [`infra/`](../../infra/).

Extend it to add a **what-if** job against your subscription, authenticating with
**OIDC federated credentials** — no stored secrets:

1. Create a user-assigned managed identity or app registration (Azure portal or `az` CLI).
2. Add a federated credential for `repo:<owner>/<repo>:pull_request`.
3. Grant it `Reader` (what-if) — a separate identity gets `Contributor` for deploys.
4. Set repository variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
   (**GitHub → repository Settings → Secrets and variables → Actions → Variables**).
5. Add a job using `azure/login@v2` with `permissions: id-token: write`.

> 🔐 Never store an Azure client secret in GitHub. If you find yourself creating one, stop — OIDC exists precisely to avoid it.

✅ **Checkpoint**: open a PR that breaks a Bicep file on purpose. CI must fail. Revert; CI must pass.

📄 See [an example what-if job and passing/failing CI output](../tracks/examples/expert/outputs/lab-01-ci-what-if-job.md) to check your implementation against.

## 4. Make `main` protected (10 min)

In **GitHub → repository Settings → Branches → Add branch ruleset** (or *Branch protection rules*):

- [ ] Require a pull request before merging
- [ ] Require the `infra-ci` check to pass
- [ ] Block force pushes

[Lab 5](lab-05-ghas.md) *(optional)* adds CodeQL as a second required check.

---

## Definition of Done

- [ ] All five evidence artifacts exist and match reality
- [ ] `./scripts/validate-infra.sh` exits 0 with no warnings
- [ ] `infra-ci` runs on every PR and includes a what-if job authenticated via OIDC
- [ ] `main` is protected and requires `infra-ci`

➡️ Next: [Lab 2 — Desired state & drift](lab-02-desired-state.md)
