# Lab 03B - WAF Fine Tuning with Triage Workbooks

## Objectives

In this lab, you will:
- Deploy the official **Application Gateway WAF Triage Workbook** from the Azure Network Security repository
- Deploy the **Front Door WAF Triage Workbook**
- Use the workbooks to visually analyze WAF rule violations
- Identify false positives and determine tuning actions
- Practice the WAF fine-tuning workflow using workbook insights

## Prerequisites

- Completed Labs 01-03 (infrastructure deployed, traffic generated, basic KQL analysis done)
- WAF logs populated in Log Analytics (run `simulate-waf-traffic.ps1` if not already done)
- Azure Portal access

> **Important**: WAF logs take 5-10 minutes to appear in Log Analytics. If you just deployed the infrastructure, run the traffic simulator first:
> ```powershell
> cd scripts/
> .\simulate-waf-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -DurationMinutes 15
> ```
> Wait 10 minutes after the simulation completes before starting this lab.

---

## Part 1: Generate Sufficient WAF Data

Before deploying the workbooks, ensure there is enough WAF data for meaningful analysis.

### Step 1: Run the Traffic Simulator Against Application Gateway

```powershell
# Navigate to the scripts directory
cd Labs/scripts/

# Run 15 minutes of mixed traffic against Application Gateway
.\simulate-waf-traffic.ps1 `
    -TargetUrl "http://<your-appgw-fqdn>" `
    -DurationMinutes 15 `
    -RequestsPerSecond 3 `
    -AttackRatio 30
```

> **Note**: Replace `<your-appgw-fqdn>` with your Application Gateway FQDN.
> Find it in `infra/.lab-outputs.json` or run:
> ```powershell
> az network public-ip show -g rg-waf-workshop -n waf-workshop-appgw-pip --query dnsSettings.fqdn -o tsv
> ```

### Step 2: Run the Traffic Simulator Against Front Door

Open a **second PowerShell terminal** and run simultaneously:

```powershell
cd Labs/scripts/

.\simulate-waf-traffic.ps1 `
    -TargetUrl "https://<your-frontdoor-endpoint>.azurefd.net" `
    -DurationMinutes 15 `
    -RequestsPerSecond 3 `
    -AttackRatio 30
```

> Find your Front Door endpoint:
> ```powershell
> az afd endpoint list -g rg-waf-workshop --profile-name <fd-profile-name> --query "[0].hostName" -o tsv
> ```

### Step 3: Wait for Log Ingestion

After the traffic simulation completes, wait **10-15 minutes** for logs to fully appear in Log Analytics.

Verify logs are available:

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(30m)
| count
```

You should see at least 500+ events. If not, wait a few more minutes and re-run the query.

---

## Part 2: Deploy Application Gateway WAF Triage Workbook

The WAF Triage Workbook is an official Microsoft tool from the [Azure Network Security](https://github.com/Azure/Azure-Network-Security) repository. It visualizes WAF rule violations and helps triage false positives.

### Step 1: Deploy via Azure Portal

1. Click the **Deploy to Azure** button below (or copy the URL to your browser):

   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FWorkbook%2520-%2520AppGw%2520WAF%2520Triage%2520Workbook%2FWAFTriageWorkbook_ARM.json)

2. Fill in the deployment parameters:

   | Parameter | Value |
   |-----------|-------|
   | **Subscription** | Your workshop subscription |
   | **Resource Group** | `rg-waf-workshop` |
   | **Workbook Display Name** | `AppGW WAF Triage Workbook` |
   | **Workbook Source Id** | Full resource ID of your Log Analytics workspace |

3. To get your **Log Analytics Workspace Resource ID**:

   ```powershell
   az monitor log-analytics workspace show \
       -g rg-waf-workshop \
       -n waf-workshop-law \
       --query id -o tsv
   ```

   The ID looks like:
   ```
   /subscriptions/<sub-id>/resourcegroups/rg-waf-workshop/providers/microsoft.operationalinsights/workspaces/waf-workshop-law
   ```

4. Click **Review + Create** → **Create**

### Step 2: Alternative - Deploy via Azure CLI

```powershell
# Get workspace resource ID
$workspaceId = az monitor log-analytics workspace show `
    -g rg-waf-workshop -n waf-workshop-law --query id -o tsv

# Deploy the workbook ARM template
az deployment group create `
    -g rg-waf-workshop `
    --template-uri "https://raw.githubusercontent.com/Azure/Azure-Network-Security/master/Azure%20WAF/Workbook%20-%20AppGw%20WAF%20Triage%20Workbook/WAFTriageWorkbook_ARM.json" `
    --parameters workbookDisplayName="AppGW WAF Triage Workbook" workbookSourceId=$workspaceId
```

### Step 3: Open the Workbook

1. Navigate to **Azure Portal** → **Monitor** → **Workbooks**
2. Or navigate to your **Log Analytics workspace** → **Workbooks**
3. Find **AppGW WAF Triage Workbook** in the list
4. Click to open

---

## Part 3: Deploy Front Door WAF Triage Workbook

### Step 1: Deploy via Azure Portal

1. Click the **Deploy to Azure** button:

   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FWorkbook%2520-%2520AFD%2520WAF%2520Triage%2520Workbook%2FAFDTriageworkbookARMTemplate.json)

2. Fill in the deployment parameters:

   | Parameter | Value |
   |-----------|-------|
   | **Subscription** | Your workshop subscription |
   | **Resource Group** | `rg-waf-workshop` |
   | **Workbook Display Name** | `Front Door WAF Triage Workbook` |
   | **Workbook Source Id** | Same Log Analytics workspace resource ID |

3. Click **Review + Create** → **Create**

### Step 2: Alternative - Deploy via Azure CLI

```powershell
az deployment group create `
    -g rg-waf-workshop `
    --template-uri "https://raw.githubusercontent.com/Azure/Azure-Network-Security/master/Azure%20WAF/Workbook%20-%20AFD%20WAF%20Triage%20Workbook/AFDTriageworkbookARMTemplate.json" `
    --parameters workbookDisplayName="Front Door WAF Triage Workbook" workbookSourceId=$workspaceId
```

---

## Part 4: Using the Application Gateway WAF Triage Workbook

### Step 1: Overview Tab

When you open the workbook, you'll see the **overview** section:

1. **Set the time range** to "Last 1 hour" (or "Last 30 minutes" if you just generated traffic)
2. **Select the Application Gateway** resource from the dropdown
3. Review the summary showing:
   - Total WAF events
   - Events by action (Blocked / Detected / Matched)
   - Events by rule group

> **What to look for**: High-count rules may indicate either real attacks or false positives. The goal is to distinguish between them.

### Step 2: Rule Violations Breakdown

1. Scroll down to the **Rule Violations** section
2. This shows a table with:
   - **Rule ID** - The specific DRS/CRS rule that triggered
   - **Rule Group** - The OWASP category (e.g., SQL Injection, XSS)
   - **Hit Count** - How many times the rule triggered
   - **Action** - What WAF did (Detected/Blocked/Matched)

3. **Click on a row** to drill down into that specific rule
4. The drill-down shows:
   - Sample request URIs that triggered the rule
   - Source IPs
   - The specific part of the request that matched (query string, body, header)

### Step 3: Identify False Positives

For each high-count rule, evaluate:

| Question | If Yes → | If No → |
|----------|----------|---------|
| Is the matched content part of normal app behavior? | **False Positive** - needs exclusion | Real attack - leave rule enabled |
| Does the match occur on a specific parameter? | Create **per-rule exclusion** for that parameter | May need broader tuning |
| Is it triggered by all requests to a specific URI? | Create **custom rule** to allow that URI first | Investigate further |
| Does the rule trigger on legitimate POST body data? | Exclude the specific **request body field** | Keep the rule |

### Step 4: Document Tuning Decisions

Create a tuning plan based on your findings:

| Rule ID | Rule Group | Match Detail | Decision | Action |
|---------|------------|-------------|----------|--------|
| 942130 | SQLi | `search` query parameter | False Positive | Exclude `search` param from rule 942130 |
| 920230 | Protocol | URL encoding in path | False Positive | Exclude request URI |
| 931130 | RFI | `callback` parameter | False Positive | Exclude `callback` from rule 931130 |
| 941100 | XSS | `<script>` in query | Real Attack | Keep enabled |

> **Tip**: This table becomes the input for Lab 04 (Exclusions & Custom Rules).

---

## Part 5: Using the Front Door WAF Triage Workbook

### Step 1: Open and Configure

1. Navigate to **Monitor** → **Workbooks** → **Front Door WAF Triage Workbook**
2. Set the time range to match your traffic simulation period
3. Select the Front Door resource

### Step 2: Analyze Front Door WAF Events

The Front Door workbook shows similar information but with Front Door-specific fields:

- **Tracking Reference** - Unique request ID for end-to-end tracing
- **Policy Name** - Which WAF policy was applied
- **Rule Name** - The managed or custom rule that matched
- **Host** - The Front Door endpoint that received the request

### Step 3: Compare Application Gateway vs Front Door WAF Events

Run the traffic simulator against both endpoints and compare:

| Aspect | Application Gateway WAF | Front Door WAF |
|--------|------------------------|----------------|
| Log Table | `ApplicationGatewayFirewallLog` | `FrontDoorWebApplicationFirewallLog` |
| Location | Regional (single region) | Global (all edge POPs) |
| Anomaly Scoring | Yes (DRS 2.1) | Yes (DRS 2.1) |
| Log Delay | 5-10 minutes | 5-10 minutes |
| Rule ID Format | Numeric (e.g., 942130) | Named (e.g., Microsoft_DefaultRuleSet-2.1-SQLI-942130) |

---

## Part 6: Fine-Tuning Workflow

Based on your triage workbook analysis, follow this workflow:

### The WAF Fine-Tuning Process

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  1. Deploy WAF   │────►│  2. Detection    │────►│  3. Generate    │
│     (DRS 2.1)    │     │     Mode         │     │     Traffic     │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  6. Switch to    │◄────│  5. Create       │◄────│  4. Analyze     │
│     Prevention   │     │     Exclusions   │     │     with Triage │
└────────┬────────┘     └──────────────────┘     │     Workbook    │
         │                                        └─────────────────┘
         ▼
┌─────────────────┐     ┌──────────────────┐
│  7. Monitor &    │────►│  8. Iterate      │
│     Validate     │     │     (repeat 3-7) │
└─────────────────┘     └──────────────────┘
```

### Step 1: Start in Detection Mode
- Always start with Detection mode when deploying new rules
- This allows you to see what the WAF would block without impacting traffic

### Step 2: Generate Representative Traffic
- Use the traffic simulator to create both legitimate and attack traffic
- Also drive real application traffic if possible

### Step 3: Analyze with Triage Workbook
- Use the workbook to identify false positives
- Focus on high-count rules first (biggest impact)
- Document findings in a tuning spreadsheet

### Step 4: Create Exclusions
- Create per-rule exclusions for false positives (see Lab 04)
- Start with the most impactful rules
- Test each exclusion individually

### Step 5: Switch to Prevention Mode
- Only switch to Prevention after thorough analysis
- Monitor closely for the first 24-48 hours
- Keep the triage workbook open for real-time monitoring

### Step 6: Iterate
- WAF tuning is an ongoing process
- Re-analyze after application changes
- Update rules when new DRS versions are released

---

## Part 7: Advanced - Create Custom Workbook Views

### Create a Combined WAF Dashboard

You can create your own workbook that combines both Application Gateway and Front Door WAF data:

1. Navigate to **Monitor** → **Workbooks** → **New**
2. Add a **query** element with:

```kql
// Combined WAF events from both Application Gateway and Front Door
let appgwEvents = AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(1h)
| extend Source = "Application Gateway", RuleIdentifier = ruleId_s, 
         Action = action_s, ClientIP = clientIp_s, URI = requestUri_s;
let fdEvents = AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(1h)
| extend Source = "Front Door", RuleIdentifier = ruleName_s,
         Action = action_s, ClientIP = clientIP_s, URI = requestUri_s;
union appgwEvents, fdEvents
| summarize Count = count() by Source, Action, bin(TimeGenerated, 5m)
| render timechart
```

3. Add another query for **Top Rules Across Both WAFs**:

```kql
let appgwRules = AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(1h)
| extend Source = "AppGW", RuleId = ruleId_s, RuleMsg = message_s;
let fdRules = AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(1h)
| extend Source = "FrontDoor", RuleId = ruleName_s, RuleMsg = ruleName_s;
union appgwRules, fdRules
| summarize Count = count() by Source, RuleId, RuleMsg
| order by Count desc
| take 20
```

4. Save the workbook as **"WAF Workshop - Combined Dashboard"**

---

## Cleanup

The workbooks are stored in the resource group and will be deleted during final cleanup.

To delete individual workbooks:
```powershell
# List workbooks
az monitor app-insights workbook list -g rg-waf-workshop --query "[].{Name:displayName, Id:id}" -o table

# Delete a specific workbook
az monitor app-insights workbook delete --resource-group rg-waf-workshop --resource-name <workbook-id>
```

---

## Key Takeaways

1. **WAF Triage Workbooks** are official Microsoft tools that dramatically simplify WAF log analysis
2. The **fine-tuning workflow** is iterative: Deploy → Detect → Analyze → Exclude → Prevent → Monitor
3. **False positive identification** requires understanding your application's normal traffic patterns
4. **Per-rule exclusions** are preferred over global exclusions for precision
5. Always start in **Detection mode** and only switch to Prevention after thorough analysis
6. The **traffic simulator** helps generate realistic data for analysis before go-live

---

## References

- [Application Gateway WAF Triage Workbook - GitHub](https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20WAF/Workbook%20-%20AppGw%20WAF%20Triage%20Workbook)
- [Front Door WAF Triage Workbook - GitHub](https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20WAF/Workbook%20-%20AFD%20WAF%20Triage%20Workbook)
- [Introducing the Application Gateway WAF Triage Workbook - TechCommunity Blog](https://techcommunity.microsoft.com/t5/azure-network-security-blog/introducing-the-application-gateway-waf-triage-workbook/ba-p/2973341)
- [Azure WAF Best Practices](https://learn.microsoft.com/azure/web-application-firewall/ag/best-practices)
- [WAF Tuning Guide](https://learn.microsoft.com/azure/web-application-firewall/ag/web-application-firewall-troubleshoot)

---

**Next Lab**: [Lab 04 - Create Exclusions and Custom Rules](lab04.md)
