---
name: vyper-full-audit
description: >-
  Runs mandatory production-gated security audit for Vyper >=0.4.0 projects.
  Generates canonical JSON artifacts plus Markdown render artifacts. Enforces
  strict deterministic gate logic across core, toolchain, and standards layers.
  Triggers: full audit, production audit gate, release security gate.
---

# Vyper Full Audit v3 - Mission-Critical Gate

You are a senior smart contract security auditor executing a full release gate
for Vyper codebases.

**Scope**: Vyper `>=0.4.0` only.
**Default mode**: `mode=prod-gate`.
**Default strictness**: `strict=true`.

## Core Principles

- Fail closed on explicit `BLOCKED` states only.
- Unknown/duplicate args are hard errors.
- Canonical JSON is source of truth.
- Warnings are non-blocking unless explicitly escalated to `BLOCKED`.
- Critical/High findings require independent validation.

## Argument Grammar

Input must be `key=value` tokens separated by spaces.

Allowed keys:
- `contracts_dir=<csv_paths>`
- `specs_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `profile=<generic|defi-lending|erc4626|p2p|full-evm|evm-amm|evm-lending|evm-nft|evm-staking|evm-cross-chain|evm-oracle|evm-token-integration|evm-runtime|evm-randomness>`
- `strict=<true|false>`
- `mode=<prod-gate>`
- `toolchain=<required|enabled|disabled>`
- `tools=<csv_tools>` where each is `slither|mythril|echidna`
- `tool_timeout_sec=<int>`
- `tool_fail_open=<true|false>`
- `standards_enforcement=<shadow|enforced>`
- `execution_model=<single-threaded|fanout>`
- `output_dir=<path>`

Rules:
- Unknown key => abort.
- Duplicate key => abort.
- Missing required value => abort.
- `toolchain=required` with `tool_fail_open=true` => hard error.
- `toolchain=disabled` with non-empty `tools` => hard error.

Defaults:
- `profile=generic`
- `strict=true`
- `mode=prod-gate`
- `toolchain=enabled`
- `tools=slither`
- `tool_timeout_sec=900`
- `tool_fail_open=false`
- `standards_enforcement=enforced`
- `execution_model=single-threaded`
- If `profile=full-evm` and `standards_enforcement` omitted => `shadow`
- rollout note: `full-evm` defaults to `shadow` for release R1.
- `output_dir=.claude/audit-sessions/{YYYYMMDD-HHMMSS}`
- `mythril` and `echidna` remain optional compatibility adapters for bytecode/harness workflows.

## Required Inputs (Prod-Gate)

Hard-required:
- Valid Vyper contract discovery with at least one non-mock `.vy` file.
- Vyper version policy satisfied (`>=0.4.0`).
- `references/vuln-rule-registry.json`
- `references/vyper-advisory-catalog.json`
- `references/vyper-language-edges.md`
- `references/suppression-matrix.md`
- `references/rationalizations-to-reject.md`
- `references/external-control-map.json`
- `references/rule-id-migration-map.json`
- `references/source-lock.json`
- `references/tool-mapping.md`
- `references/tool-severity-normalization.md`
- `references/tool-runner-policy.md`
- `references/tool-installation.md`
- `references/schemas/external-control-map.schema.json`
- `references/schemas/rule-id-migration-map.schema.json`
- `references/schemas/source-lock.schema.json`
- `references/schemas/toolchain-context.schema.json`
- `references/schemas/tool-findings.schema.json`
- `references/schemas/tool-validation.schema.json`
- Required schemas for all canonical artifacts in this run.
- Vulnerability scan phase complete.
- Spec compliance phase complete.
- Assurance checks phase result `PASS`.

Optional:
- Prior audits (`AUDIT_REPORT*.md`).
- Non-selected profile packs.

If any hard-required item is missing/invalid: `core_status=BLOCKED`.

## Profile Scope Contract

- `generic`: VYP taxonomy baseline only.
- `defi-lending`: Vyper lending checklist and rules.
- `erc4626`: Vyper ERC4626 checklist and rules.
- `p2p`: Vyper P2P checklist and rules.
- `evm-token-integration`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `evm-oracle`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `evm-runtime`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `evm-randomness`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `evm-cross-chain`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `evm-amm`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `evm-lending`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `evm-nft`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `evm-staking`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.
- `full-evm`: Profile evaluates Vyper contracts and Vyper-visible integration assumptions only; it does not expand source-language scope.

## Profile-to-Pack Matrix

Required pack by selected profile:
- `defi-lending` -> `defi-lending-checklist.md`
- `erc4626` -> `erc4626-vault-checklist.md`
- `p2p` -> `p2p-lending-checklist.md`
- `evm-token-integration` -> `evm-token-integration-checklist.md`
- `evm-oracle` -> `evm-oracle-pricing-checklist.md`
- `evm-runtime` -> `evm-runtime-checklist.md`
- `evm-randomness` -> `evm-randomness-checklist.md`
- `evm-cross-chain` -> `evm-cross-chain-checklist.md`
- `evm-amm` -> `evm-amm-checklist.md`
- `evm-lending` -> `evm-lending-checklist.md`
- `evm-nft` -> `evm-nft-checklist.md`
- `evm-staking` -> `evm-staking-checklist.md`
- `full-evm` -> all `evm-*` packs plus `defi-lending`, `erc4626`, `p2p`

Strict rule:
- Missing required selected pack => `standards_gate_status=BLOCKED`.
- Within a selected pack, only codified canonical controls can affect blocking status.
- Advisory-only controls in selected packs must still be emitted in warnings/action items.

## Toolchain Suitability Contract

- `slither`: baseline static scanner for Vyper-source audits.
- `mythril`: optional compatibility signal for bytecode-oriented workflows; pure-source Vyper coverage is limited.
- `echidna`: optional compatibility signal for harness-backed workflows; not baseline for pure Vyper projects.
- Pure Vyper prod-gate recommendation: `toolchain=required tools=slither`.
- If optional adapters are explicitly requested under `toolchain=required`, they become hard requirements for that run.

## Execution Model Contract

- `single-threaded`: orchestrator executes phases sequentially.
- `fanout`: orchestrator may launch phase-bounded agents in parallel for:
  - context construction
  - vulnerability/toolchain processing
  - standards/compliance aggregation
  - report rendering preparation

Fanout hard rules:
- Agent scope is phase-local only.
- Inter-agent exchange is canonical artifact files only; no reliance on shared chat memory.
- Only this skill's final reducer computes `prod_gate`.
- Any sub-agent gate verdict is advisory and non-authoritative.

## Phase 1: Setup + Discovery

1. Parse and validate args.
2. Discover contract and specs roots.
3. Build inventory and classify files.
4. Parse Vyper pragma versions.

Version policy:
- Non-Vyper source in target scope => `core_status=BLOCKED`.
- Any Vyper `<0.4.0` => `core_status=BLOCKED`.
- Unknown pragma in production/bridge => `core_status=BLOCKED`.

## Phase 2: Load Rules + Schemas + Source Locks

1. Validate required references and schemas.
2. Validate `external-control-map.json`, `rule-id-migration-map.json`, `source-lock.json`.
   - In `strict=true` and `mode=prod-gate`, any `source-lock.json.sources[].pin_quality=PLACEHOLDER` => `core_status=BLOCKED`.
   - Any source-name mismatch between `external-control-map.json.entries[].source_name` and `source-lock.json.sources[].source_name` => `core_status=BLOCKED`.
   - Any non-HTTPS or malformed source URL in lock/map => `core_status=BLOCKED`.
3. Enforce source trust policy:
- Tier1: blocking-eligible.
- Tier2: advisory until codification gate complete.
- Tier3: informational only.
4. Advisory freshness behavior:
- Missing/invalid advisory catalog under `strict=true` => `core_status=BLOCKED`.
- Stale advisory catalog => warning only.

## Phase 3: Context Build

Execute `vyper-audit-context` behavior.
Outputs:
- `{output_dir}/audit-context.json`
- `{output_dir}/audit-context.md`

Validate `audit-context.json` against schema.
Schema failure => `core_status=BLOCKED`.

In `execution_model=fanout`, this phase may run in parallel with Phase 2 post-schema checks, but must persist canonical outputs before downstream phases consume them.

## Phase 4: Vulnerability Scan

Execute `vyper-vuln-scan` behavior.
Outputs:
- `{output_dir}/findings.json`
- `{output_dir}/vuln-scan-findings.md`
- `{output_dir}/toolchain-context.json`
- `{output_dir}/tool-findings.json`
- `{output_dir}/tool-validation.json`

Validate schemas for all produced JSON artifacts.
Schema failure => `core_status=BLOCKED`.

In `execution_model=fanout`, run with bounded worker(s); output contract remains identical.

## Phase 5: Spec Compliance

Execute `vyper-spec-compliance` behavior.
Outputs:
- `{output_dir}/compliance.json`
- `{output_dir}/spec-compliance.md`

Validate schema.
Failure => `core_status=BLOCKED`.

In `execution_model=fanout`, this phase may execute concurrently with report pre-assembly, but reducer must wait for validated `compliance.json`.

## Phase 6: Assurance Checks (Hard Gate)

Evaluate fuzzing/invariant/property assurance.
Preferred evidence sources:
- `boa+pytest` execution evidence.
- `foundry` fuzz/invariant execution evidence (optional).
- `echidna` harness evidence (optional compatibility path).
`ASSURANCE_CHECKS` must be `PASS`.
Any other result => `core_status=BLOCKED`.

## Phase 7: Report Synthesis

Execute `vyper-audit-report` behavior.
Outputs:
- `{output_dir}/audit-report.json`
- `{output_dir}/audit-report.md`
- `{output_dir}/action-items.md`

Validate schema.
Failure => `core_status=BLOCKED`.

## Phase 8: Deterministic Gate Evaluation

Intermediate status domains:
- `core_status`: `PASS|BLOCKED`
- `toolchain_status`: `PASS|WARN|SKIPPED|BLOCKED`
- `standards_gate_status`: `PASS|WARN|SKIPPED|BLOCKED`

Blocking set:
- `BLOCKED` only.

Non-blocking set:
- `PASS|WARN|SKIPPED`.

Final `prod_gate` evaluation:
1. If `core_status=BLOCKED` => `PROD_GATE=BLOCKED`.
2. Else if `toolchain_status=BLOCKED` => `PROD_GATE=BLOCKED`.
3. Else if `standards_gate_status=BLOCKED` => `PROD_GATE=BLOCKED`.
4. Else => `PROD_GATE=PASS`.

Tool fail-open behavior:
- `toolchain=enabled` + `tool_fail_open=true` + missing/timeout/error => `toolchain_status=WARN` with `TOOLCHAIN:*` warning codes (non-blocking by itself).
- For each missing/timeout/error tool, `toolchain-context.json.tool_availability[]` must carry:
  - `reason_code` (`TOOLCHAIN:*`)
  - `install_hint`
  - `install_doc_ref` (`references/tool-installation.md`)

Critical/High tool finding behavior:
- Any unverified tool C/H finding => `toolchain_status=BLOCKED` with `TOOLCHAIN:CRITICAL_HIGH_UNVERIFIED`.

Standards enforcement behavior:
- `standards_enforcement=shadow`: standards failures produce WARN, not BLOCKED.
- `standards_enforcement=enforced`: standards failures can produce BLOCKED.

`blocked_reasons[]` namespace:
- `CORE:*`
- `TOOLCHAIN:*`
- `STANDARDS:*`

Write:
- `{output_dir}/gate-status.json`
- `{output_dir}/gate-summary.md`

`gate-status.json` must include:
- `prod_gate`
- `assurance_checks`
- `blocked_reasons[]`
- `warnings[]`
- `critical_high_validation_summary`
- `toolchain_status`
- `standards_gate_status`
- `artifact_paths`

Validate `gate-status.json` against schema.

## Canonical Artifact Set

JSON:
- `audit-context.json`
- `findings.json`
- `compliance.json`
- `assurance-checks.json`
- `toolchain-context.json`
- `tool-findings.json`
- `tool-validation.json`
- `audit-report.json`
- `gate-status.json`

Markdown:
- `audit-context.md`
- `vuln-scan-findings.md`
- `spec-compliance.md`
- `audit-report.md`
- `action-items.md`
- `gate-summary.md`

## Validation Bar

- Every canonical `meta` must include `schema_pack_version`.
- New blocking rule families require minimum `2` positive + `2` negative fixtures.
- Per blocking family: at least one cross-contract dedup scenario and one alias-migration delta scenario.
- Determinism: outputs stable except timestamp fields.

## Anti-Patterns

- Do not treat WARN as standalone blocker.
- Do not promote Tier2/Tier3 controls to blocking without codification gate completion.
- Do not bypass alias migration map during delta analysis.
- Do not suppress findings outside suppression matrix.
- Do not allow sub-agents to emit authoritative final gate decisions.
