# Tool Mapping Policy (v1)

Defines how external scanner findings map into canonical rule IDs.

## Canonical Ownership

- Canonical `rule_id` ownership is internal to this repository.
- Tool-native IDs and external checklist IDs are aliases only.
- Mapping source of truth: `external-control-map.json`.

## Mapping Rules

1. Attempt exact map by `(tool, native_id)`.
2. Attempt alias map from `external-control-map.json.aliases[]`.
3. Attempt pattern map using normalized signature fingerprints.
4. If unresolved: emit unmapped finding, never force-map.
5. If tool run is flagged as compatibility-only (`TOOLCHAIN:MYTHRIL_VYPER_LIMITED` or `TOOLCHAIN:ECHIDNA_HARNESS_REQUIRED`), preserve explicit warning context; do not synthesize canonical matches.

Source identity contract:
- `external-control-map.json.source_name` must exist in `source-lock.json.sources[].source_name`.
- Mapping entries with unknown source lock are invalid under strict/prod-gate.

## ID Stability

- Canonical rule IDs are stable across schema pack versions.
- If canonical IDs change, add aliases to `rule-id-migration-map.json`.
- Alias retention minimum is 2 schema pack versions.

## Blocking Eligibility

- Tier1 mapped controls can be blocking when profile-selected.
- Tier2 mapped controls are advisory until codification gate passes.
- Tier3 controls are informational and never blocking.
