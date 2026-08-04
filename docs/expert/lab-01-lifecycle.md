# Expert Lab 1 — Lifecycle Hardening

**Time**: 60 min · **Prerequisite**: a deployed baseline

Before adding day-2 capabilities, make day-1 trustworthy. An SRE Agent that opens a pull request
is worthless if nothing validates that pull request.

## Objective

The workload is **architected, planned, tested, built, deployed and documented** — and every one
of those stages is reproducible by someone who was not in the room.

## 1. Evidence audit (15 min)

Every artifact below must exist, be committed and match the deployed reality:

| Artifact | Must contain |
|---|---|
| `docs/architecture.md` | Mermaid diagram, resource table with CAF names, WAF trade-offs |
| `docs/development-plan.md` | Task breakdown with dependencies and module interfaces |
| `docs/test-results.md` | `bicep build`, `bicep lint`, `what-if` output, security checks |
| `docs/deployment-guide.md` | Exact commands to deploy from a clean subscription |
| `docs/operations-runbook.md` | How to diagnose, roll back and scale; who to call |

Use an agent for the gap analysis rather than reading everything yourself:

```
Compare docs/architecture.md against the resources actually deployed in <resource-group>
using the Azure MCP server. List every discrepancy in a table, then fix the documentation.
```

✅ **Checkpoint**: zero discrepancies.

## 2. Local validation gate (10 min)

```bash
./scripts/validate-infra.sh
```

It must exit `0` with **no warnings**. Warnings are future incidents.

## 3. CI on every pull request (25 min)

This repo ships [`.github/workflows/infra-ci.yml`](../../.github/workflows/infra-ci.yml), which
runs `bicep build` and `bicep lint` on every PR touching `infra/`.

Extend it to add a **what-if** job against your subscription, authenticating with
**OIDC federated credentials** — no stored secrets:

1. Create a user-assigned managed identity or app registration.
2. Add a federated credential for `repo:<owner>/<repo>:pull_request`.
3. Grant it `Reader` (what-if) — a separate identity gets `Contributor` for deploys.
4. Set repository variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.
5. Add a job using `azure/login@v2` with `permissions: id-token: write`.

> 🔐 Never store an Azure client secret in GitHub. If you find yourself creating one, stop — OIDC exists precisely to avoid it.

✅ **Checkpoint**: open a PR that breaks a Bicep file on purpose. CI must fail. Revert; CI must pass.

## 4. Make `main` protected (10 min)

- [ ] Require a pull request before merging
- [ ] Require the `infra-ci` check to pass
- [ ] Block force pushes

Lab 5 adds CodeQL as a second required check.

---

## Definition of Done

- [ ] All five evidence artifacts exist and match reality
- [ ] `./scripts/validate-infra.sh` exits 0 with no warnings
- [ ] `infra-ci` runs on every PR and includes a what-if job authenticated via OIDC
- [ ] `main` is protected and requires `infra-ci`

➡️ Next: [Lab 2 — Desired state & drift](lab-02-desired-state.md)
