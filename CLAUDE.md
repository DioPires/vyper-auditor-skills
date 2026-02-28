# vyper-defi-audit

Vyper 0.4.x smart contract audit skills for Claude Code.

## Structure

- 5 skills in separate directories, each with SKILL.md
- Shared references in `vyper-full-audit/references/` (other skills symlink to it)
- `install.sh` creates symlinks to `~/.claude/skills/`

## Development

- Reference files are the source of truth for patterns, checklists, and edges
- SKILL.md files must stay under 500 lines — delegate to reference files
- All VYP patterns target Vyper >= 0.4.0 only
- Test changes by running `/vyper-vuln-scan` or `/vyper-full-audit` against a Vyper project

## Naming Conventions

- Mock contracts: `Mock*.vy` prefix (excluded from production audit)
- Bridge contracts: non-Mock files in `auxiliary/` (included in production audit)
