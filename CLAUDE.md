# vyper-auditor-skills

Generic Vyper `>=0.4.0` smart contract audit skills with mandatory production
gating.

## Structure

- 9 skills in separate directories, each with `SKILL.md`
- Shared references in `vyper-full-audit/references/` (others symlink)
- Canonical schemas in `vyper-full-audit/references/schemas/`
- `install.sh` creates symlinks in `~/.claude/skills/`

## Development Rules

- Canonical source of truth: JSON artifacts validated by schemas
- Markdown artifacts are render outputs only
- Full audit defaults to mandatory `prod-gate`
- All behavior targets Vyper `>=0.4.0`
- Validate changes with representative projects and gate outcomes (`PASS`/`BLOCKED`)

## Naming Conventions

- Mock contracts: `Mock*.vy` or test paths (`/mock`, `/test`)
- Bridge contracts: non-mock files in `auxiliary/`
- Finding identity: `rule_id` + deterministic `finding_id`
