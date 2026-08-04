#!/usr/bin/env bash
#
# Validates every Bicep template and parameter file in infra/.
# Used by all three hackathon tracks and by the infra-ci workflow.
#
# Exit codes: 0 = all good, 1 = a build, lint or warning failure.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
infra_dir="${repo_root}/infra"

if [[ ! -d "${infra_dir}" ]]; then
  echo "❌ No infra/ directory found at ${infra_dir}"
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "❌ Azure CLI not found. Install it: https://aka.ms/azure-cli"
  exit 1
fi

failures=0

echo "🔍 Building Bicep templates in ${infra_dir}"
while IFS= read -r -d '' template; do
  rel="${template#"${repo_root}/"}"
  printf '  • %s ... ' "${rel}"
  if output="$(az bicep build --file "${template}" --stdout 2>&1 >/dev/null)"; then
    if [[ -n "${output}" ]]; then
      echo "⚠️  warnings"
      echo "${output}" | sed 's/^/      /'
      failures=$((failures + 1))
    else
      echo "✅"
    fi
  else
    echo "❌"
    echo "${output}" | sed 's/^/      /'
    failures=$((failures + 1))
  fi
done < <(find "${infra_dir}" -name '*.bicep' -print0 | sort -z)

echo "🔍 Building Bicep parameter files"
while IFS= read -r -d '' params; do
  rel="${params#"${repo_root}/"}"
  printf '  • %s ... ' "${rel}"
  if output="$(az bicep build-params --file "${params}" --stdout 2>&1 >/dev/null)"; then
    if [[ -n "${output}" ]]; then
      echo "⚠️  warnings"
      echo "${output}" | sed 's/^/      /'
      failures=$((failures + 1))
    else
      echo "✅"
    fi
  else
    echo "❌"
    echo "${output}" | sed 's/^/      /'
    failures=$((failures + 1))
  fi
done < <(find "${infra_dir}" -name '*.bicepparam' -print0 | sort -z)

if [[ "${failures}" -gt 0 ]]; then
  echo
  echo "❌ ${failures} file(s) failed validation. Warnings count as failures — fix them."
  exit 1
fi

echo
echo "✅ All Bicep templates and parameter files build cleanly with no warnings."
