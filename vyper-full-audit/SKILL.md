---
name: vyper-full-audit
description: >-
  Runs autonomous end-to-end security audit of Vyper 0.4.x smart contracts.
  Executes context building, vulnerability scanning, spec compliance,
  and report synthesis with parallel subagent spawning.
  Triggers: audit Vyper contracts, full audit, security review,
  comprehensive smart contract analysis, run audit.
---

# Vyper Full Audit — Orchestrator

You are a senior smart contract security auditor running a full autonomous audit
pipeline for Vyper >= 0.4.0 contracts. You coordinate 4 specialist skills via
their SKILL.md instructions and spawn Explore subagents for parallel work.

**Target**: Vyper >= 0.4.0 only. Reject Solidity or pre-0.4.0 Vyper.

## Key Rules

- Read before write. Read every reference and sibling SKILL.md before executing.
- Subagents are spawned via Task tool with `subagent_type: "Explore"`. Role is
  embedded in the Task prompt, NOT as a custom subagent_type value.
- Subagents return findings as Task response text. This main execution writes ALL
  output files.
- Mock contracts use `Mock*` prefix. Non-Mock files in `auxiliary/` are production
  bridges. Never skip bridges.
- Read `references/rationalizations-to-reject.md` — apply it to every finding.
- No partial runs. If a phase fails, log the failure and continue to next phase.

---

## Phase 1: Setup + Path Discovery

### Parse Arguments

Accept optional arguments:
- `contracts_dir=<path>` — explicit contracts directory
- `specs_dir=<path>` — explicit specs directory
- `exclude=<dir1,dir2>` — comma-separated directories to exclude from audit scope
  (e.g., `exclude=contracts/p2p,contracts/v1/auxiliary`)

If no arguments provided, auto-detect both. Excluded directories are filtered out
after discovery — their `.vy` files are inventoried but marked `EXCLUDED` and
skipped in all scan/compliance phases.

### Auto-Detect Contracts Directory

If `contracts_dir` not explicitly provided:

1. Glob for `contracts/` or `src/` in project root.
2. Exclude: `.venv/`, `node_modules/`, `.git/`, `build/`, `dist/`.
3. Glob `*.vy` within candidate dirs.
4. Fallback: glob `**/*.vy` across entire project, select directory containing
   the most `.vy` files.
5. If explicit arg provided, use it without detection.

### Auto-Detect Specs Directory

Glob for `**/specs/**/*.md` or `**/SPEC*.md`. Use the parent directory of the
first match as specs_dir.

### Auto-Detect Prior Audits

Glob `**/AUDIT_REPORT*.md`. If found, store paths for Phase 2. If none found,
set `KNOWN_FINDINGS = []`.

### Create Output Directory

```
output_dir = .claude/audit-sessions/{YYYYMMDD-HHMMSS}/
```

Create via Bash: `mkdir -p {output_dir}`

### Abort Conditions

Abort with clear error message if ANY of:
- No `.vy` files found anywhere in project
- All discovered `.vy` files are `Mock*` prefixed (nothing to audit)
- Any of the 4 sibling SKILL.md files are missing (see below)

### Verify Sibling Skills Exist

Read each of these files. If ANY is missing, abort with message:
"Missing required skill files. Run install.sh first."

```
~/.claude/skills/vyper-audit-context/SKILL.md
~/.claude/skills/vyper-vuln-scan/SKILL.md
~/.claude/skills/vyper-spec-compliance/SKILL.md
~/.claude/skills/vyper-audit-report/SKILL.md
```

### Phase 1 Output

Log to console:
- Contracts dir, file count, specs dir, output dir
- List of .vy files discovered (path + classification preview)

---

## Phase 2: Context Building

### Load Instructions

Read `~/.claude/skills/vyper-audit-context/SKILL.md` for detailed phase
instructions. Follow them exactly.

### Execute Context Building

Perform all work described in the context skill:
1. **Contract Inventory** — enumerate all .vy files with path, LOC, pragma
   version, classification.
2. **Trust Boundary Map** — identify owner, curator, guardian, external protocol,
   and user trust domains per contract. Map cross-contract trust relationships.
3. **External Call Graph** — grep for `extcall`, `staticcall`, `raw_call`,
   `send(`. Classify internal vs external. Flag calls to user-supplied addresses
   and unchecked return values.
4. **State Mutation Map** — for each production contract, list state variables,
   readers, writers. Flag state modified after external calls (CEI violations).

### Classification Rules

- `Mock*.vy` files → classification: `mock`
- Non-Mock files in `auxiliary/` → classification: `bridge`
- Everything else → classification: `production`

### Prior Findings

Load prior audit findings from detected AUDIT_REPORT*.md files. Parse findings
tables. If no prior audits: `KNOWN_FINDINGS = []`, log warning.

### Write Output

Write `{output_dir}/audit-context.md` containing all 4 maps + prior findings.

---

## Phase 3: Vulnerability Scanning (Parallelized)

### Load Instructions

Read `~/.claude/skills/vyper-vuln-scan/SKILL.md` for detailed phase instructions.

### Load Context

Read `{output_dir}/audit-context.md` for trust boundaries + known findings.

### Load All Reference Files

Read every file in `references/`:
- `references/vyper-vulnerability-patterns.md` (37 VYP patterns)
- `references/defi-lending-checklist.md` (63 checks)
- `references/p2p-lending-checklist.md` (15 checks)
- `references/erc4626-vault-checklist.md` (35 checks)
- `references/vyper-language-edges.md` (15 Vyper 0.4.x gotchas)
- `references/rationalizations-to-reject.md` (10 anti-shortcuts)

### Compiler CVE Check

Extract `#pragma version` from each contract. Flag applicable compiler CVEs
from the vulnerability patterns reference.

### Grep-First Pattern Scan

For each VYP-* pattern marked as `grep_scannable`:
- Run Grep tool with the pattern's trigger regex on production contracts only
- Skip `Mock*` files
- Record: file, line number, matched text, VYP-ID

### Semantic Validation via Subagents

Spawn up to 3 Explore subagents via Task tool for semantic validation.
Each subagent prompt must include:
- Role: "Vyper security analyst validating vulnerability candidates"
- Assigned contract file paths
- Candidate findings to validate
- Vyper language edges (key points from reference)
- Rationalizations to reject (key points from reference)
- Expected return format: structured findings table

### Checklist Deep Scan

Walk each production contract through applicable checklists:
- All contracts: `defi-lending-checklist.md`
- P2P contracts (in `p2p/` dir or with `P2P` in name): `p2p-lending-checklist.md`
- Vault/ERC4626 contracts: `erc4626-vault-checklist.md`

### Dedup Against Known Findings

Cross-reference all findings against KNOWN_FINDINGS from audit-context.md.
Same file + similar description = RECURRING. New = NEW.

### Write Output

Write `{output_dir}/vuln-scan-findings.md`.

---

## Phase 4: Spec Compliance (Parallelized)

### Load Instructions

Read `~/.claude/skills/vyper-spec-compliance/SKILL.md` for detailed instructions.

### Load Context

Read `{output_dir}/audit-context.md` for contract classification + trust
boundaries.

### Extract Requirements

Read all spec files from specs_dir. Extract MUST/SHALL/SHOULD requirements
using the extraction rules defined in the spec compliance skill.

### Spawn Verification Subagents

Spawn up to 4 Explore subagents via Task tool, one per contract group:

**Subagent 1: LendingVault.vy**
- Read full vault contract
- Verify against vault specs (01-vault-contract, 05-fee-structure, 06-withdrawal-queue)

**Subagent 2: Adapters**
- P2PLendingAdapter.vy + MorphoLendingAdapter.vy
- Verify against adapter/market integration specs

**Subagent 3: Strategies + Bridges**
- AaveYieldStrategy, MorphoYieldStrategy, bridge contracts
- Verify against yield strategy and bridge specs

**Subagent 4: Factory**
- LendingVaultFactory.vy
- Verify against factory spec (07-factory)

### P2P Core Scope

Contracts in `contracts/p2p/`: flag as `UNVERIFIED_SCOPE`. Only the adapter
spec covers the P2P-to-vault boundary, not P2P internals.

### Write Output

Write `{output_dir}/spec-compliance.md`.

---

## Phase 5: Report Synthesis

### Load Instructions

Read `~/.claude/skills/vyper-audit-report/SKILL.md` for detailed instructions.

### Merge Findings

Read `{output_dir}/vuln-scan-findings.md` + `{output_dir}/spec-compliance.md`.

### Delta Analysis

Compare against prior findings from audit-context.md:
- NEW / RECURRING / REGRESSION / RESOLVED classification
- REGRESSION: previously "fixed" finding reappeared — escalate severity

### Severity Calibration

Apply calibration rules from the report skill:
- Cross-cutting (2+ contracts) → bump one level (max Critical)
- Hot path (deposit, withdraw, liquidate) → bump Low to Medium
- Edge-case only → cap at Medium
- Mock contracts → cap at Informational

### Finding Validation

Spawn Explore subagents via Task tool for each CRITICAL and HIGH finding.
Each validates: code matches claim, rationalizations-to-reject applied,
independent assessment (CONFIRMED / REJECTED / UNVERIFIED).

### Write Outputs

- `{output_dir}/audit-report.md` — full report per template
- `{output_dir}/action-items.md` — prioritized remediation list

---

## Phase 6: Summary

### Print to User

1. **Executive Summary** — total findings by severity, scope coverage
2. **Critical/High Findings** — one-line summary of each
3. **Artifact Paths** — full paths to all generated files:
   - `{output_dir}/audit-context.md`
   - `{output_dir}/vuln-scan-findings.md`
   - `{output_dir}/spec-compliance.md`
   - `{output_dir}/audit-report.md`
   - `{output_dir}/action-items.md`

### Completion Signal

Print the artifact paths and summary. The audit is complete.

---

## Error Handling

- If a subagent fails or times out: log the failure, continue with available data.
  Mark affected sections as INCOMPLETE in the report.
- If a reference file is missing: warn and continue. Do not abort the full
  pipeline for a missing reference.
- If a phase produces no findings: that is a valid result. Do not fabricate
  findings to fill space.

## Anti-Patterns to Avoid

Read `references/rationalizations-to-reject.md` before starting. Specifically:
- Do not dismiss findings because "it's upgradeable" or "governance will fix it"
- Do not skip mock analysis entirely — mock bugs can indicate spec misunderstanding
- Do not conflate "no grep hit" with "no vulnerability" — semantic issues need reading
- Do not downgrade severity because a finding is "unlikely" without quantitative argument
