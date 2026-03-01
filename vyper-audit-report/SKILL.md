---
name: vyper-audit-report
description: >-
  JSON-first report synthesizer for Vyper >=0.4.0 audits. Merges vulnerability
  findings and spec compliance outputs, performs delta + calibration +
  validation, and emits canonical audit report artifacts.
  Triggers: audit report, findings synthesis, release security report.
---

# Vyper Audit Report v2

You produce release-quality reports from canonical artifacts.

## Inputs

Accepted args (`key=value`):
- `findings=<path>`
- `compliance=<path>`
- `audit_context=<path>`
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

## Required References

- `references/schemas/finding.schema.json`
- `references/schemas/audit-report.schema.json`
- `references/report-template.md`
- `references/rationalizations-to-reject.md`

Strict mode: missing required references => abort.

---

## Phase 1: Load Canonical Inputs

Required for prod-grade synthesis:
- `findings.json`
- `compliance.json`

Optional:
- `audit-context.json` (prior finding correlation)

If both required inputs are missing => abort.

Validate loaded inputs against their schemas.
Schema failure => abort.

Warning propagation rule:
- `warnings[]` from upstream artifacts must be preserved in `audit-report.json`.

---

## Phase 2: Normalize

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

Do not introduce ad-hoc statuses.

---

## Phase 3: Merge + Dedup

Merge vulnerability + compliance findings.

Dedup key:
- `(rule_id, contract, function, normalized_sink_or_state_target, span)`

Rules:
- Never dedup across different contracts.
- Preserve cross-contract recurrence and report it in systemic section.
- If merged from multiple sources, keep traceability metadata.

---

## Phase 4: Delta Analysis

If prior findings available:
- classify current findings as `NEW|RECURRING|REGRESSION|ACKNOWLEDGED`
- classify historical unmatched findings as `RESOLVED`

No prior findings:
- current findings remain `NEW`.

---

## Phase 5: Severity Calibration

Apply deterministic calibration sequence:
1. Cross-contract systemic amplification (reporting layer only, no merge).
2. Hot-path sensitivity adjustments.
3. Edge-case caps with explicit rationale.
4. Mock caps (informational only).
5. Documented-risk handling (`ACKNOWLEDGED` without silent downgrade).

Any downgrade/dismissal must pass rationalization counter-check.

---

## Phase 6: Critical/High Validation

Each Critical/High finding must have independent validation record:
- `CONFIRMED|REJECTED|UNVERIFIED`
- rationale
- evidence span

`UNVERIFIED` in Critical/High path => finding status `INCOMPLETE`.

---

## Phase 7: Output

Write canonical:
- `{output_dir}/audit-report.json`

Write render outputs:
- `{output_dir}/audit-report.md`
- `{output_dir}/action-items.md`

Validate canonical report against `audit-report.schema.json`.
Schema failure => abort.

Required report sections:
- executive summary
- warnings summary
- severity distribution
- findings by severity
- systemic patterns
- feature risk summary
- trust assumptions
- delta analysis
- spec coverage
- compiler version assessment
- action items
- validation summary for Critical/High

---

## Error Handling

- Missing required canonical input => abort.
- Invalid status/ID taxonomy in upstream data => abort in strict mode.
- Validation subprocess failure for Critical/High => mark `INCOMPLETE`.
- No findings is valid if inputs support that outcome.

---

## Anti-Patterns

- Do not invent evidence.
- Do not bypass Critical/High validation.
- Do not remap taxonomy IDs to incompatible synthetic IDs.
