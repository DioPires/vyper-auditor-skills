# Toolchain + Assurance Installation Runbook

Purpose:
- deterministic remediation for `TOOLCHAIN:*` availability failures
- deterministic setup for assurance evidence engines used by prod-gate

Policy:
- no automatic installs inside audit execution flow
- install/remediation is operator action before rerun
- required mode remains fail-closed

## Baseline for Pure Vyper Prod-Gate

`slither` is baseline external scanner.

### macOS / Linux
```bash
python3 -m pip install --user slither-analyzer
slither --version
```

## Recommended Assurance Engines (Vyper-First)

At least one of these should provide reproducible execution evidence.

### Titanoboa + pytest (preferred)
```bash
python3 -m pip install --user titanoboa pytest
python3 -c "import boa, pytest; print('boa+pytest ok')"
pytest -q
```

### Foundry (optional, strong invariants/fuzz support)
```bash
foundryup
forge --version
forge test -vv
```

## Optional Compatibility Adapters

These are not baseline requirements for pure-source Vyper audits.

### Mythril (optional, bytecode-oriented)
```bash
python3 -m pip install --user mythril "setuptools<81"
myth version
```

`setuptools<81` avoids `pkg_resources` removal breakage in current Mythril dependency chain.

### Echidna (optional, harness-oriented)
```bash
brew install echidna
echidna --version
```

Linux alternative:
```bash
sudo apt-get update
sudo apt-get install -y ghc cabal-install
cabal update
cabal install echidna
$HOME/.cabal/bin/echidna --version
```

## Verification Checklist

- `slither --version` returns successfully.
- At least one assurance engine has passing/recent execution evidence (`boa+pytest` or `forge`).
- If requested in `tools=...`, optional adapters also return version successfully.
- Re-run audit with same args and confirm expected `tool_availability[].status`.

## Mapping to Reason Codes

- `TOOLCHAIN:SLITHER_NOT_AVAILABLE` -> install Slither section above.
- `TOOLCHAIN:MYTHRIL_NOT_AVAILABLE` -> install Mythril section above.
- `TOOLCHAIN:ECHIDNA_NOT_AVAILABLE` -> install Echidna section above.
- `TOOLCHAIN:MYTHRIL_VYPER_LIMITED` -> keep adapter optional or switch to bytecode-oriented flow.
- `TOOLCHAIN:ECHIDNA_HARNESS_REQUIRED` -> provide harness-backed properties/corpus or remove from requested tools.
- `TOOLCHAIN:*_TIMEOUT` -> increase `tool_timeout_sec` after confirming tool health.
- `TOOLCHAIN:TOOL_COMPILE_FAIL` -> tool discovered but incompatible with target compiler/features; keep toolchain fail-open (`toolchain=enabled tool_fail_open=true`) or remove incompatible tool from `tools=...` for this run.
