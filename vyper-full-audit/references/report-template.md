# Report Template v3

Template used to render `audit-report.md` from canonical `audit-report.json`.

JSON is source of truth. Markdown is presentation.

## Status Enum

`NEW|RECURRING|REGRESSION|ACKNOWLEDGED|RESOLVED|INCOMPLETE`

## ID Model

- `rule_id`: canonical internal taxonomy ID (`VYP-*`, `TOK-*`, `ORC-*`, `E46-*`, etc.)
- `finding_id`: deterministic instance ID (`FND-<hash>`)

---

# {project_name} - Security Audit Report

**Date**: {date}
**Scope**: {contract_count} Vyper contracts
**Compiler Versions**: {versions}
**Audit Mode**: {mode}
**Profile**: {profile}
**PROD_GATE**: {prod_gate}
**ASSURANCE_CHECKS**: {assurance_checks}

## Warnings

| Code | Level | Source | Message |
|---|---|---|---|
| {warning_code} | {warning_level} | {warning_source} | {warning_message} |

## Executive Summary

- **Total Findings**: {total_findings}
- **Critical**: {critical}
- **High**: {high}
- **Medium**: {medium}
- **Low**: {low}
- **Informational**: {informational}

## Gate Summary

| Check | Result | Notes |
|---|---|---|
| Core Inputs | {core_inputs_status} | {notes} |
| Vulnerability Scan | {scan_status} | {notes} |
| Spec Compliance | {spec_status} | {notes} |
| Assurance Checks | {assurance_checks} | {notes} |
| Toolchain | {toolchain_status} | {notes} |
| Standards Coverage | {standards_gate_status} | {notes} |
| Critical/High Validation | {critical_high_validation} | {notes} |

## Tool Coverage Summary

| Field | Value |
|---|---|
| Mode | {tool_mode} |
| Status | {tool_status} |
| Requested Tools | {requested_tools} |
| Executed Tools | {executed_tools} |
| Missing Tools | {missing_tools} |
| Failed Tools | {failed_tools} |
| Timed Out Tools | {timed_out_tools} |
| Mapped Findings | {mapped_tool_findings} |
| Unmapped Findings | {unmapped_tool_findings} |

## Standards Coverage Summary

| Field | Value |
|---|---|
| Enforcement | {standards_enforcement} |
| Profile | {profile} |
| Status | {standards_status} |
| Required Packs | {required_packs} |
| Missing Packs | {missing_packs} |
| Controls PASS/FAIL/PARTIAL/UNVERIFIED/UNMAPPED | {control_counts} |

## Findings

### Critical

#### {finding_id} ({rule_id}) - {title}
- **Severity**: Critical
- **Status**: {status}
- **Contract**: `{contract}:{line}`
- **Function**: `{function}`
- **Confidence**: {confidence}
- **Source**: {source}

**Description**: {description}

**Evidence**:
```vyper
{code_excerpt}
```

**Recommendation**: {recommendation}

### High

#### {finding_id} ({rule_id}) - {title}
- **Severity**: High
- **Status**: {status}
- **Contract**: `{contract}:{line}`
- **Function**: `{function}`
- **Confidence**: {confidence}
- **Source**: {source}

**Description**: {description}

**Evidence**:
```vyper
{code_excerpt}
```

**Recommendation**: {recommendation}

### Medium

| Finding ID | Rule ID | Contract | Function | Status | Confidence | Summary |
|---|---|---|---|---|---|---|
| {finding_id} | {rule_id} | `{contract}:{line}` | `{function}` | {status} | {confidence} | {summary} |

### Low

| Finding ID | Rule ID | Contract | Function | Status | Confidence | Summary |
|---|---|---|---|---|---|---|
| {finding_id} | {rule_id} | `{contract}:{line}` | `{function}` | {status} | {confidence} | {summary} |

### Informational

| Finding ID | Rule ID | Contract | Function | Status | Confidence | Summary |
|---|---|---|---|---|---|---|
| {finding_id} | {rule_id} | `{contract}:{line}` | `{function}` | {status} | {confidence} | {summary} |

## Systemic Patterns

| Pattern | Affected Contracts | Related Findings | Highest Severity |
|---|---|---|---|
| {pattern} | {contracts} | {finding_ids} | {severity} |

## Feature Risk Summary

| Feature | Contracts | Related Rules | Assurance Status | Notes |
|---|---|---|---|---|
| {feature} | {contracts} | {rule_ids} | {assurance_status} | {notes} |

## Delta Analysis

| Finding ID | Rule ID | Current Status | Prior Status | Classification |
|---|---|---|---|---|
| {finding_id} | {rule_id} | {current_status} | {prior_status} | {classification} |

## Spec Coverage

| Metric | Value |
|---|---|
| Total Requirements | {total_requirements} |
| PASS | {pass_count} |
| FAIL | {fail_count} |
| PARTIAL | {partial_count} |
| UNVERIFIED | {unverified_count} |
| UNMAPPED | {unmapped_count} |

## Compiler + CVE Assessment

| Version | Contracts | Applicable CVEs | Risk |
|---|---|---|---|
| {version} | {count} | {cves} | {risk} |

## Action Items

| Priority | Finding ID | Rule ID | Severity | Action | Effort |
|---|---|---|---|---|---|
| {priority} | {finding_id} | {rule_id} | {severity} | {action} | {effort} |
