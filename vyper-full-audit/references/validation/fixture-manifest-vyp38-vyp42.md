# Fixture Manifest: VYP-38 to VYP-42

Each rule has 2 positive and 2 negative fixtures.

## VYP-38 (`skip_contract_check` misuse)

| Fixture | Path | Expected |
|---|---|---|
| positive-01 | `fixtures/vyp38/positive-01.vy` | Finding `VYP-38` High |
| positive-02 | `fixtures/vyp38/positive-02.vy` | Finding `VYP-38` High |
| negative-01 | `fixtures/vyp38/negative-01.vy` | No `VYP-38` finding |
| negative-02 | `fixtures/vyp38/negative-02.vy` | No `VYP-38` finding |

## VYP-39 (unchecked contract-creation return)

| Fixture | Path | Expected |
|---|---|---|
| positive-01 | `fixtures/vyp39/positive-01.vy` | Finding `VYP-39` High |
| positive-02 | `fixtures/vyp39/positive-02.vy` | Finding `VYP-39` High |
| negative-01 | `fixtures/vyp39/negative-01.vy` | No `VYP-39` finding |
| negative-02 | `fixtures/vyp39/negative-02.vy` | No `VYP-39` finding |

## VYP-40 (`create_copy_of` target integrity)

| Fixture | Path | Expected |
|---|---|---|
| positive-01 | `fixtures/vyp40/positive-01.vy` | Finding `VYP-40` High |
| positive-02 | `fixtures/vyp40/positive-02.vy` | Finding `VYP-40` High |
| negative-01 | `fixtures/vyp40/negative-01.vy` | No `VYP-40` finding |
| negative-02 | `fixtures/vyp40/negative-02.vy` | No `VYP-40` finding |

## VYP-41 (`@raw_return` ABI hazard)

| Fixture | Path | Expected |
|---|---|---|
| positive-01 | `fixtures/vyp41/positive-01.vy` | Finding `VYP-41` Medium |
| positive-02 | `fixtures/vyp41/positive-02.vy` | Finding `VYP-41` Medium |
| negative-01 | `fixtures/vyp41/negative-01.vy` | No `VYP-41` finding |
| negative-02 | `fixtures/vyp41/negative-02.vy` | No `VYP-41` finding (documented integration-safe use) |

## VYP-42 (`selfdestruct` semantic assumptions)

| Fixture | Path | Expected |
|---|---|---|
| positive-01 | `fixtures/vyp42/positive-01.vy` | Finding `VYP-42` Medium |
| positive-02 | `fixtures/vyp42/positive-02.vy` | Finding `VYP-42` Medium |
| negative-01 | `fixtures/vyp42/negative-01.vy` | No `VYP-42` finding |
| negative-02 | `fixtures/vyp42/negative-02.vy` | No `VYP-42` finding |
