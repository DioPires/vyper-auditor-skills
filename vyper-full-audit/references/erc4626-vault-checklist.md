# ERC4626 Vault Security Checklist

35 checks for ERC4626-compliant vaults. 20 standard compliance + 15 vault-specific.

Covers the full ERC4626 interface surface (deposit/mint/withdraw/redeem, preview/max
functions, totalAssets, conversion functions, events) plus vault-specific risks around
first-depositor attacks, fee mechanics, strategy trust boundaries, and withdrawal queues.

---

## Domain: ERC4626 Compliance (20 checks)

### E46-01: deposit() accepts assets, mints shares correctly
- **What**: `deposit(assets, receiver)` must transfer exactly `assets` from the
  caller, mint the correct number of shares to `receiver`, and emit a
  Deposit event. Shares minted must equal `previewDeposit(assets)`.
- **Grep**: `def deposit` `@external` `transferFrom` `mint` `shares`
- **Verify**:
  1. `assets` are transferred from `msg.sender` via `transferFrom`
  2. Shares minted = `assets * totalSupply / totalAssets` (round down)
  3. Shares minted to `receiver` (not `msg.sender` if different)
  4. If `totalSupply == 0`, initial share calculation is defined (1:1 or with offset)
  5. Deposit event emitted with (msg.sender, receiver, assets, shares)
  6. Reverts if `assets == 0` or minted `shares == 0`
  7. Reverts if deposit exceeds `maxDeposit(receiver)`

### E46-02: mint() accepts exact shares, charges correct assets
- **What**: `mint(shares, receiver)` must mint exactly `shares` to `receiver`
  and charge the correct amount of assets from the caller. Assets charged
  must equal `previewMint(shares)`.
- **Grep**: `def mint` `@external` `transferFrom` `assets` `ceil`
- **Verify**:
  1. Exactly `shares` are minted to `receiver`
  2. Assets charged = `shares * totalAssets / totalSupply` (round UP, favoring protocol)
  3. Assets transferred from `msg.sender` via `transferFrom`
  4. Deposit event emitted (same event as deposit())
  5. Reverts if `shares == 0` or required `assets == 0`
  6. Reverts if shares exceed `maxMint(receiver)`
  7. Asset calculation rounds up to prevent minting shares for free

### E46-03: withdraw() burns shares, returns exact assets
- **What**: `withdraw(assets, receiver, owner)` must return exactly `assets` to
  `receiver`, burning the necessary shares from `owner`. Shares burned
  must equal `previewWithdraw(assets)`.
- **Grep**: `def withdraw` `@external` `transfer` `burn` `shares`
- **Verify**:
  1. Exactly `assets` transferred to `receiver`
  2. Shares burned = `assets * totalSupply / totalAssets` (round UP, favoring protocol)
  3. If `msg.sender != owner`, allowance check and deduction applied
  4. Withdraw event emitted with (msg.sender, receiver, owner, assets, shares)
  5. Reverts if `assets == 0` or burned `shares == 0`
  6. Reverts if assets exceed `maxWithdraw(owner)`
  7. Allowance of `type(uint256).max` is treated as infinite (no deduction)

### E46-04: redeem() burns exact shares, returns correct assets
- **What**: `redeem(shares, receiver, owner)` must burn exactly `shares` from
  `owner` and return the correct amount of assets to `receiver`. Assets
  returned must equal `previewRedeem(shares)`.
- **Grep**: `def redeem` `@external` `transfer` `burn` `assets`
- **Verify**:
  1. Exactly `shares` burned from `owner`
  2. Assets returned = `shares * totalAssets / totalSupply` (round DOWN, favoring protocol)
  3. If `msg.sender != owner`, allowance check and deduction applied
  4. Withdraw event emitted (same event as withdraw())
  5. Reverts if `shares == 0` or returned `assets == 0`
  6. Reverts if shares exceed `maxRedeem(owner)`
  7. Assets are actually transferred (not just accounting update)

### E46-05: totalAssets() includes all assets under management
- **What**: `totalAssets()` must return the total amount of underlying assets held
  by the vault, including assets deployed in strategies, pending yields,
  and idle balance. Underreporting causes share overvaluation; overreporting
  causes undervaluation.
- **Grep**: `def totalAssets` `def total_assets` `balanceOf` `deployed` `strategy`
- **Verify**:
  1. Includes idle assets: `asset.balanceOf(self)`
  2. Includes deployed assets: sum of assets in all strategies
  3. Includes accrued but unclaimed yield (if applicable)
  4. Excludes protocol fees already accrued but not yet withdrawn
  5. Does not double-count any assets
  6. Strategy balance reporting is accurate (at-cost vs mark-to-market)
  7. View function (no state changes) -- safe for external callers

### E46-06: convertToShares() rounding direction
- **What**: `convertToShares(assets)` converts an asset amount to shares using
  the current exchange rate. Must round DOWN to prevent share inflation.
- **Grep**: `def convertToShares` `def convert_to_shares` `total_supply` `total_assets`
- **Verify**:
  1. Formula: `assets * totalSupply / totalAssets` (round down)
  2. Returns 0 when `totalSupply == 0` (or uses initial rate with virtual offset)
  3. Does not revert for any input (including 0 and very large values)
  4. Consistent with actual shares minted by `deposit(assets)`
  5. Does not include fees in calculation (informational function)
  6. Handles edge case: `totalAssets == 0` but `totalSupply > 0`

### E46-07: convertToAssets() rounding direction
- **What**: `convertToAssets(shares)` converts a share amount to assets using
  the current exchange rate. Must round DOWN to prevent asset inflation.
- **Grep**: `def convertToAssets` `def convert_to_assets` `total_supply` `total_assets`
- **Verify**:
  1. Formula: `shares * totalAssets / totalSupply` (round down)
  2. Returns 0 when `totalSupply == 0` (or uses initial rate with virtual offset)
  3. Does not revert for any input (including 0 and very large values)
  4. Consistent with actual assets returned by `redeem(shares)`
  5. Does not include fees in calculation (informational function)
  6. Handles edge case: `totalSupply == 0` but `totalAssets > 0`

### E46-08: previewDeposit() accuracy
- **What**: `previewDeposit(assets)` must return the number of shares that would
  be minted for the given assets. Must be accurate to within rounding and
  must NEVER return MORE shares than actually minted.
- **Grep**: `def previewDeposit` `def preview_deposit`
- **Verify**:
  1. Returns same value as actual `deposit()` would produce (minus rounding)
  2. Rounds DOWN (returns fewer shares than actual = conservative estimate)
  3. Includes any deposit fees in calculation
  4. Does not revert for any input within `maxDeposit` bounds
  5. View function, no state changes
  6. Accrues interest virtually (reflects current, not stale, exchange rate)

### E46-09: previewMint() accuracy
- **What**: `previewMint(shares)` must return the number of assets that would be
  charged for the given shares. Must NEVER return FEWER assets than actually
  charged.
- **Grep**: `def previewMint` `def preview_mint`
- **Verify**:
  1. Returns same value as actual `mint()` would charge (minus rounding)
  2. Rounds UP (returns more assets than actual = conservative estimate)
  3. Includes any deposit fees in calculation
  4. Does not revert for any input within `maxMint` bounds
  5. View function, no state changes
  6. Accrues interest virtually

### E46-10: previewWithdraw() accuracy
- **What**: `previewWithdraw(assets)` must return the number of shares that would
  be burned for the given assets. Must NEVER return FEWER shares than
  actually burned.
- **Grep**: `def previewWithdraw` `def preview_withdraw`
- **Verify**:
  1. Returns same value as actual `withdraw()` would burn (minus rounding)
  2. Rounds UP (returns more shares burned = conservative estimate)
  3. Includes any withdrawal fees in calculation
  4. Does not revert for any input within `maxWithdraw` bounds
  5. View function, no state changes
  6. Accrues interest virtually

### E46-11: previewRedeem() accuracy
- **What**: `previewRedeem(shares)` must return the number of assets that would
  be returned for the given shares. Must NEVER return MORE assets than
  actually returned.
- **Grep**: `def previewRedeem` `def preview_redeem`
- **Verify**:
  1. Returns same value as actual `redeem()` would return (minus rounding)
  2. Rounds DOWN (returns fewer assets = conservative estimate)
  3. Includes any withdrawal fees in calculation
  4. Does not revert for any input within `maxRedeem` bounds
  5. View function, no state changes
  6. Accrues interest virtually

### E46-12: maxDeposit() respects caps and paused state
- **What**: `maxDeposit(receiver)` must return the maximum assets that can be
  deposited for the given receiver. Must return 0 when deposits are paused
  or the receiver is blocked.
- **Grep**: `def maxDeposit` `def max_deposit` `supply_cap` `paused`
- **Verify**:
  1. Returns 0 when vault is paused
  2. Returns remaining capacity under supply cap: `supply_cap - totalAssets`
  3. Returns `type(uint256).max` if no cap exists
  4. Accounts for receiver-specific restrictions (if any, e.g., KYC)
  5. Never reverts (must always return a value)
  6. Consistent with what `deposit()` would actually accept

### E46-13: maxMint() respects caps and paused state
- **What**: `maxMint(receiver)` must return the maximum shares that can be minted
  for the given receiver. Must return 0 when minting is paused.
- **Grep**: `def maxMint` `def max_mint` `supply_cap` `paused`
- **Verify**:
  1. Returns 0 when vault is paused
  2. Returns remaining share capacity (converted from asset cap)
  3. Returns `type(uint256).max` if no cap exists
  4. Accounts for receiver-specific restrictions
  5. Never reverts
  6. Consistent with what `mint()` would actually accept

### E46-14: maxWithdraw() respects available liquidity
- **What**: `maxWithdraw(owner)` must return the maximum assets that the owner
  can withdraw. Limited by both their share balance and available liquidity.
- **Grep**: `def maxWithdraw` `def max_withdraw` `liquidity` `balanceOf`
- **Verify**:
  1. Limited by owner's share balance converted to assets
  2. Limited by available liquidity (idle + immediately redeemable from strategies)
  3. Returns 0 when vault is paused for withdrawals (if applicable)
  4. Accounts for withdrawal fees in the conversion
  5. Never reverts
  6. Returns the lesser of owner's balance value and available liquidity

### E46-15: maxRedeem() respects available liquidity
- **What**: `maxRedeem(owner)` must return the maximum shares that the owner
  can redeem. Limited by their share balance and available asset liquidity.
- **Grep**: `def maxRedeem` `def max_redeem` `liquidity` `balanceOf`
- **Verify**:
  1. Limited by `owner`'s share balance
  2. Limited by available liquidity converted to shares
  3. Returns 0 when vault is paused for redemptions
  4. Never reverts
  5. Consistent with what `redeem()` would actually accept
  6. Accounts for withdrawal fees

### E46-16: asset() returns correct underlying token
- **What**: `asset()` must return the address of the underlying ERC20 token.
  Must be immutable after initialization. Returning the wrong token or
  allowing changes breaks all accounting.
- **Grep**: `def asset` `underlying` `token` `immutable`
- **Verify**:
  1. Returns the correct ERC20 token address
  2. Address is immutable (set in constructor, cannot be changed)
  3. Consistent with the token used in deposit/withdraw/mint/redeem
  4. Token address is validated at deployment (not zero address)
  5. View function, no state changes

### E46-17: Deposit event correctness
- **What**: Every deposit/mint operation must emit a `Deposit` event with correct
  parameters. Missing or incorrect events break off-chain indexing and
  compliance monitoring.
- **Grep**: `event Deposit` `log Deposit` `emit Deposit`
- **Verify**:
  1. Event signature: `Deposit(sender: indexed(address), owner: indexed(address), assets: uint256, shares: uint256)`
  2. `sender` = `msg.sender` (the caller who provided assets)
  3. `owner` = `receiver` parameter (who receives the shares)
  4. `assets` = actual assets transferred (not input for fee-on-transfer)
  5. `shares` = actual shares minted
  6. Emitted on both `deposit()` and `mint()` calls
  7. Emitted after state changes (reflects final state)

### E46-18: Withdraw event correctness
- **What**: Every withdraw/redeem operation must emit a `Withdraw` event with
  correct parameters. Incorrect events break monitoring and audit trails.
- **Grep**: `event Withdraw` `log Withdraw` `emit Withdraw`
- **Verify**:
  1. Event signature: `Withdraw(sender: indexed(address), receiver: indexed(address), owner: indexed(address), assets: uint256, shares: uint256)`
  2. `sender` = `msg.sender` (the caller who initiated withdrawal)
  3. `receiver` = address receiving the assets
  4. `owner` = address whose shares were burned
  5. `assets` = actual assets transferred
  6. `shares` = actual shares burned
  7. Emitted on both `withdraw()` and `redeem()` calls

### E46-19: Share price monotonicity for passive holders
- **What**: The value of shares for passive holders (who neither deposit nor
  withdraw) must never decrease. Any decrease means value is being
  extracted from holders, which is a critical vulnerability.
- **Grep**: `exchange_rate` `convertToAssets` `totalAssets` `totalSupply` `share_price`
- **Verify**:
  1. Interest accrual only increases `totalAssets` (never decreases)
  2. Fee collection does not reduce share price (fees minted as new shares or taken from yield)
  3. Rounding errors across many operations don't compound into price decrease
  4. Strategy losses are the only acceptable decrease (documented, bounded)
  5. Donation attack cannot decrease existing share value
  6. Rebalancing between strategies preserves total value

### E46-20: Zero-amount deposit/withdraw/mint/redeem handling
- **What**: Operations with zero amounts must be handled consistently. Zero
  deposits/mints should not create phantom shares. Zero withdrawals/redeems
  should not burn shares for nothing.
- **Grep**: `amount == 0` `shares == 0` `assets == 0` `assert` `require`
- **Verify**:
  1. `deposit(0)` reverts or results in 0 shares (consistent behavior)
  2. `mint(0)` reverts or charges 0 assets
  3. `withdraw(0)` reverts or burns 0 shares
  4. `redeem(0)` reverts or returns 0 assets
  5. No division by zero in share/asset conversion when amount is 0
  6. No events emitted for zero-amount operations (if no-op approach)
  7. Behavior matches what preview functions would indicate

---

## Domain: Vault-Specific (15 checks)

### VS-01: First depositor share inflation attack prevention
- **What**: The first depositor can deposit 1 wei, then donate a large amount
  to the vault, inflating the share price so that subsequent depositors
  receive 0 shares (rounding down to 0). This is the most common ERC4626
  vulnerability.
- **Grep**: `virtual` `offset` `dead_shares` `INITIAL` `_decimalsOffset` `1000`
- **Verify**:
  1. Virtual shares/assets offset: `totalAssets() + 1` and `totalSupply() + 10**offset`
  2. Or: dead shares minted to zero address on first deposit
  3. Or: minimum first deposit enforced (e.g., >= 10**decimals)
  4. Share calculation when `totalSupply == 0` does not divide by 0
  5. Donation of assets to vault cannot inflate share price for existing holders
  6. Offset is large enough: 10**decimals_offset >= potential donation size
  7. Protection is tested with actual attack scenario

### VS-02: Withdrawal queue ordering and fairness
- **What**: When available liquidity is insufficient for all withdrawals,
  a queue mechanism must ensure fair ordering. FIFO, pro-rata, or
  priority-based -- but must be deterministic and not gameable.
- **Grep**: `queue` `withdrawal_queue` `pending_withdrawal` `FIFO` `claim`
- **Verify**:
  1. Queue ordering is deterministic (FIFO, timestamp, or share-weighted)
  2. Queue cannot be jumped by cancelling and re-requesting
  3. Queued withdrawals earn yield until fulfilled (or explicitly don't, documented)
  4. Queue processing is gas-efficient (no unbounded loops)
  5. Queued amount is locked (cannot be transferred or re-deposited)
  6. Queue can be processed by anyone (permissionless claiming)
  7. Strategy recalls prioritize queue fulfillment

### VS-03: Strategy allocation access control
- **What**: Allocating or rebalancing assets across yield strategies must be
  restricted to authorized roles (curator/admin). Unrestricted rebalancing
  allows an attacker to move assets to a malicious strategy.
- **Grep**: `allocate` `rebalance` `reallocate` `curator` `strategy` `deploy`
- **Verify**:
  1. Allocation functions restricted to curator role
  2. Curator cannot allocate to unregistered strategies
  3. Strategy registration restricted to admin/owner
  4. Allocation amounts bounded by per-strategy caps
  5. Total allocation cannot exceed totalAssets
  6. Rebalancing events emitted for monitoring
  7. Emergency recall available to guardian role

### VS-04: Strategy trust boundary
- **What**: Each yield strategy is a trust boundary. A compromised or malicious
  strategy could report inflated balances, refuse withdrawals, or drain
  deposited assets. The vault must limit exposure.
- **Grep**: `strategy` `adapter` `deposit_to` `withdraw_from` `max_allocation`
- **Verify**:
  1. Per-strategy allocation cap limits maximum exposure
  2. Strategy can be paused/removed without affecting other strategies
  3. Strategy-reported balance is verified (or bounded by deposit amount)
  4. Withdrawal from strategy has timeout (can't block vault indefinitely)
  5. Strategy cannot call back into vault to manipulate state
  6. Strategy upgrade/change requires admin action + timelock
  7. Strategy removal reclaims all assets before deregistration

### VS-05: Fee accrual before share price calculation
- **What**: Fees must be accrued (minted as shares or deducted) BEFORE any
  share price calculation. Stale fee state causes incorrect share
  prices for deposits and withdrawals.
- **Grep**: `accrue_fee` `_accrueFees` `fee` `management_fee` `performance_fee`
- **Verify**:
  1. Fee accrual called at the start of deposit/withdraw/mint/redeem
  2. Fee accrual updates totalAssets or totalSupply before conversion
  3. Fee shares are minted to fee recipient (not deducted from vault balance)
  4. Fee accrual is idempotent within the same block
  5. Fee accrual does not revert (preventing deposits/withdrawals)

### VS-06: Performance fee high-water mark
- **What**: Performance fees should only be charged on new profits above the
  previous high-water mark. Without HWM, the protocol charges fees on
  recovered losses (double-dipping).
- **Grep**: `high_water_mark` `hwm` `performance_fee` `profit` `peak`
- **Verify**:
  1. High-water mark tracks the highest share price (or totalAssets/totalSupply)
  2. Performance fee only charged when current value > high-water mark
  3. HWM is updated after fee collection
  4. HWM is per-strategy or global (document which and why)
  5. HWM cannot be reset by admin (would allow re-charging fees)
  6. Loss followed by recovery charges fee only on net new profit
  7. HWM initialization on first deposit uses the initial share price

### VS-07: Management fee calculation
- **What**: Management fees are time-based, pro-rata charges on AUM. Must
  accrue continuously based on elapsed time, not at discrete checkpoints
  that can be gamed by timing deposits.
- **Grep**: `management_fee` `annual_fee` `time_elapsed` `block.timestamp` `last_fee`
- **Verify**:
  1. Fee = totalAssets * management_fee_rate * time_elapsed / SECONDS_PER_YEAR
  2. Time elapsed = `block.timestamp - last_fee_timestamp`
  3. Fee accrues on every interaction (deposit/withdraw triggers accrual)
  4. Fee cannot be gamed by depositing right after accrual and withdrawing right before
  5. Fee rate bounded by MAX_MANAGEMENT_FEE (e.g., 10%)
  6. Fee is collected as newly minted shares (dilutes existing holders proportionally)
  7. First accrual after deployment uses deployment time as base

### VS-08: Fee recipient address validation
- **What**: The fee recipient address must not be zero. Minting shares to or
  transferring fees to address(0) permanently destroys value.
- **Grep**: `fee_recipient` `treasury` `feeRecipient` `empty(address)` `ZERO`
- **Verify**:
  1. Fee recipient setter checks `recipient != empty(address)`
  2. Constructor sets a valid initial fee recipient
  3. Fee recipient is updateable by admin (with validation)
  4. Fee recipient change does not affect already-accrued fees
  5. If fee recipient is a contract, it can receive ERC20 tokens

### VS-09: Emergency withdrawal mechanism
- **What**: A guardian or admin must be able to trigger emergency asset recall
  from strategies, bypassing normal queue and timelock mechanisms. This
  is the last line of defense against strategy exploits.
- **Grep**: `emergency` `panic` `rescue` `guardian` `recall` `force_withdraw`
- **Verify**:
  1. Emergency function exists with guardian access
  2. Recalls assets from specified strategies immediately
  3. Bypasses normal timelock on rebalancing
  4. Does not bypass user withdrawal rights (assets return to vault, not admin)
  5. Emits emergency event for monitoring
  6. Can target specific strategies (not all-or-nothing)
  7. Works even if strategy is misbehaving (try/except around strategy calls)

### VS-10: Yield strategy deposit/withdraw accounting
- **What**: When depositing to or withdrawing from strategies, the vault must
  accurately track how much is deployed. At-cost tracking (deposit amount)
  differs from mark-to-market (current value). The choice affects share
  pricing.
- **Grep**: `deployed` `strategy_balance` `total_deployed` `at_cost` `mark_to_market`
- **Verify**:
  1. Deposits to strategy increase deployed tracking by deposit amount
  2. Withdrawals from strategy decrease deployed tracking by withdrawal amount
  3. Yield/loss updates deployed tracking (if mark-to-market)
  4. Sum of deployed amounts + idle = totalAssets (invariant)
  5. Strategy reporting frequency is sufficient for accurate pricing
  6. Unreported yield doesn't cause sudden share price jumps
  7. Strategy balance queries are gas-efficient (called on every vault interaction)

### VS-11: Multi-strategy rebalancing atomicity
- **What**: Rebalancing assets across multiple strategies must be atomic. If
  withdrawal from strategy A succeeds but deposit to strategy B fails,
  assets sit idle (suboptimal) or are lost (critical).
- **Grep**: `rebalance` `reallocate` `batch` `multi_strategy` `atomic`
- **Verify**:
  1. Rebalance reverts entirely if any step fails
  2. Intermediate state (assets withdrawn from A, not yet deposited to B) is consistent
  3. Gas limit sufficient for full rebalance (or bounded iteration)
  4. Rebalance cannot be front-run for MEV extraction
  5. Events emitted for each strategy change within rebalance
  6. Slippage protection on strategy transitions involving swaps
  7. Idle assets during rebalance are accounted in totalAssets

### VS-12: Idle asset ratio management
- **What**: The vault should maintain a liquidity buffer (idle assets not deployed
  to strategies) to service withdrawals without strategy recalls. Too much
  idle reduces yield; too little causes withdrawal failures.
- **Grep**: `idle` `buffer` `liquidity_ratio` `target_idle` `min_idle` `cash`
- **Verify**:
  1. Target idle ratio is defined and enforced during rebalancing
  2. Deposits above idle target are deployed to strategies
  3. Withdrawals that breach minimum idle trigger strategy recalls
  4. Idle ratio is configurable by curator/admin (bounded)
  5. Idle assets are included in totalAssets calculation
  6. Yield on idle assets (if any) is tracked
  7. Emergency mode sets idle ratio to 100% (full recall)

### VS-13: Share transfer restrictions
- **What**: If the vault has transfer restrictions (KYC/AML, whitelist, lock-up
  periods), the `transfer` and `transferFrom` functions must enforce them.
  Missing restrictions on share transfers bypass intended access control.
- **Grep**: `transfer` `transferFrom` `whitelist` `kyc` `restricted` `lock`
- **Verify**:
  1. If restrictions exist, both `transfer` and `transferFrom` check them
  2. Restriction check applies to both sender and receiver
  3. Lock-up period prevents transfer within N blocks/seconds of deposit
  4. Whitelisted addresses can be managed by admin
  5. Restricted transfers emit informative revert messages
  6. Vault's own transfers (fee minting, etc.) bypass user restrictions if needed
  7. Restriction removal is access-controlled and event-logged

### VS-14: Reentrancy on deposit-to-strategy path
- **What**: The path from user deposit to strategy deployment may involve multiple
  external calls (token transfer in, strategy deposit). Reentrancy at any
  point can exploit intermediate state.
- **Grep**: `@nonreentrant` `reentrancy` `deposit` `deploy` `strategy` `raw_call`
- **Verify**:
  1. `@nonreentrant` on all deposit/withdraw functions
  2. Reentrancy lock covers the full deposit-to-deploy path
  3. State updates (share minting, balance tracking) before external calls
  4. Strategy deposit callback cannot re-enter vault deposit
  5. Token transfer hooks (ERC777, ERC1155) cannot re-enter
  6. Cross-function reentrancy prevented (deposit re-enters withdraw)
  7. Reentrancy protection tested with malicious token/strategy mocks

### VS-15: Cross-contract accounting consistency
- **What**: The vault's `totalAssets` must always equal the sum of strategy
  balances plus idle assets. Any drift between these creates phantom
  value or hidden insolvency.
- **Grep**: `totalAssets` `total_assets` `invariant` `consistency` `deployed` `idle`
- **Verify**:
  1. Invariant: `totalAssets == idle_balance + sum(strategy_balances)`
  2. Invariant holds after every state-changing operation
  3. Strategy balance updates and vault accounting update atomically
  4. No code path modifies one side without the other
  5. Rounding errors are bounded and don't compound over time
  6. Invariant is testable (view function or test helper)
  7. Reporting lag from strategies is bounded and documented
