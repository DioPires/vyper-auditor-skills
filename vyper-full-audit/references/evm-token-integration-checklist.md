# EVM Token Integration Checklist

Profile scope: Vyper contracts integrating external ERC20-like assets.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Blocking-candidate canonical controls: `TOK-01`, `TOK-02`, `TOK-03`
- Advisory-only controls in this release: blocklist/pause and upgradeability assumptions

## TOK-01: Non-standard return values
- Verify transfer/approve/transferFrom success handling supports tokens with missing bool returns.

## TOK-02: Fee-on-transfer accounting
- Verify accounting uses actual balance deltas, not requested transfer amounts.

## TOK-03: Rebase and supply-shift assumptions
- Verify share/accounting logic is robust to rebasing token balances.

## Advisory: Blocklist and pause behavior (non-canonical in v3)
- Verify token admin controls cannot permanently trap protocol user funds.

## Advisory: Upgradeable token trust boundary (non-canonical in v3)
- Verify upgradeable token proxy risk is documented and monitored in trust assumptions.
