# Operations Feedback Loop Skill

Use this skill when expert-track reliability or security findings become work for Copilot.

## Response principles

- Day-2 signals become day-1 source changes whenever possible.
- Do not fix drift manually unless the lab explicitly asks you to inject or observe it.
- Every remediation must name the source file or workflow that should change.
- Every remediation must name validation commands and expected evidence.

## Redaction policy

Before committing or sharing handovers, remove:

- credentials, tokens, keys and client secrets
- subscription ids and tenant ids
- resource ids and live URLs
- personal account names
- host names and IP addresses unless explicitly approved for the lab

## Safety policy

Never propose or accept remediations that:

- enable public SQL access
- replace managed identity with passwords
- remove required tags
- disable telemetry
- weaken TLS, HTTPS or FTPS settings
- remove deny-all NSG rules
- disable GHAS, Defender or branch protections to make a finding disappear
