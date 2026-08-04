# Azure Naming and Tagging Skill

Use this skill whenever an agent, prompt or plan names Azure resources for Contoso Ticketing.

## Naming

- Resource names follow CAF-style shape: `<type>-<workload>-<environment>-<region>`.
- Use placeholders in reusable assets: `<workload>`, `<environment>`, `<region>`.
- Example shape: `rg-<workload>-<environment>-<region>`.
- Do not embed subscription ids, tenant ids, resource ids, host names or personal account names.

## Required tags

Every Azure resource must carry:

- `environment`
- `workload`
- `owner`
- `costCenter`

## Security reminders

- Use managed identity for Azure-to-Azure authentication.
- Do not output passwords, keys, connection secrets or client secrets.
- SQL must use private endpoint and private DNS only.
- NSGs must include explicit deny-all inbound rules.
- Web apps must use HTTPS only, TLS 1.2 or later and FTPS disabled.

## Bicep reminders

- Keep templates in `infra/` and modules in `infra/modules/`.
- Keep parameter values in `.bicepparam`.
- Use Azure Verified Modules pinned to exact versions; never use `latest`.
