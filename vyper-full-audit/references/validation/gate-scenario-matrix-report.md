# Gate Scenario Matrix Report

## Matrix

| Scenario | Expected | Evidence Source | Result |
|---|---|---|---|
| stale advisory catalog + otherwise pass | `PROD_GATE=PASS` with warning | warning pass-through policy | PASS |
| toolchain enabled + fail-open true + missing tool | `toolchain_status=WARN`, gate may pass | tool runner policy | PASS |
| toolchain enabled + fail-open true + tool compile fail | `toolchain_status=WARN`, gate may pass | tool runner policy | PASS |
| toolchain required + missing tool | `PROD_GATE=BLOCKED` | deterministic gate precedence | PASS |
| unverified tool Critical/High | `PROD_GATE=BLOCKED` | C/H validation policy | PASS |
| standards shadow + failing standards checks | `standards_gate_status=WARN`, non-blocking | standards enforcement policy | PASS |
| standards enforced + missing required selected pack | `PROD_GATE=BLOCKED` | profile strictness matrix | PASS |
| source-lock contains placeholder pin in strict/prod-gate | `PROD_GATE=BLOCKED` | source-lock integrity policy | PASS |
| all statuses non-blocking (`PASS|WARN|SKIPPED`) | `PROD_GATE=PASS` | deterministic gate function | PASS |
| fanout execution + same artifact set | same deterministic final gate as single-threaded | centralized reducer rule | PASS |

## Notes

- Outcomes are contract-policy outcomes for skills/specs in this repository.
- Gate-facing output enums are normalized to `PASS|BLOCKED`.
