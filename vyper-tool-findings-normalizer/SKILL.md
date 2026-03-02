---
name: vyper-tool-findings-normalizer
description: >-
  Normalizes raw tool outputs into canonical tool artifacts and applies
  mapping, severity normalization, and validation contracts.
---

# Vyper Tool Findings Normalizer

Transforms raw tool outputs into canonical artifacts.

## Inputs

- `slither_raw=<path>`
- `mythril_raw=<path>`
- `echidna_raw=<path>`
- `output_dir=<path>`
- `strict=<true|false>`

## Required References

- `references/tool-mapping.md`
- `references/tool-severity-normalization.md`
- `references/external-control-map.json`
- `references/rule-id-migration-map.json`
- `references/schemas/tool-findings.schema.json`
- `references/schemas/tool-validation.schema.json`

## Output Contract

- `{output_dir}/tool-findings.json`
- `{output_dir}/tool-validation.json`
- `toolchain-context.json` remediation metadata is preserved (`reason_code`, `install_hint`, `install_doc_ref`) when tools are unavailable.

Rules:
- Canonical `rule_id` ownership is internal.
- Unmapped tool findings remain explicit in `unmapped_findings[]`.
- Any Critical/High unverified finding yields blocking summary status.
- Missing-tool cases must preserve deterministic reason codes in `TOOLCHAIN:*` namespace.
- Compatibility-limited adapter runs (`TOOLCHAIN:MYTHRIL_VYPER_LIMITED`, `TOOLCHAIN:ECHIDNA_HARNESS_REQUIRED`) must remain warning-only unless explicit blocker conditions exist.
