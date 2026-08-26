---
agent: tester
description: Validate the implemented infrastructure and application build.
---

## Inputs

- `infra/`
- `src/ContosoTicketing/`
- `docs/concepts/workload.md`

## Task

Acting as `@tester`, run the existing validation commands and write sanitized results.

## Expected output

- `docs/test-results.md`

## Done when

- `./scripts/validate-infra.sh` and `dotnet build src/ContosoTicketing` have pass/fail entries.
- Live checks that require deployment are clearly marked pending.
- Results contain no subscription ids, tenant ids, host names or secrets.
