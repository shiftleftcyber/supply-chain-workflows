# Compatibility and Deprecation Policy

## Supported references

The moving `v1` tag is the managed compatibility channel. Automation moves it to the current `main` commit only after
the complete shared-workflow validation run succeeds. Callers may use `@v1` to receive compatible fixes without
consumer pull requests, or pin a reviewed full commit SHA when immutable consumer-side review is required. Mutable
branch references such as `@main` are not supported.

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

Callers using full commit SHAs should use Dependabot to propose updates and must run all required CI checks before
accepting them. Callers using `v1` receive changes after this repository's validation succeeds, without a caller-side
pull request. Privileged workflows should first be exercised in a non-production environment when their effective
behavior, permissions, identity, or artifact format changes.

## Support boundaries

The workflow library validates its inputs and fails closed, but callers remain responsible for event triggers, branch
and tag protection, environment approvals, secret selection, cloud trust policy, and consuming immutable outputs.
