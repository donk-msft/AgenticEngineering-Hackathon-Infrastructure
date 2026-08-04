# Copilot Instructions — Agentic Engineering Hackathon (Infrastructure)

This repository is a **hackathon**. Participants build and operate the *Contoso Ticketing* Azure
workload at three levels of agentic maturity.

## Ground rules

- The requirement document is [`docs/concepts/workload.md`](../docs/concepts/workload.md). Treat its
  standards and acceptance criteria as non-negotiable.
- The reference implementation is [`infra/`](../infra/). Participants write their own; do not
  silently overwrite theirs with the reference.
- Everything is **Bicep**, modularised under `infra/modules/`, with parameters in `.bicepparam`.
- Validate with `./scripts/validate-infra.sh`. **Warnings are failures.**

## Non-negotiable standards

- CAF naming: `<type>-<workload>-<environment>-<region>`.
- Every resource carries the tags `environment`, `workload`, `owner`, `costCenter`.
- The database is never publicly reachable — private endpoint and private DNS only.
- Managed identity for all Azure-to-Azure authentication. **Never** emit a password, connection
  secret or key into a template, an output, an app setting or a workflow.
- Azure authentication from GitHub Actions uses **OIDC federated credentials**, never a stored
  client secret.
- NSGs use least privilege and include an explicit deny-all inbound rule.
- TLS 1.2 minimum, HTTPS only, FTPS disabled.

## Documentation style

- Guides live in `docs/tracks/`, concepts in `docs/concepts/`, expert labs in `docs/expert/`.
- Expert labs are named `lab-NN-<slug>.md`, are self-contained, and end with a
  **Definition of Done** checklist and a link to the next lab.
- Prefer Mermaid diagrams over prose for architecture and flow.
- Link to upstream sources rather than copying their content.

## Agentic assets

- Agents: `.github/agents/<role>.agent.md` — one responsibility, least-privilege tools, explicit
  `handoffs`, and a named output contract.
- Prompts: `.github/prompts/<workflow>-<step>-<verb>.prompt.md` — numbered, with inputs, task and
  expected output.
- These are **reference examples**. Participants are expected to write their own.
