# :bar_chart: Module 12 — Monitoring - WAF Insights,Logs & Metrics

!!! abstract "WAF Insights, diagnostic logging, KQL queries, and Azure Monitor"

*This module covers 4 topics.*

---

### WAF Insights (NEW - Public Preview)

Interactive visual dashboard for WAF security analytics

At-a-glance view of WAF effectiveness and posture

Key metrics: blocked requests, matched rules, top attackers, top triggered rules

Filter by time range, rule group, action, country

Drill down into specific rule matches and request details

Identify trends and patterns in attack traffic

Helps prioritize tuning efforts based on data

Available for both Application Gateway and Front Door WAF

Accessible via Azure Portal > WAF Policy > Insights


---

### Diagnostic Logging

Enable diagnostic settings to send WAF logs to:

Log Analytics Workspace (recommended for KQL queries)

Storage Account (long-term retention and compliance)

Event Hub (stream to SIEM/SOAR tools)

Application Gateway log: ApplicationGatewayFirewallLog

Front Door log: FrontDoorWebApplicationFirewallLog

Fields: timestamp, rule ID, rule group, action, message, request details

Next-Gen Engine adds: Log vs Detected vs Blocked action distinction

Retention: Configure based on compliance requirements


---

### KQL Query Examples for WAF Analysis

// Top 10 blocked rules (Application Gateway)

AzureDiagnostics | where ResourceType == "APPLICATIONGATEWAYS"

| where action_s == "Blocked" | summarize count() by ruleId_s | top 10 by count_

// Top attacking IPs (Front Door)

AzureDiagnostics | where ResourceType == "FRONTDOORS"

| where action_s == "Block" | summarize count() by clientIP_s | top 10 by count_

// False positive candidates: rules with high match count but low risk

// Analyze these for exclusion candidates


---

### Metrics and Azure Monitor Integration

WAF metrics available in Azure Monitor:

Matched/Blocked requests, WAF Total Requests, Rule matched requests

Create alerts based on thresholds:

Alert if blocked requests > 1000 in 5 minutes (potential attack)

Alert if WAF health drops below threshold

Azure Workbooks for custom dashboards and reporting

Action Groups for notifications (email, SMS, Logic App, Azure Function)

Integrate with Azure Monitor for comprehensive observability


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB03](../labs/lab03.md)
- [:octicons-beaker-24: LAB03B](../labs/lab03b.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 11](11-ddos.md)</div>
<div>[Module 13 :octicons-arrow-right-24:](13-copilot-sentinel.md)</div>
</div>
