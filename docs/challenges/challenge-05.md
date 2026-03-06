# :five: Challenge 5 — The Poisoned Parameter

!!! abstract "Difficulty: :orange_circle: Hard — Skills: Parameter extraction, URI parsing"

## :page_facing_up: Scenario

An attacker from IP `172.16.99.5` is injecting **XSS payloads** into your application. All the attacks use the **same query parameter** to deliver the malicious content — payloads like cookie stealing scripts, event handler injections, and encoded `<script>` tags.

**Your mission**: Identify the **query parameter name** being used as the injection vector.

---

## :clipboard: Prerequisites

- [x] Lab infrastructure deployed
- [x] WAF logs flowing to Log Analytics

## :rocket: Generate Challenge Traffic

:octicons-download-24: **Script**: [challenge-traffic.ps1](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/challenge-traffic.ps1)

```powershell
cd scripts/
.\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge 5
```

!!! warning "Wait 10-15 minutes for logs to appear in Log Analytics before investigating."

---

## :mag: Investigation

Filter by the attacker's IP, examine the request URIs, and extract the common parameter name.

??? example "Hint 1 — Filter by attacker IP"
    Use `where clientIp_s == "172.16.99.5"` and filter for XSS rule groups.

??? example "Hint 2 — Parse the query string"
    Use KQL string functions: `split(requestUri_s, "?")` to get the query string, then `split(..., "=")` to extract parameter names.

??? example "Hint 3 — KQL Query"
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where clientIp_s == "172.16.99.5"
    | where ruleGroup_s contains "XSS"
    | extend QueryString = tostring(split(requestUri_s, "?")[1])
    | extend ParamName = tostring(split(QueryString, "=")[0])
    | summarize Count = count() by ParamName
    | order by Count desc
    ```

---

## :white_check_mark: Submit Your Answer

What is the **query parameter name** used for XSS injection?

{% include "challenges/challenge-ui.html" %}

<div class="challenge-box">
  <input type="text" id="challenge-answer" placeholder="e.g., search" class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer('f2579d976934c7888785842d8e5a48a140453222e5dbca50d5a1226cd63a8dc7')">
  <button onclick="checkAnswer('f2579d976934c7888785842d8e5a48a140453222e5dbca50d5a1226cd63a8dc7')" class="challenge-btn">Check Answer</button>
  <div id="challenge-result" class="challenge-result"></div>
</div>

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Challenge 4](challenge-04.md)</div>
<div>[Challenge 6 :octicons-arrow-right-24:](challenge-06.md)</div>
</div>
