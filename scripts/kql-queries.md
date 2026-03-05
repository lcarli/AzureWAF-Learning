# KQL Query Library for Azure WAF Workshop

This document contains reusable KQL (Kusto Query Language) queries for analyzing
WAF logs in Log Analytics. Used across Labs 3, 5, 7, 8, and 10.

---

## Table of Contents

- [Application Gateway WAF Logs](#application-gateway-waf-logs)
- [Front Door WAF Logs](#front-door-waf-logs)
- [False Positive Analysis](#false-positive-analysis)
- [Bot Traffic Analysis](#bot-traffic-analysis)
- [Rate Limiting Analysis](#rate-limiting-analysis)
- [Geographic Analysis](#geographic-analysis)
- [Dashboards & Summaries](#dashboards--summaries)

---

## Application Gateway WAF Logs

### All WAF events (last 1 hour)

```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(1h)
| project TimeGenerated, clientIp_s, requestUri_s, ruleSetType_s, ruleId_s, 
          message_s, action_s, hostname_s, details_message_s
| order by TimeGenerated desc
```

### Blocked requests only

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| where TimeGenerated > ago(1h)
| project TimeGenerated, clientIp_s, requestUri_s, ruleId_s, message_s, action_s
| order by TimeGenerated desc
```

### Top triggered rules

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(24h)
| summarize Count = count() by ruleId_s, message_s, action_s
| order by Count desc
| take 20
```

### Top attacking IPs

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where action_s in ("Blocked", "Matched")
| where TimeGenerated > ago(24h)
| summarize AttackCount = count(), 
            DistinctRules = dcount(ruleId_s),
            FirstSeen = min(TimeGenerated), 
            LastSeen = max(TimeGenerated)
    by clientIp_s
| order by AttackCount desc
| take 20
```

### WAF events timeline (chart)

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(24h)
| summarize Count = count() by bin(TimeGenerated, 5m), action_s
| render timechart
```

### Anomaly score distribution (DRS 2.1)

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleSetType_s == "Microsoft_DefaultRuleSet"
| where TimeGenerated > ago(24h)
| extend AnomalyScore = toint(details_data_s)
| where isnotnull(AnomalyScore) and AnomalyScore > 0
| summarize Count = count() by AnomalyScore
| order by AnomalyScore asc
| render columnchart
```

---

## Front Door WAF Logs

### All WAF events (last 1 hour)

```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.CDN"
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(1h)
| project TimeGenerated, clientIP_s, requestUri_s, ruleName_s, 
          action_s, policy_s, trackingReference_s, host_s
| order by TimeGenerated desc
```

### Blocked requests by rule

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where action_s == "Block"
| where TimeGenerated > ago(24h)
| summarize Count = count() by ruleName_s, action_s
| order by Count desc
```

### Front Door WAF timeline

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(24h)
| summarize Count = count() by bin(TimeGenerated, 5m), action_s
| render timechart
```

---

## False Positive Analysis

### Find potential false positives (legitimate traffic blocked)

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked" or action_s == "Matched"
| where TimeGenerated > ago(24h)
| summarize 
    HitCount = count(),
    SampleURIs = make_set(requestUri_s, 5),
    SampleIPs = make_set(clientIp_s, 5)
    by ruleId_s, message_s
| order by HitCount desc
```

### Analyze specific rule hits in detail

```kql
// Replace RULE_ID with the rule you want to investigate
let targetRule = "942130"; // Example: SQL injection rule
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == targetRule
| where TimeGenerated > ago(24h)
| project TimeGenerated, clientIp_s, requestUri_s, 
          details_message_s, details_data_s, hostname_s
| order by TimeGenerated desc
| take 50
```

### Compare Detection vs. Prevention mode results

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(24h)
| summarize 
    Detected = countif(action_s == "Detected"),
    Blocked = countif(action_s == "Blocked"),
    Matched = countif(action_s == "Matched"),
    Allowed = countif(action_s == "Allowed")
| extend TotalEvents = Detected + Blocked + Matched + Allowed
```

---

## Bot Traffic Analysis

### Bot categorization overview

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleSetType_s == "Microsoft_BotManagerRuleSet"
| where TimeGenerated > ago(24h)
| summarize Count = count() by ruleGroup_s, action_s
| order by Count desc
```

### Bot requests by User-Agent

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleSetType_s == "Microsoft_BotManagerRuleSet"
| where TimeGenerated > ago(24h)
| extend UserAgent = column_ifexists("userAgent_s", "N/A")
| summarize Count = count() by UserAgent, ruleGroup_s, action_s
| order by Count desc
| take 30
```

### JavaScript Challenge results (Front Door)

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where action_s == "JSChallenge"
| where TimeGenerated > ago(24h)
| summarize Count = count() by clientIP_s, ruleName_s
| order by Count desc
```

---

## Rate Limiting Analysis

### Rate limit triggers

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleSetType_s == "Custom" 
| where message_s contains "rate"
| where TimeGenerated > ago(1h)
| summarize Count = count() by bin(TimeGenerated, 1m), clientIp_s, action_s
| order by TimeGenerated desc
```

### Requests per IP per minute (identify candidates for rate limiting)

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayAccessLog"
| where TimeGenerated > ago(1h)
| summarize RequestCount = count() by bin(TimeGenerated, 1m), clientIP_s
| where RequestCount > 50
| order by RequestCount desc
```

### Rate limiting with XFF analysis

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(1h)
| extend XFF = column_ifexists("clientIp_s", "N/A")
| summarize 
    TotalRequests = count(),
    BlockedRequests = countif(action_s == "Blocked")
    by bin(TimeGenerated, 1m), XFF
| where TotalRequests > 30
| order by TotalRequests desc
```

---

## Geographic Analysis

### Requests by country

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(24h)
| extend Country = column_ifexists("clientCountry_s", "Unknown")
| summarize Count = count() by Country, action_s
| order by Count desc
```

### Blocked requests by country (map visualization)

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| where TimeGenerated > ago(24h)
| extend Country = column_ifexists("clientCountry_s", "Unknown")
| summarize BlockedCount = count() by Country
| order by BlockedCount desc
| render piechart
```

---

## Dashboards & Summaries

### WAF health dashboard (last 24h)

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(24h)
| summarize
    TotalEvents = count(),
    BlockedRequests = countif(action_s == "Blocked"),
    DetectedThreats = countif(action_s == "Detected" or action_s == "Matched"),
    UniqueAttackers = dcount(clientIp_s),
    UniqueRulesTriggered = dcount(ruleId_s),
    TopAttackType = arg_max(count(), ruleId_s)
```

### Hourly trend (last 7 days)

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(7d)
| summarize
    Total = count(),
    Blocked = countif(action_s == "Blocked"),
    Detected = countif(action_s == "Detected" or action_s == "Matched")
    by bin(TimeGenerated, 1h)
| render timechart
```

### OWASP attack category breakdown

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleSetType_s == "Microsoft_DefaultRuleSet"
| where TimeGenerated > ago(24h)
| summarize Count = count() by ruleGroup_s
| order by Count desc
| render piechart
```
