# Tool Severity Normalization (v1)

Normalizes raw tool severities into canonical severity levels.

## Canonical Levels

- `Critical`
- `High`
- `Medium`
- `Low`
- `Informational`

## Baseline Mapping

### Slither
- High -> High
- Medium -> Medium
- Low -> Low
- Optimization/Informational -> Informational

### Mythril (optional compatibility adapter)
- High -> High
- Medium -> Medium
- Low -> Low
- Unknown -> Informational

### Echidna (optional compatibility adapter)
- Assertion/invariant break with asset loss path -> High
- Assertion/invariant break without clear asset loss -> Medium
- Flaky harness/config issues -> Low

## Overrides

- Override requires documented rationale and fixture evidence.
- Overrides live in `external-control-map.json` notes.
- Do not downgrade Critical/High without explicit validator rationale in `tool-validation.json`.
