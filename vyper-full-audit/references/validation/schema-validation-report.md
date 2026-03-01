# Schema Validation Report

## Checks

1. JSON syntax validation for all schema files.
2. JSON syntax validation for `vuln-rule-registry.json` and `vyper-advisory-catalog.json`.
3. Required contract fields presence checks:
- `warnings[]` in gate-facing schemas.
- `language_feature_usage[]` in audit-context schema.

## Result

- Status: PASS
- Date: 2026-03-01
- JSON files parsed: 15/15

## Command Evidence

```bash
python3 - <<'PY'
... json.loads() over schema and reference JSON files ...
PY
# output: PASS 15
```

```bash
rg -n '"warnings"|language_feature_usage|feature_risk_summary|vyper-advisory-catalog' ...
```

Validated contracts:
- `warnings[]` required in findings/report/gate schemas.
- `language_feature_usage[]` required in audit-context schema.
- advisory catalog schema present and parse-valid.

```bash
python3 - <<'PY'
... assert required+properties contain warnings/language_feature_usage fields ...
PY
# findings-artifact.schema.json PASS
# audit-report.schema.json PASS
# gate-status.schema.json PASS
# audit-context.schema.json PASS
```
