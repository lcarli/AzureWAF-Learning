# Lab 08 - Set Up Rate Limiting with XFF Grouping

## Overview

In this lab, you will configure **rate limiting** custom rules on both Azure Application Gateway WAF and Azure Front Door WAF. Rate limiting protects your applications from abuse by restricting the number of requests a client can make within a specified time window. You will also configure **X-Forwarded-For (XFF)** header-based grouping to accurately identify clients behind proxies or CDNs, and test rate limiting under burst traffic conditions.

## Objectives

- Understand rate limiting concepts: threshold, time window, and group-by keys
- Create a rate limit rule on Application Gateway WAF using client IP grouping
- Create a rate limit rule on Front Door WAF using X-Forwarded-For grouping
- Test rate limiting by sending burst traffic that exceeds thresholds
- Verify rate limiting triggers and analyze the resulting logs
- Configure advanced geo-based rate limiting rules
- Learn rate limiting best practices for production

## Prerequisites

- Completed Labs 05-07 (Prevention mode, Front Door WAF, Bot Protection)
- Application Gateway WAF v2 with WAF policy in Prevention mode
- Front Door Premium with WAF policy in Prevention mode
- Backend web apps deployed and accessible
- Log Analytics workspace with WAF diagnostics enabled
- Access to Azure Portal and Azure CLI

---

## Section 1: Understand Rate Limiting Concepts

### 1.1 How Rate Limiting Works

Rate limiting tracks the number of requests from a specific source within a defined time window. When the threshold is exceeded, subsequent requests are blocked until the window resets.

```
Time Window: 1 minute       Threshold: 100 requests
─────────────────────────────────────────────────────
Request  1  → ✅ Allow
Request  2  → ✅ Allow
   ...
Request 99  → ✅ Allow
Request 100 → ✅ Allow (threshold reached)
Request 101 → ❌ Block (429/403)
Request 102 → ❌ Block
   ...
Window resets after 1 minute
Request  1  → ✅ Allow (new window)
```

### 1.2 Key Configuration Parameters

| Parameter | Description | Typical Values |
|-----------|-------------|----------------|
| **Threshold** | Maximum number of requests allowed in the time window | 100-1000 per window |
| **Time window** | Duration over which requests are counted | 1 minute or 5 minutes |
| **Group-by key** | How to identify individual clients for counting | Client IP, XFF header, Geo location |
| **Action** | What to do when the threshold is exceeded | Block (403), Log, Redirect |
| **Match conditions** | Optional: apply rate limiting only to specific paths or methods | URI path, HTTP method |

### 1.3 Group-By Options

| Group-By Key | Use Case | Considerations |
|-------------|----------|----------------|
| **SocketAddr (Client IP)** | Direct client connections | Accurate when clients connect directly; inaccurate behind NAT/proxy |
| **X-Forwarded-For** | Clients behind CDN/proxy/load balancer | Identifies the real client IP from the XFF header |
| **GeoLocation** | Country-level rate limiting | Useful for geo-based traffic policies |
| **None** | Global rate limit | Counts all requests together regardless of source |

### 1.4 Application Gateway vs Front Door Rate Limiting

| Feature | Application Gateway | Front Door |
|---------|-------------------|------------|
| **Time windows** | 1 min, 5 min | 1 min, 5 min |
| **Group-by options** | ClientAddr, SocketAddr, GeoLocation | SocketAddr, GeoLocation |
| **XFF support** | Via ClientAddr (parses XFF) | Via custom match conditions |
| **Action on exceed** | Block (403) | Block (403), Log, Redirect |
| **Scope** | Per Application Gateway instance | Per Front Door PoP |

---

## Section 2: Create Rate Limit Rule (Application Gateway)

### 2.1 Create via Azure Portal

1. Navigate to the **Azure Portal** → **Resource Groups** → your workshop resource group.

2. Open the **Application Gateway WAF Policy** (e.g., `wafpolicy`).

3. Click **Custom rules** in the left-hand menu.

4. Click **+ Add custom rule**.

5. Configure the rate limit rule:

   | Setting | Value |
   |---------|-------|
   | **Custom rule name** | `RateLimitByClientIP` |
   | **Priority** | `100` |
   | **Rule type** | **Rate limit** |
   | **Rate limit duration** | 1 minute |
   | **Rate limit threshold** | `100` |
   | **Group rate limit traffic by** | **Client address** |

6. Add a match condition:

   | Setting | Value |
   |---------|-------|
   | **Match type** | String |
   | **Match variable** | RequestUri |
   | **Operator** | Any |
   | **Negate** | No |

   > **💡 Note:** Using `RequestUri` with `Any` operator matches all incoming requests, applying the rate limit globally.

7. Set the **Action** to **Block** (returns 403 Forbidden).

8. Click **Add** to save the rule.

9. Click **Save** on the custom rules page.

### 2.2 Create via Azure CLI

```bash
# Create rate limit custom rule on Application Gateway WAF policy
az network application-gateway waf-policy custom-rule create \
  --policy-name <appgw-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitByClientIP \
  --priority 100 \
  --rule-type RateLimitRule \
  --rate-limit-duration OneMin \
  --rate-limit-threshold 100 \
  --group-by-user-session "GroupByClientAddr" \
  --action Block

# Add match condition (match all requests)
az network application-gateway waf-policy custom-rule match-condition add \
  --policy-name <appgw-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitByClientIP \
  --match-variables RequestUri \
  --operator Any
```

### 2.3 Create a Rate Limit Rule for a Specific Path

For more targeted protection, create a rate limit rule for sensitive endpoints like login pages:

1. Add another custom rule:

   | Setting | Value |
   |---------|-------|
   | **Name** | `RateLimitLoginEndpoint` |
   | **Priority** | `90` |
   | **Rule type** | Rate limit |
   | **Rate limit duration** | 1 minute |
   | **Rate limit threshold** | `20` |
   | **Group by** | Client address |

2. Match condition:

   | Setting | Value |
   |---------|-------|
   | **Match variable** | RequestUri |
   | **Operator** | Contains |
   | **Match values** | `/login`, `/signin`, `/auth` |

3. **Action**: Block

```bash
# CLI alternative
az network application-gateway waf-policy custom-rule create \
  --policy-name <appgw-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitLoginEndpoint \
  --priority 90 \
  --rule-type RateLimitRule \
  --rate-limit-duration OneMin \
  --rate-limit-threshold 20 \
  --group-by-user-session "GroupByClientAddr" \
  --action Block

az network application-gateway waf-policy custom-rule match-condition add \
  --policy-name <appgw-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitLoginEndpoint \
  --match-variables RequestUri \
  --operator Contains \
  --values "/login" "/signin" "/auth"
```

### 2.4 Verify Rules in Portal

1. Navigate to **Custom rules** in the WAF policy.

2. Confirm both rules are listed:

   | Priority | Name | Type | Threshold | Action |
   |----------|------|------|-----------|--------|
   | 90 | RateLimitLoginEndpoint | Rate limit | 20/min | Block |
   | 100 | RateLimitByClientIP | Rate limit | 100/min | Block |

---

## Section 3: Create Rate Limit Rule with XFF (Front Door)

When clients connect through Front Door, the original client IP is in the **X-Forwarded-For** header. Standard socket-based grouping would see all traffic as coming from Front Door's IP. Use XFF-based grouping for accurate per-client rate limiting.

### 3.1 Create via Azure Portal

1. Navigate to the **Front Door WAF Policy** (e.g., `wafpolicyfd`).

2. Click **Custom rules** → **+ Add custom rule**.

3. Configure the rate limit rule:

   | Setting | Value |
   |---------|-------|
   | **Custom rule name** | `RateLimitByXFF` |
   | **Priority** | `100` |
   | **Rule type** | **Rate limit** |
   | **Rate limit duration** | 1 minute |
   | **Rate limit threshold (requests)** | `50` |

4. Add a match condition:

   | Setting | Value |
   |---------|-------|
   | **Match type** | String |
   | **Match variable** | SocketAddr |
   | **Operator** | Any |

   > **📝 Note:** Front Door uses `SocketAddr` with additional configuration for XFF-based grouping. The SocketAddr in Front Door context can be configured to parse the X-Forwarded-For header.

5. Set the **Action** to **Block**.

6. Click **Add** and **Save**.

### 3.2 Create via Azure CLI

```bash
# Create rate limit rule on Front Door WAF policy
az network front-door waf-policy rule create \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitByXFF \
  --priority 100 \
  --rule-type RateLimitRule \
  --rate-limit-duration-in-minutes 1 \
  --rate-limit-threshold 50 \
  --action Block \
  --defer

# Add match condition
az network front-door waf-policy rule match-condition add \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitByXFF \
  --match-variable SocketAddr \
  --operator Any
```

### 3.3 Create Path-Specific Rate Limit on Front Door

```bash
# Rate limit API endpoints more aggressively
az network front-door waf-policy rule create \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitAPI \
  --priority 90 \
  --rule-type RateLimitRule \
  --rate-limit-duration-in-minutes 1 \
  --rate-limit-threshold 30 \
  --action Block \
  --defer

az network front-door waf-policy rule match-condition add \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitAPI \
  --match-variable RequestUri \
  --operator BeginsWith \
  --values "/api/"
```

### 3.4 Verify Front Door Custom Rules

```bash
az network front-door waf-policy show \
  --name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --query "customRules.rules[].{Name:name, Priority:priority, RuleType:ruleType, Threshold:rateLimitThreshold, Action:action}" \
  --output table
```

---

## Section 4: Test Rate Limiting

### 4.1 Test Against Application Gateway

1. Navigate to the scripts directory:

   ```powershell
   cd C:\Users\lramoscostah\Downloads\scripts
   ```

2. Generate burst traffic that exceeds the rate limit:

   :octicons-download-24: **Script**: [generate-traffic.ps1](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/generate-traffic.ps1)

```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<appgw-public-ip>" -AttackType RateLimit -Count 200
   ```

   This sends 200 requests in rapid succession, which should exceed the 100 requests/minute threshold.

### 4.2 Test Against Front Door

1. Generate burst traffic against Front Door:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<endpoint>.azurefd.net" -AttackType RateLimit -Count 200
   ```

### 4.3 Manual Rate Limit Testing

If the `generate-traffic.ps1` script does not have a `RateLimit` attack type, use this PowerShell script:

```powershell
$targetUrl = "https://<appgw-public-ip>/"
$totalRequests = 200
$results = @{ "200" = 0; "403" = 0; "429" = 0; "Other" = 0 }
$rateLimitHitAt = $null

Write-Host "=== Rate Limit Test ===" -ForegroundColor Cyan
Write-Host "Target: $targetUrl"
Write-Host "Sending $totalRequests requests..."
Write-Host ""

for ($i = 1; $i -le $totalRequests; $i++) {
    try {
        $response = Invoke-WebRequest -Uri $targetUrl -Method GET `
          -SkipCertificateCheck -ErrorAction Stop -TimeoutSec 10
        $statusCode = $response.StatusCode.ToString()
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__.ToString()
        if (-not $statusCode) { $statusCode = "Error" }
    }

    if ($results.ContainsKey($statusCode)) {
        $results[$statusCode]++
    } else {
        $results["Other"]++
    }

    if (($statusCode -eq "403" -or $statusCode -eq "429") -and -not $rateLimitHitAt) {
        $rateLimitHitAt = $i
        Write-Host "  ⚠️ Rate limit triggered at request #$i" -ForegroundColor Yellow
    }

    # Progress indicator every 25 requests
    if ($i % 25 -eq 0) {
        Write-Host "  Sent $i / $totalRequests requests..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "  200 OK:        $($results['200'])" -ForegroundColor Green
Write-Host "  403 Forbidden: $($results['403'])" -ForegroundColor Red
Write-Host "  429 Too Many:  $($results['429'])" -ForegroundColor Red
Write-Host "  Other:         $($results['Other'])" -ForegroundColor Yellow
if ($rateLimitHitAt) {
    Write-Host "  Rate limit first hit at request #$rateLimitHitAt" -ForegroundColor Yellow
}
```

### 4.4 Test Login Endpoint Rate Limit

```powershell
$targetUrl = "https://<appgw-public-ip>/login"
$totalRequests = 50

Write-Host "=== Login Rate Limit Test ===" -ForegroundColor Cyan
Write-Host "Target: $targetUrl (limit: 20/min)"

for ($i = 1; $i -le $totalRequests; $i++) {
    try {
        $response = Invoke-WebRequest -Uri $targetUrl -Method POST `
          -Body @{username="test"; password="test"} `
          -SkipCertificateCheck -ErrorAction Stop
        Write-Host "  Request #$i : $($response.StatusCode)" -ForegroundColor Green
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__
        Write-Host "  Request #$i : $status — Rate Limited!" -ForegroundColor Red
    }
}
```

---

## Section 5: Verify Rate Limiting Triggers

### 5.1 Check Response Codes

After running the burst traffic, review the results:

- **Requests 1-100**: Should return **200 OK** (within threshold)
- **Requests 101+**: Should return **403 Forbidden** or **429 Too Many Requests** (rate limited)

> **📝 Note:** The exact request number where blocking starts may vary slightly due to the time window calculations and request processing time.

### 5.2 Verify via Application Gateway Metrics

1. In the Azure Portal, navigate to your **Application Gateway** resource.

2. Click **Metrics** in the left-hand menu.

3. Add the metric: **Web Application Firewall Total Rule Distribution**
   - Filter by **Rule ID** matching your rate limit rule
   - Filter by **Action** = `Blocked`

4. Set the time range to **Last 30 minutes**.

5. You should see a count of blocked requests corresponding to the burst traffic.

### 5.3 Verify via Front Door Metrics

1. Navigate to your **Front Door** profile.

2. Click **Metrics**.

3. Add the metric: **Web Application Firewall Request Count**
   - Filter by **PolicyName**
   - Split by **Action**

4. You should see a split between `Allow` and `Block` actions.

---

## Section 6: Analyze Rate Limit Logs

### 6.1 Application Gateway Rate Limit Logs

```kql
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(1h)
| where ruleId_s in ("RateLimitByClientIP", "RateLimitLoginEndpoint")
    or message_s contains "rate limit"
| project
    TimeGenerated,
    clientIp_s,
    requestUri_s,
    ruleId_s,
    action_s,
    message_s,
    details_message_s
| order by TimeGenerated desc
| take 50
```

### 6.2 Rate Limit Events Over Time

```kql
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s in ("RateLimitByClientIP", "RateLimitLoginEndpoint")
| where TimeGenerated > ago(1h)
| summarize
    AllowedCount = countif(action_s == "Allowed" or action_s == "Matched"),
    BlockedCount = countif(action_s == "Blocked")
    by bin(TimeGenerated, 1m)
| render timechart
```

### 6.3 Front Door Rate Limit Logs

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(1h)
| where ruleName_s in ("RateLimitByXFF", "RateLimitAPI")
    or details_msg_s contains "rate limit"
| project
    TimeGenerated,
    clientIP_s,
    requestUri_s,
    ruleName_s,
    action_s,
    details_msg_s,
    trackingReference_s
| order by TimeGenerated desc
| take 50
```

### 6.4 Rate Limit Impact Analysis

```kql
// Analyze how many requests were rate-limited per client
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s contains "RateLimit"
| where TimeGenerated > ago(1h)
| summarize
    TotalRequests = count(),
    AllowedRequests = countif(action_s != "Blocked"),
    BlockedRequests = countif(action_s == "Blocked"),
    FirstBlocked = minif(TimeGenerated, action_s == "Blocked"),
    LastBlocked = maxif(TimeGenerated, action_s == "Blocked")
    by clientIp_s
| extend BlockRate = round(100.0 * BlockedRequests / TotalRequests, 1)
| order by BlockedRequests desc
```

### 6.5 Top Rate-Limited IPs

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog" or Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(1h)
| where action_s == "Blocked"
| where ruleId_s contains "RateLimit" or ruleName_s contains "RateLimit"
| summarize BlockedCount = count() by clientIp_s
| order by BlockedCount desc
| take 10
| render barchart
```

---

## Section 7: Advanced: Geo-based Rate Limiting

Configure different rate limits for different geographic regions.

### 7.1 Create Geo-based Rate Limit Rule (Application Gateway)

Allow higher limits for your primary market and stricter limits for other regions:

1. Navigate to **Custom rules** in the Application Gateway WAF policy.

2. Click **+ Add custom rule**.

3. Configure:

   | Setting | Value |
   |---------|-------|
   | **Name** | `RateLimitNonDomestic` |
   | **Priority** | `80` |
   | **Rule type** | Rate limit |
   | **Duration** | 1 minute |
   | **Threshold** | `30` |
   | **Group by** | Client address |

4. Match condition:

   | Setting | Value |
   |---------|-------|
   | **Match variable** | RemoteAddr |
   | **Operator** | GeoMatch |
   | **Match values** | Select countries outside your primary market (e.g., exclude US, UK, DE) |
   | **Negate** | **Yes** (this inverts the condition to match traffic NOT from your primary countries) |

5. **Action**: Block

### 7.2 Create via Azure CLI

```bash
# Stricter rate limit for non-domestic traffic
az network application-gateway waf-policy custom-rule create \
  --policy-name <appgw-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitNonDomestic \
  --priority 80 \
  --rule-type RateLimitRule \
  --rate-limit-duration OneMin \
  --rate-limit-threshold 30 \
  --group-by-user-session "GroupByClientAddr" \
  --action Block

# Match traffic NOT from specified countries (negate the geo condition)
az network application-gateway waf-policy custom-rule match-condition add \
  --policy-name <appgw-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name RateLimitNonDomestic \
  --match-variables RemoteAddr \
  --operator GeoMatch \
  --values US GB DE FR \
  --negate true
```

### 7.3 Front Door Geo-based Rate Limiting

```bash
# Geo-based rate limit on Front Door
az network front-door waf-policy rule create \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name GeoRateLimit \
  --priority 80 \
  --rule-type RateLimitRule \
  --rate-limit-duration-in-minutes 1 \
  --rate-limit-threshold 30 \
  --action Block \
  --defer

az network front-door waf-policy rule match-condition add \
  --policy-name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --name GeoRateLimit \
  --match-variable SocketAddr \
  --operator GeoMatch \
  --values US GB DE FR \
  --negate
```

### 7.4 Verify Geo-based Rules

```kql
// Monitor geo-based rate limiting events
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == "RateLimitNonDomestic"
| where TimeGenerated > ago(1h)
| summarize
    BlockedCount = count(),
    Countries = make_set(clientIp_s)
    by bin(TimeGenerated, 5m)
| render timechart
```

---

## Section 8: Rate Limiting Best Practices

### 8.1 Choosing the Right Thresholds

| Endpoint Type | Suggested Threshold | Window | Rationale |
|--------------|-------------------|--------|-----------|
| **Homepage / general pages** | 200-500 requests | 1 min | Normal browsing generates 20-50 requests/page |
| **API endpoints** | 50-200 requests | 1 min | API calls should be controlled |
| **Login / authentication** | 10-30 requests | 1 min | Brute-force protection |
| **Search / query endpoints** | 30-100 requests | 1 min | Prevent scraping via search |
| **Static assets** | 500-2000 requests | 1 min | Browsers load many assets per page |
| **Webhook receivers** | 100-500 requests | 1 min | Varies by integration volume |

### 8.2 Avoiding False Positives

1. **Start with high thresholds** — Begin with permissive limits and reduce gradually based on observed traffic patterns.

2. **Monitor in Detection mode first** — Use Log action before Block to understand what would be rate-limited.

   ```bash
   # Create a rate limit rule with Log action first
   az network application-gateway waf-policy custom-rule create \
     --policy-name <appgw-waf-policy-name> \
     --resource-group <resource-group-name> \
     --name RateLimitTest \
     --priority 200 \
     --rule-type RateLimitRule \
     --rate-limit-duration OneMin \
     --rate-limit-threshold 50 \
     --group-by-user-session "GroupByClientAddr" \
     --action Log
   ```

3. **Exclude known high-traffic sources** — Add allow rules for:
   - Health check probes
   - Monitoring services
   - Partner API integrations
   - Internal services

4. **Consider NAT and shared IPs** — Corporate networks and mobile carriers may share a single IP among many users. Use XFF-based grouping when possible.

5. **Use path-specific rules** — Apply stricter limits to sensitive endpoints (login, API) and looser limits to general content.

### 8.3 Rate Limiting Rule Priority Guide

```
Priority 10:  AllowHealthChecks         → Allow (bypass rate limiting)
Priority 20:  AllowMonitoringTools      → Allow
Priority 80:  RateLimitNonDomestic      → Block (30/min for non-primary countries)
Priority 90:  RateLimitLoginEndpoint    → Block (20/min for login pages)
Priority 100: RateLimitByClientIP       → Block (100/min global)
Priority 200: (Managed rules)           → Various
```

### 8.4 Monitoring and Alerting

Set up alerts for sustained rate limiting:

```kql
// Alert: High rate of rate-limited requests
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s contains "RateLimit"
| where action_s == "Blocked"
| where TimeGenerated > ago(15m)
| summarize RateLimitedCount = count() by clientIp_s, bin(TimeGenerated, 5m)
| where RateLimitedCount > 500
```

To configure this as an Azure Monitor alert rule:

1. Navigate to **Azure Monitor** → **Alerts** → **+ New alert rule**.
2. **Scope**: Your Log Analytics workspace.
3. **Condition**: Custom log search using the KQL query above.
4. **Threshold**: Alert when result count > 0.
5. **Evaluation frequency**: Every 5 minutes.
6. **Actions**: Email, SMS, or webhook notification.

### 8.5 Common Rate Limiting Mistakes

| Mistake | Impact | Solution |
|---------|--------|----------|
| Threshold too low | Legitimate users blocked | Start high, reduce gradually |
| No path differentiation | Static assets trigger limits | Create path-specific rules |
| Socket-based grouping behind CDN | All traffic appears as one client | Use XFF-based grouping |
| No allow-list for health probes | Load balancer marks backend unhealthy | Add allow rules for health endpoints |
| Same limit for all geo regions | Under-protection or over-blocking | Use geo-based tiered limits |
| No monitoring | Cannot detect false positives | Set up alerts and dashboards |

### 8.6 Combining Rate Limiting with Other WAF Features

Rate limiting is most effective when combined with other WAF capabilities:

```
Layer 1: Bot Protection (Lab 07)
  └─ Block known bad bots before they consume rate limit capacity

Layer 2: Rate Limiting (this lab)
  └─ Limit request volume from individual sources

Layer 3: Managed Rules (Labs 02-05)
  └─ Inspect allowed requests for attack payloads

Layer 4: Custom Rules
  └─ Application-specific logic and restrictions
```

---

## Summary

In this lab, you:

- ✅ Understood rate limiting concepts including thresholds, time windows, and group-by keys
- ✅ Created a rate limit rule on Application Gateway using client IP grouping
- ✅ Created a rate limit rule on Front Door using XFF-based grouping
- ✅ Tested rate limiting by sending burst traffic exceeding thresholds
- ✅ Verified rate limiting triggers through response codes and metrics
- ✅ Analyzed rate limit logs using KQL queries
- ✅ Configured advanced geo-based rate limiting rules
- ✅ Learned rate limiting best practices for production deployments

---

## Workshop Completion

Congratulations! You have completed the Azure WAF Workshop. Here is a summary of what you accomplished across all labs:

| Lab | Topic | Key Skills |
|-----|-------|------------|
| Lab 05 | Prevention Mode | Switched Detection → Prevention, validated blocking |
| Lab 06 | Front Door WAF | Edge WAF, origin lockdown, multi-layer protection |
| Lab 07 | Bot Protection | Bot Manager, JavaScript Challenge, bot categorization |
| Lab 08 | Rate Limiting | Threshold configuration, XFF grouping, geo-based limits |

**Recommended next steps:**
- Review and clean up workshop resources to avoid unnecessary Azure costs
- Apply these patterns to your production WAF deployments
- Set up Azure Monitor alerts for WAF events
- Schedule regular WAF rule reviews and tuning sessions
