---
name: vyper-spec-compliance
description: >-
  Generic Vyper >=0.4.0 specification compliance verifier. Extracts normative
  requirements from multiple spec roots, maps them to code with evidence, and
  emits canonical JSON + Markdown outputs for release gating.
  Triggers: spec compliance, requirements verification, spec audit.
---

# Vyper Spec Compliance v2

You verify implementation-vs-spec correctness for Vyper projects.

**Scope**: Vyper `>=0.4.0` only.

## Inputs

Accepted args (`key=value`):
- `contracts_dir=<csv_paths>`
- `specs_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `strict=<true|false>`
- `output_dir=<path>`

Rules:
- Unknown key => abort.
- Duplicate key => abort.

Defaults:
- `strict=true`

## Required References

Hard-required:
- `references/schemas/requirement.schema.json`
- `references/schemas/compliance.schema.json`

If strict mode and required references are missing => abort.

---

## Phase 1: Discovery

1. Resolve contract roots from arg or auto-detect.
2. Resolve spec roots:
- Use explicit `specs_dir` list when provided.
- Otherwise collect all matching roots from `**/specs/**/*.md` and `**/SPEC*.md`.
- Never choose only first match.
3. Build contract inventory and apply exclude rules.
4. Parse Vyper pragma versions for production/bridge contracts.

Strict behavior:
- If no specs found => abort.
- If contracts missing/unreadable in production scope => abort.

---

## Phase 2: Requirement Extraction

Extract requirements from each spec file with priority:
1. Explicit requirement IDs (`REQ-*`, `R-*`, `SPEC-*`, etc.)
2. RFC2119 (`MUST`, `SHALL`, `SHOULD`, `MAY` and negatives)
3. Requirement-scoped bullets under requirement-like headings
4. Fallback heading units if no stronger signal

For each requirement create:
- `rule_id` (existing ID or generated `SPEC-{file}-{n}`)
- `text`
- `source_file`
- `normative_level` (`MUST|SHALL|SHOULD|MAY|UNSPECIFIED`)
- `severity_hint`

Validate each requirement object against schema.

---

## Phase 3: Mapping

Map requirements to code using layered strategy:
1. Exact identifier/function/variable matches
2. Interface and event name matches
3. Conceptual matches (state transitions, constraints, invariants)
4. Numeric/range constraint matches

For each requirement:
- `mapped_contracts[]`
- `mapped_functions[]`
- `evidence_spans[]`
- `mapping_confidence`

`UNMAPPED` requirements are retained as explicit records.

---

## Phase 4: Verification

For each mapped requirement determine:
- `PASS|FAIL|PARTIAL|UNVERIFIED`

Verification dimensions:
- Signature/API behavior
- Access control
- State transitions and ordering
- Event correctness
- Numeric constraints and bounds
- Failure-path behavior and revert semantics

Cross-contract invariants to always check:
- Accounting conservation
- Access-control consistency
- External-call boundary consistency
- State-machine/lifecycle consistency

No hardcoded project contract names.
Contract grouping must be discovery-driven.

---

## Phase 5: Coverage + Output

Write canonical output:
- `{output_dir}/compliance.json`

Write render output:
- `{output_dir}/spec-compliance.md`

`compliance.json` sections:
- metadata
- requirement registry
- mapping registry
- verification results
- invariant checks
- coverage metrics
- unmapped/unverified scope

Validate against `compliance.schema.json`.
Schema failure => abort.

---

## Prod-Gate Behavior

When called by full-audit prod-gate:
- Compliance phase is mandatory.
- Any requirement marked `UNVERIFIED` in critical paths or any extraction/mapping failure in required scope => `INCOMPLETE` outcome for phase.
- `INCOMPLETE` in required scope blocks release.

---

## Error Handling

- Missing specs => abort.
- Malformed spec file => mark file failed; if strict mode => abort.
- Mapping ambiguity => keep requirement and mark `UNVERIFIED` with rationale.
- No requirements extracted from a file => warn; if all files yield zero requirements => abort.

---

## Anti-Patterns

- Do not assume narrative specs are non-normative without analysis.
- Do not ignore unmapped requirements.
- Do not treat keyword presence alone as proof of compliance.

