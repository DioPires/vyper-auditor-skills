# DeFi Lending Security Checklist

63 checks across 6 domains for DeFi lending protocol security.

Merged from CDSecurity DeFi Lending Checklist and protocol-vulnerabilities-index
lending/yield categories. Covers collateral, pool accounting, external integrations,
access control, token handling, and economic attack vectors.

---

## Domain: Collateral Management (12 checks)

### CL-01: Collateral factor bounds validation
- **What**: Collateral factors must be constrained to 0-100% range. Overflow or
  out-of-bounds values can make positions appear overcollateralized or allow
  unlimited borrowing.
- **Grep**: `collateral_factor` `collateralFactor` `ltv`
- **Verify**:
  1. Check that collateral factor setter enforces `0 <= factor <= MAX_COLLATERAL_FACTOR`
  2. Confirm MAX_COLLATERAL_FACTOR is <= 10000 (100% in basis points) or equivalent
  3. Verify arithmetic using collateral factor cannot overflow (especially in Vyper <0.4 with unchecked math)
  4. Check that a factor of 0 effectively disables borrowing against that collateral
  5. Ensure factor changes don't retroactively make existing positions liquidatable without grace period

### CL-02: Liquidation threshold vs collateral factor ordering
- **What**: Liquidation threshold must be strictly greater than collateral factor.
  If equal or inverted, positions become instantly liquidatable on borrow or
  can never be liquidated.
- **Grep**: `liquidation_threshold` `liq_threshold` `LIQUIDATION`
- **Verify**:
  1. Check invariant: `collateral_factor < liquidation_threshold` enforced on set
  2. Verify both are denominated in the same units (basis points, WAD, etc.)
  3. Confirm the gap between them provides meaningful buffer for price movement
  4. Test: setting liquidation_threshold <= collateral_factor should revert
  5. Verify health factor calculation uses liquidation_threshold (not collateral_factor)

### CL-03: Price oracle integration for collateral valuation
- **What**: Oracle prices must be fresh, validated, and have fallback mechanisms.
  Stale or manipulated prices can enable undercollateralized borrowing or
  unfair liquidations.
- **Grep**: `oracle` `price` `latestRoundData` `get_price` `chainlink`
- **Verify**:
  1. Check staleness guard: `block.timestamp - updatedAt < MAX_STALENESS`
  2. Verify price > 0 check after oracle call
  3. Check for fallback oracle if primary fails (try/except or secondary source)
  4. Confirm oracle decimals are normalized correctly (Chainlink returns 8 decimals typically)
  5. Verify oracle address cannot be changed to arbitrary contract without timelock
  6. Check that sequencer uptime feed is consulted on L2 deployments

### CL-04: Collateral withdrawal blocked when undercollateralized
- **What**: Withdrawing collateral must not leave a position with health factor < 1.
  Missing this check allows borrowers to extract collateral while keeping debt.
- **Grep**: `withdraw_collateral` `remove_collateral` `health_factor`
- **Verify**:
  1. After withdrawal simulation, health factor is recalculated
  2. Transaction reverts if post-withdrawal health factor < 1.0
  3. Check that accrued interest is included in the health check (not stale debt)
  4. Verify the check cannot be bypassed via reentrancy during withdrawal
  5. Test: partial withdrawal that exactly reaches health factor = 1.0 boundary

### CL-05: Multi-collateral accounting isolation
- **What**: When multiple collateral types are supported, each must be tracked
  independently. Cross-contamination allows inflating one collateral position
  with another's balance.
- **Grep**: `collateral_balances` `user_collateral` `mapping`
- **Verify**:
  1. Each collateral type has independent balance tracking per user
  2. Deposit of token A does not affect balance of token B
  3. Liquidation of one collateral type does not incorrectly seize another
  4. Total collateral value aggregation uses per-token prices, not a single price
  5. Adding/removing collateral types does not corrupt existing balances

### CL-06: Collateral seizure during liquidation
- **What**: Liquidation must transfer the correct amount of collateral to the
  liquidator, including any bonus/discount. Over-seizure drains the borrower;
  under-seizure leaves bad debt.
- **Grep**: `liquidat` `seize` `bonus` `incentive` `penalty`
- **Verify**:
  1. Seized amount = (debt_repaid * liquidation_bonus) / collateral_price
  2. Liquidation bonus is bounded (e.g., 5-15%, not 100%+)
  3. Seizure cannot exceed borrower's total collateral (capped)
  4. Partial liquidation leaves remaining position healthy or fully liquidated
  5. Seized collateral is actually transferred (not just accounting update)
  6. Close factor limits how much debt can be repaid in one liquidation

### CL-07: Bad debt socialization mechanism
- **What**: When collateral value < debt (underwater position), the protocol
  must have a defined mechanism: socialize across lenders, insurance fund,
  or explicit bad debt tracking.
- **Grep**: `bad_debt` `shortfall` `socialize` `insurance` `deficit`
- **Verify**:
  1. Identify what happens when liquidation leaves residual debt
  2. Check if bad debt is tracked separately from normal borrows
  3. Verify socialization doesn't reduce existing depositor shares (only future yield)
  4. If insurance fund exists, check it's funded and drawdown is authorized
  5. Ensure bad debt cannot be created artificially (e.g., self-liquidation exploit)

### CL-08: Collateral deposit/withdrawal event emission
- **What**: All collateral state changes must emit events for off-chain tracking,
  indexing, and audit trails. Missing events make the protocol unmonitorable.
- **Grep**: `event` `log` `CollateralDeposit` `CollateralWithdraw` `emit`
- **Verify**:
  1. Deposit emits event with (user, collateral_token, amount)
  2. Withdrawal emits event with (user, collateral_token, amount)
  3. Liquidation seizure emits event with (borrower, liquidator, collateral_token, amount)
  4. Events are emitted after state changes (not before, to reflect actual state)
  5. Event parameters match actual transferred amounts (not input amounts for fee-on-transfer)

### CL-09: Frozen/paused collateral handling
- **What**: When a collateral type is frozen or paused, new deposits should be
  blocked but existing withdrawals must remain possible. Trapping user funds
  is a critical failure.
- **Grep**: `frozen` `paused` `pause` `freeze` `is_active`
- **Verify**:
  1. Frozen collateral: deposits revert, withdrawals succeed
  2. Paused protocol: check if all collateral operations halt or only deposits
  3. Verify users can always exit (withdraw collateral + repay debt) even when paused
  4. Check that freeze/pause is access-controlled (guardian/admin only)
  5. Ensure unfreezing restores full functionality without side effects

### CL-10: Dust amount handling
- **What**: Minimum collateral thresholds prevent economically unviable positions
  where gas costs exceed position value, creating unclaimable dust that bloats
  state.
- **Grep**: `min_collateral` `dust` `minimum` `MIN_` `threshold`
- **Verify**:
  1. Minimum deposit amount is enforced (if defined)
  2. Withdrawal that leaves dust below minimum either withdraws all or reverts
  3. Liquidation that leaves dust below minimum fully liquidates instead
  4. Dust threshold is denominated in value (not raw token amount) for volatile assets
  5. Check that dust threshold cannot be set so high it blocks normal operations

### CL-11: Collateral price manipulation resistance
- **What**: Spot prices from AMM pools can be manipulated within a single
  transaction. TWAP, Chainlink, or multi-source oracles resist this.
- **Grep**: `twap` `TWAP` `observe` `consult` `spot_price` `getReserves`
- **Verify**:
  1. Price source is NOT a single-block spot price from an AMM pool
  2. If TWAP, window is sufficiently long (>=15 min for major pairs)
  3. If Chainlink, deviation threshold and heartbeat are appropriate for the asset
  4. Multi-source oracle: check aggregation method (median vs mean)
  5. Check if price can be influenced by protocol's own operations (circular dependency)

### CL-12: Re-collateralization incentive mechanism
- **What**: Users approaching liquidation should have incentive to add collateral
  or repay debt. The protocol should not penalize re-collateralization.
- **Grep**: `health_factor` `add_collateral` `top_up` `repay`
- **Verify**:
  1. Adding collateral immediately improves health factor
  2. No fee or penalty on adding collateral to an at-risk position
  3. Partial repayment reduces borrow balance and improves health factor
  4. Re-collateralization is not blocked during liquidation grace period
  5. Health factor calculation is consistent between re-collateralization and liquidation paths

---

## Domain: Lending Pool Accounting (15 checks)

### LP-01: Interest rate model correctness
- **What**: The utilization-to-rate curve must be mathematically correct with
  proper kink behavior. Errors here cause rates to be too high, too low, or
  produce unexpected discontinuities.
- **Grep**: `utilization` `rate_model` `interest_rate` `kink` `slope` `jump`
- **Verify**:
  1. Utilization = total_borrows / total_supply (not inverted)
  2. Below kink: rate = base_rate + utilization * slope1
  3. Above kink: rate = base_rate + kink * slope1 + (utilization - kink) * slope2
  4. Rate at 100% utilization is finite and bounded
  5. Rate at 0% utilization equals base_rate (possibly 0)
  6. No integer overflow in rate calculation at extreme utilization

### LP-02: Interest accrual timing
- **What**: Interest must accrue based on actual time elapsed, not assumed
  block intervals. Block times vary by chain and can be irregular.
- **Grep**: `accrue` `accrual` `block.timestamp` `block.number` `last_update` `delta`
- **Verify**:
  1. Time delta calculated from `block.timestamp` (not `block.number` unless L2-specific)
  2. First accrual after deployment uses deployment time as base (not 0)
  3. Large time gaps (e.g., chain halt) don't cause overflow in interest calculation
  4. Interest accrual is idempotent if called multiple times in same block
  5. Compound interest formula used (not simple interest on large time spans)

### LP-03: Borrow/supply index update ordering
- **What**: Interest indexes must be updated BEFORE any state-changing operation.
  Failing to accrue first means operations use stale exchange rates, causing
  incorrect share/token conversions.
- **Grep**: `accrue_interest` `update_index` `borrow_index` `supply_index`
- **Verify**:
  1. Every borrow/repay/deposit/withdraw calls accrue_interest() first
  2. accrue_interest() updates both borrow_index and supply_index
  3. Index updates use time delta since last accrual
  4. No code path can modify balances without first accruing
  5. Liquidation also accrues interest before calculating amounts

### LP-04: Share/token exchange rate monotonicity
- **What**: The share-to-asset exchange rate for lenders must never decrease.
  A decreasing rate means lenders lose value, which should only happen via
  explicit bad debt socialization.
- **Grep**: `exchange_rate` `shares_to_assets` `convertToAssets` `total_supply`
- **Verify**:
  1. Exchange rate = totalAssets / totalShares (or equivalent)
  2. Interest accrual only increases totalAssets (never decreases)
  3. Fees are taken from yield (not principal), preserving monotonicity
  4. Bad debt write-off is the only acceptable decrease path
  5. Rounding in share calculations doesn't create rate decrease over many small operations

### LP-05: Total borrows tracking accuracy
- **What**: The protocol's recorded total borrows must equal the sum of all
  individual borrow balances. Drift between these creates phantom liquidity
  or hidden insolvency.
- **Grep**: `total_borrows` `totalBorrows` `total_debt` `borrow_balance`
- **Verify**:
  1. Every borrow increases total_borrows by borrow amount
  2. Every repay decreases total_borrows by repay amount
  3. Interest accrual increases total_borrows by accrued amount
  4. Liquidation repayment decreases total_borrows correctly
  5. No operation modifies individual balance without updating total

### LP-06: Rounding direction correctness
- **What**: All division rounding must favor the protocol. Borrow amounts round
  up (user owes more), repay credits round down (user still owes more),
  deposits round down (user gets fewer shares), withdrawals round down
  (user gets fewer assets).
- **Grep**: `div` `mul` `round` `ceil` `floor` `unsafe_div`
- **Verify**:
  1. Shares minted on deposit: `shares = assets * totalShares / totalAssets` (round down)
  2. Assets returned on redeem: `assets = shares * totalAssets / totalShares` (round down)
  3. Shares burned on withdraw: `shares = assets * totalShares / totalAssets` (round up)
  4. Assets charged on mint: `assets = shares * totalAssets / totalShares` (round up)
  5. Interest calculation rounds up for borrowers
  6. No rounding direction allows extracting value via repeated small operations

### LP-07: Reserve factor application
- **What**: A percentage of interest income is retained as protocol reserves.
  Incorrect application can over-charge borrowers or under-fund reserves.
- **Grep**: `reserve_factor` `reserves` `protocol_fee` `treasury`
- **Verify**:
  1. Reserve factor is bounded (e.g., 0-50%)
  2. Reserves = accrued_interest * reserve_factor / PRECISION
  3. Reserves are minted as shares or tracked as separate balance
  4. Reserve withdrawal is access-controlled (admin/treasury only)
  5. Reserve factor change applies only to future interest (not retroactive)

### LP-08: Flash loan fee calculation
- **What**: Flash loans must charge correct fees and ensure repayment within
  the same transaction. Fee bypass or incomplete repayment drains the pool.
- **Grep**: `flash` `flash_loan` `flashLoan` `flash_fee` `FLASH`
- **Verify**:
  1. Fee = borrowed_amount * flash_fee_rate / PRECISION
  2. Post-execution balance >= pre-execution balance + fee
  3. Balance check uses actual token balance (not internal accounting)
  4. Callback is restricted to known interface (receiver must implement callback)
  5. Flash loan does not update internal borrow state (it's within one tx)
  6. Reentrancy guard prevents nested flash loans if not intended

### LP-09: Liquidity check before withdrawal
- **What**: Withdrawals must be rejected if available liquidity is insufficient.
  Available = total_deposits - total_borrows. Allowing withdrawal beyond this
  creates protocol insolvency.
- **Grep**: `available_liquidity` `cash` `getCash` `withdraw` `liquidity`
- **Verify**:
  1. Available liquidity = token.balanceOf(pool) or tracked idle balance
  2. Withdrawal reverts if amount > available liquidity
  3. Available liquidity accounts for pending interest accrual
  4. Multiple simultaneous withdrawals are handled correctly (no race)
  5. Strategy-deployed assets are not counted as available for instant withdrawal

### LP-10: Borrow cap enforcement
- **What**: Global and per-user borrow caps prevent concentration risk and
  limit protocol exposure. Missing enforcement allows unlimited borrowing.
- **Grep**: `borrow_cap` `borrowCap` `max_borrow` `MAX_BORROW`
- **Verify**:
  1. Global cap: total_borrows + new_borrow <= global_borrow_cap
  2. Per-user cap: user_borrows + new_borrow <= per_user_borrow_cap
  3. Cap of 0 means unlimited (or disabled) -- verify this semantic
  4. Cap check happens after interest accrual (includes accrued interest)
  5. Cap can be updated by admin but doesn't force liquidation of existing positions

### LP-11: Supply cap enforcement
- **What**: Supply caps limit total deposits to prevent overexposure to a single
  asset. Without caps, the protocol may take on unlimited risk.
- **Grep**: `supply_cap` `supplyCap` `max_supply` `deposit_cap` `MAX_DEPOSIT`
- **Verify**:
  1. total_deposits + new_deposit <= supply_cap
  2. Cap of 0 means unlimited (or disabled) -- verify semantic consistency with borrow cap
  3. Cap check uses total assets, not total shares
  4. Existing depositors can always withdraw regardless of cap
  5. Cap updates don't affect existing positions

### LP-12: Accrued interest in health factor
- **What**: Health factor calculations must use current debt (including accrued
  but uncollected interest), not the snapshot at borrow time.
- **Grep**: `health_factor` `is_healthy` `is_solvent` `borrow_balance`
- **Verify**:
  1. Borrow balance used in health check = principal * (current_index / borrow_index_at_borrow)
  2. Interest accrual is called or simulated before health check
  3. Both collateral value and debt value use current prices
  4. Health factor < 1 consistently triggers liquidation eligibility
  5. No path computes health factor with stale debt amounts

### LP-13: Repayment exceeding debt
- **What**: If a user attempts to repay more than their outstanding debt, the
  excess must be refunded or the repay amount capped. Absorbing the excess
  is user fund theft.
- **Grep**: `repay` `close_position` `repay_amount` `max_repay`
- **Verify**:
  1. If repay_amount > outstanding_debt, only outstanding_debt is transferred
  2. Or: excess is refunded to the user in the same transaction
  3. User's borrow balance is set to 0 (not negative)
  4. Total borrows is decreased by actual repay amount (not input amount)
  5. Using type(uint256).max or equivalent as repay amount means "repay all"

### LP-14: Zero-amount operation handling
- **What**: Depositing, withdrawing, borrowing, or repaying 0 should be handled
  consistently -- either revert or succeed as no-op without side effects.
- **Grep**: `amount == 0` `amount > 0` `require.*amount` `assert.*amount`
- **Verify**:
  1. Consistent behavior across all operations (all revert or all no-op)
  2. Zero deposit does not mint shares (division by zero risk)
  3. Zero withdraw does not burn shares
  4. Zero borrow does not create a borrow position
  5. Events are not emitted for zero-amount operations (if no-op approach)

### LP-15: Interest rate update atomicity
- **What**: When interest rates are recalculated (e.g., after a borrow changes
  utilization), all dependent state must update atomically. Partial updates
  create inconsistent accounting.
- **Grep**: `update_rate` `setRate` `_accrueInterest` `sync`
- **Verify**:
  1. Rate recalculation happens within the same transaction as the triggering operation
  2. Both borrow and supply rates update together
  3. Index snapshots are taken before rate change applies
  4. No external call between rate calculation and rate storage
  5. Rate update cannot be front-run to extract value

---

## Domain: External Protocol Integration (10 checks)

### EI-01: External call return value validation
- **What**: Calls to external contracts (token transfers, oracle reads, etc.)
  must check return values. Silently ignoring failures leads to state
  inconsistency.
- **Grep**: `raw_call` `extcall` `staticcall` `transfer` `transferFrom` `approve`
- **Verify**:
  1. ERC20 transfer/transferFrom return values are checked (True) or use safeTransfer
  2. Oracle calls check for valid response (price > 0, timestamp fresh)
  3. raw_call results are decoded and validated
  4. Failed external calls revert the transaction (not silently continue)
  5. Vyper `extcall` return values are explicitly handled

### EI-02: Reentrancy protection on external calls
- **What**: External calls transfer control to untrusted code. Without reentrancy
  guards, callbacks can re-enter the protocol in an intermediate state.
- **Grep**: `@nonreentrant` `reentrancy` `lock` `mutex` `ReentrancyGuard`
- **Verify**:
  1. All functions making external calls have `@nonreentrant` in Vyper
  2. Reentrancy lock key covers the right scope (per-function vs global)
  3. Checks-effects-interactions pattern followed (state updated before external call)
  4. Token transfers happen after all internal state updates
  5. Cross-function reentrancy considered (function A calls external, re-enters via function B)

### EI-03: Slippage protection on token swaps
- **What**: Any token swap operation must enforce minimum output amounts. Without
  slippage protection, MEV bots extract value via sandwich attacks.
- **Grep**: `swap` `amountOutMin` `min_out` `slippage` `minReturn`
- **Verify**:
  1. Swap functions accept a `min_amount_out` parameter
  2. min_amount_out is validated against actual received amount
  3. Caller (not contract) sets the min_amount_out (no hardcoded tolerance)
  4. Slippage tolerance is reasonable (not 0% which always reverts, not 100% which is no protection)
  5. Price impact is checked for large swaps

### EI-04: Deadline parameter on time-sensitive operations
- **What**: Operations that are price-sensitive must include a deadline parameter.
  Without deadlines, transactions can be held in the mempool and executed at
  unfavorable prices.
- **Grep**: `deadline` `expiry` `expires` `block.timestamp` `validUntil`
- **Verify**:
  1. Swap/trade functions accept a `deadline` parameter
  2. `require(block.timestamp <= deadline)` check present
  3. Deadline is set by the user (not hardcoded far in the future)
  4. Liquidation calls have reasonable timing constraints
  5. Governance proposals have execution windows

### EI-05: External protocol upgrade/migration impact
- **What**: If the protocol integrates with upgradeable external contracts (Aave,
  Compound, etc.), an upgrade to those contracts could break assumptions.
- **Grep**: `adapter` `bridge` `external` `aave` `compound` `morpho`
- **Verify**:
  1. External contract addresses are updatable by admin (with timelock)
  2. Interface assumptions are documented (which functions, which return types)
  3. Adapter pattern isolates external protocol changes from core logic
  4. Emergency pause can stop interaction with compromised external protocol
  5. Migration path exists if external protocol is deprecated

### EI-06: Token approval management
- **What**: Token approvals must be set before transfers and ideally revoked
  after or set to exact amounts. Infinite approvals to untrusted contracts
  are a standing vulnerability.
- **Grep**: `approve` `allowance` `safeApprove` `increaseAllowance` `MAX_UINT`
- **Verify**:
  1. Approvals are set before the operation that needs them
  2. Approval amount is exact (not infinite) where practical
  3. If infinite approval used, the approved contract is trusted and immutable
  4. USDT-style tokens handled (approve to 0 before setting new value)
  5. No orphaned approvals left after contract migration

### EI-07: External oracle manipulation resistance
- **What**: Price feeds from external oracles must resist manipulation. On-chain
  oracle (e.g., Uniswap TWAP) can be manipulated; Chainlink has latency.
- **Grep**: `oracle` `price_feed` `priceFeed` `getPrice` `latestAnswer`
- **Verify**:
  1. Oracle type appropriate for use case (Chainlink for lending, TWAP for governance)
  2. Price deviation check: reject prices that differ >X% from last known price
  3. Multiple oracle sources with fallback logic
  4. Circuit breaker on extreme price movements
  5. Oracle update frequency matches protocol's time sensitivity

### EI-08: Bridge/adapter callback validation
- **What**: When adapters or bridges call back into the protocol, the caller
  must be validated. Spoofed callbacks can report fake yields or trigger
  unauthorized state changes.
- **Grep**: `callback` `msg.sender` `on_` `hook` `notify`
- **Verify**:
  1. Callback functions check `msg.sender == authorized_adapter`
  2. Adapter addresses are set in constructor or by admin only
  3. Callback data is validated (amounts, addresses)
  4. Callback cannot be triggered externally by arbitrary callers
  5. Return values from callbacks are bounded and validated

### EI-09: Multi-step operation atomicity
- **What**: Operations spanning multiple external calls must be atomic. If step 2
  of 3 fails, steps 1's effects must be reverted. Partial execution leaves
  inconsistent state.
- **Grep**: `raw_call` `extcall` `try` `except` `success`
- **Verify**:
  1. Multi-step operations revert entirely if any step fails
  2. No state is persisted between steps that can't be rolled back
  3. If partial execution is intentional, state is consistent at each step
  4. External call failures are detected (not silently ignored)
  5. Gas limits on external calls are sufficient for the operation to complete

### EI-10: External contract existence check
- **What**: Calling a non-existent contract returns success with empty data in
  the EVM. Without existence checks, the protocol may assume operations
  succeeded when no code executed.
- **Grep**: `extcodesize` `code.length` `isContract` `raw_call`
- **Verify**:
  1. Before interacting with external contracts, existence is verified
  2. Vyper's `extcall` handles non-existent contracts (reverts on empty code)
  3. Token addresses are validated at configuration time
  4. Factory-deployed contracts are verified before interaction
  5. Self-destructed contracts are handled (address exists but code is gone)

---

## Domain: Access Control (8 checks)

### AC-01: Owner/admin privilege separation
- **What**: Different administrative roles must have separated privileges. A single
  all-powerful owner is a centralization risk; granular roles limit blast
  radius.
- **Grep**: `owner` `admin` `curator` `guardian` `role` `ADMIN` `OWNER`
- **Verify**:
  1. Roles are defined: owner (deploy/upgrade), admin (parameters), guardian (emergency)
  2. Each privileged function is restricted to the minimum necessary role
  3. Owner cannot bypass guardian emergency pause
  4. Curator (if exists) is limited to strategy/allocation management
  5. Role hierarchy is documented and enforced

### AC-02: Privileged function access modifiers
- **What**: Every function that modifies critical state must have an access
  control check. Missing modifiers allow anyone to call admin functions.
- **Grep**: `@internal` `@external` `assert msg.sender` `only_owner` `authorized`
- **Verify**:
  1. All state-modifying functions have explicit access checks
  2. Access checks are at the top of the function (fail fast)
  3. No public function lacks access control when it should have it
  4. Internal functions cannot be called externally
  5. Modifier patterns are consistent across the codebase

### AC-03: Role transfer mechanism
- **What**: Admin/owner role transfers must use a 2-step process (propose + accept)
  to prevent accidental transfer to wrong address.
- **Grep**: `transfer_ownership` `pending_owner` `accept_ownership` `set_admin`
- **Verify**:
  1. Two-step transfer: propose new owner, new owner accepts
  2. Pending owner can be overwritten (cancel/replace proposal)
  3. Old owner retains privileges until new owner accepts
  4. Zero address transfer is blocked (would brick the contract)
  5. Transfer events emitted for off-chain tracking

### AC-04: Timelock on sensitive parameter changes
- **What**: Changes to critical parameters (fees, collateral factors, oracle
  addresses) should be timelocked to give users time to react.
- **Grep**: `timelock` `delay` `pending_` `scheduled` `queue`
- **Verify**:
  1. Sensitive parameters have a proposal → delay → execution pattern
  2. Delay is >= 24 hours for critical parameters (oracle, fees, caps)
  3. Pending changes can be cancelled by admin
  4. Timelock cannot be bypassed except via emergency mechanism
  5. Events emitted on proposal and execution

### AC-05: Emergency pause mechanism
- **What**: A guardian role must be able to pause the protocol immediately in
  case of exploit or critical bug. Pause should stop new actions but allow
  withdrawals.
- **Grep**: `pause` `paused` `emergency` `guardian` `circuit_breaker`
- **Verify**:
  1. Pause function exists and is restricted to guardian role
  2. When paused: deposits, borrows, and new positions blocked
  3. When paused: withdrawals, repayments, and exits still allowed
  4. Unpause is restricted to owner/admin (not guardian alone)
  5. Pause state is checked at the start of each affected function

### AC-06: Parameter bounds on admin-settable values
- **What**: Admin-configurable parameters must have enforced bounds. Unbounded
  parameters allow setting 100% fees, 0% collateral factors, etc.
- **Grep**: `set_fee` `set_` `update_` `MAX_` `MIN_` `BOUND`
- **Verify**:
  1. Fee rates bounded: 0 <= fee <= MAX_FEE (e.g., 50%)
  2. Interest model parameters bounded within reasonable ranges
  3. Collateral factors bounded: 0 <= CF <= MAX_CF
  4. Timelock durations bounded: MIN_DELAY <= delay <= MAX_DELAY
  5. Explicit revert messages on bound violations

### AC-07: Fee recipient address validation
- **What**: Fee recipient (treasury, protocol) address must not be zero. Sending
  fees to zero address burns them permanently.
- **Grep**: `fee_recipient` `treasury` `feeRecipient` `protocol_fee_to`
- **Verify**:
  1. Fee recipient setter checks `new_recipient != empty(address)`
  2. Constructor/initialization sets a valid fee recipient
  3. Fee recipient change is access-controlled
  4. Accumulated fees are withdrawable by fee recipient only
  5. Fee recipient can be updated without losing accrued fees

### AC-08: Initialization protection
- **What**: Initializer functions (used in proxy patterns) must only execute
  once. Re-initialization allows an attacker to reset owner, parameters,
  and steal funds.
- **Grep**: `__init__` `initialize` `initializer` `initialized` `_init_`
- **Verify**:
  1. `initialized` flag set in constructor/initializer
  2. Initializer checks `not self.initialized` or equivalent
  3. Implementation contract (behind proxy) is also initialized
  4. No function can reset the initialized state
  5. Critical state (owner, token) set during initialization cannot be changed

---

## Domain: Token Handling (8 checks)

### TH-01: Fee-on-transfer token compatibility
- **What**: Some tokens deduct a fee on transfer, so received amount < sent
  amount. Using the sent amount in accounting creates phantom balances.
- **Grep**: `transferFrom` `transfer` `balanceOf` `amount` `received`
- **Verify**:
  1. Actual received amount checked: `balance_after - balance_before`
  2. Internal accounting uses actual received amount, not parameter amount
  3. Fee-on-transfer behavior documented (supported or explicitly excluded)
  4. Tests exist with fee-on-transfer mock tokens
  5. Share calculations use actual transferred amounts

### TH-02: Rebasing token handling
- **What**: Rebasing tokens (stETH, AMPL) change balances automatically. Caching
  balances becomes incorrect after a rebase.
- **Grep**: `balanceOf` `cached_balance` `stored_balance` `total_assets`
- **Verify**:
  1. Protocol uses `token.balanceOf(self)` for current balance (not cached)
  2. Or: protocol explicitly does not support rebasing tokens (documented)
  3. Share-based accounting (not balance-based) if rebasing tokens supported
  4. Rebase events don't break interest calculations
  5. Negative rebases handled (balance decreases)

### TH-03: ERC20 approve race condition
- **What**: Changing allowance from N to M allows a spender to spend N + M via
  front-running. Must approve to 0 first or use increaseAllowance.
- **Grep**: `approve` `allowance` `increaseAllowance` `decreaseAllowance`
- **Verify**:
  1. Approval pattern: approve(0) then approve(amount), or use increaseAllowance
  2. Infinite approval (MAX_UINT) avoids the issue for trusted contracts
  3. User-facing approval functions document the race condition
  4. Protocol's internal approvals use safe patterns
  5. USDT-specific: must approve(0) before approve(n) (reverts otherwise)

### TH-04: Token decimal normalization
- **What**: Tokens have varying decimals (USDC=6, WETH=18, WBTC=8). All
  calculations must normalize to a common precision to avoid
  over/under-valuation.
- **Grep**: `decimals` `decimal` `10 **` `pow` `PRECISION` `normalize`
- **Verify**:
  1. Token decimals are read at deployment and stored
  2. Price calculations normalize: `value = amount * price / 10**(token_decimals + price_decimals - target_decimals)`
  3. No hardcoded 18-decimal assumption for all tokens
  4. Precision loss is minimized (multiply before divide)
  5. Cross-token calculations (e.g., collateral value vs debt value) use consistent decimals

### TH-05: Non-standard ERC20 handling
- **What**: Some widely-used tokens don't fully comply with ERC20. USDT doesn't
  return bool on transfer. BNB has approval race. Missing handlers cause
  reverts or silent failures.
- **Grep**: `transfer` `approve` `USDT` `safeTransfer` `raw_call`
- **Verify**:
  1. Transfer calls handle missing return value (USDT, BNB)
  2. Vyper's `extcall` with explicit return type handles this
  3. Or: raw_call used with return data length check
  4. Approval to non-zero for tokens that require approve(0) first
  5. List of supported tokens is documented with known quirks

### TH-06: Token blacklist/blocklist impact
- **What**: USDC and USDT can blacklist addresses, blocking all transfers to/from
  that address. If the protocol address is blacklisted, all funds are frozen.
- **Grep**: `blacklist` `blocklist` `frozen` `USDC` `USDT` `centre`
- **Verify**:
  1. Protocol acknowledges blacklist risk for stablecoins
  2. Multiple withdrawal addresses or intermediary contracts reduce risk
  3. User funds are not permanently locked if protocol address is blacklisted
  4. Blacklisted user can still have their position liquidated (by others)
  5. Emergency withdrawal to alternative address is available

### TH-07: Wrapped native token handling
- **What**: WETH/WMATIC etc. must be handled consistently. Mixed native/wrapped
  handling creates edge cases in deposit, withdrawal, and accounting.
- **Grep**: `WETH` `weth` `native` `msg.value` `deposit()` `withdraw()`
- **Verify**:
  1. Protocol uses only wrapped version (not mixed native + wrapped)
  2. If accepting native: wrapping happens atomically in the deposit function
  3. msg.value matches expected deposit amount (no excess native token)
  4. Withdrawal can optionally unwrap to native (user choice)
  5. No native token can be trapped in the contract

### TH-08: Zero-address token transfer prevention
- **What**: Transfers to address(0) typically burn tokens. Accidental transfers
  to zero address cause permanent fund loss.
- **Grep**: `empty(address)` `ZERO_ADDRESS` `address(0)` `transfer`
- **Verify**:
  1. Recipient address checked: `assert recipient != empty(address)`
  2. Token address validated at configuration time
  3. Fee recipient validated (see AC-07)
  4. Withdrawal `to` parameter validated
  5. Strategy/adapter target addresses validated

---

## Domain: Economic Attacks (10 checks)

### EA-01: Flash loan attack resistance
- **What**: Flash loans allow borrowing unlimited capital for a single transaction.
  Protocols must not assume economic actions are capital-constrained.
- **Grep**: `flash` `flashLoan` `balanceOf` `totalSupply` `price`
- **Verify**:
  1. Price oracles resist single-block manipulation (see CL-11)
  2. Governance voting requires time-weighted balance (not snapshot at vote time)
  3. Liquidity-dependent calculations use time-weighted values
  4. Share minting uses pre-deposit exchange rate (not post-deposit)
  5. Protocol cannot be drained via borrow → manipulate → repay in one tx

### EA-02: Sandwich attack mitigation
- **What**: MEV searchers can front-run and back-run user transactions to extract
  value from swaps. Protocol-initiated swaps must have slippage protection.
- **Grep**: `swap` `trade` `exchange` `amountOut` `slippage`
- **Verify**:
  1. All swap operations have minimum output amount parameter
  2. Swap deadline prevents execution in future blocks at stale prices
  3. Private mempool or commit-reveal for sensitive operations
  4. Batch auctions or Dutch auctions for liquidations
  5. User-specified slippage tolerance (not protocol-hardcoded)

### EA-03: Front-running protection on liquidations
- **What**: Liquidation opportunities can be front-run by MEV bots. The protocol
  should ensure fair liquidation regardless of who executes it.
- **Grep**: `liquidat` `seize` `bonus` `incentive` `priority`
- **Verify**:
  1. Liquidation bonus is fixed by protocol (not bidder-determined)
  2. Partial liquidation is allowed (prevents all-or-nothing race)
  3. No advantage from being first (same bonus regardless of timing)
  4. Liquidation cannot be sandwiched to extract additional value
  5. Gas optimization doesn't compromise correctness

### EA-04: Interest rate manipulation
- **What**: Large deposits or withdrawals can manipulate utilization rate and
  thus interest rates. A whale can spike rates to force liquidations or
  drop rates to reduce yield.
- **Grep**: `utilization` `interest_rate` `deposit` `withdraw` `borrow`
- **Verify**:
  1. Interest rate changes are bounded per block/time period
  2. Rate smoothing prevents instant jumps from single transactions
  3. Utilization-based rate curves have reasonable kink points
  4. Flash-loan deposit cannot meaningfully change long-term rates
  5. Rate manipulation cost exceeds potential profit

### EA-05: Share/token inflation attack (first depositor)
- **What**: First depositor can donate tokens to inflate share price, causing
  subsequent depositors to receive 0 shares (rounding to 0). Classic
  ERC4626 vulnerability.
- **Grep**: `deposit` `mint` `totalSupply` `totalAssets` `virtual` `offset`
- **Verify**:
  1. Virtual shares/assets offset implemented (e.g., 10**decimals_offset)
  2. Or: minimum first deposit enforced (e.g., >= 1000 units)
  3. Or: dead shares minted to zero address on first deposit
  4. Share minting formula handles totalSupply == 0 edge case
  5. Donation to vault contract cannot be weaponized

### EA-06: MEV extraction impact
- **What**: Miner/validator extractable value through transaction reordering,
  insertion, or censorship. Protocol design should minimize MEV surface.
- **Grep**: `block.timestamp` `block.number` `tx.origin` `coinbase`
- **Verify**:
  1. Time-dependent logic has tolerance for block timestamp manipulation
  2. No operations depend on transaction ordering within a block
  3. Liquidation mechanisms are MEV-resistant (see EA-03)
  4. Commit-reveal patterns used where ordering matters
  5. Protocol does not rely on `tx.origin` for any logic

### EA-07: Protocol insolvency handling
- **What**: Bank run scenarios where all depositors try to withdraw
  simultaneously. Protocol must handle graceful degradation when
  assets < liabilities.
- **Grep**: `insolvency` `shortfall` `bad_debt` `bank_run` `queue` `withdraw`
- **Verify**:
  1. Withdrawal queue or pro-rata withdrawal when liquidity insufficient
  2. Deployed assets can be recalled (with time delay)
  3. Share redemption is proportional (no first-come-first-served drain)
  4. Insurance fund or reserve provides buffer
  5. Protocol can operate in degraded mode (no new deposits, withdrawals only)

### EA-08: Fee extraction attack
- **What**: Manipulating the fee calculation basis to either avoid fees or
  extract excess value. Examples: depositing right before fee snapshot,
  withdrawing right after.
- **Grep**: `fee` `performance_fee` `management_fee` `accrue_fee`
- **Verify**:
  1. Fees accrue continuously (not at discrete snapshots)
  2. Fee basis cannot be manipulated by timing deposits/withdrawals
  3. Performance fees use high-water mark (prevents fee on recovered losses)
  4. Management fees are time-weighted (pro-rata)
  5. Fee calculation cannot overflow or underflow

### EA-09: Governance attack via flash-borrowed voting power
- **What**: Flash loans can temporarily acquire governance tokens to pass
  proposals in a single transaction. Voting must require time commitment.
- **Grep**: `vote` `governance` `proposal` `delegate` `voting_power`
- **Verify**:
  1. Voting power is snapshot-based (not current balance)
  2. Snapshot is taken before proposal creation (not at vote time)
  3. Minimum holding period before voting power activates
  4. Delegation requires time commitment
  5. Quorum prevents low-participation attacks

### EA-10: Price oracle manipulation via pool liquidity
- **What**: AMM pool prices can be manipulated by trading large amounts. If the
  protocol uses pool prices for valuations, attackers can create artificial
  price movements.
- **Grep**: `getReserves` `slot0` `observe` `consult` `pool_price`
- **Verify**:
  1. Pool-based prices use TWAP over sufficient window
  2. Multi-source price validation (pool + Chainlink + fallback)
  3. Price deviation circuit breaker (reject extreme changes)
  4. Protocol's own operations don't influence its price oracle
  5. Low-liquidity pools are not used as primary price source
