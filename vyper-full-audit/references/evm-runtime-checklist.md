# EVM Runtime Semantics Checklist

Profile scope: Vyper contracts relying on EVM runtime assumptions.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Canonical control: `CRT-01`
- Advisory-only controls in this release: EXTCODESIZE-only anti-bot gates, selfdestruct assumption decomposition, delegate-context assumptions

## CRT-01: CREATE2 determinism assumptions
- Validate salt and init-code uniqueness assumptions in address derivation logic.

## Advisory: EXTCODESIZE anti-bot assumptions (non-canonical in v3)
- Reject EXTCODESIZE-only EOAvsContract gating as security control.

## Advisory: Selfdestruct assumptions (non-canonical in v3)
- Avoid security-critical logic that relies on legacy selfdestruct semantics.

## Advisory: Delegate context assumptions (non-canonical in v3)
- Validate msg.sender/self/balance assumptions under delegate-call style execution.
