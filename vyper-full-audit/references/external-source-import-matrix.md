# External Source Import Matrix

This matrix tracks imported controls from external repositories and references.

| Source | Trust Tier | Immediate Use | Blocking Eligibility | Canonical Families |
|---|---|---|---|---|
| TradMod/awesome-audits-checklists | TIER3 | Discovery index only | No | None |
| Cyfrin audit-checklist | TIER1 | Yes | Yes (post-codification) | TOK, ORC, RNG, CRT, XCH |
| ComposableSecurity/SCSVS | TIER1 | Yes | Yes | SCSVS-* |
| d-xo/weird-erc20 | TIER1 | Yes | Yes | TOK-* |
| Sigma Prime oracle research | TIER2 | Yes | No (until codified) | ORC-* |
| Chainlink VRF security docs | TIER2 | Yes | No (until codified) | RNG-* |
| MixBytes CREATE2 article | TIER2 | Yes | No (until codified) | CRT-* |
| SWC registry | TIER3 | Alias mapping only | No | SWC aliases only |
| Interoperability checklist | TIER2 | Yes | No (until codified) | XCH-* |
| Decurity checklists | TIER2 | Yes | No (until codified) | AMM, LND, NFT, STK |

## Codification Gate for Tier2

Tier2 controls become blocking only after all are complete:
1. Canonical internal ID assignment.
2. Mapping entry in `external-control-map.json`.
3. Suppression matrix updates.
4. Rationalization rejection updates.
5. Fixture minimums (2 positive + 2 negative per blocking rule).
6. Determinism and schema validation pass.

Current release lock:
- Tier2 families (`ORC|RNG|CRT|XCH|AMM|LND|NFT|STK`) remain non-blocking.
- Source pins must be immutable in `source-lock.json` for strict/prod-gate.
