# vyper-auditor-skills (v2)

Generic security audit skills for Vyper `>=0.4.0` with mandatory production
release gating.

This suite produces canonical JSON artifacts and render Markdown artifacts,
blocks incomplete release evidence, and enforces hard assurance checks for
fuzz/property/invariant testing.

## Critical Positioning

- Default behavior is release-gating, not exploratory reporting.
- `PROD_GATE=PASS` means configured gate criteria passed.
- `PROD_GATE=PASS` is **not** formal proof of exploit impossibility.
- Mandatory companion controls:
- fuzz/property/invariant checks
- senior manual security review

## Installation

```bash
git clone <repo-url> ~/Documents/Personal/code/vyper-auditor-skills
cd vyper-auditor-skills
./install.sh
```

Creates symlinks in `~/.claude/skills/`.

Uninstall:

```bash
./uninstall.sh
```

## Skills

| Skill | Command | Purpose |
|---|---|---|
| `vyper-full-audit` | `/vyper-full-audit` | Mandatory production gate orchestration |
| `vyper-vuln-scan` | `/vyper-vuln-scan` | JSON-first vulnerability scanning |
| `vyper-spec-compliance` | `/vyper-spec-compliance` | Requirement extraction and compliance verification |
| `vyper-audit-context` | `/vyper-audit-context` | Deterministic inventory/trust/call/feature context |
| `vyper-audit-report` | `/vyper-audit-report` | Canonical report synthesis |

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

## Profiles

`profile` controls optional domain packs:
- `generic` (default)
- `defi-lending`
- `erc4626`
- `p2p`

In strict mode, selecting a profile requires its checklist pack.

## Full Audit (Mandatory Prod Gate)

`vyper-full-audit` defaults to:
- `mode=prod-gate`
- `strict=true`
- `profile=generic`

Example:

```text
/vyper-full-audit contracts_dir=contracts,src specs_dir=specs,docs/specs profile=generic strict=true
```

Expected release signal:
- `PROD_GATE=PASS|BLOCKED`
- `ASSURANCE_CHECKS=PASS|FAIL|BLOCKED`

### Required-vs-Optional (Prod Gate)

Required:
- valid Vyper contract discovery (`>=0.4.0`)
- rule registry + language edges + suppression matrix
- advisory catalog + advisory catalog schema
- schema set for canonical artifacts
- vulnerability scan completion
- spec compliance completion
- assurance checks `PASS`
- Critical/High validation completion

Optional:
- prior audit history
- non-selected profile packs

Any required item missing/failing/incomplete => `PROD_GATE=BLOCKED`.

## Advisory Freshness Policy

Compiler advisory mapping is sourced from:
- `vyper-full-audit/references/vyper-advisory-catalog.json`

Policy:
- Missing/invalid advisory catalog under strict mode => blocked.
- Stale catalog (older than `last_reviewed_at + stale_after_days`) => warning only.
- Freshness warning never blocks release by itself.

## Assurance Checks (Hard Gate)

Full audit validates fuzz/property/invariant assurance quality, not file presence.

PASS requires all:
- suite presence
- core invariant coverage
- execution evidence
- no unresolved failing seeds/counterexamples
- non-trivial scenario depth
- feature-conditional evidence based on
`audit-context.json.language_feature_usage[]`

Feature-conditional rule:
- if risky feature exists in codebase, targeted property/invariant evidence for that
feature family is mandatory for assurance PASS.

Anything else => `ASSURANCE_CHECKS` not PASS and prod gate blocked.

## Coverage Matrix

Current generic Vyper taxonomy:
- `VYP-01..VYP-20`: application-layer risks
- `VYP-21..VYP-30`: Vyper 0.4.x language hazards
- `VYP-31..VYP-37`: compiler CVE mapping
- `VYP-38..VYP-42`: proactive feature-risk checks

New proactive checks:
- `VYP-38`: `skip_contract_check` misuse
- `VYP-39`: unchecked contract-creation return
- `VYP-40`: `create_copy_of` target integrity risk
- `VYP-41`: `@raw_return` ABI boundary hazard
- `VYP-42`: `selfdestruct` semantic assumption risk

## Canonical Output Contract

Canonical JSON artifacts:
- `audit-context.json`
- `findings.json`
- `compliance.json`
- `audit-report.json`
- `assurance-checks.json`
- `gate-status.json`

Render Markdown artifacts:
- `audit-context.md`
- `vuln-scan-findings.md`
- `spec-compliance.md`
- `audit-report.md`
- `action-items.md`
- `gate-summary.md`

Canonical JSON is source of truth. Markdown is render-only.

### Required JSON fields for warning and feature propagation

- `findings.json`: required `warnings[]`
- `audit-report.json`: required `warnings[]` and `feature_risk_summary[]`
- `gate-status.json`: required `warnings[]`
- `audit-context.json`: required `language_feature_usage[]`

## Finding and Status Taxonomy

Finding identity:
- `rule_id`: taxonomy ID (for example `VYP-31`, `E46-05`, `SPEC-042`)
- `finding_id`: deterministic instance ID (`FND-<hash>`)

Canonical statuses:
- `NEW|RECURRING|REGRESSION|ACKNOWLEDGED|RESOLVED|INCOMPLETE`

## Schema Stability

Schemas are in `vyper-full-audit/references/schemas/`.

Policy:
- backward compatibility from v1 intentionally broken
- schema updates versioned by repository history
- every canonical artifact must validate against schema

## Validation and Sign-off Protocol

### Layer 1: Schema Integrity
Checks:
1. every updated schema parses
2. cross-schema refs resolve
3. representative fixtures validate including `warnings[]` and `language_feature_usage[]`
Pass:
- 100% schema parse + fixture validation pass

### Layer 2: Rule Contract (`VYP-38..VYP-42`)
Checks:
1. min 2 positive and 2 negative fixtures per new rule
2. positive fixture emits expected `rule_id`, deterministic `finding_id`, severity
3. negative fixture emits zero findings for that rule
Pass:
- 100% expected/actual alignment

### Layer 3: Semantic Precision
Checks:
1. each emitted finding has semantic evidence beyond regex
2. validator notes include exact unsafe condition + mitigation analysis
3. rejected candidates cross-checked against rationalization rules
Pass:
- no grep-only confirmations

### Layer 4: Dedup + Correlation
Checks:
1. same rule across different contracts remains separate
2. true duplicates in same contract coalesce once
3. systemic rollup does not mutate finding identity
Pass:
- dedup key behavior matches policy

### Layer 5: Gate Logic
Required scenarios:
- missing advisory catalog in strict mode => `BLOCKED`
- stale advisory catalog => warning present, no standalone block
- unverified new High => `BLOCKED`
- only new Medium validated + assurance PASS => may PASS
- feature present + no targeted assurance evidence => blocked via assurance
Pass:
- 100% scenario outcomes match expected statuses

### Layer 6: Determinism
Checks:
1. same input run twice
2. canonical outputs equal except timestamp fields
3. `finding_id` stable for unchanged findings
Pass:
- normalized byte-equivalent output

### Layer 7: Documentation Drift
Checks:
1. README command examples match `key=value` grammar
2. README artifact list matches schema-required contract
3. README blocking semantics match skill contracts
Pass:
- doc acceptance checks pass

## Required Validation Artifacts Before Sign-off

1. fixture manifest (`VYP-38..VYP-42` expected outcomes)
2. schema validation report
3. gate scenario matrix report (expected vs actual)
4. determinism diff report
5. documentation acceptance report
6. sample `gate-status.json` with warnings propagation

## Breaking Changes and Migration

### v1 -> v2 Summary

- focus: lending-first -> generic default with optional profiles
- outputs: markdown-only -> JSON canonical + markdown render
- IDs: local labels -> `rule_id` + deterministic `finding_id`
- statuses: normalized canonical enum
- full audit: best-effort -> mandatory prod-gate blocking semantics

### Additional v2.1 migration notes

- JSON consumers must parse required `warnings[]` fields.
- Audit context consumers must parse required `language_feature_usage[]`.
- Report consumers must parse `feature_risk_summary[]`.

### Operational Migration Checklist

1. switch downstream tooling to canonical JSON artifacts
2. update parsers for `rule_id`/`finding_id`
3. enforce `PROD_GATE` and `ASSURANCE_CHECKS` in release workflows
4. provide/auto-discover spec roots for prod runs
5. persist fuzz/property/invariant execution evidence
6. update consumers for `warnings[]` and feature usage data

## Troubleshooting

`PROD_GATE=BLOCKED` common causes:
- missing required references/schemas
- missing/invalid advisory catalog in strict mode
- missing or invalid specs in prod-gate mode
- version policy failure (`<0.4.0` or unparsable pragma)
- `INCOMPLETE` in Critical/High path
- assurance checks not PASS

Remediation pattern:
1. inspect `gate-status.json` `blocked_reasons`
2. inspect `warnings[]` for non-blocking but critical follow-up
3. fix highest-priority blocker first
4. rerun full audit with same args
5. confirm deterministic artifact validity

## Known Limits

- Not a substitute for deep manual reasoning in novel protocol architectures.
- Not a formal verification proof system.
- Requires teams to maintain meaningful assurance test suites.

## Repository Layout

```text
vyper-auditor-skills/
├── vyper-full-audit/
│   ├── SKILL.md
│   └── references/
│       ├── schemas/
│       ├── vuln-rule-registry.json
│       ├── vyper-advisory-catalog.json
│       ├── suppression-matrix.md
│       └── ...
├── vyper-vuln-scan/
├── vyper-spec-compliance/
├── vyper-audit-context/
└── vyper-audit-report/
```

## License

MIT
