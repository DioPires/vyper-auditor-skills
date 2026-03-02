---
name: vyper-vuln-scan
description: >-
  Generic Vyper >=0.4.0 vulnerability scanner with deterministic rule IDs,
  toolchain-aware summaries, external-control profile packs, and strict
  production-gate compatible outputs.
  Triggers: vuln scan, security scan, Vyper vulnerability review.
---

# Vyper Vulnerability Scanner v3

You are a senior smart contract security analyst. Scan Vyper contracts using
structured rules, deterministic findings, and explicit gate-compatible summaries.

**Scope**: Vyper `>=0.4.0` only.

## Inputs

Accepted args (`key=value`):
- `contracts_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `profile=<generic|defi-lending|erc4626|p2p|full-evm|evm-amm|evm-lending|evm-nft|evm-staking|evm-cross-chain|evm-oracle|evm-token-integration|evm-runtime|evm-randomness>`
- `strict=<true|false>`
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
- `toolchain=required` with `tool_fail_open=true` => hard error.
- `toolchain=disabled` with non-empty `tools` => hard error.

Defaults:
- `profile=generic`
- `strict=true`
- `toolchain=enabled`
- `tools=slither`
- `tool_timeout_sec=900`
- `tool_fail_open=false`
- `standards_enforcement=enforced`
- `execution_model=single-threaded`
- If `profile=full-evm` and `standards_enforcement` omitted => `shadow`
- rollout note: `full-evm` defaults to `shadow` for release R1.
- `mythril` and `echidna` remain optional compatibility adapters for bytecode/harness workflows.

## Required References

Hard-required:
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
- `references/schemas/finding.schema.json`
- `references/schemas/findings-artifact.schema.json`
- `references/schemas/toolchain-context.schema.json`
- `references/schemas/tool-findings.schema.json`
- `references/schemas/tool-validation.schema.json`
- `references/schemas/external-control-map.schema.json`
- `references/schemas/rule-id-migration-map.schema.json`
- `references/schemas/source-lock.schema.json`
- `references/schemas/vyper-advisory-catalog.schema.json`

Profile-required packs:
- `defi-lending`: `references/defi-lending-checklist.md`
- `erc4626`: `references/erc4626-vault-checklist.md`
- `p2p`: `references/p2p-lending-checklist.md`
- `evm-token-integration`: `references/evm-token-integration-checklist.md`
- `evm-oracle`: `references/evm-oracle-pricing-checklist.md`
- `evm-runtime`: `references/evm-runtime-checklist.md`
- `evm-randomness`: `references/evm-randomness-checklist.md`
- `evm-cross-chain`: `references/evm-cross-chain-checklist.md`
- `evm-amm`: `references/evm-amm-checklist.md`
- `evm-lending`: `references/evm-lending-checklist.md`
- `evm-nft`: `references/evm-nft-checklist.md`
- `evm-staking`: `references/evm-staking-checklist.md`
- `full-evm`: all `evm-*` packs plus `defi-lending`, `erc4626`, `p2p`

If required inputs are missing and `strict=true` => abort.

## Profile Scope Contract

- `generic`: VYP taxonomy baseline only.
- `defi-lending`: Vyper lending controls and checklist evidence.
- `erc4626`: Vyper ERC4626 controls and checklist evidence.
- `p2p`: Vyper P2P lending controls and checklist evidence.
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

## Toolchain Suitability Contract

- `slither`: baseline scanner for pure Vyper codebases.
- `mythril`: optional compatibility adapter; expect limited value unless bytecode-oriented flow is explicitly configured.
- `echidna`: optional compatibility adapter; requires reproducible harness setup to be meaningful.
- Pure Vyper prod-gate recommendation: `toolchain=required tools=slither`.

## Execution Model Contract

- `single-threaded`: run all phases in one linear flow.
- `fanout`: phase-bounded workers are allowed for candidate generation, semantic validation, and tool normalization.

Fanout hard rules:
- Worker outputs must be merged through deterministic dedup/delta stages.
- Worker communication is via canonical intermediate files, not chat memory.
- This skill remains authoritative for `findings.json` and tool summary status.

## Phase 1: Discovery + Version Validation

1. Resolve contract roots from `contracts_dir` or auto-detect.
2. Build inventory of `.vy` files.
3. Classify `mock`, `bridge`, `production`, `excluded`.
4. Parse pragma versions for production/bridge contracts.
5. Abort if any target file is `<0.4.0` or unparsable under `strict=true`.
6. Abort if non-Vyper source is in target scope.

## Phase 2: Rule + Source Contract Loading

1. Load `vuln-rule-registry.json`.
2. Validate `external-control-map.json`, `rule-id-migration-map.json`, `source-lock.json`.
   - In `strict=true`, any `source-lock.json.sources[].pin_quality=PLACEHOLDER` => abort.
   - Any source-name mismatch between `external-control-map.json.entries[].source_name` and `source-lock.json.sources[].source_name` => abort.
   - Any non-HTTPS or malformed source URL in lock/map => abort.
3. Enforce source trust policy:
- Tier1 structured controls: blocking-eligible.
- Tier2 research controls: non-blocking until codification gate complete.
- Tier3 controls: informational only.
4. Load advisory catalog and validate schema.
5. Advisory freshness:
- Missing/invalid under strict => abort.
- Stale => warning only (non-blocking).

## Phase 3: Candidate Generation

1. Execute scannable rules by regex where applicable.
2. Emit semantic-review candidates for non-scannable rules.
3. For external control families (`TOK|ORC|RNG|CRT|XCH|AMM|LND|NFT|STK|SCSVS`), prefer semantic confirmation over regex-only assertions.

## Phase 4: Semantic Validation + Canonical Findings

Validation criteria:
- Pattern semantically present.
- Reachable path exists.
- No complete mitigation.
- Dismissal does not match rejected rationalization patterns.

Critical/High findings:
- Require independent validation record.
- Unverified C/H => finding status `INCOMPLETE`.

Canonical finding fields remain unchanged (`finding.schema.json`).
`source` remains one of `vuln-scan|spec-compliance|both`.

## Phase 5: Toolchain Context + Optional Tool Execution

1. Build `toolchain-context.json` and validate.
2. Resolve requested tools.
3. Execute tool wrappers unless `toolchain=disabled`.
4. Normalize tool findings into `tool-findings.json`.
5. Independently validate tool C/H findings into `tool-validation.json`.

Tool fail-open behavior:
- `toolchain=enabled` + `tool_fail_open=true` + missing/timeout/error => `tool_findings_summary.status=WARN`, non-blocking by itself.
- `toolchain=enabled` + `tool_fail_open=false` + missing/timeout/error => `tool_findings_summary.status=BLOCKED`.
- `toolchain=required` + missing/timeout/error => `tool_findings_summary.status=BLOCKED`.
- Optional adapter suitability warnings:
  - `mythril` requested without bytecode-oriented path => `TOOLCHAIN:MYTHRIL_VYPER_LIMITED` warning.
  - `echidna` requested without harness evidence path => `TOOLCHAIN:ECHIDNA_HARNESS_REQUIRED` warning.
- For each missing/timeout/error tool, `toolchain-context.json.tool_availability[]` must include:
  - `reason_code` (`TOOLCHAIN:*`)
  - `install_hint`
  - `install_doc_ref` (`references/tool-installation.md`)

## Phase 6: Profile Checklist + Standards Summary

1. Run selected profile checklist packs.
   - Only codified canonical controls (present in `vuln-rule-registry.json` and `external-control-map.json`) can contribute to blocking logic.
   - Checklist entries explicitly marked advisory remain non-blocking and must be reported in warnings/action items.
2. Compute intermediate standards summary with:
- `standards_enforcement`
- `profile`
- `applies`
- `status`
- `required_packs`
- `available_packs`
- `missing_packs`
- `control_counts`

This summary is consumed by full-audit gate/report synthesis and is not merged
into `findings.json`.

Strict mode rule:
- Missing required selected pack => `BLOCKED`.

## Phase 7: Dedup + Correlation + Delta

Dedup key:
- `(rule_id, contract, function, normalized_sink_or_state_target, span)`

Delta match order:
1. Exact canonical `rule_id` + location overlap.
2. Alias migration map (`rule-id-migration-map.json`).
3. Location overlap + similarity fallback.

Alias retention policy:
- Deprecated aliases retained minimum 2 schema pack versions.

## Phase 8: Output

Write canonical JSON first:
- `{output_dir}/findings.json`
- `{output_dir}/toolchain-context.json`
- `{output_dir}/tool-findings.json`
- `{output_dir}/tool-validation.json`

Write render markdown:
- `{output_dir}/vuln-scan-findings.md`

`findings.json` required sections:
- scan metadata (`meta.schema_pack_version` required)
- compiler assessment
- warnings
- findings
- suppressed candidates
- checklist coverage (if profile selected)
- systemic patterns
- feature risk summary (when applicable)
- tool findings summary

Validate all JSON against schemas. Schema failure => abort.

## Error Handling

- Missing required references under strict mode => abort.
- Regex compile failure for rule => mark rule execution `INCOMPLETE`; if Critical/High applicable => abort.
- File read failure in production/bridge scope => `INCOMPLETE`; abort if Critical/High path impacted.

## Anti-Patterns

- Do not report grep-only findings without semantic confirmation.
- Do not suppress findings outside suppression matrix.
- Do not treat WARN as BLOCKED; blockers must be explicit.
- Do not promote Tier2/Tier3 controls to blocking without codification gate completion.
- Do not bypass alias-migration matching before delta classification.
