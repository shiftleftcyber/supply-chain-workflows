# Compatibility and Deprecation Policy

## Supported references

Each compatible workflow-library release is marked with a semantic version tag. Production callers must resolve that
tag to a reviewed full commit SHA and use the SHA in `jobs.<job>.uses`. Mutable branches and major-version tags are not
supported production references.

## Contract changes

- Patch releases contain security fixes, dependency updates, and implementation fixes that do not intentionally alter
  workflow inputs, outputs, permissions, or documented behavior.
- Minor releases may add optional inputs, outputs, or workflows. Existing callers remain compatible.
- Major releases may remove or rename workflows, change required inputs, alter outputs, or require new permissions.

Changes that increase permissions, add a secret, widen a trust policy, or weaken a security gate are treated as major
contract changes even when the YAML interface is unchanged.

## Deprecation

A workflow or input is deprecated in documentation before removal. Deprecated contracts remain available for at least
one minor release and 90 days unless an active vulnerability requires faster removal. Security advisories override the
normal deprecation window.

## Caller updates

Dependabot should update the pinned workflow SHA in caller repositories. Callers must run all required CI checks before
accepting an update. Privileged workflows should first be exercised in a non-production environment when their
effective behavior, permissions, identity, or artifact format changes.

## Support boundaries

The workflow library validates its inputs and fails closed, but callers remain responsible for event triggers, branch
and tag protection, environment approvals, secret selection, cloud trust policy, and consuming immutable outputs.
