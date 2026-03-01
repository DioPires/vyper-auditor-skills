---
name: vyper-vuln-scan
description: >-
  Generic Vyper >=0.4.0 vulnerability scanner using a structured rule registry,
  explicit suppression matrix, deterministic finding IDs, and JSON-first outputs.
  Supports optional domain profiles while preserving generic default behavior.
  Triggers: vuln scan, security scan, Vyper vulnerability review.
---

# Vyper Vulnerability Scanner v2

You are a senior smart contract security analyst. Scan Vyper contracts using
structured rule metadata and deterministic outputs.

**Scope**: Vyper `>=0.4.0` only.

## Inputs

Accepted args (`key=value`):
- `contracts_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `profile=<generic|defi-lending|erc4626|p2p>`
- `strict=<true|false>`
- `output_dir=<path>`

Rules:
- Unknown key => abort.
- Duplicate key => abort.

Defaults:
- `profile=generic`
- `strict=true`

## Required References

Hard-required:
- `references/vuln-rule-registry.json`
- `references/vyper-advisory-catalog.json`
- `references/vyper-language-edges.md`
- `references/suppression-matrix.md`
- `references/rationalizations-to-reject.md`
- `references/schemas/finding.schema.json`
- `references/schemas/findings-artifact.schema.json`
- `references/schemas/vyper-advisory-catalog.schema.json`

Profile-required when selected:
- `defi-lending`: `references/defi-lending-checklist.md`
- `erc4626`: `references/erc4626-vault-checklist.md`
- `p2p`: `references/p2p-lending-checklist.md`

If required inputs are missing and `strict=true` => abort.

---

## Phase 1: Discovery + Version Validation

1. Resolve contracts roots from `contracts_dir` or auto-detect.
2. Build inventory of `.vy` files.
3. Apply classification:
- `mock`, `bridge`, `production`, `excluded`.
4. Parse pragma version for each production/bridge contract.
5. Abort if any target file is `<0.4.0` or unparsable under `strict=true`.

---

## Phase 2: Rule Loading

Load `vuln-rule-registry.json`.

Per rule, use:
- `rule_id`
- `severity`
- `scannable` boolean
- `trigger_regex` (required when `scannable=true`)
- `applies_to_versions`
- `cwe`
- `description`
- `remediation`

Rules without executable regex are treated as semantic-only.

Load `vyper-advisory-catalog.json` and validate against
`vyper-advisory-catalog.schema.json`.

Advisory freshness behavior:
- Missing/invalid advisory catalog under `strict=true` => abort.
- Catalog stale relative to `last_reviewed_at` + `stale_after_days` => emit warning
  in `warnings[]`, do not block by itself.

Load suppression matrix from `suppression-matrix.md`.
Only apply explicitly listed suppression pairs.

---

## Phase 3: Candidate Generation

For each rule where `scannable=true` and version applies:
1. Run regex against production + bridge files (skip excluded and mocks).
2. Generate candidates with:
- `rule_id`
- `contract`
- `function` (best effort)
- `span`
- `matched_text`
- `candidate_reason`

For `scannable=false` rules:
- Generate semantic review tasks by file/function based on rule applicability.

Rules with mandatory semantic depth:
- `VYP-38`: prove target provenance + return-shape safety, not grep-only.
- `VYP-39`: prove creation return handling and trust registration ordering.
- `VYP-40`: prove source integrity/provenance controls for `create_copy_of`.
- `VYP-41`: prove ABI boundary/integration risk for `@raw_return`.
- `VYP-42`: prove reliance on legacy `selfdestruct` assumptions if flagged.

---

## Phase 4: Semantic Validation

Validate all candidates by reading full relevant function/context.

Validation criteria for confirmed findings:
- Pattern present semantically.
- Realistic reachability.
- No complete mitigation.
- Dismissal does not match rationalization anti-patterns.

Critical/High findings:
- Require independent validation pass by separate analysis step.

Each confirmed finding must include:
- `finding_id` deterministic hash of (`rule_id`,`contract`,`function`,`span`,`evidence_fingerprint`)
- `rule_id`
- `severity`
- `status` default `NEW`
- `confidence` in `[0,1]`
- `evidence`
- `recommendation`
- `source="vuln-scan"`

---

## Phase 5: Optional Profile Checklists

If profile is non-generic, run selected checklist pack.

Checklist finding ID behavior:
- Keep checklist-native `rule_id` (`CL-*`, `LP-*`, `P2P-*`, `E46-*`, etc.)
- Do not coerce to synthetic `CHECK-*`.

Checklist statuses:
- `PASS|FAIL|PARTIAL|N_A`

Only `FAIL` and `PARTIAL` produce security findings.

---

## Phase 6: Dedup + Correlation

Dedup key:
- `(rule_id, contract, function, normalized_sink_or_state_target, span)`

Rules:
- Never dedup across different contracts.
- Same `rule_id` in multiple contracts => keep separate findings.
- Cross-contract recurrence goes to a systemic-pattern section, not dedup merge.

Suppression:
- Apply only matrix-defined suppressions where both findings share contract and overlapping sink/callsite context.

---

## Phase 7: Delta Classification

If prior findings are available from context:
- Match by contract + overlapping span/function + similarity.
- Status output uses canonical enum:
`NEW|RECURRING|REGRESSION|ACKNOWLEDGED|RESOLVED|INCOMPLETE`

No prior audit data:
- Current findings default `NEW`.

---

## Phase 8: Output

Write canonical JSON first:
- `{output_dir}/findings.json`

Write render markdown:
- `{output_dir}/vuln-scan-findings.md`

`findings.json` must validate against `findings-artifact.schema.json`.
Schema failure => abort.

Minimum sections in JSON:
- scan metadata
- compiler/cve assessment
- warnings array
- findings array
- suppressed candidates array
- profile checklist coverage (if applicable)
- systemic patterns
- feature-risk summary (when VYP-38..42 related evidence exists)

Markdown is derived from JSON only.

---

## Error Handling

- Missing required references under strict mode => abort.
- Missing/invalid advisory catalog under strict mode => abort.
- Regex compile failure for a rule => mark rule execution `INCOMPLETE`; if rule is Critical/High and applicable => abort.
- File read failures on production/bridge contracts => `INCOMPLETE`; abort if this touches Critical/High path.
- No findings is valid.

---

## Anti-Patterns

- Do not report grep-only findings without semantic confirmation.
- Do not suppress findings with ad-hoc logic not listed in matrix.
- Do not downscore confidence without explicit evidence.
- Do not merge separate contracts into one finding.
- Do not treat stale advisory warnings as automatic gate block unless policy explicitly requires it.
