# :three: Challenge 3 — The Secret Path

!!! abstract "Difficulty: :yellow_circle: Medium — Skills: URI analysis, attack pattern correlation"

## :page_facing_up: Scenario

An attacker from IP `203.0.113.77` has been probing your application with **multiple attack types** — SQL injection, XSS, command injection, path traversal, and remote file inclusion. However, all attacks are targeting a **single specific API endpoint**.

**Your mission**: Identify the **URI path** being targeted.

---

## :clipboard: Prerequisites

- [x] Lab infrastructure deployed
- [x] WAF logs flowing to Log Analytics

## :rocket: Generate Challenge Traffic

:octicons-download-24: **Script**: [challenge-traffic.ps1](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/challenge-traffic.ps1)

```powershell
cd scripts/
.\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge 3
```

!!! warning "Wait 10-15 minutes for logs to appear in Log Analytics before investigating."

---

## :mag: Investigation

Filter WAF logs by the attacker's IP and analyze which URI path is being targeted.

??? example "Hint 1 — Filter by attacker IP"
    Use `where clientIp_s == "203.0.113.77"` to isolate the attacker's traffic.

??? example "Hint 2 — Extract the path"
    Use `extend Path = tostring(split(requestUri_s, "?")[0])` to separate path from query string.

??? example "Hint 3 — KQL Query"
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where clientIp_s == "203.0.113.77"
    | extend Path = tostring(split(requestUri_s, "?")[0])
    | summarize AttackTypes = dcount(ruleGroup_s), Count = count() by Path
    | order by Count desc
    ```

---

## :white_check_mark: Submit Your Answer

What is the **full URI path** being targeted? (Include leading `/`)

{% include "challenges/challenge-ui.html" %}

<div class="challenge-box">
  <input type="text" id="challenge-answer" placeholder="e.g., /api/v1/users" class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer('7c08f0b9b38ec31c605bbb3acaac74b8c820513967e7d8760b9bc4aef8df52f3')">
  <button onclick="checkAnswer('7c08f0b9b38ec31c605bbb3acaac74b8c820513967e7d8760b9bc4aef8df52f3')" class="challenge-btn">Check Answer</button>
  <div id="challenge-result" class="challenge-result"></div>
</div>

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Challenge 2](challenge-02.md)</div>
<div>[Challenge 4 :octicons-arrow-right-24:](challenge-04.md)</div>
</div>
