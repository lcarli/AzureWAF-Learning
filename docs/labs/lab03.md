# Lab 03 – Analyze WAF Logs with KQL

## Overview

In this lab you will use **Kusto Query Language (KQL)** in the **Log Analytics** workspace to analyze WAF firewall logs generated in Lab 02. You will identify which rules fired, which source IPs triggered the most alerts, understand DRS 2.1 anomaly scoring, and pinpoint false positives that need exclusions in Lab 04.

### Objectives

| # | Objective |
|---|-----------|
| 1 | Navigate to Log Analytics and run KQL queries |
| 2 | Query all WAF events from the firewall log |
| 3 | Identify the most frequently triggered rules |
| 4 | Identify the top attacking source IPs |
| 5 | Drill into a specific rule for detailed analysis |
| 6 | Visualize WAF events over time with a timechart |
| 7 | Understand DRS 2.1 anomaly scoring |
| 8 | Identify false positives for tuning |
| 9 | Document findings for exclusion configuration in Lab 04 |

### Prerequisites

- **Lab 01** and **Lab 02** completed successfully.
- At least 10–15 minutes have passed since generating traffic in Lab 02.
- Access to the Log Analytics workspace (`log-waf-workshop`).

### Estimated Duration

**40–50 minutes**

> **Reference:** For the complete query library, see [`../resources/kql-queries.md`](../resources/kql-queries.md).

---

## Section 1 – Open Log Analytics Workspace

### 1.1 – Navigate to Log Analytics

1. Open the **Azure portal**: [https://portal.azure.com](https://portal.azure.com).
2. In the top search bar, type **Log Analytics workspaces**.
3. Select **Log Analytics workspaces** from the results.
4. Click on your workspace (e.g., `log-waf-workshop`).

### 1.2 – Open the Logs Blade

1. In the left menu, select **Logs**.
2. If a **Queries** dialog appears, close it by clicking **X**.
3. You will see the KQL query editor.

### 1.3 – Set the Time Range

1. At the top of the query editor, click the **Time range** dropdown.
2. Select **Last 1 hour** (or a custom range covering your Lab 02 traffic generation window).

### 1.4 – Verify Firewall Logs Exist

Paste and run this test query to confirm logs are available:

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| count
```

**Expected result:** A count greater than `0`. If the result is `0`, wait a few more minutes and retry.

---

## Section 2 – Query All WAF Events

### 2.1 – Basic WAF Event Query

This query retrieves all WAF firewall events with key fields:

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| project
    TimeGenerated,
    ruleId_s,
    ruleGroup_s,
    Message,
    action_s,
    hostname_s,
    requestUri_s,
    clientIp_s,
    details_message_s,
    details_data_s
| sort by TimeGenerated desc
| take 100
```

1. Paste the query into the editor.
2. Click **Run** (or press **Shift + Enter**).
3. Review the results in the table below.

### 2.2 – Understanding the Fields

| Field | Description |
|-------|-------------|
| `TimeGenerated` | When the event was logged |
| `ruleId_s` | The rule ID that matched (e.g., `942130`) |
| `ruleGroup_s` | The rule group (e.g., `REQUEST-942-APPLICATION-ATTACK-SQLI`) |
| `Message` | Human-readable description of the rule |
| `action_s` | Action taken: `Detected` (Detection mode) or `Blocked` (Prevention mode) |
| `hostname_s` | Target hostname |
| `requestUri_s` | The URI that triggered the rule |
| `clientIp_s` | Source IP address |
| `details_message_s` | Detailed match information |
| `details_data_s` | The specific data that matched the rule pattern |

### 2.3 – Filter by Action

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize Count = count() by action_s
```

Since the WAF is in Detection mode, you should see only `Detected` actions (not `Blocked`).

---

## Section 3 – View Top Triggered Rules

### 3.1 – Top 10 Rules by Frequency

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize HitCount = count() by ruleId_s, Message
| sort by HitCount desc
| take 10
```

### 3.2 – Interpret the Results

Examine the output and identify patterns. Common rules you may see:

| Rule ID | Rule Group | Description |
|---------|-----------|-------------|
| **942130** | SQLI | SQL injection: SQL tautology detected |
| **942100** | SQLI | SQL injection attack detected via libinjection |
| **941100** | XSS | XSS attack detected via libinjection |
| **941110** | XSS | XSS filter – Category 1: script tag vector |
| **932100** | RCE | Remote command execution: Unix command injection |
| **930100** | LFI | Path traversal attack (/../) |
| **930110** | LFI | Path traversal attack (../) |

### 3.3 – Top Rules by Rule Group

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize HitCount = count() by ruleGroup_s
| sort by HitCount desc
```

This shows which attack categories generated the most activity.

---

## Section 4 – Identify Top Attacking IPs

### 4.1 – Top Source IPs

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize
    HitCount = count(),
    DistinctRules = dcount(ruleId_s),
    AttackTypes = make_set(ruleGroup_s)
    by clientIp_s
| sort by HitCount desc
| take 10
```

### 4.2 – Interpret the Results

| Column | Meaning |
|--------|---------|
| `clientIp_s` | The source IP address |
| `HitCount` | Total number of rule matches from this IP |
| `DistinctRules` | Number of unique rules triggered |
| `AttackTypes` | Which rule groups (attack categories) were triggered |

> **Note:** Since all attack traffic came from the `generate-traffic.ps1` script, you should see your own IP as the top attacker.

### 4.3 – Attack Activity per IP and Rule Group

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize HitCount = count() by clientIp_s, ruleGroup_s
| sort by clientIp_s asc, HitCount desc
```

---

## Section 5 – Analyze a Specific Rule in Detail

### 5.1 – Drill into Rule 942130 (SQL Injection Tautology)

Rule **942130** detects SQL injection patterns such as `1=1`, `'a'='a'`, etc. Let's examine all events for this rule:

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == "942130"
| project
    TimeGenerated,
    action_s,
    requestUri_s,
    clientIp_s,
    details_message_s,
    details_data_s
| sort by TimeGenerated desc
```

### 5.2 – Understand the Match Details

Examine the `details_data_s` field — this shows the exact string that matched the rule pattern.

Example:

| `requestUri_s` | `details_data_s` |
|-----------------|-------------------|
| `/?id=1' OR '1'='1` | `1' OR '1'='1` |
| `/?search=admin'--` | `admin'--` |

### 5.3 – Examine Another Rule: 941100 (XSS via libinjection)

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == "941100"
| project
    TimeGenerated,
    action_s,
    requestUri_s,
    details_message_s,
    details_data_s
| sort by TimeGenerated desc
```

### 5.4 – Match Location Analysis

Understand where in the request the rule matched (query string, body, headers):

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| extend matchLocation = extract("Matched Data: .* found within (.*?):", 1, details_message_s)
| summarize HitCount = count() by ruleId_s, matchLocation
| sort by HitCount desc
| take 20
```

---

## Section 6 – Visualize WAF Events Timeline

### 6.1 – Events Over Time (Timechart)

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize EventCount = count() by bin(TimeGenerated, 1m)
| render timechart with (title="WAF Events Over Time")
```

1. After running the query, click the **Chart** tab in the results pane.
2. You should see spikes corresponding to when you ran `generate-traffic.ps1`.

### 6.2 – Events by Attack Category Over Time

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize EventCount = count() by bin(TimeGenerated, 1m), ruleGroup_s
| render timechart with (title="WAF Events by Attack Category")
```

This creates a stacked timechart showing each attack category as a separate series.

### 6.3 – Events by Action Over Time

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize EventCount = count() by bin(TimeGenerated, 5m), action_s
| render timechart with (title="WAF Actions Over Time")
```

---

## Section 7 – Understand Anomaly Scoring

### 7.1 – How DRS 2.1 Anomaly Scoring Works

DRS 2.1 uses an **anomaly scoring** model rather than a simple match-and-block approach:

1. Each individual rule has a **severity** and contributes a score (Critical = 5, Error = 4, Warning = 3, Notice = 2).
2. As a request is evaluated, scores from all matching rules are **accumulated**.
3. The total score is compared against the **anomaly score threshold** (default: 5).
4. If the total exceeds the threshold, the request is blocked (in Prevention mode) or logged (in Detection mode).

| Severity | Score Contribution |
|----------|--------------------|
| Critical | 5 |
| Error | 4 |
| Warning | 3 |
| Notice | 2 |

### 7.2 – Query Anomaly Score Distribution

The anomaly score evaluation is logged as a special rule (rule ID `949110` for inbound, `959100` for outbound):

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == "949110"
| extend anomalyScore = extract("Inbound Anomaly Score Exceeded .* (Total Score: (\\d+))", 2, Message)
| summarize Count = count() by anomalyScore
| sort by anomalyScore asc
```

### 7.3 – View Requests with High Anomaly Scores

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == "949110"
| extend anomalyScore = toint(extract("Total Score: (\\d+)", 1, Message))
| where anomalyScore >= 10
| project TimeGenerated, anomalyScore, requestUri_s, clientIp_s, Message
| sort by anomalyScore desc
| take 20
```

Requests with very high anomaly scores are strong indicators of genuine attacks. Requests with scores just above the threshold may include false positives.

### 7.4 – Query the Current Anomaly Score Threshold

```powershell
# Check the anomaly score threshold in the WAF policy
az network application-gateway waf-policy show `
    --resource-group $RG `
    --name "waf-policy-workshop" `
    --query "managedRules" -o json
```

---

## Section 8 – Identify False Positives

### 8.1 – What Is a False Positive?

A **false positive** occurs when a WAF rule matches **legitimate** traffic. Common causes:

- Application-specific parameter names that resemble SQL syntax
- Authorization headers or tokens that contain encoded characters
- API payloads with JSON/XML structures that trigger injection rules
- Cookie values with special characters

### 8.2 – Find Potential False Positives

Look for rules that triggered on legitimate requests (requests to common, expected paths):

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where requestUri_s !contains "'"
    and requestUri_s !contains "<script"
    and requestUri_s !contains "../"
    and requestUri_s !contains ";"
| project TimeGenerated, ruleId_s, Message, requestUri_s, details_data_s
| sort by TimeGenerated desc
| take 50
```

This filters out obvious attack payloads and shows rules triggered by requests that appear legitimate.

### 8.3 – Analyze Cookie and Header False Positives

WAF rules often match on cookies or headers that contain encoded values:

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where details_message_s has "Request Cookies" or details_message_s has "Request Headers"
| summarize HitCount = count() by ruleId_s, Message
| sort by HitCount desc
| take 10
```

### 8.4 – Find Rules Matching on Specific Fields

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| extend matchVariable = extract("found within (.*?):", 1, details_message_s)
| summarize HitCount = count() by ruleId_s, matchVariable
| sort by HitCount desc
| take 20
```

Common match variables:

| Variable | Description |
|----------|-------------|
| `ARGS` | Query string parameters |
| `ARGS:paramName` | Specific query parameter |
| `REQUEST_HEADERS` | HTTP request headers |
| `REQUEST_HEADERS:cookie` | Cookie header |
| `REQUEST_HEADERS:authorization` | Authorization header |
| `REQUEST_BODY` | POST body content |

### 8.5 – Cross-Reference with Access Logs

To see if a "detected" request was actually from a legitimate user, correlate with access logs:

```kusto
let firewallEvents = AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(1h)
| distinct requestUri_s, clientIp_s;
AzureDiagnostics
| where Category == "ApplicationGatewayAccessLog"
| where TimeGenerated > ago(1h)
| join kind=inner firewallEvents on $left.requestUri_s == $right.requestUri_s
| project TimeGenerated, requestUri_s, httpStatus_d, clientIp_s, userAgent_s
| take 50
```

---

## Section 9 – Document Findings

### 9.1 – Create Your Findings Table

Based on your analysis, document the rules that appear to be false positives. You will use this information in Lab 04 to create exclusions.

Fill in this table with your findings:

| Rule ID | Rule Group | Match Variable | Match Value | False Positive? | Recommended Action |
|---------|-----------|----------------|-------------|-----------------|-------------------|
| 942130 | SQLI | `ARGS:id` | `1' OR '1'='1` | ❌ True positive | Keep rule active |
| _XXXXX_ | _group_ | `REQUEST_HEADERS:cookie` | _value_ | ✅ False positive | Create per-rule exclusion |
| _XXXXX_ | _group_ | `REQUEST_HEADERS:authorization` | _JWT token_ | ✅ False positive | Create global exclusion |
| | | | | | |

### 9.2 – Export Query Results

To save your findings:

1. Run a query in Log Analytics.
2. Click **Export** in the results pane.
3. Choose **Export to CSV** to download the results.
4. Alternatively, choose **Open in M** (Excel) for direct analysis.

### 9.3 – Summary Query for Lab 04

Run this comprehensive summary to prepare for Lab 04:

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

This gives you a single view of all triggered rules, where they matched, and sample data — everything you need to make exclusion decisions.

---

## Summary

In this lab you:

- ✅ Navigated to Log Analytics and ran KQL queries against WAF firewall logs
- ✅ Identified the **top triggered rules** and their frequencies
- ✅ Found the **top attacking IPs** and their activity patterns
- ✅ Drilled into specific rules (e.g., 942130 SQL injection) for detailed analysis
- ✅ Visualized WAF events over time using `render timechart`
- ✅ Understood DRS 2.1 **anomaly scoring** and analyzed score distributions
- ✅ Identified **false positives** that need exclusions
- ✅ Documented findings for use in Lab 04

### Key KQL Concepts Learned

| Concept | KQL Operator | Purpose |
|---------|-------------|---------|
| Filtering | `where` | Filter rows by condition |
| Aggregation | `summarize` | Group and aggregate data |
| Counting | `count()`, `dcount()` | Count total and distinct values |
| Sorting | `sort by` | Order results |
| Time bucketing | `bin()` | Group timestamps into intervals |
| Visualization | `render timechart` | Create time-series charts |
| String extraction | `extract()` | Extract values using regex |
| Set creation | `make_set()` | Create arrays of distinct values |
| Joins | `join` | Combine data from multiple tables |

### Next Steps

Proceed to **[Lab 04 – Create Exclusions and Custom Rules for Tuning](lab04.md)** to apply your findings and tune the WAF policy.
