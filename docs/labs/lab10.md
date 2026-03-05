# Lab 10 - Configure Microsoft Sentinel with WAF Data Connector

| Field | Detail |
|---|---|
| **Duration** | 45–60 minutes |
| **Level** | Intermediate |
| **Prerequisites** | Lab 01 environment deployed; Log Analytics workspace with WAF logs flowing |

> ⚠️ **OPTIONAL LAB**: This lab requires a Microsoft Sentinel license. Microsoft Sentinel has consumption-based pricing (per GB ingested). If you do not have Sentinel enabled, review the steps below as reference material. Deploying Sentinel on a workspace that already receives WAF logs **will increase costs**.

## Objectives

By the end of this lab you will be able to:

- Enable Microsoft Sentinel on an existing Log Analytics workspace.
- Verify that WAF log data is available in Sentinel.
- Create scheduled analytics rules to detect high-volume WAF blocks and SQL injection campaigns.
- Build a custom WAF workbook for operational visibility.
- Walk through the Sentinel incident investigation workflow for WAF events.
- Understand automation options with Sentinel playbooks.

---

## Section 1 – Prerequisites

### Licensing and Costs

| Item | Detail |
|---|---|
| **Microsoft Sentinel** | Pay-as-you-go — billed per GB of data ingested into the workspace. Free trial available for the first 31 days on new workspaces (up to 10 GB/day). |
| **Log Analytics workspace** | Must already exist with WAF diagnostic logs configured (Labs 01–04). |
| **Required roles** | `Microsoft Sentinel Contributor` + `Log Analytics Contributor` on the workspace. |
| **Estimated cost** | For a workshop generating < 1 GB of WAF logs, expect < $5 USD/day. |

> **Tip:** Use the [Microsoft Sentinel pricing calculator](https://azure.microsoft.com/pricing/details/microsoft-sentinel/) to estimate costs for your environment.

### Verify WAF Logs Are Flowing

Before enabling Sentinel, confirm that WAF logs exist in the workspace:

```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category in ("ApplicationGatewayFirewallLog", "FrontdoorWebApplicationFirewallLog")
| summarize Count = count() by Category
```

If both categories return results, you are ready to proceed.

---

## Section 2 – Enable Microsoft Sentinel

### Option A – Azure Portal

1. Sign in to the [Azure portal](https://portal.azure.com).

2. In the search bar, type **Microsoft Sentinel** and select the service.

3. Click **+ Create** (or **+ Add**).

4. In the workspace list, select your existing Log Analytics workspace (e.g., `waf-workshop-law`).

5. Click **Add**.

6. Wait for the deployment to complete (1–2 minutes).

7. Once deployed, you are redirected to the Sentinel **Overview** dashboard.

### Option B – Azure CLI

```bash
# Variables
RESOURCE_GROUP="waf-workshop-rg"
WORKSPACE_NAME="waf-workshop-law"

# Install the Sentinel extension (if not installed)
az extension add --name sentinel --upgrade

# Enable Sentinel on the workspace
az sentinel onboarding-state create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --name "default" \
  --customer-id "$(az monitor log-analytics workspace show \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $WORKSPACE_NAME \
    --query customerId -o tsv)"
```

### Option C – Bicep (Re-deploy with Sentinel Flag)

If your workshop deployment supports a Sentinel parameter:

```bash
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters deploySentinel=true
```

### Verify Sentinel Is Active

```bash
az sentinel onboarding-state show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --name "default" \
  --query "customerOptInStatus"
```

In the portal, navigate to **Microsoft Sentinel** → select your workspace → verify the **Overview** blade loads with data summary widgets.

---

## Section 3 – Connect WAF Data Sources

Since WAF diagnostic logs are already configured to flow to the Log Analytics workspace, Sentinel automatically has access to them. However, you should verify the data connectors.

### 3.1 – Verify Application Gateway WAF Connector

1. In Microsoft Sentinel, navigate to **Configuration** → **Data connectors**.

2. Search for **Azure Web Application Firewall** (or **WAF**).

3. Click the connector and review its status:
   - **Status:** Should show **Connected** if diagnostic logs are flowing.
   - **Data types:** `AzureDiagnostics` with `Category == "ApplicationGatewayFirewallLog"`.

4. If the connector shows **Not connected**, click **Open connector page** and follow the instructions to enable diagnostic settings on the Application Gateway.

### 3.2 – Verify Front Door WAF Connector

1. In the same **Data connectors** blade, search for **Azure Front Door** or **Azure Web Application Firewall**.

2. Verify the connector shows data flowing:
   - **Data types:** `AzureDiagnostics` with `Category == "FrontdoorWebApplicationFirewallLog"`.

### 3.3 – Verify Data Ingestion (KQL)

Run the following query in **Sentinel** → **Logs**:

```kql
AzureDiagnostics
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| summarize
    EventCount = count(),
    FirstEvent = min(TimeGenerated),
    LastEvent  = max(TimeGenerated)
  by Category
```

You should see recent events for both categories.

---

## Section 4 – Explore WAF Data in Sentinel

### 4.1 – Navigate to the Logs Blade

1. In Microsoft Sentinel, click **Logs** in the left menu.

2. Run the following queries to explore the WAF data.

### 4.2 – Application Gateway WAF Events

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| project
    TimeGenerated,
    hostname_s,
    requestUri_s,
    ruleId_s,
    ruleGroup_s,
    message_s,
    clientIp_s,
    action_s
| order by TimeGenerated desc
| take 50
```

### 4.3 – Front Door WAF Events

```kql
AzureDiagnostics
| where Category == "FrontdoorWebApplicationFirewallLog"
| where action_s == "Block"
| project
    TimeGenerated,
    host_s,
    requestUri_s,
    ruleName_s,
    policy_s,
    clientIP_s,
    action_s
| order by TimeGenerated desc
| take 50
```

### 4.4 – Combined WAF Summary

```kql
let AppGW = AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| summarize AppGW_Blocked = count();

let FD = AzureDiagnostics
| where Category == "FrontdoorWebApplicationFirewallLog"
| where action_s == "Block"
| summarize FD_Blocked = count();

AppGW | join kind=fullouter FD on $left.AppGW_Blocked == $right.FD_Blocked
| project AppGW_Blocked, FD_Blocked
```

---

## Section 5 – Create Analytics Rule: High Volume WAF Blocks

This scheduled analytics rule fires when the number of blocked WAF requests exceeds a configurable threshold within a 5-minute window.

### 5.1 – Create the Rule in the Portal

1. In Microsoft Sentinel, navigate to **Configuration** → **Analytics**.

2. Click **+ Create** → **Scheduled query rule**.

3. On the **General** tab:

   | Field | Value |
   |---|---|
   | Name | `High Volume WAF Blocks` |
   | Description | `Alerts when WAF blocks more than 50 requests in a 5-minute window, indicating a potential attack or misconfiguration.` |
   | Severity | `Medium` |
   | MITRE ATT&CK | `Initial Access` |
   | Status | `Enabled` |

4. On the **Set rule logic** tab, paste the following KQL:

```kql
let threshold = 50;
AzureDiagnostics
| where TimeGenerated > ago(5m)
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| where action_s in ("Blocked", "Block")
| summarize
    BlockedCount = count(),
    DistinctIPs  = dcount(coalesce(clientIp_s, clientIP_s)),
    SampleRules  = make_set(coalesce(ruleId_s, ruleName_s), 10),
    SampleURIs   = make_set(requestUri_s, 10)
  by
    Resource,
    Category,
    bin(TimeGenerated, 5m)
| where BlockedCount > threshold
| extend
    AlertTitle = strcat("High WAF block volume on ", Resource, ": ", BlockedCount, " blocks in 5 min"),
    SourceIPs  = DistinctIPs
| project
    TimeGenerated,
    Resource,
    Category,
    BlockedCount,
    SourceIPs,
    SampleRules,
    SampleURIs,
    AlertTitle
```

5. Configure the query scheduling:

   | Field | Value |
   |---|---|
   | Run query every | `5 minutes` |
   | Lookup data from the last | `5 minutes` |

6. On the **Incident settings** tab:

   - **Create incidents from alerts:** `Enabled`
   - **Alert grouping:** Group alerts into a single incident if they fire within `5 minutes` for the same `Resource`.

7. Click **Review + create** → **Create**.

### 5.2 – Verify the Rule

Navigate to **Analytics** → **Active rules** and confirm `High Volume WAF Blocks` appears with status **Enabled**.

---

## Section 6 – Create Analytics Rule: SQL Injection Campaign

This rule detects when the same source IP triggers multiple SQL injection WAF rules within a short window, indicating a targeted attack campaign.

### 6.1 – Create the Rule

1. In **Analytics**, click **+ Create** → **Scheduled query rule**.

2. On the **General** tab:

   | Field | Value |
   |---|---|
   | Name | `SQL Injection Campaign Detected` |
   | Description | `Detects multiple SQL injection attempts from the same IP within 10 minutes, suggesting an automated attack campaign.` |
   | Severity | `High` |
   | MITRE ATT&CK | `Initial Access`, `Exploitation` |
   | Status | `Enabled` |

3. On the **Set rule logic** tab:

```kql
let sqli_rules = dynamic(["942100", "942110", "942120", "942130",
                           "942140", "942150", "942160", "942170",
                           "942180", "942190", "942200", "942210",
                           "942220", "942230", "942240", "942250",
                           "942260", "942270", "942280", "942290",
                           "942300", "942310", "942320", "942330",
                           "942340", "942350", "942360", "942370",
                           "942380", "942390", "942400", "942410",
                           "942430", "942440", "942450",
                           "99031001", "99031002"]);
let threshold = 5;
AzureDiagnostics
| where TimeGenerated > ago(10m)
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| where action_s in ("Blocked", "Block")
| where ruleId_s in (sqli_rules) or ruleName_s has "SQLi" or message_s has "SQL Injection"
| extend SourceIP = coalesce(clientIp_s, clientIP_s)
| summarize
    AttemptCount     = count(),
    DistinctRules    = dcount(coalesce(ruleId_s, ruleName_s)),
    TargetURIs       = make_set(requestUri_s, 10),
    TriggeredRules   = make_set(coalesce(ruleId_s, ruleName_s), 10),
    FirstAttempt     = min(TimeGenerated),
    LastAttempt      = max(TimeGenerated)
  by SourceIP, Resource
| where AttemptCount >= threshold
| extend
    AlertTitle = strcat("SQL Injection campaign from ", SourceIP,
                        " — ", AttemptCount, " attempts against ", Resource),
    Duration   = datetime_diff('second', LastAttempt, FirstAttempt)
| project
    FirstAttempt,
    LastAttempt,
    Duration,
    SourceIP,
    Resource,
    AttemptCount,
    DistinctRules,
    TriggeredRules,
    TargetURIs,
    AlertTitle
```

4. Query scheduling:

   | Field | Value |
   |---|---|
   | Run query every | `5 minutes` |
   | Lookup data from the last | `10 minutes` |

5. Entity mapping:

   | Entity Type | Identifier | Column |
   |---|---|---|
   | IP | Address | `SourceIP` |
   | Azure Resource | ResourceId | `Resource` |

6. Incident settings:

   - **Create incidents:** `Enabled`
   - **Alert grouping:** Group by `SourceIP` within `1 hour`.

7. Click **Review + create** → **Create**.

---

## Section 7 – Create a WAF Workbook

Workbooks in Sentinel provide interactive dashboards. Below you will create a workbook with four visualizations.

### 7.1 – Create the Workbook

1. In Microsoft Sentinel, navigate to **Threat management** → **Workbooks**.

2. Click **+ Add workbook**.

3. Click **Edit** in the toolbar.

4. Remove all default elements.

### 7.2 – Add the Visualizations

#### Visualization 1: WAF Events Timeline

1. Click **+ Add** → **Add query**.

2. Paste the following KQL:

```kql
AzureDiagnostics
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| extend Action = coalesce(action_s, "Unknown")
| summarize EventCount = count() by Action, bin(TimeGenerated, 15m)
| render timechart
```

3. Set **Visualization** to **Time chart**.

4. Set the title to **WAF Events Timeline**.

#### Visualization 2: Top Blocked IPs

1. Click **+ Add** → **Add query**.

2. Paste:

```kql
AzureDiagnostics
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| where action_s in ("Blocked", "Block")
| extend SourceIP = coalesce(clientIp_s, clientIP_s)
| summarize BlockCount = count() by SourceIP
| top 20 by BlockCount desc
| render barchart
```

3. Set **Visualization** to **Bar chart**.

4. Title: **Top 20 Blocked IPs**.

#### Visualization 3: Top Triggered Rules

1. Click **+ Add** → **Add query**.

2. Paste:

```kql
AzureDiagnostics
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| where action_s in ("Blocked", "Block")
| extend RuleId = coalesce(ruleId_s, ruleName_s)
| summarize HitCount = count() by RuleId
| top 15 by HitCount desc
| render barchart
```

3. Set **Visualization** to **Bar chart**.

4. Title: **Top 15 Triggered WAF Rules**.

#### Visualization 4: Geo Map of Attacks

1. Click **+ Add** → **Add query**.

2. Paste:

```kql
AzureDiagnostics
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| where action_s in ("Blocked", "Block")
| extend SourceIP = coalesce(clientIp_s, clientIP_s)
| summarize AttackCount = count() by SourceIP
| extend GeoInfo = geo_info_from_ip_address(SourceIP)
| extend
    Latitude  = toreal(GeoInfo.latitude),
    Longitude = toreal(GeoInfo.longitude),
    Country   = tostring(GeoInfo.country)
| project SourceIP, Country, AttackCount, Latitude, Longitude
```

3. Set **Visualization** to **Map**.

4. Configure map settings:
   - **Location info using:** `Latitude` and `Longitude`
   - **Metric:** `AttackCount`

5. Title: **Geo Distribution of Blocked Requests**.

### 7.3 – Save the Workbook

1. Click **Done Editing**.

2. Click **Save**.

3. Set the following:

   | Field | Value |
   |---|---|
   | Title | `WAF Security Operations Dashboard` |
   | Resource group | Your workshop resource group |
   | Location | Same as workspace |

4. Click **Apply**.

### 7.4 – Workbook JSON Template (Export Reference)

To share or redeploy this workbook, you can export the JSON from the **Advanced Editor** in the workbook edit view. The structure follows this schema:

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "<KQL from Visualization 1>",
        "size": 0,
        "title": "WAF Events Timeline",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "visualization": "timechart"
      },
      "name": "waf-events-timeline"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "<KQL from Visualization 2>",
        "size": 0,
        "title": "Top 20 Blocked IPs",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "visualization": "barchart"
      },
      "name": "top-blocked-ips"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "<KQL from Visualization 3>",
        "size": 0,
        "title": "Top 15 Triggered WAF Rules",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "visualization": "barchart"
      },
      "name": "top-triggered-rules"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "<KQL from Visualization 4>",
        "size": 0,
        "title": "Geo Distribution of Blocked Requests",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "visualization": "map",
        "mapSettings": {
          "locInfo": "LatLong",
          "latitude": "Latitude",
          "longitude": "Longitude",
          "sizeSettings": "AttackCount"
        }
      },
      "name": "geo-map-attacks"
    }
  ],
  "fallbackResourceIds": [
    "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RG>/providers/Microsoft.OperationalInsights/workspaces/<WORKSPACE>"
  ]
}
```

> **Note:** Replace the placeholder values with your actual subscription, resource group, and workspace names, and paste the full KQL queries in place of `<KQL from Visualization N>`.

---

## Section 8 – Investigate a WAF Incident

This section walks through the Sentinel incident investigation workflow using a WAF-generated incident.

### 8.1 – Navigate to Incidents

1. In Microsoft Sentinel, click **Threat management** → **Incidents**.

2. Filter by severity (`Medium` or `High`) and status (`New`).

3. Click on an incident generated by one of the analytics rules you created (e.g., `High Volume WAF Blocks`).

### 8.2 – Review the Incident Summary

On the incident details pane, examine:

| Field | What to Look For |
|---|---|
| **Title** | Description of the alert |
| **Severity** | Medium or High |
| **Status** | New → set to **Active** |
| **Owner** | Assign to yourself |
| **Entities** | IP addresses, Azure resources involved |
| **Evidence** | Number of alerts grouped into this incident |

### 8.3 – Investigate the Incident

1. Click **Investigate** to open the investigation graph.

2. In the graph:
   - The **central node** is the incident.
   - **IP entity nodes** show the source IPs that triggered the alerts.
   - **Resource nodes** show the WAF resources involved.

3. Click on an **IP entity** and select **Related events** to see all WAF log entries for that IP.

4. Run a contextual KQL query to deep-dive:

```kql
let suspectIP = "<IP_FROM_ENTITY>";
AzureDiagnostics
| where Category in (
    "ApplicationGatewayFirewallLog",
    "FrontdoorWebApplicationFirewallLog"
)
| where clientIp_s == suspectIP or clientIP_s == suspectIP
| project
    TimeGenerated,
    Category,
    action_s,
    ruleId_s,
    ruleName_s,
    requestUri_s,
    hostname_s,
    host_s,
    message_s
| order by TimeGenerated desc
| take 100
```

### 8.4 – Take Action

Based on the investigation, decide on the response:

| Finding | Action |
|---|---|
| Confirmed attack from malicious IP | Create a custom WAF rule to block the IP |
| False positive from legitimate traffic | Create a WAF exclusion rule |
| Automated scanner / bot | Verify Bot Manager rules are enabled |
| Distributed attack from multiple IPs | Consider geo-blocking or rate limiting |

### 8.5 – Close the Incident

1. Update the incident status:

   | Field | Value |
   |---|---|
   | Status | `Closed` |
   | Classification | `True Positive – suspicious activity` or `False Positive – inaccurate data` |
   | Comment | Summary of investigation findings and actions taken |

2. Click **Apply**.

---

## Section 9 – Automation with Playbooks (Bonus)

> This section provides a conceptual overview. Creating a full playbook is outside the scope of this workshop.

### What Are Playbooks?

Sentinel **playbooks** are Azure Logic Apps triggered by Sentinel incidents or alerts. They enable automated response actions.

### WAF-Specific Playbook Ideas

| Playbook | Description |
|---|---|
| **Auto-block IP** | When a WAF incident is created, automatically add the attacker IP to a WAF custom rule deny list using the Azure REST API. |
| **Enrich with Threat Intelligence** | Look up attacker IPs in a threat intelligence feed (e.g., Microsoft TI, VirusTotal) and add the results as incident comments. |
| **Teams / Slack notification** | Send a message to a security channel with incident details and a link to the Sentinel incident. |
| **Create Jira / ServiceNow ticket** | Automatically create a ticket in your ITSM tool for WAF incidents above a severity threshold. |

### Playbook Architecture

```
Sentinel Incident Trigger
         │
         ▼
   ┌─────────────────┐
   │  Logic App       │
   │  (Playbook)      │
   │                  │
   │  1. Get incident │
   │  2. Extract IPs  │
   │  3. Call WAF API │
   │  4. Block IP     │
   │  5. Comment on   │
   │     incident     │
   └─────────────────┘
```

### Creating a Playbook (High-Level Steps)

1. In Microsoft Sentinel, navigate to **Configuration** → **Automation**.
2. Click **+ Create** → **Playbook with incident trigger**.
3. Configure the Logic App with actions:
   - **Sentinel – Get incident** (automatic trigger)
   - **Sentinel – Entities – Get IPs** (extract IP entities)
   - **HTTP – PUT** (call Azure WAF API to update custom rules)
   - **Sentinel – Add comment to incident** (document the action)
4. In **Automation rules**, create a rule that triggers this playbook for specific analytics rules.

---

## Key Takeaways

- **Microsoft Sentinel** transforms WAF from a reactive control into a **proactive security monitoring** capability.
- WAF logs flow seamlessly into Sentinel when diagnostic settings are already configured for Log Analytics.
- **Scheduled analytics rules** enable automatic detection of attack patterns — reducing mean time to detect (MTTD).
- **Workbooks** provide operational dashboards for real-time WAF visibility.
- The **incident investigation** workflow centralizes evidence and enables structured response.
- **Playbooks** automate repetitive response tasks — e.g., auto-blocking attacker IPs.

---

## Clean Up (Optional)

If you want to remove Sentinel from the workspace:

```bash
az sentinel onboarding-state delete \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --name "default" \
  --yes
```

> **Warning:** Removing Sentinel does not delete the data in the workspace, but it stops Sentinel-specific billing. Analytics rules and workbooks will be retained but inactive.

---

## Additional Resources

- [Microsoft Sentinel documentation](https://learn.microsoft.com/azure/sentinel/)
- [Microsoft Sentinel pricing](https://azure.microsoft.com/pricing/details/microsoft-sentinel/)
- [WAF data connector for Sentinel](https://learn.microsoft.com/azure/sentinel/data-connectors/azure-web-application-firewall-waf)
- [Sentinel analytics rules best practices](https://learn.microsoft.com/azure/sentinel/detect-threats-built-in)
- [Sentinel workbooks](https://learn.microsoft.com/azure/sentinel/monitor-your-data)

---

**End of Lab 10**
