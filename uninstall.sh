#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"

for skill in \
  vyper-full-audit \
  vyper-vuln-scan \
  vyper-spec-compliance \
  vyper-audit-context \
  vyper-audit-report \
  vyper-slither-scan \
  vyper-mythril-scan \
  vyper-echidna-evidence \
  vyper-tool-findings-normalizer; do
  rm -f "$SKILLS_DIR/$skill"
  echo "  Removed $skill"
done

echo "Uninstalled 9 skills from $SKILLS_DIR/"
echo "External tool binaries were not modified."
