# AGENTS.md - Shared Workflow Security Rules

These instructions extend the ShiftLeftCyber security coding rules.

## Mandatory rules

- Read `docs/threat-model.md` before changing a reusable workflow.
- Pin every external action to a full commit SHA and retain a version comment.
- Use explicit job-level permissions. Never use `write-all`.
- Do not use `secrets: inherit` in examples or workflow design.
- Do not accept arbitrary shell commands as workflow inputs.
- Validate every input before using it in a shell command, path, image reference, or release operation.
- Keep builds and provenance generation in the same trusted reusable workflow.
- Require digest-qualified image references for verification.
- Use OIDC federation instead of long-lived cloud service-account keys.
- Never run privileged publishing or signing jobs for pull requests from untrusted forks.
- Fail closed when signing, provenance generation, scanning, or verification fails.

## Required verification

Before presenting or committing workflow changes:

1. Run `actionlint` over `.github/workflows`.
2. Run `shellcheck` over shell scripts and extracted workflow shell blocks when supported.
3. Review all `permissions` blocks.
4. Confirm external actions remain pinned to full commit SHAs.
5. Confirm no secret or sensitive value is written to logs, artifacts, caches, or summaries.

