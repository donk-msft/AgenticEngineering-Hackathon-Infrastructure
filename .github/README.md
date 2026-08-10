# `.github` assets

This folder contains active repository automation and training material for the Agentic Engineering
Hackathon. Files remain here only when GitHub, Copilot or GitHub Actions need this location to
discover and run them.

Participant-safe examples live under [`docs/tracks/examples/`](../docs/tracks/examples/). Use those
examples as reference material when building your own agents, prompts, skills and handovers.

| Path | Purpose |
|---|---|
| `agents/` | Active custom agents used by the hackathon workflow. Browse participant examples in `docs/tracks/examples/*/agents/`. |
| `prompts/` | Active reusable prompts that must be discoverable by Copilot. Duplicate participant examples belong in `docs/tracks/examples/*/prompts/`. |
| `instructions/` | Active authoring instructions for agent and prompt files. |
| `workflows/` | Active CI workflows for infrastructure validation, app build, dependency review and CodeQL. |
| `codeql-config.yml` | Active CodeQL configuration consumed by `workflows/app-ci.yml`. |
| `dependabot.yml` | Active dependency update configuration for NuGet and GitHub Actions. |
