# EVM Lending Checklist

Profile scope: Vyper contracts implementing or integrating lending logic.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Canonical control: `LND-01`
- Advisory-only controls in this release: accrual ordering, liquidation bounds, bad-debt policy decomposition

## LND-01: Health factor enforcement
- Block operations that leave account under minimum health threshold.

## Advisory: Interest accrual ordering (non-canonical in v3)
- Accrue indices before mutating debt/collateral state.

## Advisory: Liquidation bounds (non-canonical in v3)
- Cap liquidation bonuses and enforce seizure upper bounds.

## Advisory: Bad debt accounting (non-canonical in v3)
- Track and resolve deficits with explicit policy.
