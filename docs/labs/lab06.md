# Lab 06 - Deploy Front Door Premium with WAF and Origin Lockdown

## Overview

In this lab, you will explore **Azure Front Door Premium** with its integrated WAF capabilities. Front Door provides a global, edge-based WAF that inspects traffic at Microsoft's point-of-presence (PoP) locations worldwide, complementing the regional WAF provided by Application Gateway. You will also configure **origin lockdown** to ensure that backend web apps only accept traffic that has been inspected by Front Door.

## Objectives

- Explore the Front Door Premium profile, endpoint, origin group, and routes
- Understand the differences between edge WAF (Front Door) and regional WAF (Application Gateway)
- Test application access through the Front Door endpoint
- Generate attack traffic via Front Door and analyze WAF logs
- Configure origin lockdown using App Service access restrictions
- Switch the Front Door WAF to Prevention mode

## Prerequisites

- Front Door Premium profile deployed via Bicep (included in workshop infrastructure)
- Backend web apps (App Services) deployed and operational
- WAF policy associated with the Front Door profile
- Log Analytics workspace with Front Door diagnostics enabled
- Azure CLI installed and authenticated

---

## Section 1: Explore Front Door in Portal

### 1.1 Navigate to Front Door Profile

1. Open the **Azure Portal** → **Resource Groups** → select your workshop resource group.

2. Click on the **Front Door and CDN profiles** resource (e.g., `afd-waf-workshop`).

3. On the **Overview** page, note the following:
   - **Endpoint hostname**: `<endpoint-name>.azurefd.net` — this is the public URL
   - **SKU**: Premium — required for WAF with managed rules and Private Link
   - **Provisioning state**: Succeeded

### 1.2 Examine the Endpoint

1. In the left-hand menu, click **Front Door manager**.

2. You should see your endpoint with its associated routes and origin groups.

3. Click on the **endpoint name** to see:
   - **Endpoint hostname**: The FQDN users will access
   - **Enabled state**: Enabled
   - **Routes**: How incoming requests are matched and forwarded

### 1.3 Examine the Origin Group

1. Click on the **origin group** name to view its configuration.

2. Review the following settings:
   - **Origins**: The backend web apps that serve traffic
   - **Health probe**: Settings for monitoring backend health
     - **Protocol**: HTTPS
     - **Path**: `/` or `/health`
     - **Interval**: 30 seconds (default)
   - **Load balancing**: How traffic is distributed across origins
     - **Sample size**: 4
     - **Successful samples required**: 3
     - **Latency sensitivity**: 0 ms (default, routes to fastest origin)

### 1.4 Examine the Routes

1. Click on the **route** to see how requests are processed:
   - **Domains**: Which hostnames trigger this route
   - **Patterns to match**: URL paths (e.g., `/*`)
   - **Origin group**: Where traffic is forwarded
   - **Forwarding protocol**: HTTPS only (recommended)
   - **Caching**: Enabled/Disabled
   - **WAF policy**: The associated WAF policy

---

## Section 2: Explore Front Door WAF Policy

### 2.1 Navigate to the WAF Policy

1. In the Azure Portal, navigate to your **resource group**.

2. Click on the **WAF policy** associated with Front Door (e.g., `wafpolicyfd`).

   > **💡 Note:** Front Door WAF policies have `policyType: "FrontDoor"` as opposed to Application Gateway WAF policies which have `policyType: "ApplicationGateway"`.

### 2.2 Examine Managed Rules

1. In the left-hand menu, click **Managed rules**.

2. Review the configured rule sets:

   | Rule Set | Version | Description |
   |----------|---------|-------------|
   | **Default Rule Set (DRS)** | 2.1 | Core OWASP protection rules for SQLi, XSS, LFI, RCE, etc. |
   | **Bot Manager** | 1.1 | Bot detection and categorization rules |

3. Click on the **DRS 2.1** rule set to expand and view the rule groups:
   - SQL Injection (SQLi)
   - Cross-Site Scripting (XSS)
   - Local File Inclusion (LFI)
   - Remote File Inclusion (RFI)
   - Remote Command Execution (RCE)
   - Protocol violations
   - And more...

### 2.3 Check the Policy Mode

1. Click **Policy settings** in the left-hand menu.

2. Verify:
   - **Mode**: Detection (we will switch to Prevention later)
   - **Redirect URL**: (optional, for redirect actions)
   - **Block response status code**: 403
   - **Block response body**: Default or custom message

### 2.4 Verify via Azure CLI

```bash
# List Front Door WAF policies in the resource group
az network front-door waf-policy list \
  --resource-group <resource-group-name> \
  --output table

# Show detailed policy configuration
az network front-door waf-policy show \
  --name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --query "{Name:name, Mode:policySettings.mode, State:policySettings.enabledState, ManagedRules:managedRules.managedRuleSets[].{RuleSet:ruleSetType, Version:ruleSetVersion}}" \
  --output json
```

---

## Section 3: Test via Front Door Endpoint

### 3.1 Get the Front Door Endpoint URL

1. In the Front Door profile, copy the **Endpoint hostname** (e.g., `waf-workshop-endpoint.azurefd.net`).

2. Alternatively, retrieve it via CLI:

   ```bash
   az afd endpoint list \
     --profile-name <frontdoor-profile-name> \
     --resource-group <resource-group-name> \
     --query "[].hostName" \
     --output tsv
   ```

### 3.2 Test Basic Connectivity

1. Open a browser and navigate to `https://<endpoint>.azurefd.net`.

2. You should see the backend web application's home page.

3. Verify via PowerShell:

   ```powershell
   $fdEndpoint = "https://<endpoint>.azurefd.net"
   $response = Invoke-WebRequest -Uri $fdEndpoint -Method GET
   Write-Host "Status: $($response.StatusCode)"
   Write-Host "Content Length: $($response.Content.Length)"
   ```

   Expected: **200 OK**

### 3.3 Examine Response Headers

1. Check the Front Door headers in the response:

   ```powershell
   $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" -Method GET
   $response.Headers | Format-Table Key, Value

   # Look for these Front Door-specific headers:
   # X-Azure-Ref: Unique request ID for tracing
   # X-Cache: HIT or MISS (if caching is enabled)
   ```

2. The **X-Azure-Ref** header is crucial for troubleshooting — it uniquely identifies each request as it flows through Front Door.

---

## Section 4: Generate Attack Traffic via Front Door

### 4.1 Run Attacks Against Front Door

1. Navigate to the scripts directory:

   ```powershell
   cd C:\Users\lramoscostah\Downloads\scripts
   ```

2. Generate SQL injection attacks via Front Door:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<endpoint>.azurefd.net" -AttackType SQLi
   ```

3. Generate XSS attacks:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<endpoint>.azurefd.net" -AttackType XSS
   ```

4. Generate all attack types:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<endpoint>.azurefd.net" -AttackType All
   ```

> **📝 Note:** Since the Front Door WAF is currently in **Detection mode**, attacks will be logged but **not blocked**. Responses will still return 200 OK.

### 4.2 Generate Legitimate Traffic

1. Also send legitimate traffic for comparison:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<endpoint>.azurefd.net" -AttackType None -Count 50
   ```

---

## Section 5: Analyze Front Door WAF Logs

Front Door WAF logs use a different table than Application Gateway WAF logs.

### 5.1 Query Front Door WAF Logs

1. Navigate to your **Log Analytics workspace** → **Logs**.

2. Run the following KQL query:

   ```kql
   AzureDiagnostics
   | where ResourceType == "FRONTDOORS" or Category == "FrontDoorWebApplicationFirewallLog"
   | where TimeGenerated > ago(1h)
   | project
       TimeGenerated,
       clientIP_s,
       clientPort_s,
       requestUri_s,
       host_s,
       ruleName_s,
       policy_s,
       policyMode_s,
       action_s,
       details_msg_s,
       details_data_s,
       trackingReference_s
   | order by TimeGenerated desc
   | take 50
   ```

### 5.2 Summarize Detections by Rule

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(1h)
| where action_s in ("Log", "Detected", "AnomalyScoring")
| summarize
    Count = count(),
    UniqueIPs = dcount(clientIP_s)
    by ruleName_s, action_s, policy_s
| order by Count desc
```

### 5.3 Detection Timeline

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(1h)
| summarize DetectionCount = count() by bin(TimeGenerated, 5m), action_s
| render timechart
```

### 5.4 Top Attacking IPs

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(1h)
| where action_s != "Allow"
| summarize
    AttackCount = count(),
    Rules = make_set(ruleName_s),
    Uris = make_set(requestUri_s)
    by clientIP_s
| order by AttackCount desc
| take 10
```

---

## Section 6: Configure Origin Lockdown

Origin lockdown ensures that your backend web apps only accept traffic from Front Door, preventing attackers from bypassing the WAF by accessing the origin directly.

### 6.1 Understand Why Origin Lockdown Matters

Without origin lockdown:
```
Attacker → Backend App (direct) → ⚠️ No WAF inspection!
Attacker → Front Door → WAF → Backend App → ✅ WAF protected
```

With origin lockdown:
```
Attacker → Backend App (direct) → ❌ 403 Forbidden
Attacker → Front Door → WAF → Backend App → ✅ WAF protected
```

### 6.2 Get the Front Door ID

1. Retrieve the Front Door resource ID (needed for the service tag):

   ```bash
   az afd profile show \
     --profile-name <frontdoor-profile-name> \
     --resource-group <resource-group-name> \
     --query "frontDoorId" \
     --output tsv
   ```

   Note the **Front Door ID** — you will use it in the access restrictions.

### 6.3 Configure Access Restrictions on Backend App 1

1. Add an access restriction to allow only Front Door traffic:

   ```bash
   # Allow traffic from Azure Front Door
   az webapp config access-restriction add \
     --name <webapp1-name> \
     --resource-group <resource-group-name> \
     --priority 100 \
     --rule-name "AllowFrontDoor" \
     --action Allow \
     --service-tag AzureFrontDoor.Backend \
     --http-header x-azure-fdid=<front-door-id>
   ```

2. Add a deny-all rule to block direct access:

   ```bash
   # The default action when access restrictions are configured
   # is to deny all traffic not matching a rule.
   # Verify by listing the rules:
   az webapp config access-restriction show \
     --name <webapp1-name> \
     --resource-group <resource-group-name> \
     --output table
   ```

### 6.4 Configure Access Restrictions on Backend App 2

1. Repeat the same configuration for the second web app:

   ```bash
   az webapp config access-restriction add \
     --name <webapp2-name> \
     --resource-group <resource-group-name> \
     --priority 100 \
     --rule-name "AllowFrontDoor" \
     --action Allow \
     --service-tag AzureFrontDoor.Backend \
     --http-header x-azure-fdid=<front-door-id>
   ```

### 6.5 Configure via Azure Portal (Alternative)

1. Navigate to your **App Service** resource.

2. In the left-hand menu, under **Settings**, click **Networking**.

3. Click **Access restriction** under Inbound traffic.

4. Click **+ Add** to add a new rule:
   - **Name**: AllowFrontDoor
   - **Action**: Allow
   - **Priority**: 100
   - **Type**: Service Tag
   - **Service Tag**: AzureFrontDoor.Backend
   - **X-Azure-FDID**: Paste the Front Door ID

5. Click **Add rule**.

6. Repeat for the second web app.

---

## Section 7: Verify Origin Lockdown

### 7.1 Test Direct Access (Should Fail)

1. Get the direct URLs of the backend web apps:

   ```bash
   az webapp show --name <webapp1-name> --resource-group <resource-group-name> \
     --query "defaultHostName" --output tsv
   ```

2. Try accessing the web app directly:

   ```powershell
   try {
       $response = Invoke-WebRequest -Uri "https://<webapp1>.azurewebsites.net" -Method GET -ErrorAction Stop
       Write-Host "Status: $($response.StatusCode) — ⚠️ Direct access still works (lockdown not effective)"
   } catch {
       Write-Host "Status: $($_.Exception.Response.StatusCode.Value__) — ✅ Direct access blocked"
   }
   ```

   Expected: **403 Forbidden** — direct access should be blocked.

3. Repeat for the second web app:

   ```powershell
   try {
       $response = Invoke-WebRequest -Uri "https://<webapp2>.azurewebsites.net" -Method GET -ErrorAction Stop
       Write-Host "Status: $($response.StatusCode) — ⚠️ Direct access still works"
   } catch {
       Write-Host "Status: $($_.Exception.Response.StatusCode.Value__) — ✅ Direct access blocked"
   }
   ```

### 7.2 Test Access via Front Door (Should Work)

1. Access the application through Front Door:

   ```powershell
   $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" -Method GET
   Write-Host "Status: $($response.StatusCode) — ✅ Front Door access works"
   ```

   Expected: **200 OK** — traffic through Front Door should work normally.

### 7.3 Verify End-to-End Flow

```powershell
# Summary test
Write-Host "=== Origin Lockdown Verification ===" -ForegroundColor Cyan

# Test 1: Direct access to App 1
Write-Host "`n[Test 1] Direct access to App 1:" -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri "https://<webapp1>.azurewebsites.net" -ErrorAction Stop
    Write-Host "  Result: $($r.StatusCode) — FAIL (should be blocked)" -ForegroundColor Red
} catch {
    Write-Host "  Result: $($_.Exception.Response.StatusCode.Value__) — PASS (blocked)" -ForegroundColor Green
}

# Test 2: Direct access to App 2
Write-Host "`n[Test 2] Direct access to App 2:" -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri "https://<webapp2>.azurewebsites.net" -ErrorAction Stop
    Write-Host "  Result: $($r.StatusCode) — FAIL (should be blocked)" -ForegroundColor Red
} catch {
    Write-Host "  Result: $($_.Exception.Response.StatusCode.Value__) — PASS (blocked)" -ForegroundColor Green
}

# Test 3: Access via Front Door
Write-Host "`n[Test 3] Access via Front Door:" -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" -ErrorAction Stop
    Write-Host "  Result: $($r.StatusCode) — PASS (accessible)" -ForegroundColor Green
} catch {
    Write-Host "  Result: ERROR — FAIL (should be accessible)" -ForegroundColor Red
}
```

---

## Section 8: Switch Front Door WAF to Prevention Mode

### 8.1 Switch Mode via Portal

1. Navigate to your **Front Door WAF Policy**.

2. Click **Policy settings** in the left-hand menu.

3. Change **Mode** from **Detection** to **Prevention**.

4. Click **Save**.

### 8.2 Switch Mode via Azure CLI

```bash
az network front-door waf-policy update \
  --name <fd-waf-policy-name> \
  --resource-group <resource-group-name> \
  --mode Prevention
```

### 8.3 Test Prevention Mode

1. Re-run attack traffic via Front Door:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<endpoint>.azurefd.net" -AttackType SQLi
   ```

2. Attacks should now return **403 Forbidden**.

3. Verify legitimate traffic still works:

   ```powershell
   $response = Invoke-WebRequest -Uri "https://<endpoint>.azurefd.net" -Method GET
   Write-Host "Legitimate request: $($response.StatusCode)"
   ```

### 8.4 Query Prevention Mode Logs

```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where action_s == "Block"
| where TimeGenerated > ago(1h)
| project
    TimeGenerated,
    clientIP_s,
    requestUri_s,
    ruleName_s,
    policy_s,
    action_s,
    trackingReference_s
| order by TimeGenerated desc
| take 30
```

---

## Section 9: Front Door vs Application Gateway WAF

### Comparison Table

| Feature | Front Door WAF | Application Gateway WAF |
|---------|---------------|------------------------|
| **Deployment location** | Edge (global PoPs) | Regional (in your VNET) |
| **Traffic inspection point** | At Microsoft's edge | At the application gateway |
| **Latency impact** | Minimal (inspected at nearest PoP) | Adds regional processing time |
| **DDoS protection** | Built-in volumetric DDoS at edge | Requires separate DDoS Protection |
| **Rule sets** | DRS 2.1 + Bot Manager | CRS 3.2 / DRS 2.1 |
| **Custom rules** | Yes | Yes |
| **Rate limiting** | Yes (per Front Door) | Yes (per Application Gateway) |
| **Bot protection** | Yes (with JS Challenge) | Yes (limited, no JS Challenge) |
| **Geo-filtering** | Yes | Yes |
| **Private Link to origin** | Yes (Premium SKU) | N/A (regional) |
| **SSL offloading** | Yes (at edge) | Yes (at gateway) |
| **Caching** | Yes | No |
| **Price model** | Per request + data transfer | Per gateway hour + capacity units |

### When to Use Each

| Scenario | Recommended WAF |
|----------|----------------|
| Global applications with users worldwide | **Front Door** |
| Applications needing edge caching + WAF | **Front Door** |
| Single-region applications in a VNET | **Application Gateway** |
| Need to inspect internal VNET traffic | **Application Gateway** |
| Defense in depth (layered protection) | **Both** (Front Door → Application Gateway) |
| API Management behind WAF | **Application Gateway** |
| Microservices with URL-based routing | **Application Gateway** |
| Need bot detection with JavaScript Challenge | **Front Door** |

### Defense in Depth Architecture

For maximum protection, use both WAFs together:

```
User → Front Door (Edge WAF) → Application Gateway (Regional WAF) → Backend App

Layer 1: Front Door WAF
  - Blocks volumetric attacks at the edge
  - Geo-filtering
  - Bot management with JS Challenge
  - Rate limiting

Layer 2: Application Gateway WAF
  - Deep packet inspection within the VNET
  - URL-based routing
  - SSL re-encryption
  - Additional managed rules
```

---

## Summary

In this lab, you:

- ✅ Explored the Front Door Premium profile, endpoint, origin group, and routes
- ✅ Examined the Front Door WAF policy with DRS 2.1 and Bot Manager rules
- ✅ Tested application access through the Front Door endpoint
- ✅ Generated attack traffic via Front Door and analyzed WAF logs
- ✅ Configured origin lockdown using App Service access restrictions
- ✅ Verified that direct access to backends is blocked while Front Door access works
- ✅ Switched the Front Door WAF to Prevention mode and validated blocking
- ✅ Compared Front Door WAF and Application Gateway WAF capabilities

**Next Lab:** [Lab 07 - Configure Bot Protection and JavaScript Challenge](lab07.md)
