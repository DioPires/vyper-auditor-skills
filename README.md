# vyper-defi-audit

Security audit skills for Vyper 0.4.x smart contracts. 5 Claude Code skills that scan for 37 vulnerability patterns, 7 compiler CVEs, and 113 DeFi/P2P/ERC4626 checklist items.

## Installation

```bash
git clone <repo-url> ~/Documents/Personal/code/vyper-defi-audit
cd vyper-defi-audit
./install.sh
```

Requires POSIX (macOS/Linux). Creates symlinks in `~/.claude/skills/`.

To uninstall: `./uninstall.sh`

## Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| `vyper-full-audit` | `/vyper-full-audit` | Autonomous end-to-end audit (runs all phases) |
| `vyper-vuln-scan` | `/vyper-vuln-scan` | Standalone vulnerability pattern scan |
| `vyper-spec-compliance` | `/vyper-spec-compliance` | Verify implementation against spec documents |
| `vyper-audit-context` | `/vyper-audit-context` | Build structured audit context (trust boundaries, call graph) |
| `vyper-audit-report` | `/vyper-audit-report` | Synthesize findings into unified report |

## Usage

### Full Audit (recommended)

```
/vyper-full-audit
```

Runs all phases autonomously: context building → vulnerability scanning → spec compliance → report synthesis. Outputs to `.claude/audit-sessions/{timestamp}/`.

Optional parameters:
```
/vyper-full-audit contracts_dir=contracts/ specs_dir=specs/
```

### Excluding Directories

Use `exclude` to skip directories from audit scope (e.g., out-of-scope contracts):
```
/vyper-full-audit exclude=contracts/p2p
/vyper-full-audit exclude=contracts/p2p,contracts/v1/auxiliary
```

Excluded files are still inventoried (for completeness) but marked `EXCLUDED` and skipped in all scan, compliance, and analysis phases. Comma-separate multiple directories.

Works with all skills:
```
/vyper-vuln-scan exclude=contracts/p2p
/vyper-spec-compliance exclude=contracts/p2p
/vyper-audit-context exclude=contracts/p2p
```

### Standalone Skills

Each skill works independently:
```
/vyper-vuln-scan          # Quick vulnerability pattern scan
/vyper-spec-compliance    # Verify against specs
/vyper-audit-context      # Build audit context only
/vyper-audit-report       # Synthesize existing findings
```

## Coverage

### 37 Vulnerability Patterns (VYP-01 to VYP-37)

- **VYP-01 to VYP-20**: Application-layer (reentrancy, access control, ERC4626 inflation, oracle, accounting)
- **VYP-21 to VYP-30**: Vyper 0.4.x language hazards (TSTORE reentrancy, transient storage, module system, create_from_blueprint)
- **VYP-31 to VYP-37**: Compiler CVEs affecting >= 0.4.0 (7 CVEs, 1 unfixed)

### 113 Checklist Items

- 63 DeFi lending checks (collateral, accounting, integration, access control, tokens, economics)
- 15 P2P lending checks (offer integrity, proxy safety, vault isolation, callbacks, Securitize)
- 35 ERC4626 vault checks (standard compliance + vault-specific)

### Reference Files

All in `vyper-full-audit/references/`:

| File | Content |
|------|---------|
| `vyper-vulnerability-patterns.md` | 37 patterns with grep triggers, detection steps, false positives |
| `defi-lending-checklist.md` | 63 DeFi lending security checks |
| `p2p-lending-checklist.md` | 15 P2P-specific checks |
| `erc4626-vault-checklist.md` | 35 ERC4626 compliance + vault checks |
| `vyper-language-edges.md` | 15 Vyper 0.4.x auditor gotchas |
| `rationalizations-to-reject.md` | 10 anti-shortcut defenses |
| `report-template.md` | Output format template |

## Contract Classification

- `Mock*.vy` prefix → mock/test (excluded from production analysis)
- Files in `auxiliary/` without `Mock` prefix → production bridge (included)
- All other `.vy` files → production

**Known limitation**: Non-`Mock` test helpers (e.g., `TestHelper.vy`, `FakeOracle.vy`) would be misclassified as production. Use `Mock` prefix for all test contracts.

## Scope

- **Target**: Vyper >= 0.4.0 only
- **Does NOT replace**: Static analysis (Slither/Mythril), formal verification, manual expert review, bug bounty programs
- **What it is**: Structured, repeatable, evidence-cited audit workflow at zero marginal cost per run

## Architecture

```
vyper-defi-audit/
├── vyper-full-audit/           # Orchestrator + canonical references/
│   ├── SKILL.md
│   └── references/             # 7 shared reference files
├── vyper-vuln-scan/            # Standalone skill
│   ├── SKILL.md
│   └── references -> symlink
├── vyper-spec-compliance/
├── vyper-audit-context/
└── vyper-audit-report/
```

Reference sharing via relative symlinks. Each skill's `references/` resolves to `vyper-full-audit/references/` via 2-hop symlink resolution.

## License

MIT
