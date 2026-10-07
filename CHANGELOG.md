# Changelog

All notable changes to the reusable workflow contracts are documented here.

The project follows semantic versioning for workflow contract releases. Callers must still pin the selected release
to its full commit SHA.

## Unreleased

- Replace broad reusable-workflow permission boundaries with the exact union of their jobs' required scopes.
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
