# Track Example Assets

These folders contain sanitized example assets for teams that get stuck while building the Contoso Ticketing workload.

Use them as reference patterns, not as files to copy over your own work. They deliberately avoid subscription ids, tenant ids, account names, resource ids, host names and other environment-specific values.

Some files also exist under `.github/` because GitHub, Copilot and GitHub Actions only discover
instructions, prompts and workflows from there. Treat those `.github/` files as active automation or
training material, not as duplicate examples; this folder is the participant-safe place to browse
examples.

| Track | Example folder | What to inspect |
|---|---|---|
| Beginner | [`beginner/`](beginner/) | A seven-step agent, prompt, skill and handover pipeline |
| Intermediate | [`intermediate/`](intermediate/) | A reduced `/plan` + `/fleet` workflow with review gates |
| Expert | [`expert/`](expert/) | Day-2 reliability and security handovers back into implementation |

Before using any example against a real environment, replace placeholders through parameter files or interactive prompts and re-run the validation commands in the relevant track guide.
