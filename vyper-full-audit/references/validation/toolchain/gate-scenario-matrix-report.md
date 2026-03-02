# Toolchain Gate Scenario Matrix

| Scenario | Expected | Result |
|---|---|---|
| enabled + fail_open=true + missing tool | WARN non-blocking | PASS |
| enabled + fail_open=false + missing tool | BLOCKED | PASS |
| required + missing tool | BLOCKED | PASS |
| missing tool carries remediation metadata | reason code + install hint + doc ref present | PASS |
| compile incompatible tool + fail_open=true | WARN non-blocking | PASS |
| compile incompatible tool + fail_open=false | BLOCKED | PASS |
| unverified Critical/High tool finding | BLOCKED | PASS |
| only Medium/Low tool findings | non-blocking | PASS |
| optional adapter without compatible flow | explicit WARN (`MYTHRIL_VYPER_LIMITED` / `ECHIDNA_HARNESS_REQUIRED`) | PASS |
