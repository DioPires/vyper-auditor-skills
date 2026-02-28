#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

for skill in vyper-full-audit vyper-vuln-scan vyper-spec-compliance vyper-audit-context vyper-audit-report; do
  ln -sf "$REPO_DIR/$skill" "$SKILLS_DIR/$skill"
  echo "  Linked $skill"
done

echo "Installed 5 skills to $SKILLS_DIR/"
