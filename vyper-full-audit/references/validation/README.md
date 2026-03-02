# Validation Artifacts (v3.1)

This folder tracks required sign-off artifacts for the v3 expansion:
- VYP-38..VYP-42 proactive feature checks
- toolchain artifacts and gate behavior (`slither` baseline, optional adapters)
- external-control profile coverage and standards gating
- immutable source-lock and migration contracts
- execution-model determinism (`single-threaded` vs `fanout`)

## Core Artifacts

- `fixture-manifest-vyp38-vyp42.md`
- `schema-validation-report.md`
- `gate-scenario-matrix-report.md`
- `determinism-diff-report.md`
- `documentation-acceptance-report.md`
- `sample-gate-status-with-warnings.json`
- `fixtures/` (2 positive + 2 negative fixtures per blocking rule)

## External Controls Artifacts

- `external-controls/README.md`
- `external-controls/schema-validation-report.md`
- `external-controls/gate-scenario-matrix-report.md`
- `external-controls/determinism-diff-report.md`
- `external-controls/mapping-integrity-report.md`
- `external-controls/fixture-manifest.md`
- `external-controls/sample-gate-status-full-evm-shadow.json`
- `external-controls/sample-gate-status-full-evm-enforced-blocked.json`

## Toolchain Artifacts

- `toolchain/README.md`
- `toolchain/fixture-manifest.md`
- `toolchain/schema-validation-report.md`
- `toolchain/gate-scenario-matrix-report.md`
- `toolchain/determinism-diff-report.md`
- `toolchain/sample-tool-findings.json`
- `toolchain/sample-toolchain-context-missing-tools.json`
