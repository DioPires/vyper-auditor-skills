---
name: vyper-spec-compliance
description: >-
  Generic Vyper >=0.4.0 specification compliance verifier. Extracts normative
  requirements, maps evidence, and emits canonical JSON with standards coverage
  summaries for deterministic production gating.
  Triggers: spec compliance, requirements verification, spec audit.
---

# Vyper Spec Compliance v3

You verify implementation-vs-spec correctness for Vyper projects.

**Scope**: Vyper `>=0.4.0` only.

## Inputs

Accepted args (`key=value`):
- `contracts_dir=<csv_paths>`
- `specs_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `profile=<generic|defi-lending|erc4626|p2p|full-evm|evm-amm|evm-lending|evm-nft|evm-staking|evm-cross-chain|evm-oracle|evm-token-integration|evm-runtime|evm-randomness>`
- `standards_enforcement=<shadow|enforced>`
- `strict=<true|false>`
- `output_dir=<path>`

Rules:
- Unknown key => abort.
- Duplicate key => abort.

Defaults:
- `profile=generic`
- `standards_enforcement=enforced`
- If `profile=full-evm` and `standards_enforcement` omitted => `shadow`
- rollout note: `full-evm` defaults to `shadow` for release R1.
- `strict=true`

## Required References

Hard-required:
- `references/schemas/requirement.schema.json`
- `references/schemas/compliance.schema.json`

If strict mode and required references missing => abort.

## Phase 1: Discovery

1. Resolve contract roots from arg or auto-detect.
2. Resolve spec roots:
- Use `specs_dir` when provided.
- Otherwise collect all matches from `**/specs/**/*.md` and `**/SPEC*.md`.
3. Build inventory and exclusions.
4. Parse Vyper pragmas.

Strict behavior:
- No specs => abort.
- Missing/unreadable production contracts => abort.
- Non-Vyper source in target scope => abort.

## Phase 2: Requirement Extraction

Extract requirements with priority:
1. explicit requirement IDs
2. RFC2119 language
3. requirement-scoped bullets
4. fallback heading units

Per requirement:
- `rule_id`
- `text`
- `source_file`
- `normative_level`
- `severity_hint`

Validate objects against requirement schema.

## Phase 3: Mapping

Map requirements to code using:
1. exact identifiers
2. interface/event names
3. conceptual state/invariant matches
4. numeric constraint matches

Record mapping confidence and evidence spans.

## Phase 4: Verification

Status per requirement:
- `PASS|FAIL|PARTIAL|UNVERIFIED|UNMAPPED`

Verification dimensions:
- API behavior
- access control
- state transitions
- event correctness
- numeric constraints
- failure-path behavior

Cross-contract invariants:
- accounting conservation
- access-control consistency
- external-call boundary consistency
- lifecycle/state-machine consistency

## Phase 5: Standards Coverage Summary

Emit required `standards_coverage_summary` object with:
- `standards_enforcement`
- `profile`
- `applies`
- `status`
- `required_packs`
- `available_packs`
- `missing_packs`
- `control_counts`

Policy:
- `shadow`: failures produce `WARN`, not standalone block.
- `enforced`: missing required selected packs or critical coverage failures may be `BLOCKED`.
- Only codified canonical controls can produce blocking standards outcomes.
- Advisory-only checklist controls remain non-blocking and must still appear in report/action items.

## Phase 6: Output

Write canonical:
- `{output_dir}/compliance.json`

Write render:
- `{output_dir}/spec-compliance.md`

`compliance.json` sections:
- metadata (`meta.schema_pack_version` required)
- requirement registry
- mapping registry
- verification results
- invariant checks
- coverage metrics
- standards coverage summary

Validate against `compliance.schema.json`.
Schema failure => abort.

## Prod-Gate Behavior

When called by full-audit prod-gate:
- Compliance phase is mandatory.
- `INCOMPLETE` in required scope blocks release.
- Standards summary contributes to gate via `standards_gate_status`.

## Error Handling

- Missing specs => abort.
- Malformed spec file => fail file; strict mode abort.
- Mapping ambiguity => keep requirement as `UNVERIFIED` with rationale.
- Zero extracted requirements across all files => abort.

## Anti-Patterns

- Do not ignore unmapped requirements.
- Do not treat keyword presence as proof of compliance.
- Do not treat `shadow` warnings as blocks.
