# :six: Challenge 6 — Count the Scanners

!!! abstract "Difficulty: :orange_circle: Hard — Skills: Aggregation, deduplication, User-Agent analysis"

## :page_facing_up: Scenario

Your WAF detected automated **vulnerability scanner traffic** coming from the `10.99.1.x` IP range. Multiple scanning tools were used, each with a **different User-Agent string**. They probed paths like `/admin`, `/phpmyadmin/`, `/.env`, `/web.config`, and other sensitive endpoints.

**Your mission**: Determine how many **distinct scanner tools** (unique User-Agent strings) were used in this scan.

---

## :clipboard: Prerequisites

- [x] Lab infrastructure deployed
- [x] WAF logs flowing to Log Analytics

## :rocket: Generate Challenge Traffic

:octicons-download-24: **Script**: [challenge-traffic.ps1](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/challenge-traffic.ps1)

```powershell
cd scripts/
.\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge 6
```

!!! warning "Wait 10-15 minutes for logs to appear in Log Analytics before investigating."

---

## :mag: Investigation

Filter by the scanner IP range, extract the User-Agent strings, and count the distinct values.

??? example "Hint 1 — Filter by IP range"
    Use `where clientIp_s startswith "10.99.1."` to isolate scanner traffic.

??? example "Hint 2 — Count distinct User-Agents"
    Use `dcount(userAgent_s)` or `summarize by UA | count` to find unique scanners.

??? example "Hint 3 — KQL Query"
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where clientIp_s startswith "10.99.1."
    | extend UA = column_ifexists("userAgent_s", "")
    | where UA != ""
    | summarize RequestCount = count() by UA
    | count
    ```
    Or to see the individual scanners:
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where clientIp_s startswith "10.99.1."
    | extend UA = column_ifexists("userAgent_s", "")
    | where UA != ""
    | summarize RequestCount = count() by UA
    | order by RequestCount desc
    ```

---

## :white_check_mark: Submit Your Answer

How many **distinct scanner tools** were detected?

{% include "challenges/challenge-ui.html" %}

<div class="challenge-box">
  <input type="text" id="challenge-answer" placeholder="Enter a number..." class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer('4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a')">
  <button onclick="checkAnswer('4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a')" class="challenge-btn">Check Answer</button>
  <div id="challenge-result" class="challenge-result"></div>
</div>

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Challenge 5](challenge-05.md)</div>
<div>[:octicons-arrow-left-24: All Challenges](index.md)</div>
</div>
