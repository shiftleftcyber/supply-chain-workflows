# Usage

Always replace `FULL_COMMIT_SHA` with a reviewed commit from this repository. The calling workflow must grant every
permission requested by the called workflow; permissions cannot be elevated through a reusable workflow.

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
    permissions:
      attestations: write
      contents: write
      id-token: write
    uses: shiftleftcyber/supply-chain-workflows/.github/workflows/release-go.yml@FULL_COMMIT_SHA
    with:
      go-version-file: api/go.mod
      working-directory: api
      config: .goreleaser.yaml
```

The caller must protect release tags and require human review. The workflow currently publishes through GoReleaser and
then creates provenance from its checksum manifest. Consumers must verify that provenance before trusting downloaded
artifacts.
