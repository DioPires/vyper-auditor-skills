---
name: vyper-audit-context
description: >-
  Generic Vyper >=0.4.0 context builder. Produces deterministic inventory,
  trust boundaries, call graph, state mutation map, and prior-finding context in
  canonical JSON plus Markdown render output.
  Triggers: audit context, trust boundary map, contract inventory.
---

# Vyper Audit Context v2

You produce deterministic context artifacts used by scan/compliance/report phases.

## Inputs

Accepted args (`key=value`):
- `contracts_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `output_dir=<path>`
- `strict=<true|false>`

Rules:
- Unknown key => abort.
- Duplicate key => abort.

Defaults:
- `strict=true`

## Required References

- `references/schemas/audit-context.schema.json`

Missing required schema under strict mode => abort.

---

## Phase 1: Contract Inventory

1. Discover contract roots from args or auto-detect.
2. Enumerate `.vy` files.
3. Apply classification:
- `mock`: filename starts `Mock` OR path contains `/mock` or `/test` markers.
- `bridge`: path includes `auxiliary/` and not mock.
- `production`: remaining non-excluded contracts.
- `excluded`: any excluded path.
4. Parse pragma version for each production/bridge contract.

Strict behavior:
- If no production or bridge contracts => abort.
- Unparsable pragma in production/bridge => abort.

---

## Phase 2: Trust Boundaries

Identify principals and trust domains by explicit authorization logic:
- Owner/Admin
- Guardian/Emergency
- Role-based operators
- External protocol dependencies
- Permissionless users

Important:
- Do not infer owner/admin boundaries from `@nonreentrant` usage.

Per contract capture:
- authorized principals by function
- privilege-critical functions
- trust assumptions
- compromise blast radius notes

---

## Phase 3: External Interaction Map

Detect and classify:
- `extcall`
- `staticcall`
- `raw_call`
- `send(`

Per call record:
- source contract/function/span
- target address provenance (immutable, storage, parameter, computed)
- call kind
- value transfer presence
- return-handling behavior
- risk flags

---

## Phase 4: State Mutation Map

For production/bridge contracts:
- enumerate state variables
- map readers/writers by function
- classify critical state (accounting, auth, config, lifecycle)
- record potential CEI/order hazards with precise spans

---

## Phase 5: Language Feature Usage Map

Extract deterministic feature usage entries for:
- `skip_contract_check`
- `raw_create`
- `create_copy_of`
- `create_minimal_proxy_to`
- `create_from_blueprint`
- `@raw_return`
- `selfdestruct`

For each entry record:
- contract/function/span
- feature
- provenance (`source|imported-interface|inferred-callgraph`)
- notes (brief risk context)

This map is canonical input for feature-conditional assurance checks.

---

## Phase 6: Prior Findings Context

Find prior reports (`AUDIT_REPORT*.md`) and extract normalized prior findings:
- `rule_id` (if available)
- `contract/function/span`
- `severity`
- `status`
- `description`

If none exist:
- keep empty prior set; this is valid.

---

## Output

Write canonical:
- `{output_dir}/audit-context.json`

Write render:
- `{output_dir}/audit-context.md`

Validate JSON against `audit-context.schema.json`.
Schema failure => abort.
`meta.schema_pack_version` is required.

Determinism requirement:
- identical repo snapshot + args => identical canonical output except timestamps.

---

## Error Handling

- Contract discovery failure => abort.
- Read failure in production/bridge scope => abort in strict mode.
- Missing prior reports => continue.
- Malformed prior report => skip that file, record parse warning.

---

## Anti-Patterns

- Do not infer trust from naming only.
- Do not silently drop unreadable production files.
- Do not mix profile-specific assumptions into generic context.
