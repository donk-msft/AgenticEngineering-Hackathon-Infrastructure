# Execution Environments — Dev Containers, Local VS Code or Cloud Shell

Every step in this hackathon can be run from more than one place. Pick whichever combination suits
your team; you can switch between options mid-track as long as each step runs somewhere that
actually supports it.

| Option | What you get | Best for | Limitations |
|---|---|---|---|
| **Dev Container** (Codespaces, or **VS Code: Dev Containers → Reopen in Container**) | Azure CLI, Bicep, .NET 8 SDK and the Bicep VS Code extension preinstalled via [`.devcontainer/devcontainer.json`](../../.devcontainer/devcontainer.json); Copilot Chat with the MCP servers in [`.vscode/mcp.json`](../../.vscode/mcp.json) | The full agentic workflow: writing agents/prompts/skills, `/plan`, `/fleet`, Bicep authoring, .NET 8 builds and deployment | The default container is not normally connected to the workload VNet |
| **Local VS Code** (repo opened directly, dev container skipped) | Whatever is already on your machine — Azure CLI, Bicep, .NET SDK, Copilot Chat | Teams with an already-configured machine, or a host that is VPN/ExpressRoute/Bastion-connected to the workload VNet | You are responsible for installing and updating Azure CLI, Bicep and the .NET SDK yourself |
| **Azure Cloud Shell** | Browser-based Bash with Azure CLI, Bicep and the .NET SDK preinstalled, no local install | Quick `az` / Bicep commands, what-if, deploy, `dotnet build`/`publish`, and verification, especially for native Windows users | No Copilot Chat/agents — write agents, prompts and Bicep in a devcontainer or local VS Code first, then paste the resulting `az`/`dotnet`/`bash` commands into Cloud Shell; **not** normally connected to your workload VNet |

## Where to run each kind of step

| Kind of step | Dev Container / Codespaces | Local VS Code | Cloud Shell |
|---|---|---|---|
| Write/edit agents, prompts, skills; use Copilot Chat, `/plan`, `/fleet` | ✅ | ✅ (if Copilot Chat is configured locally) | ❌ no Copilot Chat |
| `az login`, `az account show`, `az bicep build`, `./scripts/validate-infra.sh`, `az deployment ... what-if/create` | ✅ | ✅ | ✅ |
| `dotnet build` / `dotnet publish` | ✅ .NET 8 SDK | ✅ if .NET 8 SDK is installed | ✅ preinstalled |
| `az webapp deploy` (publish the app) | ✅ | ✅ | ✅ |
| `./scripts/bootstrap-ticketing-database.sh` (must resolve the SQL private endpoint) | ⚠️ only if the container/Codespace is network-joined to the workload VNet (not the default) | ✅ if the machine is VPN/ExpressRoute/Bastion-connected to the VNet | ❌ not normally VNet-connected |

Whenever a guide says "run this from a host connected to the workload VNet", none of the three
default options satisfy that out of the box — use a jumpbox, VPN gateway, Azure Bastion session or
a self-hosted runner that is joined to the VNet. Never enable public SQL access to work around this
boundary.

Every track guide links back to this page instead of repeating environment caveats inline — if a
step doesn't specify where to run it, any option in the "✅" columns above is fine.
