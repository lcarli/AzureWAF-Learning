# Lab 04 – Create Exclusions and Custom Rules for Tuning

## Overview

In this lab you will apply the findings from Lab 03 to tune the WAF policy. You will create **per-rule exclusions** to eliminate false positives, **global exclusions** for headers that are commonly flagged, and **custom rules** for geo-filtering, IP blocking, and request size limits. Finally, you will verify that the exclusions work correctly.

### Objectives

| # | Objective |
|---|-----------|
| 1 | Review false positive findings from Lab 03 |
| 2 | Create a per-rule exclusion for a specific rule and parameter |
| 3 | Create a global exclusion for the Authorization header |
| 4 | Create a custom rule to block a specific IP range |
| 5 | Create a custom rule for geo-filtering |
| 6 | Create a custom rule to limit request body size |
| 7 | Verify exclusions via CLI |
| 8 | Test that exclusions work by replaying previously flagged traffic |
| 9 | Understand best practices for WAF tuning |

### Prerequisites

- **Labs 01–03** completed successfully.
- False positive findings documented from Lab 03 (rule IDs, match variables, match values).
- Azure CLI authenticated and `$RG` variable set.

### Estimated Duration

**45–60 minutes**

---

## Section 1 – Review False Positives from Lab 03

### 1.1 – Recap Your Findings

Before creating exclusions, review the false positives you identified in Lab 03. Your findings table should look similar to this:

| Rule ID | Rule Group | Match Variable | Match Value | Recommended Action |
|---------|-----------|----------------|-------------|-------------------|
| 942130 | SQLI | `ARGS:id` | Application parameter with quotes | Per-rule exclusion |
| 942100 | SQLI | `REQUEST_HEADERS:authorization` | JWT token value | Global exclusion |
| 941100 | XSS | `REQUEST_HEADERS:cookie` | Session cookie with encoded characters | Global exclusion |
| 920230 | PROTOCOL | `REQUEST_HEADERS:accept-encoding` | Encoding header | Per-rule exclusion |

> **Important:** Only create exclusions for confirmed false positives. Never exclude rules for actual attack traffic.

### 1.2 – Run the Summary Query Again

If you need to refresh your findings, run this query in Log Analytics:

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| extend matchVariable = extract("found within (.*?):", 1, details_message_s)
| summarize
    HitCount = count(),
    SampleUri = take_any(requestUri_s),
    SampleData = take_any(details_data_s)
    by ruleId_s, ruleGroup_s, matchVariable, Message
| sort by HitCount desc
```

### 1.3 – Exclusion Types Overview

| Type | Scope | Use Case |
|------|-------|----------|
| **Per-rule exclusion** | Excludes a specific match variable from a **single** rule | A query parameter legitimately contains SQL-like syntax |
| **Global exclusion** | Excludes a match variable from **all** managed rules | Authorization headers or cookies that trigger multiple rules |

---

## Section 2 – Create a Per-Rule Exclusion

A per-rule exclusion tells the WAF to skip checking a specific request component for a single rule. For example, exclude the query parameter `id` from rule **942130** (SQL injection tautology detection).

### 2.1 – Create via Portal

1. Open the **Azure portal**: [https://portal.azure.com](https://portal.azure.com).
2. Navigate to **Web Application Firewall policies**.
3. Click on your WAF policy (e.g., `waf-policy-workshop`).
4. In the left menu, select **Managed rules**.
5. Click on the **DRS 2.1** managed rule set.
6. Expand the rule group **REQUEST-942-APPLICATION-ATTACK-SQLI**.
7. Locate rule **942130** – *SQL Injection Attack: SQL Tautology Detected*.
8. Click the **…** (ellipsis) next to the rule, then select **Add exclusion**.
9. Configure the exclusion:

   | Field | Value |
   |-------|-------|
   | **Applies to** | Rule 942130 |
   | **Match variable** | Request argument name |
   | **Selector operator** | Equals |
   | **Selector** | `id` |

10. Click **Add**.
11. Click **Save** at the top of the Managed rules blade.

### 2.2 – Create via Azure CLI

```powershell
$RG = "rg-waf-workshop"
$POLICY = "waf-policy-workshop"

# Add a per-rule exclusion for rule 942130, excluding the 'id' query parameter
az network application-gateway waf-policy managed-rule exclusion rule-set add `
    --resource-group $RG `
    --policy-name $POLICY `
    --match-variable "RequestArgNames" `
    --selector-match-operator "Equals" `
    --selector "id" `
    --type "OWASP" `
    --version "3.2" `
    --group-name "REQUEST-942-APPLICATION-ATTACK-SQLI" `
    --rule-ids "942130"
```

> **Note:** The CLI uses `OWASP 3.2` as the rule set type reference for DRS 2.1. Verify the correct type and version for your deployment.

### 2.3 – Verify the Exclusion

```powershell
az network application-gateway waf-policy managed-rule exclusion list `
    --resource-group $RG `
    --policy-name $POLICY `
    -o json
```

---

## Section 3 – Create a Global Exclusion

A global exclusion applies to **all** managed rules. Use this for request components that regularly trigger false positives across multiple rules, such as the `Authorization` header carrying JWT tokens.

### 3.1 – Create via Portal

1. Navigate to your WAF policy (e.g., `waf-policy-workshop`).
2. In the left menu, select **Managed rules**.
3. Click **Add exclusions** (the button above the rule set list).
4. Configure the exclusion:

   | Field | Value |
   |-------|-------|
   | **Applies to** | Global |
   | **Match variable** | Request header name |
   | **Selector operator** | Equals |
   | **Selector** | `Authorization` |

5. Click **Add**.
6. Click **Save**.

### 3.2 – Create via Azure CLI

```powershell
# Add a global exclusion for the Authorization header
az network application-gateway waf-policy managed-rule exclusion add `
    --resource-group $RG `
    --policy-name $POLICY `
    --match-variable "RequestHeaderNames" `
    --selector-match-operator "Equals" `
    --selector "Authorization"
```

### 3.3 – Add Additional Global Exclusions (Optional)

If your analysis showed false positives on cookies, add a cookie exclusion as well:

**Portal:**

1. Click **Add exclusions** again.
2. Set **Match variable** to **Request cookie name**.
3. Set **Selector operator** to **Equals**.
4. Set **Selector** to the name of the cookie (e.g., `.AspNetCore.Session`).
5. Click **Add**, then **Save**.

**CLI:**

```powershell
# Exclude a specific cookie from all managed rules
az network application-gateway waf-policy managed-rule exclusion add `
    --resource-group $RG `
    --policy-name $POLICY `
    --match-variable "RequestCookieNames" `
    --selector-match-operator "Equals" `
    --selector ".AspNetCore.Session"
```

### 3.4 – Verify Global Exclusions

```powershell
az network application-gateway waf-policy managed-rule exclusion list `
    --resource-group $RG `
    --policy-name $POLICY `
    -o table
```

---

## Section 4 – Create Custom Rule: IP Block List

Custom rules are evaluated **before** managed rules. Use them to create allow lists, block lists, or apply custom logic.

### 4.1 – Create via Portal

1. Navigate to your WAF policy.
2. In the left menu, select **Custom rules**.
3. Click **+ Add custom rule**.
4. Configure the rule:

   | Field | Value |
   |-------|-------|
   | **Custom rule name** | `BlockMaliciousIPs` |
   | **Priority** | `10` |
   | **Rule type** | Match |
   | **Match variable** | RemoteAddr |
   | **Operator** | IPMatch |
   | **Match values** | `203.0.113.0/24` (example — use a test IP range) |
   | **Negate** | No |
   | **Action** | Block |

5. Click **Add**.
6. Click **Save**.

### 4.2 – Create via Azure CLI

```powershell
# Create a custom rule to block a specific IP range
az network application-gateway waf-policy custom-rule create `
    --resource-group $RG `
    --policy-name $POLICY `
    --name "BlockMaliciousIPs" `
    --priority 10 `
    --rule-type MatchRule `
    --action Block

# Add the match condition
az network application-gateway waf-policy custom-rule match-condition add `
    --resource-group $RG `
    --policy-name $POLICY `
    --name "BlockMaliciousIPs" `
    --match-variables RemoteAddr `
    --operator IPMatch `
    --values "203.0.113.0/24"
```

### 4.3 – Verify the Custom Rule

```powershell
az network application-gateway waf-policy custom-rule list `
    --resource-group $RG `
    --policy-name $POLICY `
    -o table
```

---

## Section 5 – Create Custom Rule: Geo-Filter

Block traffic originating from specific countries using geo-match conditions.

### 5.1 – Create via Portal

1. Navigate to your WAF policy > **Custom rules**.
2. Click **+ Add custom rule**.
3. Configure the rule:

   | Field | Value |
   |-------|-------|
   | **Custom rule name** | `GeoBlockCountries` |
   | **Priority** | `20` |
   | **Rule type** | Match |
   | **Match variable** | RemoteAddr |
   | **Operator** | GeoMatch |
   | **Match values** | Select countries to block (e.g., `CN`, `RU`, `KP`) |
   | **Negate** | No |
   | **Action** | Block |

4. Click **Add**.
5. Click **Save**.

### 5.2 – Create via Azure CLI

```powershell
# Create a geo-filtering custom rule
az network application-gateway waf-policy custom-rule create `
    --resource-group $RG `
    --policy-name $POLICY `
    --name "GeoBlockCountries" `
    --priority 20 `
    --rule-type MatchRule `
    --action Block

# Add the geo-match condition (block CN, RU, KP)
az network application-gateway waf-policy custom-rule match-condition add `
    --resource-group $RG `
    --policy-name $POLICY `
    --name "GeoBlockCountries" `
    --match-variables RemoteAddr `
    --operator GeoMatch `
    --values "CN" "RU" "KP"
```

### 5.3 – Verify

```powershell
az network application-gateway waf-policy custom-rule show `
    --resource-group $RG `
    --policy-name $POLICY `
    --name "GeoBlockCountries" `
    -o json
```

> **Note:** Geo-match uses the MaxMind GeoIP database. Accuracy may vary, especially for VPN and proxy traffic.

---

## Section 6 – Create Custom Rule: Request Size Limit

Block requests with a body exceeding 100 KB to prevent abuse through oversized payloads.

### 6.1 – Create via Portal

1. Navigate to your WAF policy > **Custom rules**.
2. Click **+ Add custom rule**.
3. Configure the rule:

   | Field | Value |
   |-------|-------|
   | **Custom rule name** | `BlockLargeRequests` |
   | **Priority** | `30` |
   | **Rule type** | Match |
   | **Match variable** | RequestBody |
   | **Operator** | GreaterThan |
   | **Match values** | `102400` (100 KB in bytes) |
   | **Transforms** | None |
   | **Negate** | No |
   | **Action** | Block |

4. Click **Add**.
5. Click **Save**.

### 6.2 – Create via Azure CLI

```powershell
# Create a custom rule to limit request body size to 100KB
az network application-gateway waf-policy custom-rule create `
    --resource-group $RG `
    --policy-name $POLICY `
    --name "BlockLargeRequests" `
    --priority 30 `
    --rule-type MatchRule `
    --action Block

# Add the match condition for request body size
az network application-gateway waf-policy custom-rule match-condition add `
    --resource-group $RG `
    --policy-name $POLICY `
    --name "BlockLargeRequests" `
    --match-variables RequestBody `
    --operator GreaterThan `
    --values "102400"
```

### 6.3 – Verify All Custom Rules

```powershell
# List all custom rules
az network application-gateway waf-policy custom-rule list `
    --resource-group $RG `
    --policy-name $POLICY `
    --query "[].{Name:name, Priority:priority, Action:action, State:state}" `
    -o table
```

**Expected output:**

| Name | Priority | Action | State |
|------|----------|--------|-------|
| BlockMaliciousIPs | 10 | Block | Enabled |
| GeoBlockCountries | 20 | Block | Enabled |
| BlockLargeRequests | 30 | Block | Enabled |

---

## Section 7 – Verify Exclusions via CLI

### 7.1 – List All Exclusions

```powershell
# List all managed rule exclusions (global and per-rule)
az network application-gateway waf-policy managed-rule exclusion list `
    --resource-group $RG `
    --policy-name $POLICY `
    -o json
```

### 7.2 – View Complete WAF Policy Configuration

```powershell
# Full policy configuration including exclusions, custom rules, and managed rules
az network application-gateway waf-policy show `
    --resource-group $RG `
    --name $POLICY `
    -o json
```

### 7.3 – List Managed Rule Sets with Exclusions

```powershell
az network application-gateway waf-policy managed-rule rule-set list `
    --resource-group $RG `
    --policy-name $POLICY `
    -o json
```

### 7.4 – Verify Policy Association Is Intact

Confirm the policy is still associated with the Application Gateway:

```powershell
az network application-gateway show `
    --resource-group $RG `
    --name "appgw-waf-workshop" `
    --query "firewallPolicy.id" -o tsv
```

---

## Section 8 – Test Exclusions

### 8.1 – Re-run Previously Flagged Traffic

Send the same requests that triggered rule 942130 on the `id` parameter. With the per-rule exclusion in place, these should no longer generate firewall log entries for that rule.

```powershell
$APPGW_PIP = "<your-appgw-public-ip>"

# This request previously triggered rule 942130
Invoke-WebRequest -Uri "http://$APPGW_PIP/?id=1' OR '1'='1" `
    -UseBasicParsing -ErrorAction SilentlyContinue

Write-Host "Request sent. Check logs in 5-10 minutes."
```

### 8.2 – Send Requests with Authorization Header

```powershell
# This request previously triggered rules matching on the Authorization header
$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}

Invoke-WebRequest -Uri "http://$APPGW_PIP/" `
    -Headers $headers `
    -UseBasicParsing -ErrorAction SilentlyContinue

Write-Host "Request with Authorization header sent."
```

### 8.3 – Verify Exclusions in Logs

Wait 5–10 minutes, then run this query in Log Analytics:

```kusto
// Check if rule 942130 still fires for the 'id' parameter
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == "942130"
| where details_message_s has "ARGS:id"
| where TimeGenerated > ago(30m)
| project TimeGenerated, ruleId_s, requestUri_s, details_message_s
| sort by TimeGenerated desc
```

**Expected result:** No new entries for rule 942130 matching on `ARGS:id` after the exclusion was applied.

### 8.4 – Verify Authorization Header Exclusion

```kusto
// Check if any rules still fire for the Authorization header
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where details_message_s has "authorization"
| where TimeGenerated > ago(30m)
| project TimeGenerated, ruleId_s, requestUri_s, details_message_s
| sort by TimeGenerated desc
```

**Expected result:** No new entries matching on the Authorization header.

### 8.5 – Run Full Attack Traffic Again

Run the traffic generator to confirm that non-excluded attack patterns are still detected:

:octicons-download-24: **Script**: [generate-traffic.ps1](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/generate-traffic.ps1)

```powershell
.\scripts\generate-traffic.ps1 -TargetUrl "http://$APPGW_PIP" -AttackType All
```

Wait 5–10 minutes and verify:

```kusto
// Confirm that other attacks are still detected
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(30m)
| summarize HitCount = count() by ruleId_s, action_s
| sort by HitCount desc
| take 20
```

You should still see detections for attack rules that were **not** excluded.

---

## Section 9 – Best Practices for WAF Tuning

### 9.1 – The WAF Tuning Workflow

Follow this iterative process for production deployments:

```
┌─────────────────┐
│  1. Deploy WAF   │
│  (Detection Mode)│
└───────┬─────────┘
        │
        ▼
┌─────────────────┐
│  2. Generate &   │
│  Observe Traffic │
└───────┬─────────┘
        │
        ▼
┌─────────────────┐
│  3. Analyze Logs │
│  (KQL Queries)   │
└───────┬─────────┘
        │
        ▼
┌─────────────────┐     ┌──────────────────┐
│  4. Identify     │────▶│ 5. Create        │
│  False Positives │     │ Exclusions       │
└───────┬─────────┘     └───────┬──────────┘
        │                       │
        ▼                       ▼
┌─────────────────┐     ┌──────────────────┐
│  6. Re-test &    │────▶│ 7. Switch to     │
│  Validate        │     │ Prevention Mode  │
└─────────────────┘     └──────────────────┘
```

### 9.2 – Exclusion Best Practices

| Best Practice | Description |
|---------------|-------------|
| **Prefer per-rule over global** | Per-rule exclusions are more targeted and maintain better security posture |
| **Use specific selectors** | Use `Equals` operator with exact parameter names instead of `Contains` or `StartsWith` |
| **Document every exclusion** | Record why each exclusion was created and which legitimate traffic it affects |
| **Review exclusions periodically** | Applications change — exclusions may become unnecessary or new ones may be needed |
| **Test before going to Prevention** | Always validate exclusions in Detection mode before switching |

### 9.3 – Custom Rule Best Practices

| Best Practice | Description |
|---------------|-------------|
| **Use low priority numbers for critical rules** | Custom rules are evaluated in priority order (lower number = higher priority) |
| **Start with Log action** | Before blocking, set custom rules to `Log` mode to verify they match correctly |
| **Combine conditions** | A single custom rule can have multiple match conditions (AND logic) |
| **Use rate limiting** | Consider rate-limiting rules for DDoS and brute-force protection |
| **Keep rules simple** | Complex rules are harder to debug — prefer multiple simple rules |

### 9.4 – When to Switch to Prevention Mode

Switch to Prevention mode when:

- ✅ You have operated in Detection mode for at least **2–4 weeks**
- ✅ All known false positives have been addressed with exclusions
- ✅ No new false positives have appeared in the last **7 days**
- ✅ You have tested critical application flows and verified they are not blocked
- ✅ You have a rollback plan (can quickly switch back to Detection mode)

### 9.5 – Switching to Prevention Mode (Preview)

> **⚠️ Do not switch to Prevention mode during this workshop** unless instructed by the facilitator.

When ready for production, you would run:

**Portal:**

1. Navigate to your WAF policy.
2. Go to **Policy settings**.
3. Change **Mode** from **Detection** to **Prevention**.
4. Click **Save**.

**CLI:**

```powershell
# Switch to Prevention mode (DO NOT run during workshop unless instructed)
# az network application-gateway waf-policy update `
#     --resource-group $RG `
#     --name $POLICY `
#     --mode Prevention
```

### 9.6 – Monitoring After Prevention Mode

After switching to Prevention mode, continuously monitor for:

```kusto
// Monitor blocked requests after switching to Prevention mode
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| summarize BlockedCount = count() by bin(TimeGenerated, 5m), ruleId_s
| render timechart with (title="Blocked Requests Over Time")
```

---

## Summary

In this lab you:

- ✅ Reviewed false positive findings from Lab 03
- ✅ Created a **per-rule exclusion** (e.g., `id` parameter from rule 942130)
- ✅ Created a **global exclusion** (e.g., `Authorization` header from all managed rules)
- ✅ Created a **custom rule** to block a specific IP range
- ✅ Created a **custom rule** for geo-filtering (blocking specific countries)
- ✅ Created a **custom rule** to limit request body size
- ✅ Verified all exclusions and custom rules via CLI
- ✅ Tested exclusions by replaying previously flagged traffic
- ✅ Learned best practices for WAF tuning

### Workshop Complete! 🎉

You have completed all four labs in the Azure WAF Workshop. Here is a summary of what you accomplished:

| Lab | Topic | Key Skills |
|-----|-------|------------|
| **Lab 01** | Deploy & Explore | Portal navigation, CLI queries, architecture understanding |
| **Lab 02** | Detection Mode | Traffic generation, Detection vs. Prevention, log ingestion |
| **Lab 03** | KQL Log Analysis | KQL queries, anomaly scoring, false positive identification |
| **Lab 04** | Tuning & Custom Rules | Exclusions, custom rules, geo-filtering, best practices |

### Additional Resources

- [Azure WAF Documentation](https://learn.microsoft.com/en-us/azure/web-application-firewall/)
- [DRS Rule Groups and Rules](https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules)
- [WAF Tuning Best Practices](https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/best-practices)
- [KQL Reference](https://learn.microsoft.com/en-us/kusto/query/)
- Workshop query library: [`../resources/kql-queries.md`](../resources/kql-queries.md)
