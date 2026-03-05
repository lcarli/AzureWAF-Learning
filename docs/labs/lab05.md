# Lab 05 - Switch to Prevention Mode and Validate Protection

## Overview

In this lab, you will switch the Azure Web Application Firewall (WAF) from **Detection** mode to **Prevention** mode. In Detection mode, the WAF logs malicious requests but allows them through. In Prevention mode, the WAF actively **blocks** malicious requests and returns a **403 Forbidden** response to the attacker.

You will re-run the same attack scenarios from Lab 02, verify that attacks are now blocked, confirm that legitimate traffic and exclusions still work, and analyze the differences in the WAF logs.

## Objectives

- Switch the WAF policy from Detection mode to Prevention mode
- Re-run attack traffic and verify requests are blocked with 403 Forbidden
- Confirm legitimate traffic continues to flow normally (200 OK)
- Validate that previously configured exclusions still work correctly
- Analyze Prevention mode logs and compare them to Detection mode logs
- Configure custom error pages for blocked requests (Bonus)

## Prerequisites

- Completed Lab 02 (Attack Traffic Generation) and Lab 04 (Exclusions)
- Application Gateway WAF v2 deployed and operational
- WAF policy currently in Detection mode with exclusions configured
- Access to the Azure Portal and Azure CLI
- Log Analytics workspace with WAF diagnostics enabled

---

## Section 1: Switch to Prevention Mode

### Option A: Switch via Azure Portal

1. Navigate to the **Azure Portal** → **Resource Groups** → select your workshop resource group.

2. Open the **WAF Policy** resource (e.g., `wafpolicy`).

3. In the left-hand menu, click **Policy settings**.

4. Locate the **Mode** setting. It should currently show **Detection**.

5. Change the mode from **Detection** to **Prevention**.

6. Click **Save** at the top of the page.

7. Wait for the notification confirming the update was successful (this may take 1-2 minutes to propagate).

### Option B: Switch via Azure CLI

1. Open a terminal or Cloud Shell session.

2. Run the following command to switch to Prevention mode:

   ```bash
   # Get the WAF policy name and resource group
   az network application-gateway waf-policy show \
     --name <waf-policy-name> \
     --resource-group <resource-group-name> \
     --query "policySettings.mode" \
     --output tsv

   # Switch to Prevention mode
   az network application-gateway waf-policy policy-setting update \
     --policy-name <waf-policy-name> \
     --resource-group <resource-group-name> \
     --mode Prevention \
     --state Enabled
   ```

3. Verify the change:

   ```bash
   az network application-gateway waf-policy show \
     --name <waf-policy-name> \
     --resource-group <resource-group-name> \
     --query "policySettings" \
     --output table
   ```

   Expected output:

   | Mode       | State   | RequestBodyCheck | MaxRequestBodySizeInKb |
   |------------|---------|------------------|------------------------|
   | Prevention | Enabled | true             | 128                    |

> **⚠️ Important:** Switching to Prevention mode means malicious requests will be **actively blocked**. In a production environment, ensure you have thoroughly tested in Detection mode first and have appropriate exclusions in place before switching.

---

## Section 2: Re-run Attack Traffic

Now that the WAF is in Prevention mode, re-run the same attacks used in Lab 02 to see how the behavior changes.

### 2.1 Run SQL Injection Attacks

1. Open a PowerShell terminal and navigate to the scripts directory:

   ```powershell
   cd C:\Users\lramoscostah\Downloads\scripts
   ```

2. Execute SQL injection attacks against the Application Gateway:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<appgw-public-ip>" -AttackType SQLi
   ```

3. Observe the output. You should now see **403 Forbidden** responses instead of 200 OK.

### 2.2 Run Cross-Site Scripting (XSS) Attacks

1. Execute XSS attacks:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<appgw-public-ip>" -AttackType XSS
   ```

2. Again, observe that responses return **403 Forbidden**.

### 2.3 Run Path Traversal Attacks

1. Execute path traversal attacks:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<appgw-public-ip>" -AttackType PathTraversal
   ```

### 2.4 Run Command Injection Attacks

1. Execute command injection attacks:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<appgw-public-ip>" -AttackType CommandInjection
   ```

### 2.5 Run All Attacks

1. Alternatively, run all attack types at once:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<appgw-public-ip>" -AttackType All
   ```

> **📝 Note:** Keep the terminal output visible. You will compare the HTTP response codes (403 vs 200) in the next section.

---

## Section 3: Verify Blocking

After running the attacks, verify that the WAF is actively blocking malicious requests.

### 3.1 Check HTTP Response Codes

1. In the PowerShell output from the attack scripts, look for the HTTP status codes:

   ```
   [BLOCKED] 403 Forbidden - SQL Injection attempt: ?id=1' OR '1'='1
   [BLOCKED] 403 Forbidden - XSS attempt: ?input=<script>alert('xss')</script>
   [BLOCKED] 403 Forbidden - Path Traversal attempt: /../../etc/passwd
   ```

2. Verify that **all attack requests** return **403 Forbidden**.

### 3.2 Manual Verification with curl

1. Test a SQL injection attempt manually:

   ```powershell
   # SQL Injection - should return 403
   Invoke-WebRequest -Uri "https://<appgw-public-ip>/?id=1' OR '1'='1" `
     -SkipCertificateCheck -Method GET 2>&1 | Select-Object StatusCode, StatusDescription
   ```

2. Test an XSS attempt manually:

   ```powershell
   # XSS - should return 403
   Invoke-WebRequest -Uri "https://<appgw-public-ip>/?input=<script>alert('xss')</script>" `
     -SkipCertificateCheck -Method GET 2>&1 | Select-Object StatusCode, StatusDescription
   ```

3. You should receive a **403 Forbidden** response with a generic error page indicating the request was blocked.

### 3.3 Verify via Application Gateway Metrics

1. In the Azure Portal, navigate to your **Application Gateway** resource.

2. Click **Metrics** in the left-hand menu.

3. Add the metric **Web Application Firewall Total Rule Distribution** with the filter:
   - **Action** = `Blocked`

4. Set the time range to the **Last 30 minutes**.

5. You should see a spike in blocked requests corresponding to your attack traffic.

---

## Section 4: Verify Legitimate Traffic Still Works

It is critical that Prevention mode does not block legitimate application traffic.

### 4.1 Test Normal HTTP Requests

1. Send a standard request to the application root:

   ```powershell
   $response = Invoke-WebRequest -Uri "https://<appgw-public-ip>/" `
     -SkipCertificateCheck -Method GET
   Write-Host "Status: $($response.StatusCode) $($response.StatusDescription)"
   ```

   Expected: **200 OK**

2. Test a request with normal query parameters:

   ```powershell
   $response = Invoke-WebRequest -Uri "https://<appgw-public-ip>/api/products?category=electronics&page=1" `
     -SkipCertificateCheck -Method GET
   Write-Host "Status: $($response.StatusCode) $($response.StatusDescription)"
   ```

   Expected: **200 OK**

3. Test a POST request with standard form data:

   ```powershell
   $body = @{
       username = "john.doe"
       email    = "john@example.com"
   }
   $response = Invoke-WebRequest -Uri "https://<appgw-public-ip>/api/users" `
     -SkipCertificateCheck -Method POST -Body $body
   Write-Host "Status: $($response.StatusCode) $($response.StatusDescription)"
   ```

   Expected: **200 OK** or **201 Created**

### 4.2 Generate Legitimate Traffic Batch

1. Use the traffic generation script with legitimate traffic:

   ```powershell
   .\generate-traffic.ps1 -TargetUrl "https://<appgw-public-ip>" -AttackType None -Count 50
   ```

2. Verify all responses return **200 OK**.

---

## Section 5: Verify Exclusions Work

Exclusions configured in Lab 04 should continue to allow specific parameters through even in Prevention mode.

### 5.1 Test Excluded Parameters

1. If you previously created an exclusion for a parameter (e.g., `searchQuery`), test it now:

   ```powershell
   # This request contains a pattern that normally triggers WAF rules
   # but should be allowed through because of the exclusion
   $response = Invoke-WebRequest `
     -Uri "https://<appgw-public-ip>/search?searchQuery=select * from products" `
     -SkipCertificateCheck -Method GET
   Write-Host "Status: $($response.StatusCode) $($response.StatusDescription)"
   ```

   Expected: **200 OK** (because the `searchQuery` parameter is excluded from WAF inspection)

2. Verify that the same pattern in a **non-excluded** parameter is still blocked:

   ```powershell
   # Same pattern but in a non-excluded parameter - should be blocked
   try {
       $response = Invoke-WebRequest `
         -Uri "https://<appgw-public-ip>/search?otherParam=select * from products" `
         -SkipCertificateCheck -Method GET -ErrorAction Stop
       Write-Host "Status: $($response.StatusCode)"
   } catch {
       Write-Host "Status: $($_.Exception.Response.StatusCode.Value__) - Blocked as expected"
   }
   ```

   Expected: **403 Forbidden**

### 5.2 Review Exclusions in Portal

1. Navigate to **WAF Policy** → **Managed rules** → **Exclusions**.

2. Verify your exclusions are still listed and active.

3. Confirm that the exclusion scope (Global, Per-rule, or Per-rule-group) is correct.

---

## Section 6: Analyze Prevention Mode Logs

### 6.1 Query Blocked Events in Log Analytics

1. Navigate to your **Log Analytics workspace** in the Azure Portal.

2. Click **Logs** in the left-hand menu.

3. Run the following KQL query to see blocked requests:

   ```kql
   AzureDiagnostics
   | where ResourceType == "APPLICATIONGATEWAYS"
   | where Category == "ApplicationGatewayFirewallLog"
   | where action_s == "Blocked"
   | where TimeGenerated > ago(1h)
   | project
       TimeGenerated,
       clientIp_s,
       requestUri_s,
       ruleId_s,
       ruleSetType_s,
       ruleSetVersion_s,
       ruleGroup_s,
       message_s,
       action_s,
       details_message_s,
       details_data_s
   | order by TimeGenerated desc
   | take 50
   ```

4. Review the results. You should see:
   - **action_s** = `Blocked` for all attack requests
   - The **ruleId_s** identifies which WAF rule triggered the block
   - The **message_s** provides a description of the detected threat

### 6.2 Summarize Blocked Requests by Rule

```kql
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| where TimeGenerated > ago(1h)
| summarize
    BlockedCount = count(),
    UniqueIPs = dcount(clientIp_s),
    SampleUri = any(requestUri_s)
    by ruleId_s, ruleGroup_s, message_s
| order by BlockedCount desc
```

### 6.3 Blocked Requests Over Time

```kql
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| where TimeGenerated > ago(1h)
| summarize BlockedCount = count() by bin(TimeGenerated, 5m)
| render timechart
```

---

## Section 7: Compare Detection vs. Prevention Logs

Understanding the differences in log entries between Detection and Prevention mode is crucial for WAF operations.

### 7.1 Side-by-Side Comparison Query

Run this query to compare Detection and Prevention log entries:

```kql
// Compare Detection vs Prevention mode actions
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(24h)
| summarize
    DetectedCount = countif(action_s == "Detected"),
    BlockedCount = countif(action_s == "Blocked"),
    MatchedCount = countif(action_s == "Matched"),
    AllowedCount = countif(action_s == "Allowed")
    by ruleId_s, ruleGroup_s
| order by DetectedCount + BlockedCount desc
| take 20
```

### 7.2 Key Differences

| Aspect | Detection Mode | Prevention Mode |
|--------|---------------|-----------------|
| **Action on match** | Logs the request, allows it through | Logs the request, **blocks** it with 403 |
| **Log field `action_s`** | `Detected` | `Blocked` |
| **Impact on user** | None — request is served | User receives 403 Forbidden |
| **Backend receives request** | Yes | No — request never reaches backend |
| **Use case** | Tuning, testing, baseline analysis | Active production protection |
| **Risk of false positives** | Low (no impact on users) | High (legitimate traffic may be blocked) |

### 7.3 Timeline Comparison

```kql
// Visualize when Detection vs Prevention events occurred
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated > ago(24h)
| where action_s in ("Detected", "Blocked")
| summarize Count = count() by bin(TimeGenerated, 15m), action_s
| render timechart
```

### 7.4 Verify No False Positives in Prevention Mode

```kql
// Look for blocked requests that might be false positives
// Check for blocked URIs that look like legitimate traffic
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| where TimeGenerated > ago(1h)
| where requestUri_s !contains "select"
    and requestUri_s !contains "script"
    and requestUri_s !contains "etc/passwd"
    and requestUri_s !contains "cmd"
    and requestUri_s !contains "exec"
| project TimeGenerated, clientIp_s, requestUri_s, ruleId_s, message_s
| order by TimeGenerated desc
```

> **💡 Tip:** If this query returns results, those may be false positives that need exclusions before remaining in Prevention mode.

---

## Section 8: Custom Error Pages (Bonus)

By default, the WAF returns a generic 403 Forbidden page. You can configure a custom error page to provide a better user experience.

### 8.1 Create a Custom Error Page

1. Create an HTML file for the custom error page. Host it on a publicly accessible storage account or web server:

   ```html
   <!DOCTYPE html>
   <html lang="en">
   <head>
       <meta charset="UTF-8">
       <title>Access Denied</title>
       <style>
           body {
               font-family: 'Segoe UI', Arial, sans-serif;
               display: flex;
               justify-content: center;
               align-items: center;
               height: 100vh;
               margin: 0;
               background: #f0f2f5;
           }
           .container {
               text-align: center;
               padding: 40px;
               background: white;
               border-radius: 8px;
               box-shadow: 0 2px 10px rgba(0,0,0,0.1);
           }
           h1 { color: #e74c3c; }
           p { color: #555; }
       </style>
   </head>
   <body>
       <div class="container">
           <h1>🚫 Access Denied</h1>
           <p>Your request has been blocked by our Web Application Firewall.</p>
           <p>If you believe this is an error, please contact support.</p>
           <p><small>Reference ID: {{azure-ref}}</small></p>
       </div>
   </body>
   </html>
   ```

### 8.2 Configure Custom Error Page via Azure Portal

1. Navigate to your **Application Gateway** resource.

2. Click **Listeners** in the left-hand menu.

3. Select the listener associated with your WAF-protected site.

4. Scroll down to **Error page URL** settings.

5. For **HTTP status code 403**, toggle **Show custom error page** to **Yes**.

6. Enter the URL of your hosted custom error page.

7. Click **Save**.

### 8.3 Configure Custom Error Page via Azure CLI

```bash
# Configure custom error page for 403 responses
az network application-gateway http-listener update \
  --gateway-name <appgw-name> \
  --resource-group <resource-group-name> \
  --name <listener-name> \
  --custom-error-pages StatusCode=HttpStatus403 CustomErrorPageUrl="https://<storage-account>.blob.core.windows.net/errors/403.html"
```

### 8.4 Test the Custom Error Page

1. Send a malicious request that triggers the WAF:

   ```powershell
   Invoke-WebRequest -Uri "https://<appgw-public-ip>/?id=1' OR '1'='1" `
     -SkipCertificateCheck -Method GET 2>&1
   ```

2. The response should now display your custom error page instead of the generic 403 page.

---

## Section 9: Key Takeaways

### When to Use Detection Mode

- ✅ **Initial deployment** — monitor traffic patterns and identify false positives
- ✅ **After rule changes** — validate new rules or exclusions before enforcing
- ✅ **Baseline analysis** — understand what the WAF would block without impacting users
- ✅ **Migration** — when moving from another WAF product to Azure WAF

### When to Use Prevention Mode

- ✅ **Production protection** — after thorough testing in Detection mode
- ✅ **Compliance requirements** — when active blocking is mandated
- ✅ **Known attack patterns** — when you are confident in the rules and exclusions
- ✅ **Defense in depth** — as part of a layered security strategy

### Recommended Workflow

```
1. Deploy WAF in Detection mode
2. Generate baseline traffic (legitimate + simulated attacks)
3. Analyze logs and identify false positives
4. Configure exclusions for false positives
5. Re-test to confirm exclusions work
6. Switch to Prevention mode
7. Monitor closely for the first 24-48 hours
8. Configure alerts for blocked traffic anomalies
```

### Key Points

| Topic | Key Point |
|-------|-----------|
| **Mode transition** | Always test in Detection before switching to Prevention |
| **Exclusions** | Must be configured in Detection mode to avoid blocking legitimate traffic |
| **Custom error pages** | Improve user experience when requests are blocked |
| **Monitoring** | Set up alerts in Azure Monitor for unusual blocking patterns |
| **Rollback plan** | Always have a plan to switch back to Detection if issues arise |

---

## Summary

In this lab, you:

- ✅ Switched the WAF policy from Detection to Prevention mode
- ✅ Re-ran attack traffic and confirmed requests are now blocked (403 Forbidden)
- ✅ Verified that legitimate traffic continues to work normally (200 OK)
- ✅ Confirmed that exclusions work correctly in Prevention mode
- ✅ Analyzed Prevention mode logs using KQL queries
- ✅ Compared Detection vs. Prevention mode log entries
- ✅ Optionally configured a custom 403 error page

**Next Lab:** [Lab 06 - Deploy Front Door Premium with WAF and Origin Lockdown](lab06.md)
