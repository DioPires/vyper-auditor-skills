# P2P Lending Security Checklist

15 checks specific to P2P (peer-to-peer) lending protocols. Pool-based DeFi lending
checks miss these P2P-specific attack surfaces.

Use alongside `defi-lending-checklist.md` for full coverage. P2P protocols have unique
risks around signed offers, per-borrower collateral isolation, callback trust models,
and proxy/delegatecall patterns not present in pool-based designs.

---

## Domain: Offer Integrity (3 checks)

### P2P-01: Signed offer replay protection
- **What**: Signed lending/borrowing offers must not be replayable. An attacker
  who captures a valid signature can re-submit it to execute the offer
  multiple times or on different chains.
- **Grep**: `nonce` `used_nonce` `offer_hash` `signature` `ecrecover` `replay` `chain_id` `EIP712`
- **Verify**:
  1. Each offer has a unique nonce or hash that is marked as used on execution
  2. Nonce/hash storage is checked before execution: `assert not self.used_nonces[nonce]`
  3. Nonce is marked used BEFORE external calls (prevents reentrancy replay)
  4. Cross-chain replay: `chain_id` is included in the signed message (EIP-712 domain separator)
  5. Cancelled offers are tracked and cannot be executed after cancellation
  6. Batch offer invalidation supported (e.g., invalidate all nonces below threshold)
  7. Signature scheme is EIP-712 compliant with proper domain separator

### P2P-02: Offer expiry enforcement
- **What**: Lending offers must expire after a defined time window. Stale offers
  executed at outdated terms disadvantage the signer, especially if market
  conditions have changed.
- **Grep**: `expiry` `expires` `deadline` `valid_until` `block.timestamp` `offer_expiry`
- **Verify**:
  1. Offer struct includes an expiry timestamp field
  2. Execution checks: `assert block.timestamp <= offer.expiry`
  3. Expiry check happens before any state changes or external calls
  4. Expiry is part of the signed message (signer commits to time window)
  5. Zero expiry has defined behavior (infinite validity or instant expiry -- verify which)
  6. Clock source is `block.timestamp` (not `block.number` which varies across chains)
  7. Expiry cannot be extended after signing without new signature

### P2P-03: Partial fill accounting
- **What**: If offers support partial fills, the remaining unfilled amount must
  be tracked accurately. Accounting errors allow overfilling (taking more
  than offered) or leave unclaimable dust.
- **Grep**: `partial` `filled` `remaining` `fill_amount` `offer_filled` `dust`
- **Verify**:
  1. Filled amount tracked per offer: `self.offer_filled[offer_hash] += fill_amount`
  2. Fill check: `self.offer_filled[offer_hash] + fill_amount <= offer.total_amount`
  3. Dust handling: if remaining < minimum_fill, final fill takes all remaining
  4. Partial fill does not re-execute the full offer (only remaining portion)
  5. Each partial fill emits an event with (offer_hash, fill_amount, remaining)
  6. Partial fills of a cancelled offer revert
  7. Interest terms scale correctly with partial fill amount

---

## Domain: Proxy/Delegatecall Safety (3 checks)

### P2P-04: Delegatecall target address validation
- **What**: Delegatecall executes external code in the caller's context. If the
  target address can be changed to arbitrary contracts, an attacker can
  execute arbitrary logic with the caller's storage and balance.
- **Grep**: `delegatecall` `raw_call` `is_delegate_call` `implementation` `target`
- **Verify**:
  1. Delegatecall targets are immutable (set at deploy time) or whitelisted
  2. If updateable, target change requires admin + timelock
  3. Target address cannot be set to zero or arbitrary contract
  4. Target contract is verified/audited before whitelisting
  5. Delegatecall is not used with user-supplied addresses
  6. Vyper `raw_call` with `is_delegate_call=True` is audited for context safety
  7. Self-destruct in target would destroy the calling contract (verified impossible)

### P2P-05: Storage layout compatibility
- **What**: Delegatecall executes target code against caller's storage. If storage
  layouts differ, variables read/write to wrong slots, corrupting state.
  This is critical in proxy upgrade patterns.
- **Grep**: `storage` `slot` `layout` `proxy` `implementation` `upgrade`
- **Verify**:
  1. Proxy and implementation share identical storage layout (same variable order)
  2. New implementation only APPENDS storage variables (never reorders)
  3. Storage gaps reserved for future additions (`_reserved: uint256[50]`)
  4. No storage variable type changes between versions (uint256 -> address)
  5. Mapping/dynamic array storage slot calculations match between proxy and impl
  6. Initialization function sets implementation-specific state (not constructor)
  7. Storage layout is tested across upgrade versions

### P2P-06: Delegatecall context preservation
- **What**: In delegatecall context, `msg.sender` and `msg.value` come from the
  original caller, not the proxy. Implementation code must account for
  this or access control checks break.
- **Grep**: `msg.sender` `msg.value` `delegatecall` `context` `self`
- **Verify**:
  1. Implementation functions use `msg.sender` correctly (it's the original caller, not the proxy)
  2. `msg.value` in delegatecall context reflects the original transaction value
  3. `self` (address(this)) in delegatecall points to the PROXY, not the implementation
  4. Balance checks use the proxy's balance, not the implementation's
  5. Events emitted in delegatecall context show the proxy's address as emitter
  6. Token approvals given to `self` in delegatecall approve the proxy (intended behavior?)
  7. Access control checks reference the correct address context

---

## Domain: Collateral Vault Isolation (3 checks)

### P2P-07: Per-borrower vault isolation
- **What**: P2P lending often uses per-borrower collateral vaults. One borrower
  must not be able to access, manipulate, or claim another borrower's
  collateral. Shared state between vaults is a critical vulnerability.
- **Grep**: `vault` `collateral_vault` `borrower_vault` `isolated` `per_user`
- **Verify**:
  1. Each borrower has a dedicated collateral vault (or isolated mapping)
  2. Vault operations check `msg.sender == vault_owner` or authorized liquidator
  3. No shared mutable state between vaults (counters, totals that affect individuals)
  4. Cross-vault operations (if any) are explicitly authorized and bounded
  5. Vault factory creates vaults deterministically (CREATE2) to prevent impersonation
  6. Vault cannot be re-assigned to a different borrower
  7. Vault balance queries are scoped to the queried borrower only

### P2P-08: Pending transfer accounting
- **What**: Assets in transit (being transferred between vaults, to/from external
  protocols, or during settlement) must be tracked separately. Counting
  in-flight assets as available creates double-spend or phantom balance.
- **Grep**: `pending` `in_flight` `in_transit` `locked` `transferring` `settlement`
- **Verify**:
  1. Pending amounts are tracked in a separate variable (not mixed with available balance)
  2. Pending amounts are not counted as available for withdrawal
  3. Pending amounts are not counted as available for collateral valuation
  4. Transfer completion clears the pending amount and credits the destination
  5. Transfer failure returns the pending amount to the source
  6. Timeout mechanism for stuck transfers (admin can resolve)
  7. Sum of (available + pending + deployed) == total for each vault

### P2P-09: Withdrawal authorization
- **What**: Only the vault owner (borrower) or an authorized liquidator should
  be able to withdraw from a collateral vault. Missing authorization checks
  allow theft of collateral.
- **Grep**: `withdraw` `withdrawal` `authorized` `owner` `liquidator` `seize`
- **Verify**:
  1. Normal withdrawal: `assert msg.sender == vault_owner`
  2. Liquidation withdrawal: `assert msg.sender == lending_market` or authorized liquidator
  3. No public function allows arbitrary address to withdraw
  4. Authorized liquidator list is managed by admin only
  5. Withdrawal after loan repayment releases full collateral to borrower
  6. Partial withdrawal maintains position health (health factor check)
  7. Emergency withdrawal path exists for contract upgrade/migration scenarios

---

## Domain: Callback Trust Model (3 checks)

### P2P-10: on_loan_created caller validation
- **What**: The `on_loan_created` callback (or equivalent) is invoked when a new
  loan is originated. If the caller is not validated, anyone can register
  fake loans and manipulate vault accounting or claim unearned yield.
- **Grep**: `on_loan_created` `loan_created` `callback` `hook` `notify_loan` `msg.sender`
- **Verify**:
  1. `assert msg.sender == authorized_lending_market` at function entry
  2. Lending market address is set at initialization (immutable or admin-only change)
  3. Loan parameters (principal, interest, duration) are validated for bounds
  4. Callback does not trust caller-supplied collateral values (re-reads from source)
  5. Callback effects are bounded (cannot mint unlimited shares or allocate unlimited funds)
  6. Multiple lending markets (if supported) are individually whitelisted
  7. Callback cannot re-enter the lending market

### P2P-11: on_settlement caller validation and principal bounds
- **What**: Settlement callbacks report loan repayment or default outcomes. A
  spoofed settlement could report inflated returns (stealing from vault) or
  fake defaults (writing off valid loans).
- **Grep**: `on_settlement` `settle` `repay_callback` `loan_repaid` `principal` `msg.sender`
- **Verify**:
  1. `assert msg.sender == authorized_lending_market` at function entry
  2. Reported principal matches the principal recorded at loan origination
  3. Reported interest does not exceed theoretical maximum (rate * time * principal)
  4. Settlement can only happen once per loan (loan status checked and updated)
  5. Default settlement writes off the correct amount (not more, not less)
  6. Settlement updates internal accounting atomically (no partial update paths)
  7. Overpayment is handled correctly (refund or cap at outstanding amount)

### P2P-12: Callback return amount verification
- **What**: Callback return values reporting amounts received must be verified
  against actual token balance changes. Trusting reported amounts without
  verification enables value extraction.
- **Grep**: `return` `callback` `amount_received` `balance` `balanceOf`
- **Verify**:
  1. Return value from callback is checked: `returned_amount <= principal + max_interest`
  2. Actual token balance change matches reported amount (balance_after - balance_before)
  3. Return amount of 0 is handled (complete default case)
  4. Return amount greater than expected is handled (excess capped or refunded)
  5. Token balance verification accounts for fee-on-transfer tokens
  6. Return amount feeds into share price calculation correctly
  7. Failed callback (revert) does not leave accounting in inconsistent state

---

## Domain: Securitize Integration (3 checks)

### P2P-13: Flash loan DS token balance accounting
- **What**: DS (Digital Security) tokens may be involved in flash loan operations.
  Balance checks must verify actual token balances before and after the
  flash operation to prevent phantom balance exploits.
- **Grep**: `flash` `ds_token` `DS` `digital_security` `balanceOf` `balance_before`
- **Verify**:
  1. Balance snapshot taken before flash operation: `balance_before = token.balanceOf(self)`
  2. Balance verified after callback: `assert token.balanceOf(self) >= balance_before + fee`
  3. DS token transfer restrictions (e.g., KYC checks) don't silently fail during flash
  4. DS token compliance hooks (onTransfer) are accounted for in gas estimation
  5. Flash loan cannot bypass DS token transfer restrictions
  6. Multiple DS tokens handled independently (no cross-token balance confusion)
  7. Flash loan callback cannot manipulate DS token compliance state

### P2P-14: Swap slippage protection on DS token operations
- **What**: Swapping DS tokens may involve restricted pools with limited liquidity.
  Slippage protection is critical to prevent value extraction through
  price manipulation in thin markets.
- **Grep**: `swap` `slippage` `min_out` `amountOutMin` `ds_token` `exchange`
- **Verify**:
  1. All DS token swap operations accept and enforce `min_amount_out` parameter
  2. Slippage tolerance is caller-specified (not hardcoded)
  3. Pool liquidity is sufficient for the swap size (or transaction reverts)
  4. Deadline parameter present to prevent stale execution
  5. DS token compliance checks don't interfere with slippage calculations
  6. Multi-hop swaps (DS -> intermediate -> target) check slippage on final output
  7. Swap revert messages are descriptive (slippage vs compliance vs liquidity)

### P2P-15: Balance verification after external token operations
- **What**: After any external operation involving token transfers, the actual
  received amount must be verified. This catches fee-on-transfer behavior,
  failed transfers, and partial fills in a single check.
- **Grep**: `balance` `balanceOf` `received` `actual_amount` `transfer` `fee_on_transfer`
- **Verify**:
  1. Pattern: `before = token.balanceOf(self)` -> operation -> `received = token.balanceOf(self) - before`
  2. Internal accounting uses `received` (not the requested/expected amount)
  3. Operation reverts if `received == 0` when non-zero expected
  4. Operation reverts if `received < min_expected` (slippage check)
  5. Fee-on-transfer tokens: documentation states whether supported
  6. Rebasing tokens: balance check accounts for rebase between snapshots
  7. Verification covers all external token operations (not just transfers -- includes swaps, redeems, claims)
