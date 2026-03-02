# Toolchain Fixture Manifest

## Tool Availability Scenarios (Baseline)

- `fixtures/tool-available.json` -> baseline `slither` available
- `fixtures/tool-missing.json` -> baseline `slither` missing
- `fixtures/tool-timeout.json` -> baseline `slither` timeout

## Normalization Scenarios

- `fixtures/normalized-mapped.json` -> mapped findings with canonical rule IDs
- `fixtures/normalized-unmapped.json` -> unmapped findings retained

## Validation Scenarios

- `fixtures/ch-validated.json` -> Critical/High fully validated
- `fixtures/ch-unverified.json` -> unverified Critical/High blocks gate

## Canonical Sample Artifacts

- `sample-tool-findings.json` -> normalized tool findings sample
- `sample-toolchain-context-missing-tools.json` -> remediation metadata contract sample
