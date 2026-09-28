# Contoso Ticketing Test Results

## Deployment summary

| Check | Result | Sanitized evidence |
|---|---|---|
| Local Bicep validation | Pass | All templates and parameter files built with zero warnings. |
| .NET application build | Pass | Build completed with zero warnings and zero errors. |
| Azure subscription validation | Pass | Provisioning validation reported `Succeeded`. |
| Azure what-if | Pass | What-if reported `Succeeded`; three initial creates were visible and dependent nested modules were short-circuited. No deletion was visible. |
| Approved infrastructure deployment | **Fail** | Subscription deployment reached terminal state `Failed`. The App Service resource could not be created because its globally scoped name was already allocated. |
| Application deployment | **Fail** | Not attempted because infrastructure provisioning did not succeed. |
| `GET /healthz` | **Fail** | Not testable; application deployment was blocked. URL withheld. |
| `GET /readyz` | **Fail** | Not testable; application deployment was blocked. URL withheld. |

No subscription ID, tenant ID, live host name, account name, token, credential, or secret is included in this evidence.

## Acceptance criteria

The following results distinguish completed validation from live checks. A criterion that could not be verified against a successful live deployment is marked **Fail** rather than inferred from the template.

| Acceptance criterion | Result | Evidence |
|---|---|---|
| Subscription deployment reports `Succeeded` | **Fail** | Terminal deployment state was `Failed`. |
| Every resource follows the required CAF naming convention | **Fail** | A complete live deployment was unavailable for verification. |
| Every resource carries all four required tags | **Fail** | A complete live deployment was unavailable for verification. |
| SQL public network access is `Disabled` | **Fail** | Not verified against a completed live deployment. |
| SQL private endpoint connection is `Approved` | **Fail** | Not verified against a completed live deployment. |
| SQL DNS resolves from the app to the private endpoint subnet | **Fail** | App execution context was unavailable. |
| All subnets have NSGs with explicit deny-all inbound rules | **Fail** | Not verified against a completed live deployment. |
| Bootstrap identity is the sole Entra SQL administrator and the script is private | **Fail** | Not verified against a completed live deployment. |
| Bootstrap script uses `OnExpiration` and `P1D` | **Fail** | Not verified against a completed live deployment. |
| Web app has system identity and no password or connection secret | **Fail** | Web app provisioning failed. |
| Web app is HTTPS-only with TLS 1.2+ | **Fail** | Web app provisioning failed. |
| Application Insights receives workspace-based telemetry | **Fail** | Application was not deployed, so live telemetry was not verified. |
| Every infrastructure module uses an exact version-pinned AVM | **Pass** | Static review found exact versions on all AVM declarations and no `latest` reference. |
| `GET /healthz` returns HTTP 200 | **Fail** | Not testable; redacted URL was unavailable. |
| `GET /readyz` returns HTTP 200 | **Fail** | Not testable; redacted URL was unavailable. |
| Infrastructure validation script passes | **Pass** | Completed with zero warnings. |
| .NET application build passes | **Pass** | Completed with zero warnings and zero errors. |

## Failure disposition

The failure is a global App Service naming collision, not an authentication or template-validation failure. App Service names must be globally unique. The approved CAF pattern produced a name already owned elsewhere, so the current environment values cannot create this web app.

Do not work around the failure by adopting an unapproved random suffix, enabling public SQL access, adding credentials, or making a portal-only change. Choose a distinct, lowercase workload token of 3–13 characters, update the parameter file, rerun local validation, Azure validation, and what-if, then obtain deployment approval again.
