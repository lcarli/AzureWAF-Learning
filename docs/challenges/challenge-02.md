# :two: Challenge 2 — Name the Rule

!!! abstract "Difficulty: :green_circle: Easy — Skills: Rule ID lookup, log analysis"

## :page_facing_up: Scenario

An attacker has been sending **XSS (Cross-Site Scripting)** payloads containing the string `WAF-CHALLENGE-2026`. All payloads use `<script>alert('WAF-CHALLENGE-2026')</script>` injected into various query parameters.

A specific WAF managed rule detected and flagged every single one of these requests.

**Your mission**: Find the **Rule ID** that detected these XSS attacks.

---

## :clipboard: Prerequisites

- [x] Lab infrastructure deployed
- [x] WAF logs flowing to Log Analytics

## :rocket: Generate Challenge Traffic

```powershell
cd scripts/
.\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge 2
```

!!! warning "Wait 10-15 minutes for logs to appear in Log Analytics before investigating."

---

## :mag: Investigation

Search the WAF logs for events related to the `WAF-CHALLENGE-2026` payload and identify which rule triggered.

??? example "Hint 1 — Search for the payload"
    Look for `WAF-CHALLENGE-2026` in `requestUri_s` or `details_data_s` fields.

??? example "Hint 2 — Group by rule"
    Use `summarize count() by ruleId_s, message_s` to find which rule matched.

??? example "Hint 3 — KQL Query"
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where requestUri_s contains "WAF-CHALLENGE-2026"
        or details_data_s contains "WAF-CHALLENGE-2026"
    | summarize Count = count() by ruleId_s, message_s
    | order by Count desc
    ```

---

## :white_check_mark: Submit Your Answer

What is the **Rule ID** that detected the XSS attacks?

{% include "challenges/challenge-ui.html" %}

<div class="challenge-box">
  <input type="text" id="challenge-answer" placeholder="e.g., 942100" class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer('b28161474e6d3bb6240da827a2dd52450cb7cfaacd38ef41988f060611e1c3c1')">
  <button onclick="checkAnswer('b28161474e6d3bb6240da827a2dd52450cb7cfaacd38ef41988f060611e1c3c1')" class="challenge-btn">Check Answer</button>
  <div id="challenge-result" class="challenge-result"></div>
</div>

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Challenge 1](challenge-01.md)</div>
<div>[Challenge 3 :octicons-arrow-right-24:](challenge-03.md)</div>
</div>
