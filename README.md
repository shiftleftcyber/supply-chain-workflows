# ShiftLeftCyber Supply Chain Workflows

Reusable GitHub Actions workflows for building, attesting, signing, and verifying ShiftLeftCyber software.

The workflows are intentionally opinionated. They centralize security-sensitive build behavior without accepting
arbitrary shell commands or inheriting all caller secrets.

## Workflows

| Workflow | Purpose |
|---|---|
| `build-container-gar.yml` | Build and push an OCI image to Google Artifact Registry, generate SLSA build provenance, and optionally sign it with Cosign. |
| `verify-container.yml` | Verify GitHub build provenance and an optional Cosign keyless signature for a digest-qualified OCI image. |
| `release-go.yml` | Build and publish a tagged Go release with GoReleaser, then attest the published checksums. |
| `sbom-lifecycle.yml` | Generate source and container CycloneDX SBOMs, sign and verify them with SecureSBOM, and publish them as a workflow artifact. |
| `terraform-validate.yml` | Run formatting, initialization without a backend, and validation over an explicit directory matrix. |
| `go-lint.yml` | Run pinned Go linting against a module. |
| `shellcheck.yml` | Run pinned ShellCheck analysis against a selected directory. |

See [`docs/usage.md`](docs/usage.md) for caller examples and [`docs/threat-model.md`](docs/threat-model.md) for the
security model and known limitations.

## Versioning

Callers should pin reusable workflows to a full commit SHA:

```yaml
jobs:
  build:
    permissions:
      attestations: write
      contents: read
      id-token: write
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/build-container-gar.yml@FULL_COMMIT_SHA
```

Release tags provide human-readable milestones, but commit SHAs are the supported production reference.

## Security principles

- Build and provenance generation happen in the same reviewed reusable workflow.
- External actions are pinned to full commit SHAs.
- Cloud authentication uses GitHub OIDC and Google Workload Identity Federation.
- Workflows request job-level least-privilege permissions.
- Callers pass named inputs and secrets; `secrets: inherit` is not required.
- Published and deployed images are identified by immutable digest.
- Inputs used by shell commands are validated before use.
- Failures stop the workflow; security controls do not silently fall back.

## Private repositories

GitHub artifact attestations for private or internal repositories require a GitHub plan that supports them. Confirm
organization entitlement before adopting provenance generation in private repositories.

## Contributing

Workflow changes affect every repository that adopts them. Pull requests must include:

1. A security-impact description.
2. Validation with `actionlint` and `shellcheck`.
3. A clean, blocking Zizmor security scan.
4. Review of permissions, input validation, action pinning, and secret exposure.
5. A versioned release after merge when callers should adopt the change.
