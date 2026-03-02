# EVM NFT Checklist

Profile scope: Vyper contracts integrating NFT logic.
This profile does not expand source-language scope beyond Vyper.

## Codification Status (v3)

- Canonical control: `NFT-01`
- Advisory-only controls in this release: approval scope, metadata trust, royalty accounting decomposition controls

## NFT-01: Safe transfer hooks
- Validate receiver hook behavior and reentrancy boundaries.

## Advisory: Approval scope (non-canonical in v3)
- Restrict operator approvals and document revocation patterns.

## Advisory: Metadata trust assumptions (non-canonical in v3)
- Treat offchain metadata as untrusted for security-critical decisions.

## Advisory: Royalty/accounting side effects (non-canonical in v3)
- Validate royalty flows do not break settlement accounting.
