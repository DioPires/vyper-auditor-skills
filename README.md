# vyper-auditor-skills (v3)

Mission-critical audit skills for Vyper `>=0.4.0` with deterministic production
gating.

This suite emits canonical JSON artifacts, render-only Markdown outputs, and
explicit gate outcomes across core, toolchain, and standards layers.

## Critical Positioning

- Default behavior is release-gating, not exploratory reporting.
- `PROD_GATE=PASS` means configured controls passed; it is not formal proof.
- Mandatory companion controls remain:
- fuzz/property/invariant testing
- senior manual security review

## Installation

```bash
git clone <repo-url> ~/Documents/Personal/code/vyper-auditor-skills
cd vyper-auditor-skills
./install.sh
```

Creates symlinks in `~/.claude/skills/`.
This does not install external binaries (Slither/Titanoboa/Foundry/Mythril/Echidna).
Use [tool-installation.md](/Users/dpires/Documents/Personal/code/vyper-auditor-skills/vyper-full-audit/references/tool-installation.md) for deterministic tool setup.

Uninstall:

```bash
./uninstall.sh
```

## Skills

| Skill | Command | Purpose |
|---|---|---|
| `vyper-full-audit` | `/vyper-full-audit` | Mandatory production gate orchestration |
| `vyper-vuln-scan` | `/vyper-vuln-scan` | Deterministic vulnerability scan + tool summaries |
| `vyper-spec-compliance` | `/vyper-spec-compliance` | Requirement extraction/compliance verification |
| `vyper-audit-context` | `/vyper-audit-context` | Deterministic context/trust/call/feature map |
| `vyper-audit-report` | `/vyper-audit-report` | Canonical report synthesis |
| `vyper-slither-scan` | `/vyper-slither-scan` | Slither raw findings adapter (baseline) |
| `vyper-mythril-scan` | `/vyper-mythril-scan` | Mythril compatibility adapter (optional, bytecode-oriented) |
| `vyper-echidna-evidence` | `/vyper-echidna-evidence` | Echidna compatibility adapter (optional, harness-oriented) |
| `vyper-tool-findings-normalizer` | `/vyper-tool-findings-normalizer` | Tool findings normalization/validation |

## Scope Contract

- Source-language scope remains Vyper only.
- Non-Vyper files in target scope are gate blockers.
- EVM profiles evaluate Vyper-visible integration/runtime assumptions only; they do not expand source-language scope.

## Argument Grammar

All skills use `key=value` tokens.

Rules:
- Unknown key: hard error.
- Duplicate key: hard error.
- List values: comma-separated CSV in value.

Examples:
- `contracts_dir=contracts,src`
- `specs_dir=specs,docs/specs`
- `exclude=contracts/mocks,legacy`
- `tools=slither`

## Profiles

`profile` controls optional packs:
- `generic` (default)
- `defi-lending`
- `erc4626`
- `p2p`
- `full-evm`
- `evm-amm`
- `evm-lending`
- `evm-nft`
- `evm-staking`
- `evm-cross-chain`
- `evm-oracle`
- `evm-token-integration`
- `evm-runtime`
- `evm-randomness`

Strict mode:
- missing required selected pack => blocked
- non-selected pack missing => non-blocking

## Toolchain API

Supported args in full-audit and vuln-scan:
- `toolchain=required|enabled|disabled` (default `enabled`)
- `tools=<csv_tools>` where each is `slither|mythril|echidna` (default `slither`)
- `tool_timeout_sec=<int>` (default `900`)
- `tool_fail_open=true|false` (default `false`)
- `standards_enforcement=shadow|enforced`
- `execution_model=single-threaded|fanout` (default `single-threaded`)

Vyper-first policy:
- Baseline scanner: `slither`.
- Production recommendation for pure Vyper repos: `toolchain=required tools=slither`.
- `mythril` and `echidna` are optional compatibility adapters; they are not required for pure-source Vyper profiles.
- Assurance evidence is expected from Vyper-native test stacks (`boa+pytest`, optional `foundry`), with Echidna accepted only when harness-backed and reproducible.

Defaults:
- `profile=full-evm` + omitted `standards_enforcement` => `shadow`
- all other profiles => `enforced`
- rollout note: `full-evm` defaults to `shadow` for first release cycle (R1) before mandatory enforcement.

Hard rules:
- `toolchain=required` forbids `tool_fail_open=true`
- `toolchain=disabled` rejects non-empty `tools`

Tool remediation contract:
- If a tool is `MISSING|ERROR|TIMEOUT`, `toolchain-context.json.tool_availability[]` includes:
  - `reason_code` (`TOOLCHAIN:*`)
  - `install_hint`
  - `install_doc_ref`

## Execution Model Contract

- `single-threaded`: one orchestrator flow, sequential phase execution.
- `fanout`: phase-bounded parallel agents are allowed for context, vuln/tool, and compliance/report prep.

Hard constraints in `fanout`:
- Agents are phase-scoped only; no freeform cross-phase autonomy.
- Inter-agent handoff is artifact-only (`audit-context.json`, `findings.json`, `compliance.json`, `tool*.json`), not chat memory.
- Only top-level full-audit reducer computes final `PROD_GATE`.
- Sub-agents cannot emit final gate decisions.

Operational guidance:
- Use `execution_model=fanout` for large repos/context pressure.
- Keep `execution_model=single-threaded` for minimal/debug runs.

## Deterministic Gate Function

Intermediate statuses:
- `core_status`: `PASS|BLOCKED`
- `toolchain_status`: `PASS|WARN|SKIPPED|BLOCKED`
- `standards_gate_status`: `PASS|WARN|SKIPPED|BLOCKED`

Blocking set:
- `BLOCKED` only

Non-blocking set:
- `PASS|WARN|SKIPPED`

Final gate:
1. if `core_status=BLOCKED` => `PROD_GATE=BLOCKED`
2. else if `toolchain_status=BLOCKED` => `PROD_GATE=BLOCKED`
3. else if `standards_gate_status=BLOCKED` => `PROD_GATE=BLOCKED`
4. else => `PROD_GATE=PASS`

Gate-facing enums:
- `prod_gate`: `PASS|BLOCKED`
- `assurance_checks`: `PASS|BLOCKED`

`WARN` policy:
- warning-only signals (including stale advisory and fail-open tool warnings) are non-blocking by themselves.

`blocked_reasons[]` namespace:
- `CORE:*`
- `TOOLCHAIN:*`
- `STANDARDS:*`

## Canonical Output Contract

Canonical JSON artifacts:
- `audit-context.json`
- `findings.json`
- `compliance.json`
- `assurance-checks.json`
- `toolchain-context.json`
- `tool-findings.json`
- `tool-validation.json`
- `audit-report.json`
- `gate-status.json`

Render Markdown artifacts:
- `audit-context.md`
- `vuln-scan-findings.md`
- `spec-compliance.md`
- `audit-report.md`
- `action-items.md`
- `gate-summary.md`

Required meta field:
- Every canonical artifact meta includes `schema_pack_version`.

## Canonical ID Policy

- Internal `rule_id` values are canonical.
- External source IDs are aliases/provenance only.
- Alias migration map is mandatory for delta matching before similarity fallback.
- Deprecated aliases retained for minimum 2 schema pack versions.

## Source Trust Policy

- Tier1 structured sources: blocking-eligible after codification.
- Tier2 research/blog sources: non-blocking until codification gate complete.
- Tier3 social/video/index sources: never blocking.

Codification gate before blocking:
1. internal canonical rule ID assigned
2. mapping entry added
3. suppression entries added
4. anti-rationalization coverage added
5. fixture minimums passed
6. determinism and schema checks passed

Source-lock integrity policy:
- `source-lock.json` entries use immutable commit/hash snapshots (`pin_quality=IMMUTABLE`).
- `pin_quality=PLACEHOLDER` is forbidden in strict/prod-gate.
- `external-control-map.json.entries[].source_name` must match `source-lock.json.sources[].source_name`.
- URLs in source lock/map must be HTTPS and validated.

## Validation and Sign-off Protocol

### Layer 1: Schema Integrity
- All schemas parse and refs resolve.
- Representative artifacts validate.

### Layer 2: Rule Contract
- New blocking rules require at least 2 positive + 2 negative fixtures.

### Layer 3: Semantic Precision
- Findings require semantic proof; no grep-only confirmations.

### Layer 4: Dedup + Correlation
- Dedup behavior must match policy.
- Alias migration matching required before fallback similarity.

### Layer 5: Gate Logic
- Gate matrix must match deterministic precedence and warning policy.

### Layer 6: Determinism
- Same inputs produce identical canonical outputs except timestamps.

### Layer 7: Documentation Drift
- README/skill examples align with key-value grammar and schema contracts.

## Required Validation Artifacts Before Sign-off

- schema validation report
- gate scenario matrix report
- determinism diff report
- documentation acceptance report
- toolchain validation corpus
- external-controls validation corpus
- sample gate-status artifacts including toolchain/standards statuses

## Migration Notes (v2 -> v3)

- Adds toolchain canonical artifacts and summary fields.
- Adds standards coverage summaries and profile expansion.
- Normalizes gate-facing status enums to `PASS|BLOCKED` (legacy `FAIL` no longer emitted).
- Enforces strict source-lock integrity (`pin_quality=PLACEHOLDER` blocks strict/prod-gate).
- Adds deterministic tool remediation metadata (`reason_code`, `install_hint`, `install_doc_ref`).
- Keeps Vyper-only source scope unchanged.
- Keeps warning semantics non-blocking unless escalated to explicit blocker.
