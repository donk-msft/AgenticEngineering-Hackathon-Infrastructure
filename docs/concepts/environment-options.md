# Execution Environments — Dev Containers, Local VS Code or Cloud Shell

Every step in this hackathon can be run from more than one place. Pick whichever combination suits
your team; you can switch between options mid-track as long as each step runs somewhere that
actually supports it.

| Option | What you get | Best for | Limitations |
|---|---|---|---|
| **Dev Container** (Codespaces, or **VS Code: Dev Containers → Reopen in Container**) | Azure CLI, Bicep, .NET 8 SDK and the Bicep VS Code extension preinstalled via [`.devcontainer/devcontainer.json`](../../.devcontainer/devcontainer.json); Copilot Chat with the MCP servers in [`.vscode/mcp.json`](../../.vscode/mcp.json) | The full agentic workflow: writing agents/prompts/skills, `/plan`, `/fleet`, Bicep authoring, .NET 8 builds and deployment | The default container is not normally connected to the workload VNet |
| **Local VS Code** (repo opened directly, dev container skipped) | Whatever is already on your machine — Azure CLI, Bicep, .NET SDK, Copilot Chat | Teams with an already-configured machine | You are responsible for installing and updating Azure CLI, Bicep and the .NET SDK yourself |
| **Azure Cloud Shell** | Browser-based Bash with Azure CLI, Bicep and the .NET SDK preinstalled, no local install | Quick `az` / Bicep commands, what-if, deploy, `dotnet build`/`publish`, and verification, especially for native Windows users | No Copilot Chat/agents — write agents, prompts and Bicep in a devcontainer or local VS Code first, then paste the resulting `az`/`dotnet`/`bash` commands into Cloud Shell |

## Where to run each kind of step

| Kind of step | Dev Container / Codespaces | Local VS Code | Cloud Shell |
|---|---|---|---|
| Write/edit agents, prompts, skills; use Copilot Chat, `/plan`, `/fleet` | ✅ | ✅ (if Copilot Chat is configured locally) | ❌ no Copilot Chat |
| `az login`, `az account show`, `az bicep build`, `./scripts/validate-infra.sh`, `az deployment ... what-if/create` | ✅ | ✅ | ✅ |
| `dotnet build` / `dotnet publish` | ✅ .NET 8 SDK | ✅ if .NET 8 SDK is installed | ✅ preinstalled |
| `az webapp deploy` (publish the app) or trigger the [`app-deploy` workflow](../../.github/workflows/app-deploy.yml) | ✅ | ✅ | ✅ |
| Database bootstrap | ✅ fully automated — runs as part of `az deployment sub create`, no manual step from any environment | | |

The database bootstrap no longer needs a host connected to the workload VNet: it runs inside a
VNet-integrated `Microsoft.Resources/deploymentScripts` container as part of the Bicep deployment
itself, authenticated with a managed identity. There is no VM, Bastion session or Key Vault secret
to manage from any of the three environments above. Never enable public SQL access to work around
network boundaries.

Every track guide links back to this page instead of repeating environment caveats inline — if a
step doesn't specify where to run it, any option in the "✅" columns above is fine.
