---
name: vyper-echidna-evidence
description: >-
  Collects Echidna harness-based compatibility evidence and normalizes
  counterexamples for assurance and tool validation workflows.
---

# Vyper Echidna Evidence

Collect Echidna outputs as optional harness-backed evidence.

## Inputs

- `contracts_dir=<csv_paths>`
- `harness_dir=<path_optional>`
- `output_dir=<path>`
- `tool_timeout_sec=<int>`
- `strict=<true|false>`

## Prerequisite

- `echidna` binary must be available on PATH.
- If missing, emit `TOOLCHAIN:ECHIDNA_NOT_AVAILABLE` and include:
  - `install_hint`: `brew install echidna`
  - `install_doc_ref`: `vyper-full-audit/references/tool-installation.md`
- If harness inputs are absent, emit warning `TOOLCHAIN:ECHIDNA_HARNESS_REQUIRED` and skip execution deterministically.

## Output Contract

- Emit `{output_dir}/echidna-evidence.raw.json` with:
  - properties executed
  - failing seeds/counterexamples
  - execution metadata
- Do not assign canonical `rule_id` here.

## Validation

- Failing counterexamples must remain unresolved until independently validated.
- Missing tool must not be silently ignored; include remediation metadata.
- Harness-missing compatibility cases must emit explicit warning metadata.
