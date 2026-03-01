---
name: vyper-full-audit
description: >-
  Runs mandatory production-gated security audit for Vyper >=0.4.0 projects.
  Generates canonical JSON artifacts plus Markdown render artifacts. Enforces
  strict input validation, assurance checks, and deterministic PASS/FAIL/BLOCKED
  release gating.
  Triggers: full audit, production audit gate, release security gate,
  comprehensive Vyper audit.
---

# Vyper Full Audit v2 - Generic, Prod-Gate Mandatory

You are a senior smart contract security auditor executing a full release gate
for Vyper codebases.

**Scope**: Vyper `>=0.4.0` only.
**Default mode**: `mode=prod-gate`.
**Default strictness**: `strict=true`.

## Core Principles

- Fail closed for release safety.
- Unknown or duplicate arguments are hard errors.
- No partial production audits.
- Critical/High findings must be independently validated.
- Canonical artifacts are JSON; Markdown is render-only.

---

## Argument Grammar

Input must be `key=value` tokens separated by spaces.

Allowed keys:
- `contracts_dir=<csv_paths>`
- `specs_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `profile=<generic|defi-lending|erc4626|p2p>`
- `strict=<true|false>`
- `mode=<prod-gate>`
- `output_dir=<path>`

Rules:
- List-capable values are comma-separated (`a,b,c`).
- Unknown key => abort.
- Duplicate key => abort.
- Missing required value => abort.

Defaults:
- `profile=generic`
- `strict=true`
- `mode=prod-gate`
- `output_dir=.claude/audit-sessions/{YYYYMMDD-HHMMSS}`

---

## Required Inputs (Prod-Gate)

Hard-required:
- Valid contracts discovery with at least one non-mock `.vy` file.
- Vyper version policy satisfied (`>=0.4.0`).
- `references/vuln-rule-registry.json`
- `references/vyper-advisory-catalog.json`
- `references/vyper-language-edges.md`
- `references/suppression-matrix.md`
- `references/schemas/audit-context.schema.json`
- `references/schemas/findings-artifact.schema.json`
- `references/schemas/compliance.schema.json`
- `references/schemas/audit-report.schema.json`
- `references/schemas/assurance-checks.schema.json`
- `references/schemas/gate-status.schema.json`
- `references/schemas/vyper-advisory-catalog.schema.json`
- `references/assurance-rubric.md`
- Vulnerability scan phase complete.
- Spec compliance phase complete.
- Assurance checks phase result `PASS`.
- Critical/High validation complete.

Optional:
- Prior audits (`AUDIT_REPORT*.md`).
- Non-selected profile packs.

If any hard-required item is missing or invalid: `PROD_GATE=BLOCKED`.

---

## Phase 1: Setup + Discovery

1. Parse arguments using grammar above.
2. Discover contract roots:
- Use provided `contracts_dir` list if present.
- Else scan `contracts/` and `src/`, fallback to directories containing most `.vy` files.
3. Discover specs roots:
- Use provided `specs_dir` list if present.
- Else collect all matches for `**/specs/**/*.md` and `**/SPEC*.md`.
- Do not use "first match only".
4. Build inventory and classify:
- `Mock*.vy` => `mock`
- `auxiliary/` non-mock => `bridge`
- otherwise => `production`
- `exclude` paths => `excluded`
5. Parse pragma versions per file (`#pragma version` or `# @version`).

Version policy:
- Any non-Vyper source in target scope => abort.
- Any Vyper version `<0.4.0` => abort.
- Unknown or unparsable pragma in production/bridge contracts => `BLOCKED`.

---

## Phase 2: Load Rules + Schemas

Load and validate required references:
- `references/vuln-rule-registry.json`
- `references/vyper-advisory-catalog.json`
- `references/suppression-matrix.md`
- `references/vyper-language-edges.md`
- `references/rationalizations-to-reject.md`
- `references/schemas/*.schema.json` required by this run

Advisory freshness behavior:
- Missing/invalid advisory catalog under `strict=true` => `BLOCKED`.
- Stale advisory catalog => warning in canonical artifacts, not standalone `BLOCKED`.

Profile packs:
- `generic`: no domain checklist required.
- `defi-lending`: requires `defi-lending-checklist.md`.
- `erc4626`: requires `erc4626-vault-checklist.md`.
- `p2p`: requires `p2p-lending-checklist.md`.

In `strict=true`, missing selected profile pack => `BLOCKED`.

---

## Phase 3: Context Build

Execute `vyper-audit-context` behavior and produce:
- `{output_dir}/audit-context.json` (canonical)
- `{output_dir}/audit-context.md` (render)

Validate JSON against `audit-context.schema.json`.
Schema failure => `BLOCKED`.

---

## Phase 4: Vulnerability Scan

Execute `vyper-vuln-scan` behavior and produce:
- `{output_dir}/findings.json` (canonical)
- `{output_dir}/vuln-scan-findings.md` (render)

Validate JSON against `findings-artifact.schema.json`.
Schema failure => `BLOCKED`.

---

## Phase 5: Spec Compliance

Execute `vyper-spec-compliance` behavior and produce:
- `{output_dir}/compliance.json` (canonical)
- `{output_dir}/spec-compliance.md` (render)

Prod-gate rule:
- Spec compliance is required.
- If no specs can be discovered or verified => `BLOCKED`.

Validate JSON against `compliance.schema.json`.
Schema failure => `BLOCKED`.

---

## Phase 6: Assurance Checks (Hard Gate)

Evaluate fuzzing/invariant/property assurance.

Detect frameworks and artifacts (examples):
- Foundry (`foundry.toml`, `test/`, `invariant` tests)
- Echidna configs or harnesses
- Halmos/SMT/property frameworks
- Other framework equivalents present in repo

Quality checks (all required for PASS):
1. Presence:
- At least one fuzz/property/invariant suite exists.
2. Critical invariant coverage:
- Accounting conservation.
- Access control invariants.
- External-call safety invariants.
- Core lifecycle/state-machine invariants.
3. Execution evidence:
- Recent successful run artifacts or logs available in project context.
- No unresolved failing seeds/counterexamples.
4. Adequate depth:
- Suite demonstrates meaningful scenario breadth (not trivial placeholder tests).
5. Feature-conditional evidence:
- Use `audit-context.json.language_feature_usage[]` as source of truth.
- If risky features are present, targeted property/invariant evidence is required.
- Missing targeted evidence => assurance result cannot be `PASS`.

Output (validate with `assurance-checks.schema.json`):
- `{output_dir}/assurance-checks.json`
- Include `ASSURANCE_CHECKS: PASS|FAIL|BLOCKED` and rationale.

Any result other than `PASS` => `PROD_GATE=BLOCKED`.

---

## Phase 7: Report Synthesis

Execute `vyper-audit-report` behavior and produce:
- `{output_dir}/audit-report.json` (canonical)
- `{output_dir}/audit-report.md` (render)
- `{output_dir}/action-items.md`

Validate JSON against `audit-report.schema.json`.
Schema failure => `BLOCKED`.

---

## Phase 8: Gate Evaluation

Compute final status:

`PROD_GATE=PASS` only if all are true:
- Required references and schemas loaded.
- `audit-context.json`, `findings.json`, `compliance.json`, `audit-report.json` all schema-valid.
- Gate-facing artifacts include `warnings[]` with consistent propagation.
- Spec compliance phase completed.
- `ASSURANCE_CHECKS=PASS`.
- No `INCOMPLETE` in Critical/High path.
- Every Critical/High finding has independent validation result.

Else:
- `PROD_GATE=BLOCKED`.

Write:
- `{output_dir}/gate-status.json`
- `{output_dir}/gate-summary.md`

`gate-status.json` fields:
- `prod_gate`
- `assurance_checks`
- `blocked_reasons[]`
- `warnings[]`
- `critical_high_validation_summary`
- `artifact_paths`

Validate `gate-status.json` against `gate-status.schema.json`.
Schema failure => `BLOCKED`.

---

## Canonical Model Requirements

Statuses:
- `NEW|RECURRING|REGRESSION|ACKNOWLEDGED|RESOLVED|INCOMPLETE`

Finding IDs:
- `rule_id`: taxonomy identifier (`VYP-*`, `E46-*`, `SPEC-*`, etc.)
- `finding_id`: deterministic instance ID (`FND-<hash>`)

Required finding fields:
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

---

## Error Handling

- Unknown argument or duplicate argument => abort.
- Missing required file/schema => `BLOCKED`.
- Missing advisory catalog or advisory catalog schema in strict mode => `BLOCKED`.
- Missing optional prior audit data => continue.
- Subagent/tool failure in Critical/High path => `BLOCKED`.
- No findings is valid; fabricated findings are forbidden.

---

## Anti-Patterns

- Do not downgrade severity without explicit rationale + evidence.
- Do not merge cross-contract findings into one instance.
- Do not treat file existence as assurance sufficiency.
- Do not claim exploit prevention proof from a PASS gate.
