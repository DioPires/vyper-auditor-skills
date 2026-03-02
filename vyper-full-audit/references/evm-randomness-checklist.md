# EVM Randomness Checklist

Profile scope: Vyper contracts integrating randomness providers.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Canonical control: `RNG-01`
- Advisory-only controls in this release: callback gas/revert handling, replay decomposition, lifecycle synchronization

## RNG-01: Callback authorization
- Restrict callback entrypoints to authorized coordinator addresses.

## Advisory: Callback gas and reversion handling (non-canonical in v3)
- Bound callback gas and define retry/failure behavior.

## Advisory: Replay protection for fulfillments (non-canonical in v3)
- Prevent duplicate or stale fulfillment acceptance.

## Advisory: Consumer state synchronization (non-canonical in v3)
- Ensure request lifecycle state transitions are atomic and monotonic.
