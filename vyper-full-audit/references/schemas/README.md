# Schema Pack (v2)

Canonical JSON artifacts must validate against these schemas.

## Schemas

- `vuln-rule.schema.json`
- `checklist-item.schema.json`
- `requirement.schema.json`
- `finding.schema.json`
- `delta.schema.json`
- `audit-context.schema.json`
- `findings-artifact.schema.json`
- `compliance.schema.json`
- `audit-report.schema.json`
- `assurance-checks.schema.json`
- `gate-status.schema.json`
- `vyper-advisory-catalog.schema.json`

## Validation Policy

- Production-gate mode requires schema validation success for all canonical artifacts.
- Schema mismatch in required artifact blocks release.
- Markdown artifacts are render-only and are not canonical.
- Gate-facing artifacts must carry `warnings[]` end-to-end.
- Audit context must carry deterministic `language_feature_usage[]` when features are present.
