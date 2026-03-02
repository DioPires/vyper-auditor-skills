# EVM Cross-Chain Checklist

Profile scope: Vyper contracts with bridge/interoperability integrations.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Canonical control: `XCH-01`
- Advisory-only controls in this release: replay/finality/pause decomposition controls

## XCH-01: Domain separation
- Validate chain/domain identifiers for all signed or relayed messages.

## Advisory: Replay protection (non-canonical in v3)
- Ensure message IDs/nonces cannot be replayed across chains.

## Advisory: Finality assumptions (non-canonical in v3)
- Explicitly encode finality wait policy and rollback handling.

## Advisory: Pausable safety controls (non-canonical in v3)
- Ensure emergency pause can contain compromised bridge counterparties.
