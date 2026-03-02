---
name: vyper-mythril-scan
description: >-
  Runs Mythril as optional compatibility adapter and emits normalized
  intermediate artifacts for tool findings correlation.
---

# Vyper Mythril Scan

Use Mythril findings as optional compatibility evidence input.

## Inputs

- `contracts_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `bytecode_dir=<path_optional>`
- `output_dir=<path>`
- `tool_timeout_sec=<int>`
- `strict=<true|false>`

## Prerequisite

- `myth` binary must be available on PATH.
- If missing, emit `TOOLCHAIN:MYTHRIL_NOT_AVAILABLE` and include:
  - `install_hint`: `python3 -m pip install --user mythril`
  - `install_doc_ref`: `vyper-full-audit/references/tool-installation.md`
- If no compatible bytecode-oriented input is available for requested targets, emit warning `TOOLCHAIN:MYTHRIL_VYPER_LIMITED` and skip execution deterministically.

## Output Contract

- Emit raw findings file: `{output_dir}/mythril-findings.raw.json`
- Include deterministic per-issue fingerprint fields.
- Do not assign canonical `rule_id` here.

## Validation

- Timeout or execution failure must be explicit in output metadata.
- Do not silently drop failed analyses.
- Missing tool must not be silently ignored; include remediation metadata.
- Compatibility-limited runs must not fabricate findings; emit explicit warning metadata.
