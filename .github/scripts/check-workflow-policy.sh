#!/usr/bin/env bash
set -euo pipefail

failed=false

while IFS= read -r workflow; do
  while IFS= read -r use_line; do
    reference="${use_line#*uses:}"
    reference="${reference%%#*}"
    reference="${reference//\"/}"
    reference="${reference//\'/}"
    reference="${reference//[[:space:]]/}"

    if [[ "${reference}" == ./* ]]; then
      continue
    fi
    if [[ ! "${reference}" =~ @([a-f0-9]{40})$ ]]; then
      echo "Unpinned external action in ${workflow}: ${reference}"
      failed=true
    fi
  done < <(grep -E '^[[:space:]]*(-[[:space:]]*)?uses:' "${workflow}" || true)
done < <(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) -print)

if grep -R -n -E 'secrets:[[:space:]]*inherit|permissions:[[:space:]]*(read-all|write-all)' .github/workflows; then
  echo "Forbidden broad secret or permission configuration found."
  failed=true
fi

if [[ "${failed}" == "true" ]]; then
  exit 1
fi

echo "Workflow policy checks passed."
