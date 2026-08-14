# Example Output — Lab 1: `what-if` Job in `infra-ci`

What a correctly implemented **what-if job**, added to
[`.github/workflows/infra-ci.yml`](../../../../../.github/workflows/infra-ci.yml) and authenticated
with OIDC, looks like — both the workflow YAML and a passing run.

## Workflow YAML (added job)

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  build-and-lint:
    # ... existing bicep build / bicep lint job ...

  what-if:
    name: Azure what-if
    runs-on: ubuntu-latest
    needs: build-and-lint
    steps:
      - uses: actions/checkout@v4

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: What-if against the baseline
        run: |
          az deployment sub what-if \
            --name ticketing-ci-whatif \
            --location swedencentral \
            --template-file infra/main.bicep \
            --parameters infra/main.bicepparam
```

## Expected job log (no drift)

```text
Run az deployment sub what-if ...
Resource and property changes are indicated with these symbols:
  = No change

The deployment will update the following scope:

Scope: /subscriptions/<subscription-id>

Resource changes: 12 no change
```

`0` create/delete/modify lines and only `= No change` entries is the passing shape — this is the
signal the Lab 2 scheduled drift check keys off of.

## Expected job log when the PR breaks something (checkpoint)

Breaking a Bicep file on purpose — for example, a bad reference in `infra/modules/networking.bicep`
— should fail the **build-and-lint** job before what-if even runs:

```text
Run az bicep build --file infra/main.bicep
Error BCP057: The name "snetApp" does not exist in the current context.
Error: Process completed with exit code 1.
```

✅ Checkpoint met when: the PR shows a **red ❌** on `infra-ci` for the broken commit, and a **green
✅** once reverted — with the `what-if` job present in both cases (it is allowed to be skipped by
`needs:` when the earlier job fails, but must run and pass once the earlier job is green).
