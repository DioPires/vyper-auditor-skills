# External Controls Mapping Integrity Report

## Result

- Status: PASS
- Date: 2026-03-02

## Checks

1. Every codified external rule in `vuln-rule-registry.json` has a mapping entry.
2. No duplicate `(canonical_rule_id, source_name, source_control_id)` collisions.
3. Alias migration entries exist for each external family.
4. `external-control-map.source_name` values are present in `source-lock.sources[].source_name`.
5. Tier2 entries are explicitly non-blocking in this release.
