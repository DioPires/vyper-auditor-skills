# Assurance Rubric (Prod-Gate)

This rubric defines when `ASSURANCE_CHECKS` is `PASS|FAIL|BLOCKED`.

## Required Dimensions

1. Suite Presence
- At least one fuzz/property/invariant suite exists.

2. Critical Invariant Coverage
- Accounting conservation covered.
- Access control safety covered.
- External-call safety covered.
- Core lifecycle/state-machine covered.

3. Execution Evidence
- Evidence of recent execution available.
- No unresolved failing seeds/counterexamples.

4. Non-triviality
- Suites are meaningful, not placeholder tests.

5. Feature-Conditional Evidence (mandatory when feature exists)
- Features are discovered from `audit-context.json.language_feature_usage[]`.
- If a feature is present, at least one targeted property/invariant must exist and have execution evidence.

Required mapping:
- `skip_contract_check` -> target provenance + return-shape safety properties.
- `raw_create`, `create_copy_of`, `create_minimal_proxy_to`, `create_from_blueprint` -> creation-failure handling and non-zero/code-presence invariants.
- `raw_return` -> ABI compatibility and caller-decoding properties.
- `selfdestruct` -> lifecycle safety properties proving no critical logic relies on legacy full-delete assumptions.

## Evaluation

- `PASS`: all required dimensions satisfy rubric.
- `FAIL`: suite exists but quality/execution/feature-targeted criteria fail.
- `BLOCKED`: required evidence absent or cannot be assessed.

Prod-gate rule:
- Only `PASS` allows release gate to pass.
