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
2. The reusable workflow at the exact pinned commit.
3. GitHub-hosted runners and GitHub's OIDC/attestation services.
4. Google Workload Identity Federation and Artifact Registry.
5. External actions and downloaded tools pinned by version and digest.
6. SecureSBOM and Sigstore services used for signing or verification.

## STRIDE analysis

| Threat | Example | Mitigation |
|---|---|---|
| Spoofing | An attacker publishes from an unexpected workflow or repository. | Verify the GitHub attestation signer workflow and Cosign certificate identity; use protected refs and environments. |
| Tampering | A mutable tag is replaced after verification. | Build, attest, sign, return, and deploy digest-qualified image references. |
| Repudiation | A release cannot be tied to a workflow invocation. | Generate signed provenance containing repository, commit, event, and workflow identity. |
| Information disclosure | A cloud credential or API key appears in logs or artifacts. | Use OIDC, named secrets, minimal output, and no environment dumps or inherited secrets. |
| Denial of service | Unbounded builds or invalid paths consume runner capacity. | Validate inputs, set timeouts, constrain paths, and rely on caller concurrency policies. |
| Elevation of privilege | Pull-request code gains a write token or cloud credential. | Privileged workflows must be called only from trusted refs; job-level permissions and cloud trust policies enforce this independently. |

## Known limitations

- A reusable workflow cannot compensate for a caller that grants credentials to untrusted triggers.
- SLSA provenance proves how an artifact was produced; it does not prove the artifact is vulnerability-free or suitable
  for deployment.
- An SBOM signature proves signed-content integrity and signing-key association; it does not prove SBOM completeness or
  factual correctness.
- GitHub artifact attestations for private repositories depend on organization plan availability.
- Callers pinned to an older commit do not automatically receive fixes. Automated update pull requests and prompt
  security advisories are required.

## Secure failure

Signing, attestation, and verification errors are terminal. Optional features are disabled only through explicit boolean
inputs. No workflow converts a failed security control into a successful result.

