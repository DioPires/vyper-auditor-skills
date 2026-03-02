# Suppression Matrix (v3)

Only suppression rules listed here are allowed.

Suppression conditions must match both:
- same contract file
- overlapping sink/callsite context

## Allowed Suppressions

| Suppressor Rule | Suppressed Rule | Condition | Rationale |
|---|---|---|---|
| VYP-03 | VYP-13 | Same `raw_call` site where failure handling is shared root cause | Avoid duplicate symptom-level reporting |
| VYP-39 | CRT-01 | Same creation site and same missing return/address validation root cause | Prevent double-reporting of factory return trust issue |
| TOK-02 | VYP-05 | Same token transfer path where balance-delta proof supersedes return-shape-only warning | Preserve highest-fidelity accounting finding |
| ORC-01 | VYP-15 | Same oracle path where staleness/round checks are root cause | Collapse overlapping oracle integrity findings |

## External Family Coverage Contract

Each codified external family rule must have an explicit suppression posture.

| Canonical Rule ID | Family | Suppression Posture | Notes |
|---|---|---|---|
| TOK-01 | TOK | NONE | Keep explicit non-standard return handling finding visible. |
| TOK-02 | TOK | CONDITIONAL | Only suppresses `VYP-05` under overlap condition above. |
| TOK-03 | TOK | NONE | Trust-boundary/liveness assumption should remain explicit. |
| ORC-01 | ORC | CONDITIONAL | Only suppresses `VYP-15` under overlap condition above. |
| RNG-01 | RNG | NONE | Callback authorization findings remain explicit. |
| CRT-01 | CRT | CONDITIONAL | Only suppressed by `VYP-39` under overlap condition above. |
| XCH-01 | XCH | NONE | Replay protection findings remain explicit. |
| AMM-01 | AMM | NONE | Slippage control findings remain explicit. |
| LND-01 | LND | NONE | Health-factor enforcement findings remain explicit. |
| NFT-01 | NFT | NONE | Hook reentrancy boundary findings remain explicit. |
| STK-01 | STK | NONE | Reward index drift findings remain explicit. |
| SCSVS-I1 | SCSVS | NONE | Standards evidence gap findings remain explicit. |

## Family Completeness Constraint

New family cannot become blocking until all are present:
- rule entries in `vuln-rule-registry.json`
- source mappings in `external-control-map.json`
- suppression posture in this matrix
- anti-rationalization coverage in `rationalizations-to-reject.md`
- fixture set + expected outcomes
- validation docs updated

## Prohibited Suppressions

- Cross-file suppressions.
- Cross-contract suppressions.
- Broad per-file suppressions that hide unrelated findings.
- Any suppression not present in this matrix.
- Bulk suppressions for `VYP-38` to `VYP-42` without callsite-specific overlap proof.
- Suppression based only on severity or source trust tier.
