# ShiftLeftCyber Supply Chain Workflows

Reusable GitHub Actions workflows for building, attesting, signing, and verifying ShiftLeftCyber software.

The workflows are intentionally opinionated. They centralize security-sensitive build behavior without accepting
arbitrary shell commands or inheriting all caller secrets.

## Workflows

| Workflow | Purpose |
|---|---|
| `build-container-gar.yml` | Build and push an OCI image to Google Artifact Registry, generate SLSA build provenance, and optionally sign it with Cosign. |
| `build-container-registry.yml` | Build, attest, and sign an image for GHCR or another token-authenticated OCI registry. |
| `container-sbom.yml` | Generate, sign, and verify an SBOM for a digest-qualified container image. |
| `go-ci.yml` | Format, vet, test, build, and optionally smoke-test a Go container. |
| `verify-container.yml` | Verify GitHub build provenance and an optional Cosign keyless signature for a digest-qualified OCI image. |
| `release-go.yml` | Build and publish a tagged Go release, attest its checksums, optionally attach evidence, and update its major tag. |
| `release-github-action.yml` | Publish a GitHub Action release and optionally update its major compatibility tag. |
| `sbom-lifecycle.yml` | Generate source and container CycloneDX SBOMs, sign and verify them with SecureSBOM, and publish them as a workflow artifact. |
| `source-sbom-go.yml` | Generate, sign, verify, and vulnerability-scan a Go source SBOM without requiring a container registry. |
| `source-sbom-node.yml` | Generate, sign, and verify a Node source SBOM. |
| `publish-sbom-interlynk.yml` | Publish one named signed SBOM artifact to Interlynk. |
| `publish-sbom-sbomify.yml` | Publish one named signed SBOM artifact to Sbomify. |
| `rearm.yml` | Generate, sign, and publish evidence through ReARM. |
| `terraform-validate.yml` | Run formatting, initialization without a backend, and validation over an explicit directory matrix. |
| `node-ci.yml` | Install, lint, test, and build a Node project with controlled package-manager behavior. |
| `go-lint.yml` | Run pinned Go linting against a module. |
| `security-go.yml` | Run govulncheck, dependency review, and CodeQL for a Go module. |
| `shellcheck.yml` | Run pinned ShellCheck analysis against a selected directory. |
| `validate-actions.yml` | Run the standard Actionlint and Zizmor policy against a caller repository. |

See [`docs/usage.md`](docs/usage.md) for caller examples and [`docs/threat-model.md`](docs/threat-model.md) for the
security model and known limitations.

Workflow contracts and removal timelines are documented in [`docs/compatibility.md`](docs/compatibility.md). Not every
workflow applies to every repository; compose the smallest set needed rather than enabling optional integrations by
default.

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
