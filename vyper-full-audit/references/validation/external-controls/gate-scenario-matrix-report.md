# External Controls Gate Scenario Matrix

| Scenario | Expected | Result |
|---|---|---|
| `profile=full-evm`, `standards_enforcement=shadow`, standards failures present | WARN non-blocking | PASS |
| `profile=full-evm`, `standards_enforcement=enforced`, missing required selected pack | BLOCKED | PASS |
| `profile=generic` with external pack missing | SKIPPED/non-blocking | PASS |
| Tier2 control finding (`ORC|RNG|CRT|XCH|AMM|LND|NFT|STK`) | WARN/non-blocking | PASS |
| source-lock contains `pin_quality=PLACEHOLDER` under strict/prod-gate | BLOCKED | PASS |
| source-name mismatch between map and source-lock | BLOCKED | PASS |
