# Example Output — Lab 2: Drift Detection with `what-if`

What a real drift — introduced manually in the Azure portal — looks like in `what-if` output, and
the shape of the GitHub issue the scheduled workflow should open.

## `what-if` output showing drift

After lowering the web app's minimum TLS version to `1.0` in the portal, re-running:

```bash
az deployment sub what-if \
  --name ticketing-drift \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

should report a **modify**, not `= No change`:

```text
Resource and property changes are indicated with these symbols:
  - Delete
  + Create
  ~ Modify
  = No change

The deployment will update the following scope:

Scope: /subscriptions/<subscription-id>

  ~ Microsoft.Web/sites/app-ticketing-dev-swedencentral [2023-12-01]
    ~ properties.siteConfig.minTlsVersion: "1.0" => "1.2"

Resource changes: 1 to modify, 11 no change
```

## Scheduled workflow → GitHub issue (example)

```yaml
name: drift-check
on:
  schedule:
    - cron: "0 6 * * *"
  workflow_dispatch:

permissions:
  id-token: write
  contents: read
  issues: write

jobs:
  what-if:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - id: whatif
        run: |
          result=$(az deployment sub what-if \
            --name ticketing-drift \
            --location swedencentral \
            --template-file infra/main.bicep \
            --parameters infra/main.bicepparam \
            --no-pretty-print)
          echo "result<<EOF" >> "$GITHUB_OUTPUT"
          echo "$result" >> "$GITHUB_OUTPUT"
          echo "EOF" >> "$GITHUB_OUTPUT"
      - if: contains(steps.whatif.outputs.result, 'Modify') || contains(steps.whatif.outputs.result, 'Delete')
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Infra drift detected by scheduled what-if',
              labels: ['drift'],
              body: 'Scheduled what-if reported a difference between `infra/` and the deployed state. See the workflow run for the full diff.'
            });
```

## Resulting GitHub issue (example)

```markdown
Title: Infra drift detected by scheduled what-if

Scheduled what-if reported a difference between `infra/` and the deployed state. See the
workflow run for the full diff.

Detected change:
- Microsoft.Web/sites/app-ticketing-dev-swedencentral: properties.siteConfig.minTlsVersion
  "1.0" => "1.2"

Run: <workflow run URL>
```

✅ Checkpoint met when: your manual portal change produces both the modified `what-if` output above
and a real GitHub issue with a similar shape — then reconciling (redeploying from source) returns
`what-if` to `Resource changes: 0 to modify` / all `= No change`.
