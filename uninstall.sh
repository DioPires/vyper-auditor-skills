#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"

for skill in vyper-full-audit vyper-vuln-scan vyper-spec-compliance vyper-audit-context vyper-audit-report; do
  rm -f "$SKILLS_DIR/$skill"
  echo "  Removed $skill"
done

echo "Uninstalled 5 skills from $SKILLS_DIR/"
