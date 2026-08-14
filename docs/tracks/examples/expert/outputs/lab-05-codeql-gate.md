# Example Output — Lab 5: CodeQL Gate Blocking the SQL Injection *(optional lab)*

What a correctly wired CodeQL gate looks like when it catches the deliberate SQL injection from
[the fault-and-vulnerability contract](../../../../concepts/fault-and-vulnerability.md).

## Code-scanning alert (example)

```text
Rule:              cs/sql-injection
CWE:                CWE-89
Security severity:  8.8 (Critical)
State:               open
File:                src/ContosoTicketing/Endpoints/TicketsEndpoints.cs:42
Message:             This query depends on a user-provided value, which is not sanitized.
```

## Gate check output (the `gh api` query from the lab)

```bash
gh api repos/{owner}/{repo}/code-scanning/alerts --jq \
  '[.[] | select(.state=="open" and (.rule.security_severity_level|IN("high","critical")))] | length'
```

```text
1
```

A non-zero count should fail the workflow step, for example:

```text
Run gh api repos/.../code-scanning/alerts --jq '...'
1
##[error]Process completed with exit code 1.
Error: found 1 open High/Critical CodeQL alert(s); failing the build.
```

## Pull request checks (example)

```text
❌ infra-ci / build-and-lint          — required
❌ app-ci / codeql-gate               — required, failing (1 High/Critical alert)
✅ app-ci / dependency-review         — required
```

## After Copilot's fix

Re-running the same `gh api` query against the branch with the parameterised query restored:

```text
0
```

```text
✅ app-ci / codeql-gate — passing
```

✅ Checkpoint met when: your PR shows the same failing → passing transition, with the alert
referencing `CWE-89` at `security-severity ≥ 7.0` before the fix, and zero open High/Critical
alerts after Copilot's PR merges.
