# Expert Lab Output Examples

Written, sanitized examples of what a **correctly implemented** step should produce, so you can
validate your own output against a known-good shape instead of guessing. Every file below is
referenced from its lab; none of these are meant to be copy-pasted verbatim — they use placeholders
for anything environment-specific (resource names, ids, timestamps).

| File | Validates the step in |
|---|---|
| [`lab-01-ci-what-if-job.md`](lab-01-ci-what-if-job.md) | [Lab 1, §3 — CI on every pull request](../../../../expert/lab-01-lifecycle.md#3-ci-on-every-pull-request-25-min) |
| [`lab-02-drift-detection.md`](lab-02-drift-detection.md) | [Lab 2, §2 — Drift detection with what-if](../../../../expert/lab-02-desired-state.md#2-drift-detection-with-what-if-15-min) |
| [`lab-03-sre-agent-onboarding.md`](lab-03-sre-agent-onboarding.md) | [Lab 3 — Onboard the Azure SRE Agent](../../../../expert/lab-03-sre-agent.md) |
| [`lab-05-codeql-gate.md`](lab-05-codeql-gate.md) *(optional lab)* | [Lab 5, §3 — Fail the build on high severity](../../../../expert/lab-05-ghas.md#3-fail-the-build-on-high-severity-10-min) |
| [`lab-06-defender-connector.md`](lab-06-defender-connector.md) *(optional lab)* | [Lab 6, §2–3 — GitHub connector and posture](../../../../expert/lab-06-defender.md#2-connect-github-to-defender-for-cloud-15-min) |
| [`lab-07-feedback-loops.md`](lab-07-feedback-loops.md) | [Lab 7, §1 — Map every signal](../../../../expert/lab-07-close-the-loop.md#1-map-every-signal-15-min) |

Lab 4's example is the existing sanitized handover at
[`../handovers/sre-incident-issue.md`](../handovers/sre-incident-issue.md) — it already shows the
expected shape of an incident → Copilot handover, so it is not duplicated here.
