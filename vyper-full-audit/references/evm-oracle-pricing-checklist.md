# EVM Oracle Pricing Checklist

Profile scope: Vyper contracts consuming oracle feeds.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Canonical control: `ORC-01`
- Advisory-only controls in this release: positivity/round-integrity decomposition, decimals, manipulation resistance, fallback policy

## ORC-01: Staleness checks
- Enforce maximum price age and explicit stale-feed handling.

## Advisory: Positive value and round integrity checks (non-canonical in v3)
- Validate positive price values and round completeness.

## Advisory: Decimals normalization (non-canonical in v3)
- Normalize feed decimals before arithmetic.

## Advisory: Manipulation resistance (non-canonical in v3)
- Avoid single-block spot prices for critical collateralization paths.

## Advisory: Failure mode policy (non-canonical in v3)
- Define deterministic fallback behavior (pause/last-good/fail-closed).
