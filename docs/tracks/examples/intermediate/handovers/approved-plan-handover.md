# Approved Plan Handover

| Field | Value |
|---|---|
| Source | `/plan` output reviewed by `@plan-reviewer` |
| Artifact | `plan.md`, `docs/plan-review.md` |
| Next step | `/fleet` implementation |
| Human decision | `<approved / revise plan>` |

## Required checks before `/fleet`

- [ ] Each workload acceptance criterion maps to a task.
- [ ] Parallel batches have explicit dependencies.
- [ ] Module parameters and outputs are named consistently.
- [ ] Security tasks cover private SQL, managed identity, NSG deny-all, HTTPS, TLS and FTPS.
- [ ] No subscription ids, tenant ids, resource ids, host names or secrets are present.
