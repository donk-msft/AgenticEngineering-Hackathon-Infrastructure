---
name: azure-naming-and-tagging
description: 'Generate or review Azure resource names and tags for the Contoso Ticketing workload. Use when creating Bicep, planning infrastructure, naming Azure resources, checking CAF conventions, or validating required tags.'
argument-hint: '<workload> <environment> <region>'
---

# Azure Naming and Tagging

Apply the naming and tagging contract in `docs/concepts/workload.md` whenever Azure resources are
created, changed, documented, or reviewed for Contoso Ticketing.

## Inputs

Collect or identify these values before producing names:

- `workload`, such as `ticketing`
- `environment`, using `dev`, `tst`, or `prd`
- `region`, using the lowercase Azure location token, such as `swedencentral`
- `owner`
- `costCenter`

In reusable agents, prompts, plans, and examples, retain the placeholders `<workload>`,
`<environment>`, and `<region>` instead of inserting live environment identifiers.

## Naming Contract

Use lowercase names and hyphen separators. The default CAF-style shape is:

`<type>-<workload>-<environment>-<region>`

Use the workload's required type prefixes and exact patterns:

| Resource | Required name |
|---|---|
| Resource group | `rg-<workload>-<environment>-<region>` |
| Virtual network | `vnet-<workload>-<environment>-<region>` |
| App Service plan | `asp-<workload>-<environment>-<region>` |
| Web app | `app-<workload>-<environment>-<region>` |
| SQL logical server | `sql-<workload>-<environment>-<region>` |
| SQL database | `sqldb-<workload>-<environment>-<region>` |
| SQL private endpoint | `pep-sql-<workload>-<environment>-<region>` |
| Log Analytics workspace | `log-<workload>-<environment>-<region>` |
| Application Insights | `appi-<workload>-<environment>-<region>` |
| Database bootstrap identity | `id-dbbootstrap-<workload>-<environment>-<region>` |

Use these specified exceptions exactly:

| Resource | Required name |
|---|---|
| App subnet | `snet-app` |
| Private endpoint subnet | `snet-privateendpoints` |
| Deployment script subnet | `snet-deployscript` |
| App subnet NSG | `nsg-app-<environment>-<region>` |
| Private endpoint subnet NSG | `nsg-pep-<environment>-<region>` |
| Deployment script subnet NSG | `nsg-deployscript-<environment>-<region>` |
| SQL private DNS zone | `privatelink.database.windows.net` |

Do not add subscription IDs, tenant IDs, resource IDs, host names, personal account names, random
suffixes, or unapproved abbreviations to a name. If a resource type is not listed, derive its CAF
type prefix and apply the default shape; flag any Azure length or character constraint that prevents
the shape from being used exactly.

## Required Tags

Apply this tag object to every resource that supports tags:

```bicep
var tags = {
  environment: environment
  workload: workload
  owner: owner
  costCenter: costCenter
}
```

Additional tags are allowed, but they do not replace any required tag. Pass the shared tag object
to modules instead of rebuilding partial tag objects in individual resources.

## Procedure

1. Read the declared `workload`, `environment`, and Azure `region` values from parameters; do not
	infer them from subscription-specific identifiers.
2. Build the shared suffix as `<workload>-<environment>-<region>`.
3. Select the exact pattern from the tables above. Use the default shape only for an unlisted type.
4. Apply the shared required tags to every taggable resource, including the resource group.
5. Check each generated or existing name for lowercase characters, segment order, separator use,
	the correct prefix, and the absence of environment-specific hardcoding in reusable assets.
6. Report each mismatch as `resource: expected <name>, found <name>` and correct it at the shared
	variable or parameter that owns the name when possible.
7. Re-run `./scripts/validate-infra.sh` after Bicep changes. Treat warnings as failures.

## Output

When asked to generate names, return a concise resource-to-name mapping and the four required tag
values. When reviewing infrastructure, list violations first, followed by corrected names and any
Azure platform constraint that needs a documented exception.
