# Suppression Matrix (v2)

Only suppression rules listed here are allowed.

Suppression conditions must match both:
- same contract file
- overlapping sink/callsite context

| Suppressor Rule | Suppressed Rule | Condition | Rationale |
|---|---|---|---|
| VYP-03 | VYP-13 | Same `raw_call` site where failure handling is the shared root cause | Avoid duplicate reporting of symptom-level unchecked return where root cause already captured |

## Prohibited Suppressions

- Cross-file suppressions.
- Cross-contract suppressions.
- Broad per-file suppressions that hide unrelated findings.
- Any suppression not present in this matrix.
- Bulk suppressions for `VYP-38` to `VYP-42` without callsite-specific overlap proof.
