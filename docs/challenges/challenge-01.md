# :one: Challenge 1 — Identify the Attacker

!!! abstract "Difficulty: :green_circle: Easy — Skills: KQL queries, IP analysis"

## :page_facing_up: Scenario

Your Azure WAF has detected a burst of **SQL injection attacks**. A single IP address is responsible for all of them — 50 requests containing classic SQLi payloads like `OR 1=1`, `UNION SELECT`, and `DROP TABLE`.

**Your mission**: Analyze the WAF logs and identify the attacker's IP address.

---

## :clipboard: Prerequisites

- [x] Lab infrastructure deployed
- [x] WAF logs flowing to Log Analytics

## :rocket: Generate Challenge Traffic

```powershell
cd scripts/
.\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge 1
```

!!! warning "Wait 10-15 minutes for logs to appear in Log Analytics before investigating."

---

## :mag: Investigation

Use **Log Analytics** or **WAF Insights** to find which IP address sent the SQL injection attacks.

??? example "Hint 1 — Which log table to use"
    Query the `AzureDiagnostics` table filtered by `Category == "ApplicationGatewayFirewallLog"`.

??? example "Hint 2 — How to filter for SQLi"
    Filter where `ruleGroup_s` contains `"SQLI"` or look at rule IDs in the 942xxx range.

??? example "Hint 3 — KQL Query"
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where ruleGroup_s contains "SQLI"
    | summarize AttackCount = count() by clientIp_s
    | order by AttackCount desc
    | take 5
    ```

---

## :white_check_mark: Submit Your Answer

What is the **IP address** of the attacker?

{% include "challenges/challenge-ui.html" %}

<div class="challenge-box">
  <input type="text" id="challenge-answer" placeholder="e.g., 192.168.1.1" class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer('dc6693d50f7d237af8a04dd3b9a42e37c4978979aedc7dc60723b3df22a880af')">
  <button onclick="checkAnswer('dc6693d50f7d237af8a04dd3b9a42e37c4978979aedc7dc60723b3df22a880af')" class="challenge-btn">Check Answer</button>
  <div id="challenge-result" class="challenge-result"></div>
</div>

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: All Challenges](index.md)</div>
<div>[Challenge 2 :octicons-arrow-right-24:](challenge-02.md)</div>
</div>
