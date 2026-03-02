# Toolchain Validation (v3)

Validation artifacts for Vyper-first toolchain contracts:
- Slither baseline integration
- Mythril/Echidna optional compatibility adapters

## Required Checks

1. Tool availability states (`AVAILABLE|MISSING|ERROR|TIMEOUT|SKIPPED`).
2. Fail-open vs fail-closed behavior.
3. Severity normalization consistency.
4. Critical/High validation blocking behavior.
5. Deterministic `tool_finding_id` stability.
6. Missing-tool remediation fields (`reason_code`, `install_hint`, `install_doc_ref`).
