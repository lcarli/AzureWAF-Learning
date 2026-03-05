# :bookmark_tabs: Module 04 — Managed RulesOWASP, DRS 2.1+ & Anomaly Scoring

!!! abstract "Default Rule Sets, anomaly scoring, and managed rule operations"

*This module covers 7 topics.*

---

### Azure WAF Managed Rules

Created, maintained, and updated by Microsoft security team automatically

Rules updated seamlessly - no customer action required

You cannot modify or delete managed rules (but can disable or create exclusions)

Based on OWASP Core Rule Set (CRS) with Microsoft enhancements

Default Rule Set (DRS) 2.1 is the recommended ruleset

Includes Microsoft Threat Intelligence Collection rules for zero-day protection

Rolling support policy: only latest 3 versions supported (from Feb 2026)

Older rulesets get 12-month final support window before retirement

Azure Portal: Managed Rule Sets


---

### Managed Ruleset Versions

Application Gateway

CRS 3.2 (OWASP-based)

DRS 2.1 (Microsoft Default - RECOMMENDED)

DRS 2.1 adds Microsoft Threat Intelligence rules

DRS 2.1 uses Anomaly Scoring mode

CRS 3.0 and 3.1 are being retired

Plan migration to DRS 2.1 ASAP

Front Door Premium

DRS 2.1 (Default and recommended)

DRS 1.x (Legacy - traditional mode)

DRS 2.x uses Anomaly Scoring

DRS 1.x uses Traditional (block on first match)

Microsoft Threat Intelligence rules included

Migrate from DRS 1.x to 2.x for better protection


---

### Common Attacks Prevented by Managed Rules

SQL Injection (SQLi): Blocks malicious SQL statements in parameters, headers, cookies

Cross-Site Scripting (XSS): Prevents script injection in user-facing pages

Remote Code Execution (RCE): Blocks OS command injection attempts

Local File Inclusion (LFI): Prevents path traversal attacks

Remote File Inclusion (RFI): Blocks inclusion of external malicious files

Protocol violations: Malformed HTTP requests, missing headers

Session fixation: Prevents session hijacking attempts

Scanner detection: Identifies and blocks automated vulnerability scanners

Java/Spring attacks: Log4Shell, Spring4Shell protection via MSTIC rules


---

### Anomaly Scoring vs. Traditional Mode

Anomaly Scoring (DRS 2.x) - RECOMMENDED

Each matching rule adds to a cumulative score

Default threshold: 5 points

Request blocked only when total score >= threshold

Reduces false positives significantly

Rule scores: Critical=5, Error=4, Warning=3, Notice=2

Allows legitimate traffic with minor rule matches

Better for production environments

Traditional Mode (DRS 1.x)

Block on first rule match

No scoring accumulation

Higher false positive rate

Simpler to understand

Legacy behavior - being phased out

Only available on Front Door DRS 1.x

Migrate to DRS 2.x for better accuracy


---

### Paranoia Level (PL)

Controls the aggressiveness of managed rules

PL1 (Default): Baseline rules with lowest false positive rate

PL2: Additional rules for moderate security - may increase false positives

PL3: Aggressive detection - recommended only for high-security apps

PL4: Maximum detection - very high false positive rate, needs extensive tuning

Higher PL = more rules enabled = more false positives = more tuning needed

Recommendation: Start with PL1, increase only if needed with proper tuning

Each level includes all rules from lower levels


---

### WAF Detection Process for Managed Rules

Request arrives at WAF engine

Phase 1: Request headers are evaluated against header-related rules

Phase 2: Request body is evaluated against body-related rules

Phase 3: Response headers are evaluated (if response inspection enabled)

Phase 4: Response body is evaluated (if response inspection enabled)

Anomaly score is accumulated across all phases

If total score >= threshold, action is taken (block/log based on mode)

Matched rules and scores are logged in diagnostic logs


---

### Behind the Scenes of a Managed Rule

Each managed rule has: Rule ID, Rule Group, Severity, Description

Rule evaluation uses pattern matching (regex) against request components

Example Rule 942100 (SQL Injection Detection):

Evaluates: ARGS, ARGS_NAMES, REQUEST_COOKIES, REQUEST_HEADERS

Pattern: Detects common SQL keywords (SELECT, UNION, INSERT, DROP...)

Severity: Critical (score = 5 in anomaly mode)

Action: Depends on mode (block in Prevention, log in Detection)

Understanding rule internals helps with tuning and exclusion creation


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB03](../labs/lab03.md)
- [:octicons-beaker-24: LAB03B](../labs/lab03b.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 03](03-waf-policies.md)</div>
<div>[Module 05 :octicons-arrow-right-24:](05-exclusions.md)</div>
</div>
