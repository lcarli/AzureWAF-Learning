# :four: Challenge 4 — Bot Detective

!!! abstract "Difficulty: :yellow_circle: Medium — Skills: User-Agent analysis, bot detection"

## :page_facing_up: Scenario

A malicious bot has been **crawling your entire site** — scanning admin pages, configuration files, backup files, and sensitive endpoints. It uses a **custom User-Agent string** that doesn't match any known browser or legitimate bot.

The bot made approximately 60 requests across 20 different paths.

**Your mission**: Identify the bot's **User-Agent string**.

---

## :clipboard: Prerequisites

- [x] Lab infrastructure deployed
- [x] WAF logs flowing to Log Analytics
- [x] Bot Manager ruleset enabled (default in workshop setup)

## :rocket: Generate Challenge Traffic

:octicons-download-24: **Script**: [challenge-traffic.ps1](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/challenge-traffic.ps1)

```powershell
cd scripts/
.\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge 4
```

!!! warning "Wait 10-15 minutes for logs to appear in Log Analytics before investigating."

---

## :mag: Investigation

Look for unusual User-Agent strings in the WAF or Access logs. The bot's UA won't match standard browsers.

??? example "Hint 1 — Where to find User-Agent"
    Check the `userAgent_s` field in WAF logs, or look at the Access Log for non-standard UAs.

??? example "Hint 2 — Filter out legitimate browsers"
    Legitimate browsers contain `Mozilla`. Filter for UAs that don't match known patterns.

??? example "Hint 3 — KQL Query"
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where ruleSetType_s == "Microsoft_BotManagerRuleSet"
    | extend UA = column_ifexists("userAgent_s", "")
    | summarize Count = count() by UA
    | where UA !contains "Mozilla" and UA != ""
    | order by Count desc
    ```

---

## :white_check_mark: Submit Your Answer

What is the **exact User-Agent string** of the malicious bot?

{% include "challenges/challenge-ui.html" %}

<div class="challenge-box">
  <input type="text" id="challenge-answer" placeholder="e.g., BadBot/1.0" class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer('26e83c1300782d73ed80324165739c40102a0713b64790e643b64855f009454f')">
  <button onclick="checkAnswer('26e83c1300782d73ed80324165739c40102a0713b64790e643b64855f009454f')" class="challenge-btn">Check Answer</button>
  <div id="challenge-result" class="challenge-result"></div>
</div>

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Challenge 3](challenge-03.md)</div>
<div>[Challenge 5 :octicons-arrow-right-24:](challenge-05.md)</div>
</div>
