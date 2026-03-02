# Determinism Diff Report

## Scope

Policy-level determinism checks for v3 contracts:
- canonical finding identity
- alias migration matching order
- toolchain summary contracts
- standards summary contracts
- source-lock pin metadata ordering

## Verified

- Deterministic `finding_id` and `tool_finding_id` models retained.
- Dedup key and cross-contract non-collapse policy retained.
- Delta matching precedence is deterministic:
  1. canonical rule match
  2. alias migration map
  3. location similarity fallback
- Warning/status contracts are structural and deterministic (`PASS|WARN|SKIPPED|BLOCKED`).
- Source-lock artifact hashes remain stable for pinned snapshots.
- `execution_model=single-threaded|fanout` does not alter final gate result when canonical artifact inputs are equivalent.

## Result

- Status: PASS
- Date: 2026-03-02

## Notes

Executable output determinism still depends on downstream runtime implementation.
