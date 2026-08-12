# Connect GitHub to the Azure SRE Agent

The expert track uses two separate GitHub integrations:

| Integration | Where | Purpose |
|---|---|---|
| Code/Knowledge Base repository | **Code** card during onboarding, or **Builder → Knowledge base** | Indexes source for investigation and file references |
| GitHub OAuth connector | **Builder → Connectors** | Reads repository evidence and creates an approved issue |

Connect the repository first and wait until it is indexed. Then configure the GitHub OAuth connector
with the narrowest access needed by the scenario:

- Metadata and contents: read-only
- Issues: read/write, required to create the approved handover issue
- Pull requests and Actions: read-only, if status or workflow evidence is needed
- No pull-request or Actions write access

Prefer a fine-grained PAT limited to the generated repository when interactive OAuth is not suitable.
Treat it as a password: paste it only into the connector form, never into this repository, an issue,
chat, shell history or workflow secret. Set the shortest practical expiry and revoke it when the
exercise ends.

Verify the connector with a read-only request:

```text
List recent issues from <owner>/<repo> and summarize the top 3.
```

For the handover exercise, the SRE Agent investigates and requests approval, then creates exactly
one **unassigned** issue. The learner reviews it and assigns `copilot-swe-agent`. The SRE Agent does
not create a branch or pull request, merge changes, deploy code or make direct Azure changes.

References: [Connect source code](https://learn.microsoft.com/azure/sre-agent/connect-source-code),
[Set up the GitHub connector](https://learn.microsoft.com/azure/sre-agent/setup-github-connector), and
the [Azure SRE Agent workshop](https://github.com/JoranBergfeld/sre-agent-workshop).
