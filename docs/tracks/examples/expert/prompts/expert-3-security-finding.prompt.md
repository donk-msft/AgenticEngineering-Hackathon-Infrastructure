---
mode: agent
description: Triage a GHAS or Defender finding and route it back into implementation.
---

## Inputs

- `docs/concepts/workload.md`
- `docs/concepts/fault-and-vulnerability.md`
- `docs/remediation-plan.md`

## Task

Acting as `@security-finding-reviewer`, review the security finding and write a sanitized triage artifact.

## Expected output

- `docs/security-finding-triage.md`
- `docs/remediation-results.md` when an approved source change is required

## Done when

- The finding is classified as true positive, false positive or needs investigation.
- The responsible fix area is identified.
- The triage does not include secrets, resource ids, tenant ids, subscription ids or live URLs.
- Approved source changes are handed to `@implementer-from-handover` and validated before completion.
