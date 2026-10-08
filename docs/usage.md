# Usage

Use `v1` for centrally managed, backward-compatible updates, or replace `FULL_COMMIT_SHA` with a reviewed commit when
the caller requires an immutable reference and consumer-side review for every update. The calling workflow must grant
every permission requested by the called workflow; permissions cannot be elevated through a reusable workflow.

## Validate caller workflows

```yaml
jobs:
  actions-policy:
    permissions:
      contents: read
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/validate-actions.yml@FULL_COMMIT_SHA
```

This checks workflow syntax and security posture and rejects mutable external action references, `write-all`, and
`secrets: inherit`.

## Test a Go module

```yaml
jobs:
  go-ci:
    permissions:
      contents: read
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/go-ci.yml@FULL_COMMIT_SHA
    with:
      working-directory: api
      go-version-file: api/go.mod
      goexperiment: jsonv2

  go-security:
    permissions:
      contents: read
      security-events: write
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/security-go.yml@FULL_COMMIT_SHA
    with:
      working-directory: api
      go-version-file: api/go.mod
```

## Generate a source-only Go SBOM

```yaml
jobs:
  source-sbom:
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v')
    permissions:
      contents: read
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/source-sbom-go.yml@FULL_COMMIT_SHA
    with:
      component-type: library
      file-prefix: example-${{ github.sha }}
      secure-sbom-signing-key-id: ${{ vars.SECURE_SBOM_SIGNING_KEY_ID }}
    secrets:
      secure-sbom-api-key: ${{ secrets.SECURE_SBOM_API_KEY }}
```

Publication should be a separate dependent job that receives the exact artifact and only the destination-specific
secret. Do not pass all repository secrets to an SBOM workflow.

Set `component-type: library` for a Go module that does not contain a `main` package. The default `application` mode
retains the executable-oriented behavior used by existing callers.

## Scan an SBOM with OSV Scanner

Keep vulnerability policy separate from SBOM generation by passing the generated artifact to the scanner workflow:

```yaml
jobs:
  source-sbom:
    permissions:
      contents: read
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/source-sbom-go.yml@FULL_COMMIT_SHA
    with:
      component-type: library
      file-prefix: example-${{ github.sha }}
      secure-sbom-signing-key-id: ${{ vars.SECURE_SBOM_SIGNING_KEY_ID }}
    secrets:
      secure-sbom-api-key: ${{ secrets.SECURE_SBOM_API_KEY }}

  osv-scan:
    needs: source-sbom
    permissions:
      actions: read
      contents: read
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/scan-sbom-osv.yml@FULL_COMMIT_SHA
    with:
      artifact-name: ${{ needs.source-sbom.outputs.artifact-name }}
      sbom-file: ${{ needs.source-sbom.outputs.signed-sbom-file }}
```

The scanner makes a byte-identical temporary copy named `bom.json` because OSV Scanner v2 detects CycloneDX input by
filename. It verifies the copy before scanning and uploads only the scan report as a separate artifact.

## Build, attest, and sign a GAR image

```yaml
name: Release container

on:
  push:
    branches: [main]
    tags: ['v*.*.*']

permissions: read-all

jobs:
  container:
    permissions:
      attestations: write
      contents: read
      id-token: write
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/build-container-gar.yml@FULL_COMMIT_SHA
    with:
      registry: northamerica-northeast2-docker.pkg.dev
      image-name: example-project/images/example-api
      tags: |
        northamerica-northeast2-docker.pkg.dev/example-project/images/example-api:main-${{ github.sha }}
      context: api
      dockerfile: api/Dockerfile
      workload-identity-provider: projects/123456789/locations/global/workloadIdentityPools/github/providers/github
      service-account: github-builder@example-project.iam.gserviceaccount.com
```

The Google trust policy should constrain the repository, organization, ref, and reusable workflow identity. Do not use
one unrestricted service account across the organization.

## Verify before deployment

```yaml
jobs:
  verify:
    permissions:
      contents: read
      id-token: write
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/verify-container.yml@FULL_COMMIT_SHA
    with:
      image-ref: ${{ needs.container.outputs.image-ref }}
      attestation-repository: shiftleftcyber/example-api
      signer-workflow: shiftleftcyber/supply-chain-workflows/.github/workflows/build-container-gar.yml
      registry: northamerica-northeast2-docker.pkg.dev
      workload-identity-provider: projects/123456789/locations/global/workloadIdentityPools/github/providers/github
      service-account: github-reader@example-project.iam.gserviceaccount.com
      certificate-identity-regexp: '^https://github.com/shiftleftcyber/example-api/.github/workflows/release.yml@refs/(heads/main|tags/v.*)$'
```

Make deployment depend on this job and consume only its already verified digest-qualified image reference.

## Generate and protect SBOMs

```yaml
jobs:
  sbom:
    permissions:
      contents: read
      id-token: write
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/sbom-lifecycle.yml@FULL_COMMIT_SHA
    with:
      source-directory: api
      go-version-file: api/go.mod
      goexperiment: jsonv2
      image-ref: ${{ needs.container.outputs.image-ref }}
      registry: northamerica-northeast2-docker.pkg.dev
      workload-identity-provider: projects/123456789/locations/global/workloadIdentityPools/github/providers/github
      service-account: github-reader@example-project.iam.gserviceaccount.com
      secure-sbom-signing-key-id: ${{ vars.SECURE_SBOM_SIGNING_KEY_ID }}
      file-prefix: example-api-${{ github.sha }}
    secrets:
      secure-sbom-api-key: ${{ secrets.SECURE_SBOM_API_KEY }}
```

Vendor publication to Interlynk, Sbomify, or another destination belongs in a separate caller-controlled job. It should
download the signed workflow artifact and receive only the secret required by that destination.

## Validate Terraform

```yaml
jobs:
  terraform:
    permissions:
      contents: read
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/terraform-validate.yml@FULL_COMMIT_SHA
    with:
      terraform-version: 1.11.4
      directories-json: '["terraform/envs/qa", "terraform/envs/prod", "terraform/modules/api"]'
```

This workflow never initializes a backend or receives cloud credentials.

## Lint Go and shell code

```yaml
jobs:
  go-lint:
    permissions:
      contents: read
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/go-lint.yml@FULL_COMMIT_SHA
    with:
      working-directory: api
      go-version-file: api/go.mod

  shellcheck:
    permissions:
      contents: read
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/shellcheck.yml@FULL_COMMIT_SHA
    with:
      scan-directory: api
      severity: warning
```

Repository-specific code generation must happen in a separate local job. These lint workflows intentionally do not
accept arbitrary setup commands.

## Publish a Go release

```yaml
jobs:
  release:
    if: startsWith(github.ref, 'refs/tags/v')
    needs: source-sbom
    permissions:
      attestations: write
      contents: write
      id-token: write
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/release-go.yml@FULL_COMMIT_SHA
    with:
      go-version-file: api/go.mod
      working-directory: api
      config: .goreleaser.yaml
      evidence-artifact-name: ${{ needs.source-sbom.outputs.artifact-name }}
      evidence-file: ${{ needs.source-sbom.outputs.signed-sbom-file }}
      update-major-tag: true
```

The caller must protect release tags and require human review. The workflow currently publishes through GoReleaser and
then creates provenance from its checksum manifest. Optional evidence must be a single named file from a workflow
artifact produced earlier in the same run. The major compatibility tag moves only after the release, provenance, and
optional evidence upload succeed. Consumers must verify provenance before trusting downloaded artifacts.
