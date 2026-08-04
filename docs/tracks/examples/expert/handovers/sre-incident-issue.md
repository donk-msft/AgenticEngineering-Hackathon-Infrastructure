# SRE Incident Handover Issue

## Summary

`<one-sentence sanitized incident summary>`

## Signal

- Source: `<Azure SRE Agent / alert / drift check>`
- Type: `<reliability / drift / deployment health>`
- Approval state: `<approved for Copilot / needs human review>`

## Impact

- User impact: `<sanitized impact>`
- Affected route or capability: `<healthz / readyz / api/tickets / deployment>`

## Evidence

- Symptom: `<sanitized symptom>`
- Time window: `<relative time window>`
- Suspected area: `<networking / database / webapp / monitoring / app code>`
- Redacted references: `<placeholder links or artifact paths>`

## Acceptance criteria affected

- [ ] `<criterion from docs/concepts/workload.md>`

## Requested Copilot task

`<minimum source change requested>`

## Validation required

- [ ] `./scripts/validate-infra.sh`
- [ ] `dotnet build src/ContosoTicketing`
- [ ] `<live acceptance check with redacted target>`

## Redaction confirmation

- [ ] No credentials, subscription ids, tenant ids, resource ids, host names, IP addresses or personal account names are present.
