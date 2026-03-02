# EVM AMM Checklist

Profile scope: Vyper contracts interacting with AMMs.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Canonical control: `AMM-01`
- Advisory-only controls in this release: deadline/oracle-circularity/fee-token decomposition controls

## AMM-01: Slippage bounds
- Enforce caller-provided slippage bounds on swaps.

## Advisory: Deadline enforcement (non-canonical in v3)
- Reject stale swap intents using deadlines.

## Advisory: Oracle circularity (non-canonical in v3)
- Prevent using manipulable AMM spot prices as sole collateral oracle.

## Advisory: Fee-on-transfer compatibility (non-canonical in v3)
- Verify path accounting with transfer-tax tokens.
