# Toolchain Determinism Diff Report

## Result

- Status: PASS
- Date: 2026-03-02

## Verified

- Deterministic `tool_finding_id` and normalized severity mapping.
- Deterministic missing-tool reason-code generation.
- Stable ordering for `requested_tools`, `executed_tools`, and `missing_tools`.
- Expected diffs limited to timestamp fields.
