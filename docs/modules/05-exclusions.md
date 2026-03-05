# :wrench: Module 05 — Exclusions & FalsePositive Tuning

!!! abstract "False positive tuning with exclusions and best practices"

*This module covers 4 topics.*

---

### WAF Tuning Best Practices

Step 1: Deploy WAF in Detection mode and collect logs for 2-4 weeks

Step 2: Analyze logs to identify false positives using KQL queries

Step 3: Create exclusions for legitimate traffic patterns

Step 4: Disable specific rules only if exclusion is not possible

Step 5: Switch to Prevention mode and monitor closely

Step 6: Continuously refine based on new application changes

Over 50% of support cases are due to false positives - proper tuning is essential!

Less than 5% of support cases are due to managed rule bugs


---

### Exclusions - Concepts

Exclusions tell the WAF to ignore specific request attributes during evaluation

Can be applied globally or to specific rules/rule groups (per-rule exclusions)

Exclusion scopes: Request Header, Cookie, Query String, Body, URI

Match operators: Equals, Contains, Starts With, Ends With, Regex

Per-rule exclusions are more secure - skip inspection only for specific rules

Global exclusions skip ALL rule evaluations for the specified attribute

IMPORTANT: Do NOT create blanket exclusions - be as specific as possible


---

### Common Exclusion Scenarios

Microsoft Entra ID tokens: Auth headers trigger false positives (special chars)

- > Exclude "Authorization" header for specific authentication rules
CSRF tokens: Anti-forgery tokens contain encoded characters

- > Exclude "__RequestVerificationToken" cookie for XSS rules
Rich text editors: HTML content in request body triggers XSS rules

- > Exclude specific body parameters for XSS rule group
File uploads: Binary content triggers various rule groups

- > Consider body size limits and specific rule exclusions
API payloads: JSON/XML payloads with special characters

- > Exclude specific parameters for SQL/XSS rule groups

---

### Exclusions: Application Gateway vs. Front Door

Application Gateway Exclusions

Supports per-rule exclusions since DRS 2.1

Global exclusions for all managed rules

Scopes: header, cookie, args, body

Operators: equals, contains, starts/ends with

Can exclude by request attribute name

Recommended: Use per-rule exclusions

Front Door Exclusions

Per-rule exclusions supported

Global exclusions for all managed rules

Same exclusion scopes as Application Gateway

Common: Entra ID token in Authorization header

Common: Cookie-based session tokens

Recommended: Start per-rule, expand only if needed


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB04](../labs/lab04.md)
- [:octicons-beaker-24: LAB03B](../labs/lab03b.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 04](04-managed-rules.md)</div>
<div>[Module 06 :octicons-arrow-right-24:](06-custom-rules.md)</div>
</div>
