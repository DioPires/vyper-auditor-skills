# Vyper 0.4.x Language Edges

15 Vyper 0.4.x behaviors that change risk analysis compared to Solidity.

These are auditor gotchas: language semantics that shift the threat model in ways
that Solidity-trained auditors may not expect. Each entry explains the audit impact,
the key difference from Solidity or pre-0.4.0 Vyper, and specific code patterns to check.

---

## 1. Checked Arithmetic
- **Audit impact**: Overflow/underflow = revert (DoS), not value corruption. The threat model
  shifts from "attacker gets wrong value" to "attacker triggers permanent revert." Critical
  in withdrawal paths, liquidation functions, and any operation that must not be blockable.
  Every arithmetic operation is a potential DoS vector if operands are attacker-influenced.
  Unlike Solidity, there is no `unchecked` escape hatch — when you need wrapping behavior
  for gas counters or hash computations, you must use `unsafe_add`/`unsafe_sub`/`unsafe_mul`/
  `unsafe_div`, which have their own risks (see VYP-37 for evaluation order issues).
- **Key difference**: Solidity requires explicit `unchecked {}` to disable overflow checks
  (since 0.8.0). Vyper has no equivalent block scope — arithmetic is always checked globally.
  The `unsafe_*` builtins exist but are per-operation, not per-block. Pre-0.4.0 Vyper also had
  checked arithmetic, so this is consistent but worth emphasizing for Solidity auditors who
  rely on `unchecked` blocks for gas-sensitive math.
- **Watch for**: Functions where revert is worse than a wrong value (withdrawal DoS). Subtraction
  on user-influenced values without prior bounds check. Multiplication that could overflow with
  large token amounts or prices. Accumulator patterns approaching `max_value(uint256)`. Fee
  calculations where `amount * fee_bps / 10000` can overflow for large amounts.

## 2. convert() Is Checked
- **Audit impact**: Type conversions that silently truncate or wrap in Solidity will revert in
  Vyper. Most dangerous case: `convert(int256, uint256)` reverts on negative input. When the
  int256 comes from Chainlink (which returns int256 prices) or user input, a negative value
  permanently blocks the function. This is a DoS vector, not a value integrity issue.
- **Key difference**: Solidity's `uint256(int256Value)` silently reinterprets bits — negative
  becomes huge positive. Vyper's `convert()` reverts. Safer for value integrity but creates
  a new availability attack surface. No way to do unchecked conversion in Vyper.
- **Watch for**: `convert()` on user-supplied values or oracle returns. Any `convert()` in a
  critical path (withdrawals, liquidations) where revert = DoS. Chainlink `latestRoundData()`
  returning int256 price converted to uint256 without positivity check.

## 3. No Inheritance — Modules via initializes/exports
- **Audit impact**: Vyper has no class inheritance. Code reuse uses modules with explicit
  `initializes:`, `uses:`, and `exports:`. The auditor must verify three things that are
  automatic in Solidity: (1) modules are actually initialized, (2) initialization order
  satisfies dependencies, (3) external functions are exported. Silent failures are common
  and dangerous — missing `exports:` removes functions from the ABI without any compiler
  warning, and missing `initializes:` leaves module state at zero defaults (e.g., owner =
  address(0), which may cause access control to accept the zero address as authorized).
  The module system is Vyper 0.4.x's biggest architectural departure from both Solidity
  and pre-0.4.0 Vyper. Auditors must build a mental model of the module dependency graph.
- **Key difference**: Solidity inheritance auto-includes parent constructors and exposes
  public/external functions. Vyper requires explicit opt-in for everything. Storage layout
  is also explicit — modules declare their own slots, `initializes:` copies layout into the
  contract. There is no virtual/override mechanism; module functions are either exported
  as-is or replaced with the contract's own implementation.
- **Watch for**: Missing `exports:` for module `@external` functions (VYP-29). Wrong
  `initializes:` order (VYP-27). `uses:` without `initializes:` (VYP-28 — owner = address(0)).
  Modules that define storage but are never initialized. Contracts that import a module but
  neither `initializes:` nor `uses:` it (dead code that confuses reviewers).

## 4. default_return_value for Non-Compliant Tokens
- **Audit impact**: Vyper's `extcall` is strict: if interface declares a return type but callee
  returns nothing, the call reverts. Breaks USDT and other non-compliant ERC20s that don't
  return bool. The fix is per-call — every individual `extcall` needs `default_return_value=True`.
  Missing it on a single call breaks the entire contract for non-compliant tokens.
- **Key difference**: Solidity's low-level `.call()` doesn't enforce return types. OpenZeppelin's
  `SafeERC20` wraps this. Vyper has no SafeERC20 equivalent — the developer must add
  `default_return_value=True` on every ERC20 interaction individually.
- **Watch for**: `extcall` to ERC20 transfer/transferFrom/approve without `default_return_value=True`.
  Contracts claiming arbitrary ERC20 support but missing the parameter on some calls. Newly
  added functions that copy-paste extcall patterns but forget the parameter.

## 5. File-Level Nonreentrancy Pragma
- **Audit impact**: `#pragma nonreentrancy on` applies to ALL state-mutating externals in the
  file. No per-function opt-out. Creates a hard choice for callback contracts: protect everything
  (blocking callbacks) or protect nothing. Contracts needing both protection and callbacks
  must use CEI ordering without the pragma and document the reentrancy safety argument.
- **Key difference**: Solidity's `nonReentrant` is per-function and opt-in. Pre-0.4.0 Vyper used
  `@nonreentrant("lock")` per function with named keys. The 0.4.x pragma simplifies but removes
  all granularity — it's all-or-nothing at the file level.
- **Watch for**: Contracts needing callbacks (adapter pattern, flash loans, ERC-777) that use
  the pragma — callbacks will revert. Contracts omitting pragma for callbacks but losing all
  protection. Mixed patterns where some functions need guards and others need callbacks.

## 6. raw_call Returns (bool, Bytes)
- **Audit impact**: `raw_call` returns `(bool, Bytes[...])`. The bool indicates success. Must
  always be checked or `revert_on_failure=True` must be set. Ignoring the bool is a silent
  failure — contract continues as if call succeeded when it didn't. No linting ecosystem
  catches this in Vyper, unlike Solidity where `require(success)` is well-established.
- **Key difference**: Solidity's `.call()` also returns `(bool, bytes)` but the `require(success)`
  pattern is industry standard. Vyper's `revert_on_failure=True` parameter is a cleaner
  alternative that Solidity lacks, but must be explicitly opted into.
- **Watch for**: `raw_call` without `revert_on_failure=True` where bool is not captured.
  Functions destructuring only the bytes and ignoring the bool. Copy-pasted patterns where
  some instances check and others don't.

## 7. Immutables — Set Once, No Runtime Validation
- **Audit impact**: Set in `@deploy`/`__init__`, cannot change. No post-deploy fix — wrong value
  requires full redeployment. Deploy-time validation is the only defense. Audit must verify
  both contract-level assertions and deploy script parameter validation.
- **Key difference**: Solidity immutables work the same, but Solidity more commonly uses
  initializer patterns (upgradeable proxies) allowing re-init. Vyper strongly favors
  non-upgradeable contracts, making deploy-time validation the sole checkpoint.
- **Watch for**: Zero-address immutables (token, oracle, owner permanently address(0)). Missing
  validation in `@deploy`. Deploy scripts without constructor argument validation. Fee
  percentages without range checks (permanently set to 100%).

## 8. DynArray — O(n) Ops, Fixed Max, Panic on Overflow
- **Audit impact**: Three risks: (1) append beyond capacity = panic revert (DoS), (2) pop on
  empty array = panic revert, (3) iteration is O(n) and unbounded if max is large. Attackers
  who can grow the array can cause permanent DoS. The fixed max is both protection (bounded
  growth) and attack surface (fill to capacity, all future appends fail permanently). Unlike
  Solidity mappings, there is no O(1) key-value alternative in Vyper — DynArray is the only
  variable-length collection, so many patterns that would use mappings in Solidity must use
  DynArrays with iteration, increasing gas costs and DoS surface.
- **Key difference**: Solidity arrays grow without hard cap (gas-limited only). Vyper enforces
  compile-time maximum — prevents unbounded growth but creates a fixed DoS target. Solidity
  doesn't have this specific "fill the array" DoS vector. Additionally, Vyper DynArrays are
  memory-backed for local variables (not storage-backed), so large local DynArrays can hit
  memory expansion costs.
- **Watch for**: Unbounded append in loops with attacker-controlled count. Small-capacity
  DynArrays fillable by permissionless operations. No removal mechanism (only append, never
  pop). Iteration over large DynArrays in gas-sensitive functions. `pop()` without
  `len(arr) > 0` check. Withdrawal queues or market lists as DynArrays.

## 9. No Fallback/Receive — Only Explicit @payable
- **Audit impact**: Vyper contracts reject ETH unless an `@payable` function exists. No implicit
  `receive()`. Contracts that should accept ETH must explicitly handle it. ETH from
  `selfdestruct` (deprecated but still functional) or coinbase block rewards accumulates in the
  contract without a withdrawal mechanism, creating permanently trapped value. Only `__default__`
  handles both unmatched selectors and plain ETH transfers — there is no way to differentiate
  between "user sent ETH" and "user called a non-existent function with value."
- **Key difference**: Solidity separates `receive()` (plain ETH, no calldata) and `fallback()`
  (unmatched selector or calldata present). Vyper merges both into `__default__`. Cannot
  accept plain ETH transfers while rejecting calls with bad selectors, or vice versa. This
  limits flexibility for contracts that need nuanced ETH handling.
- **Watch for**: Contracts that should receive ETH but lack `@payable` — ETH transfers revert.
  Trapped ETH from selfdestruct/coinbase without sweep mechanism. `__default__` triggered by
  mistyped function calls (user calls wrong function name, hits default). Vaults or bridges
  that need to hold ETH. WETH unwrap patterns that need to receive ETH.

## 10. Module Storage Layout
- **Audit impact**: `initializes:` copies module state into contract storage. Declaration order
  determines slot assignment. Reordering in refactor/upgrade silently moves state to wrong
  slots, corrupting all existing storage. Cross-module init dependencies produce zero reads
  if order is wrong.
- **Key difference**: Solidity uses C3 linearization for deterministic layout based on inheritance
  graph. Vyper's layout is ordered by `initializes:` declaration order — more explicit but
  fragile. Simple reordering breaks storage compatibility.
- **Watch for**: Multiple `initializes:` — verify order matches existing deployment layout.
  Cross-module deps where Module B reads Module A's state during init. Upgradeable patterns
  requiring preserved module order across versions.

## 11. extcall/staticcall Syntax
- **Audit impact**: Vyper 0.4.x uses explicit `extcall`/`staticcall` keywords, making external
  call boundaries visually obvious. This aids auditing — every external interaction is
  syntactically distinct. However, `extcall` doesn't auto-handle non-compliant returns (see
  edge #4), and calls to EOAs succeed silently (no code = success with empty return).
- **Key difference**: Solidity uses same `.function()` syntax for internal and external calls,
  making boundaries harder to spot. Vyper's explicit syntax is an auditing advantage.
  `revert_on_failure` and `default_return_value` parameters have no Solidity equivalent.
- **Watch for**: `extcall` to untrusted addresses without return handling. `staticcall` where
  `extcall` is needed (state-changing call via staticcall reverts at EVM level). Missing
  `default_return_value=True` on ERC20 calls. `extcall` to EOA succeeding silently.

## 12. Transient Keyword (EIP-1153)
- **Audit impact**: Native `transient` keyword for EIP-1153. Cheaper than regular storage
  (TSTORE: 100 gas vs SSTORE: 5000+ gas) but with dangerous semantics that break common
  assumptions. Two critical behaviors: (1) transient storage persists for the entire
  transaction, not just the current call frame — stale values leak between calls in the same
  tx, (2) TSTORE operations are NOT rolled back when a sub-call reverts — reverted sub-calls
  leave transient side effects. Most developers assume revert = no side effects, but TSTORE
  breaks this. The combination makes transient storage especially risky in multicall, batch
  execution, and flash loan patterns.
- **Key difference**: Solidity has no native transient syntax (requires inline assembly with
  TSTORE/TLOAD opcodes). Vyper makes it a first-class keyword, encouraging wider use but also
  increasing the attack surface. The non-revert behavior is surprising for all developers
  regardless of language background.
- **Watch for**: Stale transient state between external calls in same tx. Multicall/batch
  patterns where transient state from call N affects call N+1. Flash loan callbacks where
  transient state persists after revert. Transient vars not cleared on all exit paths
  (including early returns and error branches). Reentrancy locks using transient storage
  (see edge #13).

## 13. @nonreentrant Uses TSTORE
- **Audit impact**: Reentrancy lock via TSTORE costs 100 gas. The 2300 gas stipend from
  `send()` is enough to execute TSTORE in the callee, enabling bypass of the reentrancy
  guard. Novel attack vector unique to Vyper 0.4.x. Any contract using both `send()` and
  `@nonreentrant` is potentially vulnerable.
- **Key difference**: Solidity's OpenZeppelin `nonReentrant` uses SSTORE (5000+ gas), safe
  against 2300 gas stipend. Pre-0.4.0 Vyper also used SSTORE. The 0.4.x switch to TSTORE
  is a gas optimization that introduced a security regression for `send()` users.
- **Watch for**: `send()` combined with `@nonreentrant` in same contract. ETH transfers to
  untrusted recipients via `send()`. Contracts migrating from pre-0.4.0 that relied on
  `send()` being safe. Replace with `raw_call` value transfer.

## 14. Decimal Type Is Opt-In
- **Audit impact**: `decimal` (fixed-point, 10 decimal places) requires `#pragma: use_decimal`.
  Underused and less battle-tested. `sqrt()` has rounding bugs in 0.4.0 (VYP-33). Fixed
  precision may not suit all financial calculations. Most Vyper DeFi uses uint256 with manual
  scaling instead. When present, verify precision and rounding direction.
- **Key difference**: Solidity has no native fixed-point type. Vyper's decimal is unique but
  niche. The opt-in pragma means auditors should check whether it's enabled and, if so,
  scrutinize all decimal arithmetic for precision loss.
- **Watch for**: Financial calculations using `decimal` — verify precision covers token
  decimals. `sqrt()` on decimal in 0.4.0 (rounding bug). Mixing `decimal` and `uint256` in
  same calculation. Contracts enabling `use_decimal` but using it in only one place.

## 15. create_from_blueprint (ERC-5202)
- **Audit impact**: Factory pattern deploying new contracts from a deployed blueprint. The
  blueprint must have an ERC-5202 preamble (`0xFE7100` prefix) that makes it non-callable
  directly (starts with `INVALID` opcode). The `code_offset` parameter must match the
  preamble length — wrong offset deploys bytecode starting from the wrong position, producing
  a broken contract that may appear to deploy successfully. Blueprint address should be
  immutable to prevent implementation swaps that could deploy malicious contracts through
  an otherwise trusted factory.
- **Key difference**: Solidity factories use `new Contract()` which embeds init code in the
  factory's own bytecode. Vyper separates init code into a standalone "blueprint" deployment,
  making factories more gas-efficient (factory bytecode is smaller) but adding a runtime
  dependency on the blueprint contract's address and integrity. The ERC-5202 preamble
  requirement has no Solidity equivalent — it's unique to the blueprint pattern.
- **Watch for**: Blueprint address mutability — should be immutable, validated at deploy.
  `code_offset` matching actual preamble length (default is 3 for standard ERC-5202).
  Constructor args matching blueprint's `@deploy` signature (type mismatches may not revert
  cleanly). Blueprint verified on-chain with ERC-5202 preamble. Mutable blueprint addresses
  enabling malicious implementation swap. Factory contracts that don't validate the deployed
  contract's initialization succeeded.
