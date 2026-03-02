# External Controls Validation (v3)

Validation artifacts for profile-scoped external controls and standards gating.

## Required Checks

1. Source trust tier policy enforcement.
2. Mapping integrity (`external-control-map.json`).
3. Alias migration stability (`rule-id-migration-map.json`).
4. Shadow vs enforced behavior correctness.
5. Deterministic outputs for standards summaries.
6. Executable fixture coverage:
- 2 positive + 2 negative per codified rule.
- 1 cross-contract dedup + 1 alias-migration scenario per family.
7. Source-lock integrity scenarios:
- placeholder pin block in strict/prod-gate
- source-name identity mismatch block

## Rollout Lock

- Tier2 families remain non-blocking in this release until codification gate promotion.

## Sample Gate Artifacts

- `sample-gate-status-full-evm-shadow.json`
- `sample-gate-status-full-evm-enforced-blocked.json`

## Fixture Assets

- Fixture inputs live under `fixtures/`.
- Referenced synthetic Vyper contracts live under `contracts/fixtures/`.
