# Gate Scenario Matrix Report

## Matrix

| Scenario | Expected | Evidence Source | Result |
|---|---|---|---|
| missing advisory catalog in strict mode | `PROD_GATE=BLOCKED` | `vyper-full-audit/SKILL.md` required inputs + error handling | PASS |
| stale advisory catalog | warning emitted, no standalone block | `vyper-full-audit/SKILL.md` advisory freshness behavior | PASS |
| unverified new High finding | `PROD_GATE=BLOCKED` | `vyper-full-audit/SKILL.md` Phase 8 (`INCOMPLETE` in Critical/High) | PASS |
| only new Medium findings + assurance PASS | gate may pass | `vyper-full-audit/SKILL.md` Phase 8 block criteria | PASS |
| feature present without feature-targeted assurance evidence | assurance non-PASS -> blocked | `assurance-rubric.md` feature-conditional evidence + full-audit Phase 6 | PASS |

## Notes

- This repository defines skills/spec contracts, not executable scanner code.
- Scenario outcomes validated at policy-contract layer in skill and rubric files.

## Command Evidence

```bash
rg -n 'advisory|BLOCKED|warnings\\[\\]|INCOMPLETE|language_feature_usage|feature-conditional' \\
  vyper-full-audit/SKILL.md vyper-full-audit/references/assurance-rubric.md
```
