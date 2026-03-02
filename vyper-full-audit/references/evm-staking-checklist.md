# EVM Staking Checklist

Profile scope: Vyper contracts with staking/reward distribution.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Canonical control: `STK-01`
- Advisory-only controls in this release: claim ordering, cooldown policy, precision decomposition controls

## STK-01: Reward index monotonicity
- Ensure reward-per-share index updates are monotonic and time-consistent.

## Advisory: Claim/unstake ordering (non-canonical in v3)
- Prevent claim and unstake race conditions that double-count rewards.

## Advisory: Cooldown and exit policy (non-canonical in v3)
- Enforce cooldown windows and emergency exit semantics consistently.

## Advisory: Precision and dust handling (non-canonical in v3)
- Bound rounding drift in long-lived reward distribution.
