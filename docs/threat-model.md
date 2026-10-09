# Threat Model

## Scope

This repository supplies reusable GitHub Actions workflows to other ShiftLeftCyber repositories. A compromise can
affect every caller that updates to the compromised commit, making this repository part of the organization's trusted
build platform.

## Assets

- Integrity of software artifacts, container images, SBOMs, signatures, and provenance.
- GitHub OIDC identities and short-lived cloud credentials.
- Repository and environment secrets explicitly supplied by callers.
- Release, registry, and artifact metadata.
- Trust in the identity of the shared builder workflow.

## Trust boundaries

1. The caller repository and its workflow configuration.
2. The reusable workflow at an exact pinned commit or the validated moving major compatibility tag.
3. GitHub-hosted runners and GitHub's OIDC/attestation services.
4. Google Workload Identity Federation and Artifact Registry.
5. External actions and downloaded tools pinned by version and digest.
6. SecureSBOM and Sigstore services used for signing or verification.
7. Token-authenticated OCI registries used by the registry-neutral container workflow.
8. Interlynk, Sbomify, and ReARM endpoints that receive explicitly selected evidence.
9. npm and PyPI packages installed by the Node SBOM and Interlynk publishing workflows.

## STRIDE analysis

| Threat | Example | Mitigation |
|---|---|---|
| Spoofing | An attacker publishes from an unexpected workflow or repository. | Verify the GitHub attestation signer workflow and Cosign certificate identity; use protected refs and environments. |
| Tampering | A mutable tag is replaced after verification. | Build, attest, sign, return, and deploy digest-qualified image references. |
| Repudiation | A release cannot be tied to a workflow invocation. | Generate signed provenance containing repository, commit, event, and workflow identity. |
| Information disclosure | A cloud credential or API key appears in logs or artifacts. | Use OIDC, named secrets, minimal output, and no environment dumps or inherited secrets. |
| Denial of service | Unbounded builds or invalid paths consume runner capacity. | Validate inputs, set timeouts, constrain paths, and rely on caller concurrency policies. |
| Elevation of privilege | Pull-request code gains a write token or cloud credential. | Privileged workflows must be called only from trusted refs; job-level permissions and cloud trust policies enforce this independently. |
| Supply-chain compromise | A build tool, package, or action is replaced upstream. | Pin actions and images immutably, pin tool versions, centralize review, and fail when reviewed source tags resolve unexpectedly. |
| Confused deputy | A caller publishes the wrong artifact or targets an attacker-controlled service. | Validate artifact names, identifiers, HTTPS endpoints, image digests, and registry ownership before privileged operations. |

Workflow changes are statically analyzed by both `actionlint` and Zizmor. Zizmor runs in blocking console mode with
the regular persona, online audits, and no severity suppression. Any reported actionable finding fails the pull-request
check.

Reusable workflow permissions can only be maintained or reduced across the caller and callee chain. Workflows that
upload SARIF declare `security-events: write` at the reusable-workflow boundary, then explicitly remove it from jobs
that do not upload results. Callers must grant the same scope; GitHub rejects an attempted elevation before jobs start.
Every reusable workflow boundary therefore declares only the union of its jobs' required scopes. Broad declarations
such as `read-all` are prohibited because they force least-privilege callers to grant unrelated repository access.

The Go release workflow accepts only a validated artifact name and a single basename when attaching evidence produced
earlier in the same workflow run. It rejects paths and empty files, uploads only after GoReleaser and provenance
generation succeed, and moves a validated major tag only after all release evidence has been published.

Source SBOM workflows accept only enumerated component and generator types. ReARM's `custom` generator remains
available for backward compatibility and executes only on trusted, non-pull-request events; callers should select a
native generator such as `go` when available to avoid repository-defined build containers and stale toolchains.

The OSV scanner consumes one validated JSON basename from a named workflow artifact. It scans a byte-identical copy
named `bom.json` to satisfy OSV v2's CycloneDX filename detection, verifies that copy before use, and publishes the
report as a separate artifact so scanning policy is not coupled to SBOM production. The pinned scanner container has a
read-only root filesystem, read-only SBOM input, and write access only to its report directory. OSV queries necessarily
disclose package coordinates from the SBOM to the OSV service.

## Known limitations

- A reusable workflow cannot compensate for a caller that grants credentials to untrusted triggers.
- SLSA provenance proves how an artifact was produced; it does not prove the artifact is vulnerability-free or suitable
  for deployment.
- An SBOM signature proves signed-content integrity and signing-key association; it does not prove SBOM completeness or
  factual correctness.
- GitHub artifact attestations for private repositories depend on organization plan availability.
- Callers pinned to an older commit do not automatically receive fixes. Automated update pull requests and prompt
  security advisories are required.
- Callers using the moving `v1` tag trust every compatible change merged to this repository after its validation suite
  passes. A repository or maintainer compromise can therefore affect those callers without a consumer-side review.
  High-assurance or independently governed callers should use full commit SHAs instead.
- The Interlynk client currently installs its pinned source tree's Python requirements without a lock file containing
  hashes. That workflow should be enabled only when Interlynk publication is required, and the dependency set must be
  reviewed whenever the pinned client commit changes.
- The Node SBOM workflow installs an exact cdxgen version from npm. Registry compromise remains a residual risk until a
  reviewed digest-pinned distribution is available.
- The Go security workflow permits Go's authenticated automatic toolchain selection only while compiling the pinned
  govulncheck version. Scanning continues with the caller module's declared Go toolchain.
- The Go security workflow permits callers to explicitly disable govulncheck for a documented, temporary risk
  acceptance. It remains enabled by default, and disabling it does not disable dependency review or CodeQL.
- Token-authenticated registries do not provide OIDC federation in every configuration. Callers must provide a scoped,
  short-lived token when the registry supports one and must never expose the token to pull-request jobs.

## Secure failure

Signing, attestation, and verification errors are terminal. Optional features are disabled only through explicit boolean
inputs. No workflow converts a failed security control into a successful result.
