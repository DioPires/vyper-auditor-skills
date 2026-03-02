#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

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
  ln -sf "$REPO_DIR/$skill" "$SKILLS_DIR/$skill"
  echo "  Linked $skill"
done

echo "Installed 9 skills to $SKILLS_DIR/"
echo "External tools (slither/titanoboa/foundry/mythril/echidna) are not auto-installed."
echo "See vyper-full-audit/references/tool-installation.md for deterministic setup."
