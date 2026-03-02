---
name: vyper-audit-report
description: >-
  JSON-first report synthesizer for Vyper >=0.4.0 audits. Merges canonical
  findings, compliance, and toolchain summaries with deterministic gate status
  and standards coverage sections.
  Triggers: audit report, findings synthesis, release security report.
---

# Vyper Audit Report v3

You produce release-quality reports from canonical artifacts.

## Inputs

Accepted args (`key=value`):
- `findings=<path>`
- `compliance=<path>`
- `audit_context=<path>`
- `tool_findings=<path>`
- `tool_validation=<path>`
- `gate_status=<path>`
- `output_dir=<path>`
- `strict=<true|false>`

Rules:
- Unknown key => abort.
- Duplicate key => abort.

Defaults:
- `strict=true`
- `findings={output_dir}/findings.json`
- `compliance={output_dir}/compliance.json`
- `audit_context={output_dir}/audit-context.json`
- `tool_findings={output_dir}/tool-findings.json`
- `tool_validation={output_dir}/tool-validation.json`
- `gate_status={output_dir}/gate-status.json`

## Required References

- `references/schemas/finding.schema.json`
- `references/schemas/audit-report.schema.json`
- `references/schemas/tool-findings.schema.json`
- `references/schemas/tool-validation.schema.json`
- `references/rule-id-migration-map.json`
- `references/report-template.md`
- `references/rationalizations-to-reject.md`

Strict mode: missing required references => abort.

## Phase 1: Load Canonical Inputs

Required:
- `findings.json`
- `compliance.json`

Optional but preferred:
- `audit-context.json`
- `tool-findings.json`
- `tool-validation.json`
- `gate-status.json`

Validation:
- Validate every loaded JSON against schema.
- Schema failure in required input => abort.

Warning propagation:
- Preserve upstream `warnings[]` from all loaded artifacts.

## Phase 2: Normalize Core Findings

Normalize into canonical finding objects with required fields:
- `finding_id`
- `rule_id`
- `severity`
- `status`
- `contract`
- `function`
- `span`
- `confidence`
- `evidence`
- `recommendation`
- `source`

Canonical statuses only:
- `NEW|RECURRING|REGRESSION|ACKNOWLEDGED|RESOLVED|INCOMPLETE`

## Phase 3: Merge + Dedup

Merge vulnerability + compliance findings.

Dedup key:
- `(rule_id, contract, function, normalized_sink_or_state_target, span)`

Rules:
- Never dedup across different contracts.
- Preserve cross-contract recurrence in systemic section.
- Keep traceability metadata.

## Phase 4: Delta Analysis with Migration Support

Delta match order:
1. Exact canonical `rule_id` + location overlap.
2. Alias mapping from `rule-id-migration-map.json`.
3. Location overlap + similarity fallback.

No prior findings:
- Current findings default `NEW`.

## Phase 5: Severity Calibration + Validation

Calibration sequence:
1. Cross-contract systemic amplification (reporting only).
2. Hot-path sensitivity adjustments.
3. Edge-case caps with rationale.
4. Mock caps (informational only).
5. Documented-risk handling (`ACKNOWLEDGED` without silent downgrade).

Critical/High findings:
- Require independent validation record.
- `UNVERIFIED` in C/H path => `INCOMPLETE`.

## Phase 6: Tool and Standards Summaries

Do not merge tool findings into canonical `findings[]`.
Use summary-only policy:
- `tool_coverage_summary` from `tool-findings.json` + `tool-validation.json`
- `standards_coverage_summary` from `compliance.json` and `gate-status.json`

`WARN` semantics:
- Non-blocking in summaries unless explicit blocker code exists in gate status.
- Treat Mythril/Echidna adapter limitations as warning context unless explicit blocker status exists.

## Phase 7: Output

Write canonical:
- `{output_dir}/audit-report.json`

Write render:
- `{output_dir}/audit-report.md`
- `{output_dir}/action-items.md`

Validate `audit-report.json` against schema.
Schema failure => abort.

Required report sections:
- executive summary
- warnings summary
- severity distribution
- findings by severity
- systemic patterns
- feature risk summary
- delta analysis
- spec coverage
- tool coverage summary
- standards coverage summary
- compiler version assessment
- action items
- critical/high validation summary

## Error Handling

- Missing required input => abort.
- Invalid status/ID taxonomy in required input => abort in strict mode.
- Missing optional tool artifacts => emit neutral summary object, not error.

## Anti-Patterns

- Do not inject tool findings directly into canonical findings array.
- Do not bypass C/H validation.
- Do not treat WARN as BLOCKED without explicit blocker status.
