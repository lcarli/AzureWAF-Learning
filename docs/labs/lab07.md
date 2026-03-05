# Lab 07 - Configure Bot Protection and JavaScript Challenge

## Overview

In this lab, you will configure **bot protection** on Azure WAF using the **Bot Manager** ruleset. You will learn how Azure WAF categorizes bots into Good, Bad, and Unknown categories, test bot detection using various User-Agent strings, configure the **JavaScript Challenge** action on Front Door to distinguish between real browsers and automated clients, and fine-tune bot rules for production use.

## Objectives

- Examine the Bot Manager 1.1 ruleset and understand its rule groups
- Understand the three bot categories: Good, Bad, and Unknown
- Test bot detection using simulated bot traffic
- Analyze bot detection logs with KQL queries
- Configure a JavaScript Challenge (JSChallenge) custom rule on Front Door
- Test the JavaScript Challenge with automated clients vs. browsers
- Fine-tune bot rules by overriding actions for specific categories
- Learn bot protection best practices for production deployments

## Prerequisites

- Completed Lab 06 (Front Door WAF configuration)
- Front Door Premium with WAF policy in Prevention mode
- Application Gateway WAF v2 with WAF policy configured
- Bot Manager 1.1 ruleset enabled on both WAF policies
- Log Analytics workspace with WAF diagnostics enabled
- Access to Azure Portal and Azure CLI

---

## Section 1: Examine Bot Manager Ruleset

### 1.1 View Bot Manager Rules in Portal (Front Door)

1. Navigate to the **Azure Portal** → **Resource Groups** → your workshop resource group.

2. Open the **Front Door WAF Policy** (e.g., `wafpolicyfd`).

3. Click **Managed rules** in the left-hand menu.

4. Locate the **Microsoft_BotManagerRuleSet** (version 1.1).

5. Click to expand the rule set and examine the rule groups:

   | Rule Group | Description | Example Rule IDs |
   |-----------|-------------|------------------|
   | **BadBots** | Known malicious bots and scrapers | Bot100100, Bot100200 |
   | **GoodBots** | Legitimate bots (search engines, monitoring) | Bot200100, Bot200200 |
   | **UnknownBots** | Unclassified automated clients | Bot300100, Bot300200 |

### 1.2 View Bot Manager Rules in Portal (Application Gateway)

1. Navigate to the **Application Gateway WAF Policy** (e.g., `wafpolicy`).

2. Click **Managed rules** in the left-hand menu.

3. Locate the **BotProtection** rule set if enabled.

4. Review the available rules. Note that Application Gateway Bot Manager has fewer features than Front Door's Bot Manager.

### 1.3 Verify Bot Manager via Azure CLI

```bash
# Check Front Door WAF policy managed rules
az network front-door waf-policy show \
  --name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --query "managedRules.managedRuleSets[?ruleSetType=='Microsoft_BotManagerRuleSet']" \
  --output json

# Check Application Gateway WAF policy managed rules
az network application-gateway waf-policy show \
  --name <appgw-waf-policy-name> \
  --resource-group <resource-group-name> \
  --query "managedRules.managedRuleSets[?ruleSetType=='Microsoft_BotManagerRuleSet']" \
  --output json
```

---

## Section 2: Understand Bot Categories

Azure WAF classifies bots into three categories based on their User-Agent strings, behavioral patterns, and IP reputation.

### 2.1 Good Bots

Good bots are legitimate, well-identified automated clients that serve beneficial purposes.

| Bot Type | Example User-Agents | Purpose |
|----------|-------------------|---------|
| Search engines | `Googlebot/2.1`, `Bingbot/2.0`, `Applebot` | Web indexing and search |
| Monitoring | `UptimeRobot/2.0`, `Pingdom`, `Site24x7` | Uptime and performance monitoring |
| SEO tools | `AhrefsBot`, `SemrushBot` | SEO analysis |
| Social media | `Twitterbot`, `facebookexternalhit` | Link preview generation |
| Feed readers | `Feedly`, `Feedbin` | RSS/Atom feed aggregation |

**Default action**: Log/Allow — Good bots are typically allowed through.

### 2.2 Bad Bots

Bad bots are known malicious automated clients used for harmful activities.

| Bot Type | Example User-Agents | Purpose |
|----------|-------------------|---------|
| Scrapers | `Scrapy`, `HTTrack`, `WebCopier` | Content theft and scraping |
| Vulnerability scanners | `Nikto`, `sqlmap`, `Nessus` | Automated vulnerability scanning |
| Spam bots | Various | Comment spam, form spam |
| Credential stuffing | Custom scripts | Brute-force login attempts |
| DDoS tools | Various | Distributed denial-of-service |

**Default action**: Block — Bad bots are blocked by default.

### 2.3 Unknown Bots

Unknown bots are automated clients that do not match known good or bad bot patterns.

| Bot Type | Example User-Agents | Purpose |
|----------|-------------------|---------|
| Custom scripts | `python-requests/2.28`, `curl/7.88` | Various (could be legitimate or malicious) |
| Modified browsers | Empty or generic User-Agents | Evasion, testing |
| New/uncommon tools | `custom-agent/1.0` | Unknown intent |
| Headless browsers | `HeadlessChrome` | Automation, testing, scraping |

**Default action**: Log — Unknown bots are logged for review but not blocked by default.

### 2.4 Decision Matrix

```
                    ┌─────────────────┐
                    │  Incoming Bot   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Identify Bot   │
                    │   Category      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼──────┐ ┌────▼──────┐ ┌─────▼────────┐
     │   Good Bot    │ │ Bad Bot   │ │ Unknown Bot  │
     │   (Allow)     │ │ (Block)   │ │ (Challenge)  │
     └───────────────┘ └───────────┘ └──────────────┘
```

---

## Section 3: Test Bot Detection

### 3.1 Generate Bot Traffic via Front Door

1. Navigate to the scripts directory:

   ```powershell
   cd C:\Users\lramoscostah\Downloads\scripts
   ```

2. Run the bot traffic simulation:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<endpoint>.azurefd.net" -AttackType Bot
   ```

   This generates traffic with various bot User-Agent strings including:
   - `curl/7.88.1` (Unknown bot)
   - `python-requests/2.28.0` (Unknown bot)
   - `Scrapy/2.7.0` (Bad bot)
   - `sqlmap/1.7` (Bad bot)
   - `Googlebot/2.1` (Good bot)

### 3.2 Manual Bot Testing with PowerShell

1. Test with a known **bad bot** User-Agent:

   ```powershell
   try {
       $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" `
         -Headers @{"User-Agent" = "Scrapy/2.7.0 (+https://scrapy.org)"} `
         -Method GET -ErrorAction Stop
       Write-Host "Scrapy: $($response.StatusCode) — Not blocked" -ForegroundColor Yellow
   } catch {
       Write-Host "Scrapy: $($_.Exception.Response.StatusCode.Value__) — Blocked" -ForegroundColor Green
   }
   ```

2. Test with an **unknown bot** User-Agent:

   ```powershell
   try {
       $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" `
         -Headers @{"User-Agent" = "python-requests/2.28.0"} `
         -Method GET -ErrorAction Stop
       Write-Host "python-requests: $($response.StatusCode)" -ForegroundColor Yellow
   } catch {
       Write-Host "python-requests: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Red
   }
   ```

3. Test with a **good bot** User-Agent:

   ```powershell
   $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" `
     -Headers @{"User-Agent" = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"} `
     -Method GET
   Write-Host "Googlebot: $($response.StatusCode)" -ForegroundColor Green
   ```

4. Test with a **normal browser** User-Agent:

   ```powershell
   $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" `
     -Headers @{"User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"} `
     -Method GET
   Write-Host "Chrome Browser: $($response.StatusCode)" -ForegroundColor Green
   ```

### 3.3 Batch Bot Testing Script

Run a comprehensive test of multiple User-Agent strings:

```powershell
$fdEndpoint = "https://<endpoint>.azurefd.net"
$userAgents = @(
    @{ Name = "Chrome Browser";    UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"; Expected = "Allow" },
    @{ Name = "Googlebot";         UA = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"; Expected = "Allow" },
    @{ Name = "Bingbot";           UA = "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"; Expected = "Allow" },
    @{ Name = "curl";              UA = "curl/7.88.1"; Expected = "Log/Challenge" },
    @{ Name = "python-requests";   UA = "python-requests/2.28.0"; Expected = "Log/Challenge" },
    @{ Name = "Scrapy";            UA = "Scrapy/2.7.0"; Expected = "Block" },
    @{ Name = "sqlmap";            UA = "sqlmap/1.7#stable"; Expected = "Block" },
    @{ Name = "Nikto";             UA = "Mozilla/5.0 (Nikto/2.1.6)"; Expected = "Block" },
    @{ Name = "Empty UA";          UA = ""; Expected = "Log/Challenge" }
)

Write-Host "`n=== Bot Detection Test Results ===" -ForegroundColor Cyan
Write-Host ("{0,-20} {1,-8} {2,-15}" -f "Bot Name", "Status", "Expected") -ForegroundColor White

foreach ($bot in $userAgents) {
    try {
        $headers = @{}
        if ($bot.UA -ne "") { $headers["User-Agent"] = $bot.UA }
        $r = Invoke-WebRequest -Uri $fdEndpoint -Headers $headers -Method GET -ErrorAction Stop
        $status = $r.StatusCode
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__
    }
    $color = if ($status -eq 200) { "Green" } elseif ($status -eq 403) { "Red" } else { "Yellow" }
    Write-Host ("{0,-20} {1,-8} {2,-15}" -f $bot.Name, $status, $bot.Expected) -ForegroundColor $color
}
```

---

## Section 4: Analyze Bot Logs

### 4.1 Query Bot Manager Detections

1. Navigate to your **Log Analytics workspace** → **Logs**.

2. Run the following KQL query to see bot-related events:

   ```kql
   AzureDiagnostics
   | where Category == "FrontDoorWebApplicationFirewallLog"
   | where ruleName_s startswith "Bot" or ruleSetType_s == "Microsoft_BotManagerRuleSet"
   | where TimeGenerated > ago(1h)
   | project
       TimeGenerated,
       clientIP_s,
       requestUri_s,
       ruleName_s,
       action_s,
       details_msg_s,
       details_data_s,
       trackingReference_s
   | order by TimeGenerated desc
   | take 50
   ```

### 4.2 Summarize by Bot Category

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where ruleSetType_s == "Microsoft_BotManagerRuleSet"
| where TimeGenerated > ago(1h)
| extend BotCategory = case(
    ruleName_s startswith "Bot100", "Bad Bot",
    ruleName_s startswith "Bot200", "Good Bot",
    ruleName_s startswith "Bot300", "Unknown Bot",
    "Other"
)
| summarize
    Count = count(),
    UniqueIPs = dcount(clientIP_s),
    Actions = make_set(action_s),
    SampleRules = make_set(ruleName_s)
    by BotCategory
| order by Count desc
```

### 4.3 Bot Detection Over Time

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where ruleSetType_s == "Microsoft_BotManagerRuleSet"
| where TimeGenerated > ago(1h)
| extend BotCategory = case(
    ruleName_s startswith "Bot100", "Bad Bot",
    ruleName_s startswith "Bot200", "Good Bot",
    ruleName_s startswith "Bot300", "Unknown Bot",
    "Other"
)
| summarize Count = count() by bin(TimeGenerated, 5m), BotCategory
| render timechart
```

### 4.4 Detailed Bad Bot Analysis

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where ruleSetType_s == "Microsoft_BotManagerRuleSet"
| where ruleName_s startswith "Bot100"
| where TimeGenerated > ago(1h)
| project
    TimeGenerated,
    clientIP_s,
    requestUri_s,
    ruleName_s,
    action_s,
    details_msg_s
| order by TimeGenerated desc
```

---

## Section 5: Configure JavaScript Challenge (Front Door)

The **JavaScript Challenge (JSChallenge)** is a Front Door-specific action that serves a JavaScript challenge page to the client. Real browsers can execute the JavaScript and pass the challenge automatically, while simple bots and scripts (like curl or python-requests) cannot.

### 5.1 Understand JavaScript Challenge

```
Client Request → Front Door WAF
                     │
              ┌──────▼──────┐
              │ JS Challenge │
              │   Rule Hit   │
              └──────┬───────┘
                     │
         ┌───────────┼───────────┐
         │                       │
    ┌────▼────┐            ┌─────▼─────┐
    │ Browser │            │  Bot/CLI  │
    │ (passes │            │ (cannot   │
    │  JS)    │            │  execute  │
    └────┬────┘            │  JS)      │
         │                 └─────┬─────┘
    ┌────▼────┐            ┌─────▼─────┐
    │ 200 OK  │            │ Challenge │
    │ Access  │            │ Failed    │
    │ granted │            │ (blocked) │
    └─────────┘            └───────────┘
```

### 5.2 Create JavaScript Challenge Custom Rule via Portal

1. Navigate to your **Front Door WAF Policy** → **Custom rules**.

2. Click **+ Add custom rule**.

3. Configure the rule:

   | Setting | Value |
   |---------|-------|
   | **Custom rule name** | `ChallengeUnknownBots` |
   | **Priority** | `50` |
   | **Status** | Enabled |
   | **Rule type** | Match |
   | **Condition** | |
   | - Match type | String |
   | - Match variable | RequestHeader |
   | - Header name | User-Agent |
   | - Operator | Contains |
   | - Match values | `python-requests`, `curl`, `wget`, `httpie`, `Go-http-client` |
   | - Transforms | Lowercase |
   | **Action** | **JSChallenge** |

4. Click **Add** to save the rule.

5. Click **Save** on the custom rules page.

### 5.3 Create JavaScript Challenge Rule via Azure CLI

```bash
# Create a custom rule with JSChallenge action
az network front-door waf-policy rule create \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name ChallengeUnknownBots \
  --priority 50 \
  --action JSChallenge \
  --rule-type MatchRule \
  --defer

# Add match condition for User-Agent patterns
az network front-door waf-policy rule match-condition add \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name ChallengeUnknownBots \
  --match-variable RequestHeader \
  --selector User-Agent \
  --operator Contains \
  --values "python-requests" "curl" "wget" "httpie" "Go-http-client" \
  --transforms Lowercase
```

### 5.4 Create an Additional Rule for Empty User-Agents

Requests with no User-Agent are highly suspicious. Add a rule to challenge them:

1. In the **Custom rules** page, click **+ Add custom rule**.

2. Configure:

   | Setting | Value |
   |---------|-------|
   | **Custom rule name** | `ChallengeEmptyUA` |
   | **Priority** | `51` |
   | **Condition** | |
   | - Match variable | RequestHeader |
   | - Header name | User-Agent |
   | - Operator | Equal |
   | - Match values | (leave empty) |
   | - Negate | No |
   | **Action** | **JSChallenge** |

3. Click **Add** and **Save**.

---

## Section 6: Test JavaScript Challenge

### 6.1 Test with curl/PowerShell (Should Be Challenged)

1. Send a request with a curl User-Agent:

   ```powershell
   try {
       $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" `
         -Headers @{"User-Agent" = "curl/7.88.1"} `
         -Method GET -ErrorAction Stop
       Write-Host "Status: $($response.StatusCode)"
       Write-Host "Content contains JS challenge: $($response.Content -match 'challenge')"
   } catch {
       $statusCode = $_.Exception.Response.StatusCode.Value__
       Write-Host "Status: $statusCode — JS Challenge served (bot cannot execute JavaScript)" -ForegroundColor Yellow
   }
   ```

2. Send a request with python-requests User-Agent:

   ```powershell
   try {
       $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" `
         -Headers @{"User-Agent" = "python-requests/2.28.0"} `
         -Method GET -ErrorAction Stop
       Write-Host "Status: $($response.StatusCode)"
   } catch {
       $statusCode = $_.Exception.Response.StatusCode.Value__
       Write-Host "Status: $statusCode — JS Challenge served" -ForegroundColor Yellow
   }
   ```

   > **📝 Note:** The JavaScript Challenge typically returns a **200** response with a challenge page containing JavaScript that must be executed. Non-browser clients will not be able to solve the challenge and will not access the backend.

### 6.2 Test with a Browser (Should Pass)

1. Open **Microsoft Edge** or **Google Chrome**.

2. Navigate to `https://<endpoint>.azurefd.net`.

3. The browser should:
   - Briefly display the challenge page (may appear as a short loading screen)
   - Automatically execute the JavaScript
   - Redirect to the actual application
   - Display the application content normally

4. Subsequent requests from the same browser session should pass without being challenged again (the challenge result is cached in a cookie).

### 6.3 Verify Challenge in Network Tab

1. Open **Developer Tools** (F12) in your browser.

2. Go to the **Network** tab.

3. Navigate to `https://<endpoint>.azurefd.net`.

4. Look for:
   - An initial response with JavaScript challenge content
   - A cookie being set (e.g., `afd-js-challenge`)
   - A subsequent request with the challenge cookie that returns 200 OK

---

## Section 7: Fine-tune Bot Rules

### 7.1 Override Actions for Specific Bot Categories

You can customize the default actions for each bot rule group.

#### Allow Good Bots Explicitly

1. Navigate to **Front Door WAF Policy** → **Managed rules**.

2. Expand the **Microsoft_BotManagerRuleSet** rule set.

3. For the **GoodBots** rule group:
   - Click on a specific rule (e.g., `Bot200100`)
   - Change the action to **Allow**
   - This ensures good bots are never inadvertently blocked

#### Block Bad Bots

1. For the **BadBots** rule group:
   - Verify all rules are set to **Block** (default behavior in Prevention mode)
   - Consider setting the action to **Redirect** to a honeypot page for threat intelligence

#### Challenge Unknown Bots

1. For the **UnknownBots** rule group:
   - Change the action from **Log** to **JSChallenge**
   - This forces unknown bots to prove they are real browsers

### 7.2 Override via Azure CLI

```bash
# Override a specific bot rule action
az network front-door waf-policy managed-rule-definition list \
  --query "[?ruleSetType=='Microsoft_BotManagerRuleSet'].ruleGroups[].rules[].{RuleId:ruleId, Description:description}" \
  --output table

# Override UnknownBots group to JSChallenge
az network front-door waf-policy managed-rules override add \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --type Microsoft_BotManagerRuleSet \
  --version 1.1 \
  --rule-group-id UnknownBots \
  --rule-id Bot300100 \
  --action JSChallenge
```

### 7.3 Create Allow List for Specific Bots

If you have partner integrations or monitoring tools that use custom User-Agents, create allow rules:

1. Navigate to **Custom rules** → **+ Add custom rule**.

2. Configure:

   | Setting | Value |
   |---------|-------|
   | **Name** | `AllowMonitoringBots` |
   | **Priority** | `10` (lower number = higher priority) |
   | **Condition** | |
   | - Match variable | RequestHeader |
   | - Header name | User-Agent |
   | - Operator | Contains |
   | - Match values | `UptimeRobot`, `Pingdom`, `Site24x7` |
   | **Action** | **Allow** |

3. Click **Add** and **Save**.

> **⚠️ Important:** Allow rules must have a **lower priority number** (higher priority) than block or challenge rules so they are evaluated first.

### 7.4 Verify Rule Order

Review the custom rules to ensure the correct evaluation order:

```
Priority 10:  AllowMonitoringBots      → Allow
Priority 50:  ChallengeUnknownBots     → JSChallenge
Priority 51:  ChallengeEmptyUA         → JSChallenge
Priority 100: (other custom rules)     → Various
```

Rules are evaluated from lowest priority number (highest priority) to highest priority number (lowest priority). The first matching rule determines the action.

---

## Section 8: Bot Protection Best Practices

### 8.1 Deployment Strategy

| Phase | Actions |
|-------|---------|
| **1. Monitor** | Enable Bot Manager in Detection/Log mode. Analyze logs for 1-2 weeks to understand bot traffic patterns. |
| **2. Identify** | Categorize observed bots: which are legitimate, which are malicious, which are unknown. |
| **3. Allow-list** | Create custom allow rules for known-good bots (monitoring tools, partner integrations). |
| **4. Challenge** | Enable JSChallenge for unknown bots to filter out simple automated scripts. |
| **5. Block** | Enable blocking for bad bots. Start with high-confidence rules. |
| **6. Refine** | Continuously review logs and adjust rules based on new bot patterns. |

### 8.2 Recommendations

1. **Start in Detection mode** — Never deploy bot blocking directly in production without analyzing traffic first.

2. **Use JavaScript Challenge before blocking** — JSChallenge provides a softer approach for unknown bots. It allows legitimate browsers while blocking scripts.

3. **Allow-list your monitoring tools** — Ensure uptime monitors, health checks, and synthetic testing tools are not blocked.

4. **Monitor good bot verification** — Major search engines (Google, Bing) support reverse DNS verification. Enable this when available.

5. **Combine with rate limiting** — Bots that pass bot detection may still be harmful if they generate excessive traffic. Apply rate limiting as a secondary defense (Lab 08).

6. **Review regularly** — Bot patterns change. Review bot logs monthly and adjust rules accordingly.

7. **Use custom rules for specificity** — Managed rules provide broad coverage. Use custom rules for application-specific bot patterns.

### 8.3 Common Pitfalls

| Pitfall | Impact | Solution |
|---------|--------|----------|
| Blocking `python-requests` globally | Breaks legitimate API integrations | Use JSChallenge instead of Block |
| Not allow-listing monitoring bots | False uptime alerts | Create priority allow rules |
| Ignoring empty User-Agents | Missing a category of bot traffic | Add a rule for empty UAs |
| Blocking Googlebot without verification | Drops search ranking | Allow good bots, verify with rDNS |
| No logging for allowed bots | Cannot track good bot behavior | Enable logging for all actions |

### 8.4 KQL Alert for High Bot Activity

Set up an alert for unusual bot activity:

```kql
// Alert: High volume of bad bot detections
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where ruleSetType_s == "Microsoft_BotManagerRuleSet"
| where ruleName_s startswith "Bot100"
| where TimeGenerated > ago(15m)
| summarize BadBotCount = count() by bin(TimeGenerated, 5m)
| where BadBotCount > 100
```

To create this as an Azure Monitor alert:

1. Navigate to **Azure Monitor** → **Alerts** → **+ New alert rule**.
2. **Scope**: Select your Log Analytics workspace.
3. **Condition**: Use the KQL query above as a custom log search.
4. **Threshold**: Alert when result count > 0.
5. **Actions**: Configure an action group (email, SMS, webhook).
6. **Name**: "High Bad Bot Activity Alert".

---

## Summary

In this lab, you:

- ✅ Examined the Bot Manager 1.1 ruleset and its rule groups
- ✅ Understood the three bot categories: Good, Bad, and Unknown
- ✅ Tested bot detection using various User-Agent strings
- ✅ Analyzed bot detection logs using KQL queries
- ✅ Configured a JavaScript Challenge custom rule on Front Door
- ✅ Tested the JavaScript Challenge with automated clients and browsers
- ✅ Fine-tuned bot rules by overriding actions for specific categories
- ✅ Learned bot protection best practices for production deployments

**Next Lab:** [Lab 08 - Set Up Rate Limiting with XFF Grouping](lab08.md)
