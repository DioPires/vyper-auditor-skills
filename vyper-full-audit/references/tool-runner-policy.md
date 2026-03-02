# Tool Runner Policy (v3)

Defines deterministic tool execution behavior for Vyper-first audits.

## Inputs

- `toolchain=required|enabled|disabled`
- `tools=<csv_tools>` where each is `slither|mythril|echidna`
- `tool_timeout_sec=<int>`
- `tool_fail_open=true|false`

## Defaults

- `toolchain=enabled`
- `tools=slither`
- `tool_timeout_sec=900`
- `tool_fail_open=false`

## Vyper-First Suitability Contract

- `slither`: baseline static analyzer for pure Vyper source audits.
- `mythril`: optional compatibility adapter; useful mainly in bytecode-oriented workflows.
- `echidna`: optional compatibility adapter; requires harness-backed property workflow.
- Pure Vyper production recommendation: `toolchain=required tools=slither`.

## Required Mode Rules

- `toolchain=required` enforces full availability for requested tools.
- `toolchain=required` with `tool_fail_open=true` is invalid (hard error).
- Missing/timeout/error on requested tool in required mode => `TOOLCHAIN:*` blocked reason.
- Compile incompatibility (`TOOLCHAIN:TOOL_COMPILE_FAIL`) on requested tool in required mode => blocked.
- If optional adapters (`mythril`, `echidna`) are explicitly requested in required mode, they are treated as hard requirements for that run.

## Enabled Mode Rules

- `tool_fail_open=false`: missing/timeout/error on requested tool => blocked.
- `tool_fail_open=true`: missing/timeout/error => warning; no standalone block.
- `tool_fail_open=true`: compile incompatibility (`TOOLCHAIN:TOOL_COMPILE_FAIL`) => warning; no standalone block.
- Suitability warnings are explicit but non-blocking by themselves:
  - `TOOLCHAIN:MYTHRIL_VYPER_LIMITED`
  - `TOOLCHAIN:ECHIDNA_HARNESS_REQUIRED`

## Disabled Mode Rules

- Toolchain artifacts are still emitted with `status=SKIPPED`.
- Requested tools list should be empty after normalization.

## Critical/High Validation Rules

- Any unverified Critical/High tool finding => `TOOLCHAIN:CRITICAL_HIGH_UNVERIFIED` block.
- Medium/Low findings are non-blocking by default.

## Remediation Contract for Missing Tools

For each tool with status `MISSING|ERROR|TIMEOUT`, `toolchain-context.json` must include:
- `reason_code` in `TOOLCHAIN:*` namespace
- `install_hint` with short deterministic command hint
- `install_doc_ref` pointing to local runbook

Reason code examples:
- `TOOLCHAIN:TOOLS_NOT_AVAILABLE` (aggregate)
- `TOOLCHAIN:SLITHER_NOT_AVAILABLE`
- `TOOLCHAIN:MYTHRIL_NOT_AVAILABLE`
- `TOOLCHAIN:ECHIDNA_NOT_AVAILABLE`
- `TOOLCHAIN:SLITHER_TIMEOUT`
- `TOOLCHAIN:TOOL_COMPILE_FAIL`
- `TOOLCHAIN:MYTHRIL_VYPER_LIMITED`
- `TOOLCHAIN:ECHIDNA_HARNESS_REQUIRED`

Install runbook reference:
- `references/tool-installation.md`
