# Report Template

Template for audit report output. Fill in `{placeholders}` during report generation.

Matches the structure established by prior audits (AUDIT_REPORT_V2.md pattern).
Sections are ordered by reader priority: executive summary first, action items last.

---

## How to Use

1. Replace all `{placeholders}` with actual values during generation.
2. Delete any severity section that has zero findings (e.g., if no Critical findings, remove the Critical section entirely).
3. Finding IDs use prefix convention: `V-` (vault), `A-` (adapter/strategy/bridge), `P-` (P2P lending), `F-` (factory).
4. Status field tracks delta from prior audits: NEW, RECURRING, REGRESSION, RESOLVED.
5. Cross-Cutting Patterns section captures systemic issues spanning multiple contracts.

---

# {project_name} — Security Audit Report

**Date**: {date}
**Auditor**: {auditor_identifier}
**Scope**: {contract_count} Vyper {vyper_version} contracts (~{loc} LOC)
**Contracts Directory**: `{contracts_dir}`
**Compiler Versions**: {versions}
**Prior Audits**: {prior_audit_count} ({prior_finding_count} findings across prior audits)
**Methodology**: {methodology_description}

---

## Executive Summary

**{total_findings} validated findings** across the audited contract suite. Organized by severity, deduplicated, and verified against source code.

**Finding distribution:**

| Severity | Count |
|----------|-------|
| Critical | {critical} |
| High | {high} |
| Medium | {medium} |
| Low | {low} |
| Informational | {info} |
| **Total** | **{total}** |

**Prior audit status:**
{prior_audit_status_bullets}
<!-- Format each as: - {finding_id} ({description}): **{STATUS}** — {detail} -->

---

## Scope

### Contracts Audited

| Contract | Path | LOC | Classification |
|----------|------|-----|----------------|
| {contract_name} | `{contract_path}` | {loc} | {classification} |
<!-- Classification: Core, Adapter, Strategy, Bridge, Factory, Auxiliary -->
<!-- One row per audited contract -->

### Contracts Excluded

| Contract | Path | Reason |
|----------|------|--------|
| {contract_name} | `{contract_path}` | {exclusion_reason} |
<!-- Common reasons: Test mock, Interface-only, Out of scope, Third-party dependency -->

---

## Findings

### Critical

<!-- Critical: Direct fund loss, privilege escalation, or protocol-breaking vulnerability -->
<!-- exploitable without preconditions or with readily achievable preconditions -->

#### {finding_id}: {title}

- **Severity**: Critical
- **Category**: {category}
- **Contract**: `{contract_file}:{line_number}`
- **Status**: NEW | RECURRING | REGRESSION
- **Prior audit ref**: {prior_finding_id} (if applicable, otherwise omit this line)

**Description**: {description}

**Evidence**:
```vyper
{code_excerpt}
```

**Impact**: {impact_statement}

**Recommendation**:
{recommendation}

---

### High

<!-- High: Significant fund risk, DoS, or privilege boundary violation -->
<!-- exploitable but may require specific preconditions -->

#### {finding_id}: {title}

- **Severity**: High
- **Category**: {category}
- **Contract**: `{contract_file}:{line_number}`
- **Status**: NEW | RECURRING | REGRESSION
- **Prior audit ref**: {prior_finding_id}

**Description**: {description}

**Evidence**:
```vyper
{code_excerpt}
```

**Impact**: {impact_statement}

**Recommendation**:
{recommendation}

---

### Medium

<!-- Medium: Conditional fund risk, accounting errors, or violated invariants -->
<!-- requires uncommon preconditions or limited blast radius -->

#### {finding_id}: {title}

- **Severity**: Medium
- **Category**: {category}
- **Contract**: `{contract_file}:{line_number}`
- **Status**: NEW | RECURRING | REGRESSION

**Description**: {description}

**Evidence**:
```vyper
{code_excerpt}
```

**Impact**: {impact_statement}

**Recommendation**:
{recommendation}

---

### Low

<!-- Low: Defense-in-depth, code quality, minor edge cases -->
<!-- Tabular format for brevity -->

| ID | Contract | Line | Issue | Recommendation |
|----|----------|------|-------|----------------|
| {finding_id} | `{contract_file}` | {line} | {issue_description} | {recommendation} |

---

### Informational

<!-- Informational: Best practices, documentation gaps, style -->
<!-- Tabular format for brevity -->

| ID | Contract | Line | Issue | Recommendation |
|----|----------|------|-------|----------------|
| {finding_id} | `{contract_file}` | {line} | {issue_description} | {recommendation} |

---

## Cross-Cutting Patterns

Patterns that appear across multiple contracts or findings. These indicate systemic issues rather than isolated bugs.

| Pattern | Contracts Affected | Related Findings | Severity |
|---------|--------------------|-----------------|----------|
| {pattern_name} | {contract_list} | {finding_ids} | {max_severity} |
<!-- Example patterns: -->
<!-- Unlimited ERC20 approvals | LendingVault.vy | V-C1 | Critical -->
<!-- Missing buffer deduction | LendingVault.vy | V-H1, V-H4 | High -->
<!-- Unchecked raw_call return | AavePoolBridge.vy, MorphoBridge.vy | A-M4 | Medium -->

---

## Trust Assumptions Matrix

| Role | Trust Level | Assumption | If Compromised |
|------|------------|------------|----------------|
| {role} | {trust_level} | {what_is_assumed} | {maximum_damage} |
<!-- Trust levels: Fully trusted, Semi-trusted, External dependency, Untrusted -->
<!-- Include: Owner, Curator, Factory Owner, Registered Adapter, Yield Strategy, -->
<!--          Registered Market, Bridge Auth Strategy, Oracle, Flash Lender -->

---

## Delta Analysis

Comparison with prior audits. Only include this section if prior audits exist.

### Summary

| Status | Count | Description |
|--------|-------|-------------|
| NEW | {new} | First identified in this audit |
| RECURRING | {recurring} | Present in prior audit, still unfixed |
| REGRESSION | {regression} | Fixed in prior audit, re-introduced |
| RESOLVED | {resolved} | Present in prior audit, now fixed |

### Resolved Findings

| Prior ID | Title | Resolution |
|----------|-------|------------|
| {prior_finding_id} | {title} | {how_resolved} |

### Recurring Findings

| Prior ID | Current ID | Title | Notes |
|----------|-----------|-------|-------|
| {prior_finding_id} | {current_finding_id} | {title} | {what_changed} |

---

## Spec Coverage

Map findings and verification against specification documents. Only include if specs exist.

| Spec Document | Requirements | Verified | Partial | Failed | N/A |
|---------------|-------------|----------|---------|--------|-----|
| {spec_name} | {req_count} | {verified} | {partial} | {failed} | {na} |
<!-- Verified: requirement is correctly implemented and tested -->
<!-- Partial: implemented but with caveats or missing edge cases -->
<!-- Failed: implementation contradicts spec -->
<!-- N/A: requirement not yet implemented or out of scope -->

---

## Compiler Version Assessment

| Version | Contracts | Applicable CVEs | Unfixed CVEs | Risk Level |
|---------|-----------|-----------------|--------------|------------|
| {version} | {contract_count} | {cve_list} | {unfixed_list} | {risk} |
<!-- Risk levels: None, Low, Medium, High -->
<!-- Check: https://github.com/vyperlang/vyper/security/advisories -->
<!-- Include CVE ID, affected pattern, and whether audited code triggers it -->

### CVE Detail

| CVE | Description | Affected Pattern | Present in Codebase | Risk |
|-----|-------------|-----------------|---------------------|------|
| {cve_id} | {description} | {pattern} | Yes/No | {risk} |

---

## Action Items

Prioritized remediation plan. Items within each priority are ordered by estimated impact.

### Priority 1 — Critical (fix before any deployment)

| # | Finding | Action | Effort |
|---|---------|--------|--------|
| 1 | {finding_id} | {action_description} | {effort_estimate} |
<!-- Effort: Trivial (< 1 hr), Low (< 1 day), Medium (1-3 days), High (> 3 days) -->

### Priority 2 — High (fix before mainnet)

| # | Finding | Action | Effort |
|---|---------|--------|--------|
| {n} | {finding_id} | {action_description} | {effort_estimate} |

### Priority 3 — Medium (fix in next release)

| # | Finding | Action | Effort |
|---|---------|--------|--------|
| {n} | {finding_id} | {action_description} | {effort_estimate} |

### Priority 4 — Low/Informational (address when convenient)

| # | Finding | Action | Effort |
|---|---------|--------|--------|
| {n} | {finding_id} | {action_description} | {effort_estimate} |

---

## Appendix A: Finding Categories

Reference for the `Category` field used in findings.

| Category | Description |
|----------|-------------|
| Access Control | Missing or insufficient permission checks |
| Arithmetic | Overflow, underflow, precision loss, rounding |
| Reentrancy | Same-contract or cross-contract reentrancy |
| Oracle | Price feed validation, staleness, manipulation |
| DoS | Denial of service via gas, array bounds, or griefing |
| Accounting | Incorrect balance/share/fee tracking |
| Input Validation | Missing parameter checks or bounds |
| Trust Boundary | Excessive trust in external components |
| Upgradeability | Immutability constraints, no migration path |
| Token Handling | Non-standard ERC20 behavior, approval patterns |
| Compiler | Vyper CVE or version-specific behavior |
| Code Quality | Dead code, missing events, documentation gaps |

## Appendix B: Severity Definitions

| Severity | Criteria |
|----------|----------|
| Critical | Direct loss of funds or complete protocol compromise. Exploitable without unlikely preconditions. |
| High | Significant fund risk or protocol disruption. May require specific but achievable preconditions. |
| Medium | Conditional fund risk, violated invariants, or accounting errors. Requires uncommon preconditions or has limited blast radius. |
| Low | Defense-in-depth issues, minor edge cases, code quality. No direct fund risk under normal conditions. |
| Informational | Best practices, documentation gaps, style recommendations. No security impact. |
