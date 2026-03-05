# Lab 11 - Use Copilot for Security to Investigate WAF Events

| Field | Detail |
|---|---|
| **Duration** | 30–45 minutes |
| **Level** | Intermediate |
| **Prerequisites** | Microsoft Copilot for Security license; WAF environment from previous labs; Microsoft Sentinel (optional) |

> ⚠️ **OPTIONAL LAB**: This lab requires Microsoft Copilot for Security (GA). Copilot for Security uses Security Compute Units (SCUs) and has separate licensing. If you do not have access, review the steps below as reference material to understand how AI-assisted WAF investigation works.

## Objectives

By the end of this lab you will be able to:

- Access and navigate Microsoft Copilot for Security.
- Use natural language prompts to investigate WAF events.
- Triage WAF incidents with AI-generated summaries and recommendations.
- Request WAF policy tuning suggestions from Copilot.
- Generate KQL queries using natural language.
- Understand Copilot plugin capabilities for Azure WAF.

---

## Section 1 – Prerequisites

### Licensing Requirements

| Requirement | Detail |
|---|---|
| **Microsoft Copilot for Security** | Generally Available (GA). Requires a separate license. |
| **Security Compute Units (SCUs)** | Copilot is billed per SCU-hour. Minimum 1 SCU must be provisioned. |
| **Azure subscription** | The subscription must have Copilot for Security access enabled. |
| **Roles required** | `Security Administrator` or `Global Administrator` for initial setup; `Security Reader` for usage. |
| **Data sources** | Log Analytics workspace with WAF logs; Microsoft Sentinel (recommended). |

### SCU Configuration

SCUs determine the compute capacity available for Copilot sessions. For this workshop:

1. Navigate to [https://securitycopilot.microsoft.com](https://securitycopilot.microsoft.com).
2. Go to **Owner settings** → **Capacity management**.
3. Ensure at least **1 SCU** is provisioned.
4. Note the region — it must align with your data residency requirements.

> **Cost note:** 1 SCU costs approximately $4 USD/hour. You can deprovision SCUs after the workshop to stop charges.

---

## Section 2 – Introduction to Copilot for Security

### What Is Copilot for Security?

Microsoft Copilot for Security is a **generative AI-powered security assistant** that helps security analysts investigate threats, respond to incidents, and optimize security posture using **natural language**. It integrates with Microsoft's security ecosystem, including:

- **Microsoft Sentinel** — Incident investigation and KQL generation.
- **Microsoft Defender for Cloud** — Cloud security posture.
- **Azure WAF** — Web application firewall log analysis.
- **Microsoft Defender XDR** — Extended detection and response.

### How It Helps with WAF

| Capability | Benefit |
|---|---|
| **Natural language queries** | Investigate WAF events without writing KQL |
| **Incident summarization** | Get instant summaries of WAF attacks |
| **Pattern recognition** | Identify attack campaigns across logs |
| **Policy recommendations** | Get WAF tuning suggestions |
| **KQL generation** | Convert questions into optimized KQL queries |
| **Threat intelligence** | Correlate attacker IPs with known threats |

---

## Section 3 – Access Copilot for Security

### 3.1 – Open the Standalone Experience

1. Open your browser and navigate to:

   ```
   https://securitycopilot.microsoft.com
   ```

2. Sign in with your Azure AD / Microsoft Entra ID credentials.

3. You are presented with the **Copilot for Security** home screen with a prompt bar at the center.

### 3.2 – Verify Plugin Activation

1. Click the **Sources** icon (plug icon) in the prompt bar.

2. Verify the following plugins are enabled:

   | Plugin | Status |
   |---|---|
   | **Microsoft Sentinel** | ✅ Enabled |
   | **Azure Firewall and WAF** (or Natural Language to KQL for Azure WAF) | ✅ Enabled |
   | **Microsoft Defender for Cloud** | ✅ Enabled (optional) |

3. If a plugin is disabled, toggle it **On** and configure the required settings (workspace ID, subscription).

### 3.3 – Embedded Experience in Sentinel

Copilot for Security is also available **embedded** within Microsoft Sentinel:

1. Open the [Azure portal](https://portal.azure.com).
2. Navigate to **Microsoft Sentinel** → your workspace.
3. Open any **Incident**.
4. Look for the **Copilot** panel on the right side of the incident view.

---

## Section 4 – Natural Language WAF Investigation

In this section, you will use natural language prompts to investigate WAF events. Type each prompt in the Copilot prompt bar and review the AI-generated response.

### 4.1 – Top WAF Attacks

**Prompt:**

```
Show me the top WAF attacks in the last 24 hours
```

**What to expect:**
- Copilot queries your Log Analytics workspace.
- Returns a summary of the most frequent attack types (SQL injection, XSS, etc.).
- Shows the count of blocked requests per category.
- May include a chart or table visualization.

**Follow-up prompt:**

```
Break down these attacks by source country
```

### 4.2 – Most Blocked IPs

**Prompt:**

```
Which IPs were blocked most frequently by WAF in the last 24 hours?
```

**What to expect:**
- A ranked list of source IPs with block counts.
- Possible threat intelligence enrichment (known malicious IPs).
- Geolocation data for each IP.

**Follow-up prompt:**

```
Are any of these IPs known to be malicious according to Microsoft Threat Intelligence?
```

### 4.3 – SQL Injection Investigation

**Prompt:**

```
Is there an ongoing SQL injection attack against my application?
```

**What to expect:**
- Copilot analyzes WAF logs for SQL injection rule triggers (942xxx rules).
- Identifies whether the pattern is consistent with an automated attack.
- Provides source IPs, targeted URIs, and timeline.

**Follow-up prompt:**

```
Show me the specific SQL injection payloads that were blocked
```

### 4.4 – Resource-Specific Investigation

**Prompt:**

```
Summarize WAF events for the Application Gateway named waf-workshop-appgw in the last 12 hours
```

**What to expect:**
- A scoped summary for the specific Application Gateway resource.
- Total requests, blocked requests, block rate percentage.
- Top triggered rules and top targeted endpoints.

### 4.5 – False Positive Analysis

**Prompt:**

```
What WAF rule exclusions should I create based on false positives in the last 7 days?
```

**What to expect:**
- Copilot analyzes patterns of blocked requests that may be legitimate.
- Identifies rules with high trigger rates on known-good endpoints.
- Suggests specific exclusion configurations (rule ID + request attribute).

> **Important:** Always validate Copilot's exclusion suggestions manually before applying them. False positive analysis requires business context that AI may not have.

---

## Section 5 – Incident Triage with Copilot

This section walks through using Copilot to investigate a WAF incident from Microsoft Sentinel.

### 5.1 – Start from a Sentinel Incident

1. In Microsoft Sentinel, navigate to **Threat management** → **Incidents**.

2. Select a WAF-related incident (e.g., `SQL Injection Campaign Detected` from Lab 10).

3. Click on the incident to open the details pane.

4. In the **Copilot panel** (right side), you will see an automatic incident summary.

### 5.2 – Analyze the Attack Pattern

In the Copilot prompt bar (or the embedded panel), type:

**Prompt:**

```
Analyze this incident and tell me if this is a real attack or a false positive
```

**What Copilot does:**
- Examines the entities (IPs, URLs) associated with the incident.
- Checks the attack payloads against known patterns.
- Looks for indicators of automated vs. manual attacks.
- Provides a confidence assessment.

### 5.3 – Get Response Recommendations

**Prompt:**

```
What actions should I take to respond to this WAF incident?
```

**What to expect:**
- Prioritized list of response actions.
- Specific recommendations such as:
  - Block the source IP with a custom WAF rule.
  - Enable rate limiting on the targeted endpoint.
  - Verify application input validation.
  - Create a WAF exclusion if it is a false positive.

### 5.4 – Generate an Incident Report

**Prompt:**

```
Generate an incident report for this WAF attack that I can share with management
```

**What to expect:**
- A structured report with:
  - Executive summary.
  - Timeline of events.
  - Impact assessment.
  - Actions taken.
  - Recommendations.

---

## Section 6 – WAF Policy Recommendations

Use Copilot to get proactive WAF tuning suggestions.

### 6.1 – Identify Unnecessary Rules

**Prompt:**

```
Are there any WAF rules I should disable for my application based on the log patterns?
```

**What to expect:**
- Copilot identifies WAF rules that have never triggered (candidates for cleanup).
- Highlights rules that trigger frequently on legitimate traffic (false positive candidates).

### 6.2 – Suggest Custom Rules

**Prompt:**

```
What custom rules should I add to block the attack patterns identified in recent WAF logs?
```

**What to expect:**
- Specific custom rule suggestions based on observed attack patterns.
- Example: If repeated attacks come from a specific country, Copilot may suggest a geo-filtering rule.
- If specific URI paths are targeted, Copilot may suggest path-based rate limiting.

### 6.3 – Policy Mode Assessment

**Prompt:**

```
Should I switch my WAF policy from Detection mode to Prevention mode? What would be the impact?
```

**What to expect:**
- Analysis of current Detection-mode logs.
- Count of requests that *would have been blocked*.
- Risk assessment of enabling Prevention mode.
- Recommendation on timing and approach for the switch.

---

## Section 7 – Generate KQL Queries with Copilot

One of Copilot's most powerful features is converting natural language into KQL queries that you can run directly in Log Analytics.

### 7.1 – SQL Injection Query

**Prompt:**

```
Write a KQL query to find all SQL injection attempts from the last hour against my Application Gateway
```

**Expected generated KQL:**

```kql
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where Category == "ApplicationGatewayFirewallLog"
| where ruleGroup_s == "REQUEST-942-APPLICATION-ATTACK-SQLI"
    or message_s has "SQL Injection"
| project
    TimeGenerated,
    clientIp_s,
    requestUri_s,
    ruleId_s,
    message_s,
    action_s,
    hostname_s
| order by TimeGenerated desc
```

**Validation steps:**

1. Copy the generated query.
2. Open **Log Analytics** → **Logs**.
3. Paste and run the query.
4. Verify the results match your expectations.

### 7.2 – Top Attackers by Country

**Prompt:**

```
Write a KQL query that shows the top 10 countries attacking my WAF, with attack counts
```

**Expected generated KQL:**

```kql
AzureDiagnostics
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| where action_s in ("Blocked", "Block")
| extend SourceIP = coalesce(clientIp_s, clientIP_s)
| extend GeoInfo = geo_info_from_ip_address(SourceIP)
| extend Country = tostring(GeoInfo.country)
| summarize AttackCount = count() by Country
| top 10 by AttackCount desc
| render barchart
```

### 7.3 – Hourly Block Rate

**Prompt:**

```
Write a KQL query showing the hourly WAF block rate as a percentage over the last 24 hours
```

**Expected generated KQL:**

```kql
AzureDiagnostics
| where TimeGenerated > ago(24h)
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| extend IsBlocked = action_s in ("Blocked", "Block")
| summarize
    TotalRequests  = count(),
    BlockedRequests = countif(IsBlocked)
  by bin(TimeGenerated, 1h)
| extend BlockRate = round(100.0 * BlockedRequests / TotalRequests, 2)
| project TimeGenerated, TotalRequests, BlockedRequests, BlockRate
| render timechart
```

> **Tip:** Always review and validate Copilot-generated KQL queries before using them in production analytics rules. Copilot provides a strong starting point, but schema details and field names should be verified against your actual data.

---

## Section 8 – Copilot Plugins for WAF

### Available Plugins

| Plugin | Capabilities |
|---|---|
| **Azure Firewall and WAF** | Query WAF logs, analyze policies, get rule recommendations, investigate blocked requests |
| **Microsoft Sentinel** | Incident investigation, entity enrichment, KQL generation, threat hunting |
| **Natural Language to KQL** | Convert plain English questions into optimized KQL queries |
| **Microsoft Defender Threat Intelligence** | Enrich IPs and domains with threat intelligence data |

### Plugin-Specific Capabilities for WAF

The **Azure Firewall and WAF** plugin supports the following skills:

| Skill | Description | Example Prompt |
|---|---|---|
| **Get WAF logs** | Retrieve WAF logs filtered by time, action, or IP | *"Show WAF blocks from the last 6 hours"* |
| **Analyze WAF policy** | Review the configuration of a WAF policy | *"Describe the WAF policy on my App Gateway"* |
| **Investigate IP** | Get all WAF events for a specific IP | *"What did IP 203.0.113.50 do against my WAF?"* |
| **Suggest exclusions** | Recommend WAF rule exclusions | *"Suggest exclusions for false positives"* |
| **Threat intelligence lookup** | Cross-reference IPs with threat feeds | *"Is 198.51.100.25 a known malicious IP?"* |

### Enabling Additional Plugins

1. In Copilot for Security, click the **Sources** icon.
2. Browse the plugin catalog.
3. Toggle on additional plugins as needed.
4. Some plugins require configuration (API keys, workspace IDs).

---

## Section 9 – Best Practices for WAF Investigation with Copilot

### Effective Prompting Strategies

| Strategy | Example |
|---|---|
| **Be specific about time ranges** | *"Show attacks in the last 4 hours"* instead of *"Show attacks"* |
| **Name your resources** | *"…on Application Gateway named waf-workshop-appgw"* instead of *"…on my App Gateway"* |
| **Use follow-up prompts** | Start broad, then drill down: *"Show top attacks"* → *"Focus on SQL injection"* → *"Show payloads"* |
| **Ask for explanations** | *"Explain what WAF rule 942130 does and why it was triggered"* |
| **Request specific formats** | *"Give me a table of the top 10 blocked IPs with their countries"* |
| **Validate with data** | *"Show me the KQL query you used so I can verify it"* |

### What Copilot Does Well

- ✅ Summarizing large volumes of WAF logs quickly.
- ✅ Identifying patterns across thousands of events.
- ✅ Generating starting-point KQL queries.
- ✅ Correlating WAF data with threat intelligence.
- ✅ Explaining WAF rules in plain language.

### Where Human Judgment Is Still Needed

- ⚠️ Determining whether a blocked request is a true attack or a false positive requires business context.
- ⚠️ WAF exclusion decisions should always be validated by a security engineer.
- ⚠️ Copilot-generated KQL may use slightly different field names — always validate.
- ⚠️ Policy mode changes (Detection → Prevention) should be tested in staging first.
- ⚠️ Copilot may not have visibility into custom application logic.

---

## Section 10 – Key Takeaways

### How Copilot Transforms WAF Operations

| Traditional WAF Operations | With Copilot for Security |
|---|---|
| Write KQL queries manually | Ask questions in natural language |
| Manually correlate IPs with threat intel | Automatic enrichment with Microsoft TI |
| Read raw WAF logs line by line | Get AI-generated summaries and patterns |
| Investigate incidents for 30–60 minutes | Get initial triage in seconds |
| Rely on tribal knowledge for WAF tuning | Get data-driven policy recommendations |
| Create reports manually | Auto-generate incident reports |

### Key Benefits

1. **Faster Mean Time to Investigate (MTTI):** Reduce WAF incident investigation from minutes to seconds.
2. **Lower skill barrier:** Junior analysts can perform WAF investigations that previously required senior expertise.
3. **Better WAF tuning:** Data-driven recommendations reduce false positives and improve security posture.
4. **Consistent investigations:** AI ensures all relevant data sources are queried every time.
5. **Audit trail:** All Copilot sessions are logged for compliance and review.

### Limitations

- Copilot requires **SCUs** — there is a direct cost per hour of usage.
- **Data residency:** Copilot processes data in the region where SCUs are provisioned.
- **Plugin availability:** Not all security products have Copilot plugins yet.
- **Accuracy:** Copilot is an AI assistant — always validate its outputs.

---

## Summary

In this lab you explored how Microsoft Copilot for Security accelerates WAF operations:

- **Section 4:** Used natural language to investigate WAF events without writing KQL.
- **Section 5:** Triaged a WAF incident from Sentinel with AI-assisted analysis.
- **Section 6:** Requested WAF policy recommendations for better security posture.
- **Section 7:** Generated KQL queries from plain English questions.
- **Section 8:** Explored the WAF-specific plugin capabilities.
- **Section 9:** Learned best practices for effective Copilot prompting.

Copilot for Security represents a fundamental shift in how security teams interact with WAF data — moving from **query-driven investigation** to **conversation-driven investigation**.

---

## Additional Resources

- [Microsoft Copilot for Security documentation](https://learn.microsoft.com/security-copilot/)
- [Copilot for Security pricing](https://azure.microsoft.com/pricing/details/copilot-for-security/)
- [Azure WAF plugin for Copilot](https://learn.microsoft.com/security-copilot/plugin-azure-firewall)
- [Effective prompting for Copilot](https://learn.microsoft.com/security-copilot/prompting-security-copilot)
- [Copilot for Security sessions and audit](https://learn.microsoft.com/security-copilot/manage-audit-logs)

---

**End of Lab 11**
