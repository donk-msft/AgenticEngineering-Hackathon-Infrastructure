# Example Output — Lab 6: Defender for Cloud GitHub Connector *(optional lab)*

What a correctly deployed and authorized Defender for Cloud ↔ GitHub connector looks like, plus a
filled-in example of the posture questionnaire from Lab 6 §3.

## `infra/modules/githubConnector.bicep` deployment output (example)

```text
$ az deployment sub create --name ticketing-baseline --location swedencentral \
    --template-file infra/main.bicep --parameters infra/main.bicepparam

{
  "properties": {
    "outputs": {
      "githubConnectorId": {
        "type": "String",
        "value": "/subscriptions/<subscription-id>/providers/Microsoft.Security/securityConnectors/github-ticketing-connector"
      }
    },
    "provisioningState": "Succeeded"
  }
}
```

## DevOps security page (example, after OAuth authorization)

```text
Defender for Cloud → DevOps security

Repository                          Status        Findings surfaced
<owner>/<repo>                      Connected     3 CodeQL, 0 secret scanning, 1 dependency
```

## Posture questionnaire (filled-in example)

| Question | Answer |
|---|---|
| What is the secure score? | 78% (was 64% before enabling Defender for SQL and App Service) |
| Highest-severity recommendation? | "SQL databases should have vulnerability findings resolved" (High) |
| Any attack path from internet to the SQL database? | No — attack path analysis shows the private endpoint blocks direct reachability |
| Does Defender agree the SQL server is not publicly exposed? | Yes — `publicNetworkAccess: Disabled` confirmed by both the desired-state contract and Defender's own scan |

## Code-to-cloud correlation (example)

```text
Recommendation: "Code vulnerabilities should be remediated (powered by GitHub Advanced Security)"
Related finding: cs/sql-injection (CWE-89) in <owner>/<repo>
Affected resource: app-ticketing-dev-swedencentral (App Service)
Downstream data store: sql-ticketing-dev-swedencentral (Azure SQL)
```

✅ Checkpoint met when: your own DevOps security page lists your repository as **Connected**, your
posture questionnaire has real (not placeholder) answers, and you can trace one finding from the
repository to a specific running resource the same way the example above does.
