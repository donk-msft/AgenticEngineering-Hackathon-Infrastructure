# Runbook: `/api/tickets` 500 and `/readyz` 503

## Trigger

Use this runbook when `/healthz` remains `200` while `/readyz` returns `503` or `/api/tickets`
returns `500`. This pattern means the web process is alive but the SQL dependency is unavailable or
unauthorized.

## Collect evidence

1. Record UTC start time, endpoint status codes, alert IDs, deployment name, and affected resource
   IDs.
2. Query recent application failures:

   ```kusto
   AppExceptions
   | where TimeGenerated > ago(30m)
   | where Message has_any ("database", "tickets", "SqlException")
   | project TimeGenerated, OperationName, Message, InnermostMessage
   | order by TimeGenerated desc
   ```

3. Check App Service and SQL activity logs for configuration changes in the same time window.
4. Verify SQL public access is still `Disabled`; never enable it for diagnosis.
5. From an approved VNet-connected host, resolve
   `<sql-server>.database.windows.net`. It must return a private address.
6. Verify the SQL private endpoint connection is `Approved` and the private DNS VNet link exists.
7. As the Entra SQL administrator, check the app principal and role membership:

   ```sql
   SELECT name, type_desc
   FROM sys.database_principals
   WHERE name = N'<app-service-name>';

   SELECT roles.name AS role_name, members.name AS member_name
   FROM sys.database_role_members
   JOIN sys.database_principals AS roles
     ON roles.principal_id = role_principal_id
   JOIN sys.database_principals AS members
     ON members.principal_id = member_principal_id
   WHERE members.name = N'<app-service-name>';
   ```

## Diagnose

| Evidence | Likely cause | Safe response |
|---|---|---|
| App principal missing or no `db_datareader` | SQL data-plane authorization drift | Page the Entra SQL administrator; rerun the idempotent bootstrap from a private host. |
| Public DNS answer or missing VNet link | Private DNS drift | Restore the private DNS zone link from Bicep. |
| Private endpoint not approved | Private endpoint drift or failed deployment | Review deployment operations and restore from Bicep. |
| NSG no longer permits app subnet to TCP 1433 | Network policy drift | Restore the reviewed NSG rule from Bicep. |
| No infrastructure drift, SQL timeout/throttling evidence | Platform or capacity incident | Correlate SQL metrics and Resource Health; escalate before scaling. |

## Verify and close

Confirm all three routes return `200`, the alert resolves, and `az deployment sub what-if` shows no
unexplained drift. Record symptom, telemetry, root cause, exact remediation, approver, validation,
and any required repository change in the incident handover.
