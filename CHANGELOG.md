# Changelog

All notable changes to the reusable workflow contracts are documented here.

The project follows semantic versioning for workflow contract releases. Callers may use the validated moving major tag
or pin a selected release to its full commit SHA.

## Unreleased

- Separate registry-attached BuildKit SLSA provenance from optional GitHub Artifact Attestations so private
  repositories without Enterprise Cloud can retain provenance and Cosign verification.
- Require OSV inputs to be unsigned CycloneDX documents and update OSV Scanner to v2.7.0 for CycloneDX 1.7 support.
- Replace broad reusable-workflow permission boundaries with the exact union of their jobs' required scopes.
- Add a validated moving `v1` compatibility tag for callers that opt into centrally managed workflow updates.
- Allow Go releases to attach one validated evidence artifact and update the validated major compatibility tag after
  release publication and provenance generation succeed.

### Added

- Reusable Go and Node CI workflows.
- Reusable Go security, Actionlint, and Zizmor workflows.
- Separate Go source, Node source, and container SBOM workflows.
- Narrow Interlynk and Sbomify publication workflows.
- A standardized ReARM evidence workflow.
- A registry-neutral container build, provenance, and signing workflow.
- A GitHub Action release workflow with optional major compatibility tag management.
- CODEOWNERS and blocking workflow policy validation.
