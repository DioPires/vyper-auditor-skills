# Schema Validation Report

## Checks

1. JSON syntax validation for all schema files.
2. JSON syntax validation for canonical reference JSON files.
3. Required contract fields presence checks:
- `warnings[]` in gate-facing schemas.
- `schema_pack_version` in canonical `meta` objects.
- `tool_findings_summary`, `tool_coverage_summary`, `toolchain_status`, `standards_gate_status` contracts.
- tool remediation fields in `toolchain-context.schema.json`.
- source-lock pin integrity fields (`pin_quality`, `artifacts[]`).
- assurance evidence provenance field `evidence_engines[]` in `assurance-checks.schema.json`.

## Result

- Status: PASS
- Date: 2026-03-02
- JSON schema files parsed: PASS

## Contract Evidence

Validated contracts:
- `findings-artifact.schema.json` requires `tool_findings_summary`.
- `audit-report.schema.json` requires `tool_coverage_summary` and `standards_coverage_summary`.
- `gate-status.schema.json` requires `toolchain_status`, `standards_gate_status`, and `critical_high_validation_summary`.
- `compliance.schema.json` requires `standards_coverage_summary`.
- `assurance-checks.schema.json` includes canonical `meta` with `schema_pack_version` and requires `evidence_engines`.
- all canonical `meta` contracts require `schema_pack_version`.
