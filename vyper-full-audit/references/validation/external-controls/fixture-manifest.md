# External Controls Fixture Manifest

Executable fixture corpus for external-control families.

Contract:
- 2 positive + 2 negative fixtures per codified rule.
- 1 cross-contract dedup + 1 alias-migration scenario per family.

## Codified Rule Fixtures

| Rule ID | Family | Tier | Blocking Eligible | Fixtures |
|---|---|---|---|---|
| TOK-01 | TOK | TIER1 | true | `tok-01-positive-{01,02}.json`, `tok-01-negative-{01,02}.json` |
| TOK-02 | TOK | TIER1 | true | `tok-02-positive-{01,02}.json`, `tok-02-negative-{01,02}.json` |
| TOK-03 | TOK | TIER1 | true | `tok-03-positive-{01,02}.json`, `tok-03-negative-{01,02}.json` |
| ORC-01 | ORC | TIER2 | false | `orc-01-positive-{01,02}.json`, `orc-01-negative-{01,02}.json` |
| RNG-01 | RNG | TIER2 | false | `rng-01-positive-{01,02}.json`, `rng-01-negative-{01,02}.json` |
| CRT-01 | CRT | TIER2 | false | `crt-01-positive-{01,02}.json`, `crt-01-negative-{01,02}.json` |
| XCH-01 | XCH | TIER2 | false | `xch-01-positive-{01,02}.json`, `xch-01-negative-{01,02}.json` |
| AMM-01 | AMM | TIER2 | false | `amm-01-positive-{01,02}.json`, `amm-01-negative-{01,02}.json` |
| LND-01 | LND | TIER2 | false | `lnd-01-positive-{01,02}.json`, `lnd-01-negative-{01,02}.json` |
| NFT-01 | NFT | TIER2 | false | `nft-01-positive-{01,02}.json`, `nft-01-negative-{01,02}.json` |
| STK-01 | STK | TIER2 | false | `stk-01-positive-{01,02}.json`, `stk-01-negative-{01,02}.json` |
| SCSVS-I1 | SCSVS | TIER1 | true | `scsvs-i1-positive-{01,02}.json`, `scsvs-i1-negative-{01,02}.json` |

## Family-Level Scenarios

| Family | Cross-Contract Dedup | Alias Migration |
|---|---|---|
| TOK | `tok-cross-contract-dedup-01.json` | `tok-alias-migration-01.json` |
| ORC | `orc-cross-contract-dedup-01.json` | `orc-alias-migration-01.json` |
| RNG | `rng-cross-contract-dedup-01.json` | `rng-alias-migration-01.json` |
| CRT | `crt-cross-contract-dedup-01.json` | `crt-alias-migration-01.json` |
| XCH | `xch-cross-contract-dedup-01.json` | `xch-alias-migration-01.json` |
| AMM | `amm-cross-contract-dedup-01.json` | `amm-alias-migration-01.json` |
| LND | `lnd-cross-contract-dedup-01.json` | `lnd-alias-migration-01.json` |
| NFT | `nft-cross-contract-dedup-01.json` | `nft-alias-migration-01.json` |
| STK | `stk-cross-contract-dedup-01.json` | `stk-alias-migration-01.json` |
| SCSVS | `scsvs-cross-contract-dedup-01.json` | `scsvs-alias-migration-01.json` |

## Source-Lock Integrity Scenarios

- `source-lock-placeholder-block-01.json`: strict/prod-gate blocks placeholder pins.
- `source-name-mismatch-block-01.json`: strict/prod-gate blocks map/lock source-name mismatch.
