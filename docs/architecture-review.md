# Contoso Ticketing Architecture Review

**Result: PASS FOR PLANNING; LIVE ACCEPTANCE PENDING**

The design and owner clarifications cover the workload's security, platform, build, deployment, and
verification controls. A target subscription is available, but the workload has not been deployed;
all criteria that depend on live resources remain pending runtime evidence.

This review assesses design coverage only. Criteria that require a deployed workload remain subject
to live verification even when the architecture is marked **Covered**.

## Acceptance criteria mapping

| # | Workload acceptance criterion | Status | Design coverage or gap |
|---|---|---|---|
| 1 | Subscription deployment reports `Succeeded` | **Covered** | Deploy the resources into the existing subscription, then require `az deployment sub show` to report `Succeeded`. No deployment exists yet, so live evidence remains pending. |
| 2 | Every resource follows CAF naming | **Covered** | The resource table defines CAF names. Storage accounts use the owner-approved constrained-resource convention `stticketdev<hash6>` because Azure prohibits hyphens, limits names to 24 characters, and requires global uniqueness. Concrete `dev` and `swedencentral` names remain examples generated from parameters. |
| 3 | Every resource has `environment`, `workload`, `owner`, and `costCenter` tags | **Covered** | The introduction, Security decisions, and handover require all four tags on every taggable resource, including the resource group. Live resource enumeration is still required. |
| 4 | SQL `publicNetworkAccess` is `Disabled` | **Covered** | Target architecture, Resource table, Security decisions, and handover all require disabled SQL public access. |
| 5 | SQL private endpoint connection state is `Approved` | **Covered** | The owner selected same-scope automatic approval. Deployment must still verify that the live connection state is `Approved`. |
| 6 | SQL FQDN resolves from the app to `10.10.2.x` | **Covered** | The diagram and Security decisions link `privatelink.database.windows.net` to the VNet and map SQL to the private endpoint subnet. This must be tested from the app execution context. |
| 7 | Every subnet has an NSG and explicit deny-all inbound | **Covered** | The Resource table and handover attach an NSG to all three subnets and require deny-all inbound at priority 4096. |
| 8 | Bootstrap identity is sole Entra SQL administrator; script has no public IP and runs only in workload VNet | **Covered** | The diagram, Resource table, Security decisions, and handover fix the user-assigned bootstrap identity as sole administrator and place the script privately in `snet-deployscript`. |
| 9 | Bootstrap uses `OnExpiration` and `P1D` | **Covered** | The Resource table, Security decisions, and handover specify both exact values. |
| 10 | Web app has system-assigned identity and no password or connection secret in app settings | **Covered** | Security decisions and handover require the system-assigned identity and prohibit credential-bearing settings. |
| 11 | Web app is HTTPS-only with TLS 1.2 or higher | **Covered** | The diagram, Security decisions, and handover require `httpsOnly: true`, TLS 1.2 or higher, and disabled FTPS. |
| 12 | Application Insights receives telemetry and is workspace-based | **Covered** | The diagram and Resource table route application telemetry to workspace-based Application Insights backed by Log Analytics. Receipt must be confirmed with a live telemetry query. |
| 13 | Every module uses an exact version-pinned AVM | **Covered** | Resource entries identify exact AVM versions and the IaC decision prohibits `latest`. Native child resources must remain inside the applicable AVM interface rather than bypassing AVM. |
| 14 | `GET /healthz` returns `200` | **Covered** | The architecture fixes `/healthz` as the platform health path and requires the .NET 8 API routes. A deployed HTTP assertion is still required. |
| 15 | `GET /readyz` returns `200` through private SQL using managed identity | **Covered** | The diagram, readiness web test, Security decisions, and handover define the managed-identity/private-endpoint path. A deployed HTTP assertion and dependency evidence are still required. |
| 16 | `./scripts/validate-infra.sh` passes | **Covered** | The owner requires the repository's authoritative infrastructure validation script as a build gate. |
| 17 | `dotnet build src/ContosoTicketing` passes | **Covered** | The owner requires this exact application build command as a build gate. |

**Summary:** 17 covered, 0 ambiguous, 0 missing. Live deployment evidence is still pending.

## Findings

### F1 - Environment parameterization boundary is not explicit enough

**Severity: Mandatory**

The architecture repeatedly uses `dev`, `swedencentral`, and `10.10.0.0/16`. These are acceptable as
the approved development baseline, but reusable Bicep must not embed them. The document says the
values are parameters, yet the handover does not enumerate the address space and subnet prefixes as
parameter inputs. Without that boundary, the concrete examples can be implemented as hardcoded
environment values.

### F2 - Live acceptance evidence does not exist yet

**Severity: Mandatory**

The target subscription exists, but the workload has not been deployed. Design coverage is complete;
deployment success, runtime configuration, DNS, endpoint, route, identity, tag, and telemetry claims
must still be proven against live resources.

## Security and standards review

- **PASS:** SQL has no public access path; private endpoint and private DNS are mandatory.
- **PASS:** Application and bootstrap database access use managed identities.
- **PASS:** No password, key, credential, subscription ID, tenant ID, personal account, or resource
  ID is introduced by the design.
- **PASS:** TLS 1.2 or higher, HTTPS-only, disabled FTPS, least-privilege NSGs, and explicit deny-all
  inbound are fixed decisions.
- **PASS:** Database bootstrap log retention uses `OnExpiration` and `P1D`.
- **PASS:** AVM references are exact-version requirements; `latest` is prohibited.
- **PASS WITH EXCEPTION:** Storage accounts follow the separately approved constrained-resource
   naming convention because Azure storage naming cannot use the default hyphenated CAF shape.
- **PASS WITH TRADE-OFF:** The web app has a public HTTPS endpoint. The workload prohibits public SQL,
  not public App Service ingress, and the owner explicitly accepted this development-only exposure.

## Required planner tasks

1. **Implement the approved storage convention.** Generate the constrained storage account name
   with the documented prefix and deterministic six-character `uniqueString` suffix. Keep its inputs
   non-secret and record the storage convention as an explicit naming exception in implementation
   documentation and validation rules.
2. **Define all environment inputs.** Parameterize `workload`, `environment`, `location`, `owner`,
   `costCenter`, VNet address space, and all subnet prefixes in `.bicepparam`; keep `dev`,
   `swedencentral`, and `10.10.x.x` only in the development parameter file. Do not derive reusable
   names from subscription IDs, tenant IDs, resource IDs, or personal identifiers.
3. **Use automatic private endpoint approval.** Deploy the SQL private endpoint in the same
   administrative scope so approval is automatic, then verify the live connection state is
   `Approved`.
4. **Implement with pinned AVM only.** Map every resource to the exact AVM version in the Resource
   table, keep child resources within AVM interfaces where supported, and introduce no `latest`
   reference.
5. **Run the required repository build gates.** Require `./scripts/validate-infra.sh` and
   `dotnet build src/ContosoTicketing` to complete successfully with warnings treated as failures.
6. **Deploy to the available subscription and add live verification.** Require
   `az deployment sub show` to
   report `Succeeded`, enumerate names and required tags, confirm SQL public access is disabled,
   confirm private endpoint approval, inspect every subnet NSG and deny rule, and inspect bootstrap
   identity, networking, cleanup, and retention settings.
7. **Add live application and observability verification.** From the deployed environment, verify
   private SQL DNS resolves to `10.10.2.x`, `/healthz` and `/readyz` return `200`, the app has a
   system-assigned identity with no credential-bearing settings, and workspace-based Application
   Insights contains recent application telemetry.

## Resolved design decisions

The planner must preserve the owner-approved development baseline: public HTTPS App Service ingress;
no corporate connectivity integration; development only in Sweden Central; 30-day Log Analytics
retention with no daily cap and default sampling; service-default SQL point-in-time restore with no
long-term retention; alert rules without an action group; one P0v3 worker; the documented serverless
SQL sizing; no autoscale; and no formal workload-specific SLO, RPO, or RTO.

The owner additionally resolved that SQL private endpoint approval is automatic in the same
administrative scope; `./scripts/validate-infra.sh` and `dotnet build src/ContosoTicketing` are
mandatory build gates; and successful deployment means the workload resources are deployed into the
existing subscription with subscription deployment state `Succeeded`.

## Handover to `@planner`

Hand off this review and the architecture to `@planner`. All design ambiguities are resolved and
planning may begin. Tasks 1 through 7 remain mandatory implementation and verification work and must
appear in the plan with explicit evidence outputs. Final acceptance remains blocked until the live
checks pass.