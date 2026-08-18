# Copilot Instructions — Agentic Engineering Hackathon (Infrastructure)

> **Purpose:** This file is active repository automation/training material. Copilot and custom agents
> use it for repository-wide guidance; participant-safe example assets live under
> [`docs/tracks/examples/`](../docs/tracks/examples/).

This repository is a **hackathon**. Participants build and operate the *Contoso Ticketing* Azure
workload at three levels of agentic maturity.

## Ground rules

- The requirement document is [`docs/concepts/workload.md`](../docs/concepts/workload.md). Treat its
  standards and acceptance criteria as non-negotiable.
- The reference implementation is [`infra/`](../infra/). Participants write their own; do not
  silently overwrite theirs with the reference.
- Everything is **Bicep**, modularised under `infra/modules/`, with parameters in `.bicepparam`.
- The application is [`src/ContosoTicketing`](../src/ContosoTicketing/) — a minimal .NET 8 web API.
  All three tracks deploy the same infrastructure *and* the same application; keep them aligned.
- Validate with `./scripts/validate-infra.sh` and `dotnet build src/ContosoTicketing`.
  **Warnings are failures.**

## Non-negotiable standards

- CAF naming: `<type>-<workload>-<environment>-<region>`.
- Compose infrastructure from **Azure Verified Modules** pinned to an exact version
  (`br/public:avm/res/<provider>/<resource>:<version>`) — never `latest`.
- Every resource carries the tags `environment`, `workload`, `owner`, `costCenter`.
- The database is never publicly reachable — private endpoint and private DNS only.
- Managed identity for all Azure-to-Azure authentication. **Never** emit a password, connection
  secret or key into a template, an output, an app setting or a workflow.
- Azure authentication from GitHub Actions uses **OIDC federated credentials**, never a stored
  client secret.
- NSGs use least privilege and include an explicit deny-all inbound rule.
- Deployment scripts (`Microsoft.Resources/deploymentScripts`) use `cleanupPreference: OnExpiration`
  with `retentionInterval: P1D` — `OnSuccess`/`Always` can delete the container before the script
  completes and destroys its logs.
- TLS 1.2 minimum, HTTPS only, FTPS disabled.
- Application SQL access is parameterised — never concatenate input into SQL text. The SQL
  injection in [`docs/concepts/fault-and-vulnerability.md`](../docs/concepts/fault-and-vulnerability.md)
  is a deliberate lab exercise and must never be merged to `main`.

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
- Keep participant-safe reference examples under `docs/tracks/examples/`; `.github/` is only for
  assets that must be discovered by Copilot, GitHub or GitHub Actions.
