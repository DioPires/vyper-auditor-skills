---
name: vyper-slither-scan
description: >-
  Runs Slither for Vyper audit workflows and emits normalized intermediate
  artifacts for tool findings correlation.
---

# Vyper Slither Scan

Use Slither findings as baseline tool evidence input for pure Vyper repositories.

## Inputs

- `contracts_dir=<csv_paths>`
- `exclude=<csv_paths>`
- `output_dir=<path>`
- `tool_timeout_sec=<int>`
- `strict=<true|false>`

## Prerequisite

- `slither` binary must be available on PATH.
- If missing, emit `TOOLCHAIN:SLITHER_NOT_AVAILABLE` and include:
  - `install_hint`: `python3 -m pip install --user slither-analyzer`
  - `install_doc_ref`: `vyper-full-audit/references/tool-installation.md`

## Output Contract

- Emit raw findings file: `{output_dir}/slither-findings.raw.json`
- Include deterministic per-issue fingerprint fields.
- Do not assign canonical `rule_id` here.

## Validation

- Timeout or execution failure must be explicit in output metadata.
- Do not silently drop failed analyses.
- Missing tool must not be silently ignored; include remediation metadata.
