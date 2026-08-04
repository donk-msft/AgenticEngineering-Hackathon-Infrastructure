# Security Finding Handover

## Finding

- Source: `<GHAS / Defender for Cloud / dependency review>`
- Severity: `<critical / high / medium / low>`
- Status: `<true positive / false positive / needs investigation>`
- Affected source area: `<app / infra / workflow / docs>`

## Risk

`<sanitized risk summary>`

## Required action

`<minimum safe remediation>`

## Guardrails

- [ ] Do not introduce secrets or credential-based SQL access.
- [ ] Do not make SQL publicly reachable.
- [ ] Do not disable GHAS, Defender, telemetry or branch protection.
- [ ] Keep app SQL access parameterized.
- [ ] Preserve required tags and AVM version pins.

## Validation

- [ ] Relevant scan rerun or finding state checked.
- [ ] `./scripts/validate-infra.sh` if infrastructure changed.
- [ ] `dotnet build src/ContosoTicketing` if application code changed.

## Redaction confirmation

- [ ] No credentials, subscription ids, tenant ids, resource ids, host names, IP addresses or personal account names are present.
