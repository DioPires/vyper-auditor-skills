# Rationalizations to Reject

When auditing, these common rationalizations must be challenged, not accepted. Each has caused real bugs to be missed in production systems.

Based on Trail of Bits "Building Secure Contracts" — adapted for Vyper DeFi vault auditing.

**How to use this file**: Before downgrading or dismissing any finding, check it against these 10 rationalizations. If your reasoning matches one, escalate instead of dismissing. Document the rationalization you almost accepted in your finding notes.

---

## 1. "Only the owner can call this"

**Rationalization**: The function has access control, so it's safe.

**Rejected because**: Owner compromise is in-scope for security audits. Compromised keys, social engineering, insider threats, and governance attacks can all give an attacker owner privileges. Functions callable only by owner should still be analyzed for what damage an attacker with owner access could inflict. Multi-sig schemes reduce but don't eliminate this — threshold signatures have been compromised (Ronin, Harmony Horizon).

**Real example**: Bridge contracts (S01/S02 findings) — owner-only functions `set_aave_pool` and `set_morpho` allow the owner to redirect all protocol interactions to a malicious contract. If the owner key is compromised, the attacker replaces the real Aave/Morpho pool with a draining contract. Every subsequent vault operation sends funds to the attacker.

**Instead**: Document the damage potential as ACKNOWLEDGED risk. Map owner privilege escalation paths. Quantify "blast radius" — what is the maximum loss from a compromised owner key? Include this in the Trust Assumptions Matrix.

---

## 2. "The amount is bounded by a cap"

**Rationalization**: There's an upper bound on the value, so overflow/DoS isn't possible.

**Rejected because**: The bound itself may BE the attack vector. Caps create exhaustion attacks: if an attacker can fill the cap cheaply, legitimate users are permanently blocked. Fixed-size arrays, counters with maximums, and rate limits all create cap-based DoS surfaces.

**Real example**: V-H3 — `LendingVaultFactory.vy` uses `DynArray[address, 1000]` for `_vaults_by_asset` and `_vaults_by_curator`. The 1001st `append` panics. An attacker deploys 1000 dust vaults for USDC (minimal gas cost per deployment), permanently blocking `deploy_vault` for that asset. The cap that was meant to be "generous enough" became the exact DoS vector.

**Instead**: Ask: can an attacker fill this cap? What is the cost? Is it permissionless? If filling the cap is cheaper than the damage it causes, it's exploitable. Consider unbounded structures (HashMap with counter) or require stake/deposits to consume capacity.

---

## 3. "The token is trusted / well-known"

**Rationalization**: We only support USDC/WETH/DAI, so we don't need to handle weird token behavior.

**Rejected because**: Even "trusted" tokens have non-standard behavior. USDT doesn't return `bool` on `transfer`/`approve` (needs `default_return_value=True` in Vyper). USDC has a blocklist that can freeze vault funds. DAI has a permit function with non-standard nonce behavior. Tokens can be upgraded (USDC is proxied). Fee-on-transfer tokens cause accounting mismatches. Rebasing tokens (stETH) break balance-based accounting.

**Real example**: A-M4 — Both `AavePoolBridge.vy` and `MorphoBridge.vy` use `raw_call` for `transferFrom` without checking the return value. If the vault ever supports USDT (which returns no value on success but doesn't revert on failure in some edge cases), shares get credited without tokens actually transferring. The bridge thinks it received funds; it didn't.

**Instead**: Enumerate every token behavior that could affect your contract: no-return, blocklist, fee-on-transfer, rebasing, upgradeable proxy, permit quirks. Test with actual token contracts, not mocks. Document supported token assumptions explicitly.

---

## 4. "Gas cost makes the attack impractical"

**Rationalization**: The attack requires too many transactions or too much gas to be economically viable.

**Rejected because**: L2 gas is 100-1000x cheaper than L1. An attack that costs $50,000 in gas on Ethereum mainnet costs $50-500 on Arbitrum or Optimism. Base, zkSync, and other L2s are even cheaper. Gas cost analysis MUST specify which chain and include L2 pricing. Additionally, gas costs trend downward over time — an attack impractical today may become trivial after EIP-4844 blob fee reductions.

**Real example**: Withdrawal queue DoS — an attacker fills the queue with dust withdrawal requests. Processing the queue iterates over all entries. On L1, filling 1000 queue entries costs significant gas. On Arbitrum/Optimism, the same attack costs under $10. The queue processing then consumes excessive gas on every deposit/mint, potentially bricking the vault.

**Instead**: Always price attacks at L2 gas rates. If the protocol will deploy on L2 (or might in the future), use L2 costs as the baseline. Express attack cost as a ratio: attacker_cost / victim_loss. If ratio < 1, it's profitable regardless of absolute gas cost.

---

## 5. "The contract has `#pragma nonreentrancy on`"

**Rationalization**: Vyper's built-in reentrancy guard protects all state-mutating functions.

**Rejected because**: Vyper's `#pragma nonreentrancy on` (or `@nonreentrant` in older versions) only prevents re-entering the SAME contract. Cross-contract reentrancy — where Contract A calls Contract B, which calls back into Contract C that reads stale state from Contract A — is not prevented. In a multi-contract system (vault + adapter + bridge + strategy), the reentrancy surface is the entire call graph, not individual contracts.

**Real example**: `P2PLendingAdapter.vy` deliberately omits `#pragma nonreentrancy on` because its callback pattern (`on_loan_created`, `on_settlement`) requires being called by registered markets during execution. The vault's reentrancy guard on `LendingVault.vy` does NOT protect the adapter — an attacker who re-enters through the adapter during a vault operation can manipulate `active_exposure` or `total_deployed` while the vault's state is inconsistent.

**Instead**: Map the full cross-contract call graph. Identify every external call and what state it assumes is consistent. Check read-after-write patterns across contract boundaries. Consider checks-effects-interactions at the SYSTEM level, not just the contract level.

---

## 6. "This is a known design decision"

**Rationalization**: The team already knows about this. It's intentional. No need to report it.

**Rejected because**: "Known" does not mean "documented" or "risk-accepted." A finding that exists in the team's mental model but not in written documentation will be forgotten when team members leave, when new developers join, or during incident response under pressure. Audits serve as external documentation — every risk should be captured regardless of whether the team is aware.

**Real example**: V-C1 — Unlimited ERC20 approvals (`max_value(uint256)`) granted to every registered adapter and yield strategy. The team knows this and considers it a "deferred to v2" design choice. But without formal documentation, a future developer might assume adapters are sandboxed. The audit report captures: a compromised adapter calls `ERC20.transferFrom(vault, attacker, vault_balance)` directly, bypassing all vault accounting. This is now permanently documented.

**Instead**: Report the finding with status ACKNOWLEDGED. Include the design rationale if known. Document the risk: what happens if this assumption is violated? Let the team formally accept the risk in writing. This protects both the team and future auditors doing delta analysis.

---

## 7. "The strategy/adapter/bridge is trusted"

**Rationalization**: The component is deployed by the protocol team and assumed to be correct.

**Rejected because**: "Trusted" components are the highest-value targets for attackers precisely because they have elevated privileges. A compromised adapter with unlimited approval can drain the entire vault. Bugs in trusted components are more dangerous than bugs in untrusted ones because trusted components bypass safety checks. Trust boundaries should be analyzed for what happens when trust is violated.

**Real example**: V-C1 — `LendingVault.vy` grants `max_value(uint256)` ERC20 approval to every registered `AaveYieldStrategy` and adapter at lines 1211, 431, and 1148. A compromised or buggy strategy doesn't need to exploit any vault logic — it simply calls `asset.transferFrom(vault, attacker, asset.balanceOf(vault))` using the pre-existing approval. The vault's `total_assets()` is never updated, corrupting NAV for all remaining depositors.

**Instead**: Apply defense-in-depth to trusted components. Use per-call approvals instead of blanket approvals. Implement withdrawal caps. Monitor for anomalous behavior. Document the trust boundary explicitly: "If component X is compromised, the maximum loss is Y." Include this in the Trust Assumptions Matrix.

---

## 8. "The oracle is reliable"

**Rationalization**: Chainlink is battle-tested. We don't need extra validation.

**Rejected because**: Chainlink has experienced outages, stale prices, and incorrect data. The LUNA/UST crash caused Chainlink to freeze prices. During network congestion, `updatedAt` can be hours old. Negative prices are theoretically possible (oil futures went negative in 2020). Vyper 0.4.x `convert(int256, uint256)` reverts on negative values (checked arithmetic), turning a bad price into a full DoS of all oracle-dependent functions.

**Real example**: P-H2 — Multiple P2P contracts (`P2PLendingVaultedBase.vy:336-349`, `P2PLendingSecuritizeBase.vy:420-432`) cast Chainlink's `int256 answer` to `uint256` without checking `answer > 0`. No `updatedAt` staleness check. No `answeredInRound >= roundId` validation. During network congestion, a stale price could enable borrowing at incorrect collateral valuations or trigger unwarranted liquidations. A negative price causes a revert, DoS-ing all lending operations.

**Instead**: Always validate: `answer > 0`, `updatedAt > block.timestamp - MAX_STALENESS`, `answeredInRound >= roundId`. Implement fallback oracles (TWAP, secondary feed). Define behavior for oracle failure: pause, use last known good price, or revert with clear error. Document the staleness window chosen and why.

---

## 9. "The compiler version is fine"

**Rationalization**: We're using the latest Vyper release. Compiler bugs are rare.

**Rejected because**: As of February 2026, at least 7 CVEs affect Vyper >= 0.4.0. One (VYP-37, reversed side-effect evaluation order) remains unfixed. Compiler bugs in Vyper have historically been severe — the Curve exploit (July 2023) was caused by a Vyper reentrancy guard bug affecting versions 0.2.15-0.3.0. Compiler bugs are invisible at the source level: the Vyper code looks correct, but the generated bytecode is wrong.

**Real example**: VYP-37 — Side effects in compound expressions may evaluate in reversed order. If a function call with side effects appears in a complex expression (e.g., `a + f(x)` where `f` mutates state), the evaluation order may differ from what the source code implies. This is still unfixed as of February 2026. Any Vyper 0.4.x contract using compound expressions with side-effecting function calls is potentially affected.

**Instead**: Check every deployed compiler version against the CVE database (https://github.com/vyperlang/vyper/security/advisories). Document which CVEs apply. For unfixed CVEs, audit the specific code patterns that trigger them. Include a Compiler Version Assessment table in the audit report. Recommend pinning compiler versions and re-auditing after upgrades.

---

## 10. "This is just a mock contract"

**Rationalization**: Mock contracts are only for testing. They'll never be deployed to mainnet.

**Rejected because**: Deployment scripts don't enforce contract classification. A mock contract with the same interface as a production contract can be deployed by accident — wrong config file, wrong environment variable, copy-paste in a deployment script. Mock contracts typically skip safety checks, hardcode return values, and lack access control. If deployed to mainnet, they create catastrophic vulnerabilities: tokens sent to a mock bridge are lost, mock oracles return hardcoded prices, mock adapters skip authentication.

**Real example**: P-M7 — All contracts in `contracts/v1/auxiliary/` (MockAavePool, MockMorpho, MockERC20, MockAdapter, etc.) have no mainnet deployment guard. There is no `assert chain.id != 1` or equivalent check. The naming convention (`Mock*`) is the only protection, and naming conventions are not enforced by the EVM. A deployment script that reads the wrong contract path deploys a mock to mainnet. `MockAavePool` would silently accept deposits and provide no yield; withdrawals would return zero.

**Instead**: Add `assert chain.id != 1` (and other mainnet chain IDs) to mock contract constructors. Maintain a deployment allowlist: only contracts on the list can be deployed to production chains. Deployment scripts should validate contract names and bytecode hashes against known-good values. Flag any contract in the `auxiliary/` or `mocks/` directory that lacks a mainnet guard.

---

## Quick Reference

| # | Rationalization | One-line counter |
|---|----------------|-----------------|
| 1 | Only owner can call | Owner compromise is in-scope |
| 2 | Amount is bounded | The bound may be the DoS vector |
| 3 | Token is trusted | USDT, blocklists, upgrades, rebasing |
| 4 | Gas makes it impractical | L2 gas is 100-1000x cheaper |
| 5 | Has nonreentrancy pragma | Cross-contract reentrancy still possible |
| 6 | Known design decision | Known != documented != risk-accepted |
| 7 | Strategy/adapter is trusted | Trusted = highest-privilege = highest-value target |
| 8 | Oracle is reliable | Chainlink has had outages and stale prices |
| 9 | Compiler version is fine | 7 CVEs affect >= 0.4.0, 1 unfixed |
| 10 | It's a mock contract | Deployment scripts don't enforce naming conventions |

---

## Addendum: Feature-Risk Rationalizations (VYP-38 to VYP-42)

### 11. "skip_contract_check is safe because interface is typed"

**Rationalization**: The interface definition protects us even if `skip_contract_check=True`.

**Rejected because**: `skip_contract_check=True` explicitly bypasses interface contract checks.
Type signatures in source do not enforce target trustworthiness or runtime return-shape behavior.

**Instead**: Require allowlisted/immutable targets plus explicit return-shape validation.

### 12. "raw_return is just an optimization detail"

**Rationalization**: `@raw_return` only affects gas and has no security impact.

**Rejected because**: `@raw_return` changes ABI boundary assumptions. Integrators may decode
payloads incorrectly, causing authorization/accounting side effects in dependent systems.

**Instead**: Treat `@raw_return` as integration risk. Require caller compatibility tests.

### 13. "selfdestruct still fully disables contract logic"

**Rationalization**: `selfdestruct` guarantees terminal disable semantics.

**Rejected because**: Modern EVM semantics changed historical assumptions. Security controls
must not rely on legacy full-delete behavior.

**Instead**: Use explicit kill-state flags and withdrawal/disable flows independent of selfdestruct.
