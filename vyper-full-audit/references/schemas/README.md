# Schema Pack (v3)

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
- `toolchain-context.schema.json`
- `tool-findings.schema.json`
- `tool-validation.schema.json`
- `external-control-map.schema.json`
- `rule-id-migration-map.schema.json`
- `source-lock.schema.json`

## Validation Policy

- Production-gate mode requires schema validation success for all canonical artifacts.
- Schema mismatch in required artifact blocks release.
- Markdown artifacts are render-only and are not canonical.
- Gate-facing artifacts must carry `warnings[]` end-to-end.
- Audit context must carry deterministic `language_feature_usage[]` when features are present.
- Schema rollouts are atomic: schema edits + sample artifacts + validation docs in one change set.
- `schema_pack_version` is required in all canonical `meta` objects.
- Gate-facing enums are normalized to `PASS|BLOCKED` for `prod_gate` and `assurance_checks`.
- `toolchain-context.schema.json` requires remediation fields for unavailable tools (`reason_code`, `install_hint`, `install_doc_ref`).
- `assurance-checks.schema.json` requires explicit `evidence_engines[]` provenance.
- `source-lock.schema.json` enforces pin quality (`IMMUTABLE|PLACEHOLDER`) and artifact hash manifests.
