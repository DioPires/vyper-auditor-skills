# Determinism Diff Report

## Scope

Policy-level determinism checks for repository contracts that define deterministic behavior.

## Verified

- Deterministic `finding_id` contract retained (`FND-<hash>` model).
- Dedup key and cross-contract non-collapse policy retained.
- No new non-deterministic identifiers introduced in schemas.
- Warning propagation fields are structural and deterministic (`warnings[]` arrays).

## Result

- Status: PASS
- Date: 2026-03-01

## Notes

Executable output determinism still depends on downstream runtime implementation of these skills.

## Contract Evidence

- `vyper-vuln-scan/SKILL.md`: deterministic `finding_id` definition unchanged.
- `vyper-vuln-scan/SKILL.md`: dedup key unchanged.
- `vyper-full-audit/SKILL.md`: canonical artifact validation and gate rules deterministic.

```bash
rg -n 'finding_id|Dedup key|identical repo snapshot' \\
  vyper-vuln-scan/SKILL.md vyper-audit-context/SKILL.md
```
