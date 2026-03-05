# Lab 01 – Deploy Application Gateway WAF v2 with DRS 2.1

## Overview

In this lab you will explore the Azure infrastructure that has already been deployed via Bicep. You will examine the **Application Gateway WAF v2**, its associated **WAF Policy** configured with **DRS 2.1**, and verify that backend web applications are reachable through the gateway.

### Objectives

| # | Objective |
|---|-----------|
| 1 | Understand the deployed infrastructure and resource layout |
| 2 | Explore the Application Gateway WAF v2 in the Azure portal |
| 3 | Examine the WAF policy configuration (Detection mode, DRS 2.1, Bot Manager 1.1) |
| 4 | Verify backend connectivity through the Application Gateway |
| 5 | Confirm diagnostic settings are sending logs to Log Analytics |

### Prerequisites

- An Azure subscription with **Contributor** access to the workshop resource group.
- Azure CLI (`az`) version 2.50 or later installed and authenticated.
- A modern web browser (Edge, Chrome, or Firefox).
- The workshop Bicep deployment completed successfully.

### Estimated Duration

**30–40 minutes**

---

## Section 1 – Verify Deployment

The workshop infrastructure was deployed using a Bicep template. Before diving in, confirm that all resources exist and are in a healthy state.

### 1.1 – Log in to Azure CLI

```powershell
# Log in to Azure (skip if already authenticated)
az login

# Set the target subscription
az account set --subscription "<Your-Subscription-Name-or-ID>"
```

### 1.2 – Set environment variables

Create variables that will be reused throughout all labs:

```powershell
# Replace with your actual resource group name
$RG = "rg-waf-workshop"

# Verify the resource group exists
az group show --name $RG --query "{Name:name, Location:location, State:properties.provisioningState}" -o table
```

**Expected output:**

| Name | Location | State |
|------|----------|-------|
| rg-waf-workshop | eastus2 | Succeeded |

### 1.3 – List all deployed resources

```powershell
az resource list --resource-group $RG --output table --query "[].{Name:name, Type:type, Location:location}"
```

You should see resources similar to the following:

| Name | Type | Description |
|------|------|-------------|
| `appgw-waf-workshop` | `Microsoft.Network/applicationGateways` | Application Gateway WAF v2 |
| `waf-policy-workshop` | `Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies` | WAF Policy |
| `afd-waf-workshop` | `Microsoft.Cdn/profiles` | Azure Front Door Premium |
| `alb-workshop` | `Microsoft.ServiceNetworking/trafficControllers` | Application Gateway for Containers |
| `webapp-backend-01` | `Microsoft.Web/sites` | Backend Web App 1 |
| `webapp-backend-02` | `Microsoft.Web/sites` | Backend Web App 2 |
| `log-waf-workshop` | `Microsoft.OperationalInsights/workspaces` | Log Analytics Workspace |
| `pip-appgw` | `Microsoft.Network/publicIPAddresses` | Public IP for Application Gateway |

> **Note:** Exact resource names may differ depending on your deployment parameters.

### 1.4 – Get the Application Gateway public IP

```powershell
$APPGW_PIP = az network public-ip show `
    --resource-group $RG `
    --name "pip-appgw" `
    --query "ipAddress" -o tsv

Write-Host "Application Gateway Public IP: $APPGW_PIP"
```

Save this value — you will use it throughout the workshop.

---

## Section 2 – Explore Application Gateway in the Portal

### 2.1 – Navigate to the Application Gateway

1. Open the **Azure portal**: [https://portal.azure.com](https://portal.azure.com).
2. In the top search bar, type **Application gateways** and select the service.
3. Click on your Application Gateway (e.g., `appgw-waf-workshop`).

### 2.2 – Examine the Overview blade

On the **Overview** blade, verify the following:

| Property | Expected Value |
|----------|----------------|
| **Tier** | WAF V2 |
| **Status** | Running |
| **Virtual network/subnet** | Your workshop VNet and AppGW subnet |

### 2.3 – Examine the SKU and Capacity

1. In the left menu, select **Configuration**.
2. Verify:
   - **Tier**: `WAF V2`
   - **Autoscaling**: Confirm whether min/max instance counts are configured.
   - **HTTP2**: Verify the status.

```powershell
# CLI equivalent: Query the SKU
az network application-gateway show `
    --resource-group $RG `
    --name "appgw-waf-workshop" `
    --query "{Tier:sku.tier, SKU:sku.name, Capacity:sku.capacity, AutoscaleMin:autoscaleConfiguration.minCapacity, AutoscaleMax:autoscaleConfiguration.maxCapacity}" `
    -o table
```

### 2.4 – Examine Frontend configuration

1. In the left menu, select **Frontend IP configurations**.
2. Verify that a **Public** frontend IP is associated (the public IP created earlier).

```powershell
# CLI equivalent
az network application-gateway frontend-ip list `
    --resource-group $RG `
    --gateway-name "appgw-waf-workshop" `
    -o table
```

### 2.5 – Examine Backend Pools

1. In the left menu, select **Backend pools**.
2. Click on the backend pool to view its targets.
3. Verify that the two backend web apps are listed (e.g., `webapp-backend-01.azurewebsites.net` and `webapp-backend-02.azurewebsites.net`).

```powershell
# CLI equivalent
az network application-gateway address-pool list `
    --resource-group $RG `
    --gateway-name "appgw-waf-workshop" `
    --query "[].{Name:name, BackendAddresses:backendAddresses[].fqdn}" `
    -o json
```

### 2.6 – Examine HTTP Listeners

1. In the left menu, select **Listeners**.
2. Verify there is at least one HTTP listener on port **80**.

```powershell
# CLI equivalent
az network application-gateway http-listener list `
    --resource-group $RG `
    --gateway-name "appgw-waf-workshop" `
    --query "[].{Name:name, Protocol:protocol, Port:frontendPort}" `
    -o table
```

### 2.7 – Examine Routing Rules

1. In the left menu, select **Rules**.
2. Click on the routing rule to examine the configuration.
3. Verify the rule binds the **listener** to the **backend pool** with the correct **HTTP settings**.

```powershell
# CLI equivalent
az network application-gateway rule list `
    --resource-group $RG `
    --gateway-name "appgw-waf-workshop" `
    -o table
```

---

## Section 3 – Explore WAF Policy

### 3.1 – Navigate to the WAF Policy

1. In the Azure portal search bar, type **Web Application Firewall policies** and select the service.
2. Click on your WAF policy (e.g., `waf-policy-workshop`).

> **Alternative navigation:** From the Application Gateway blade, select **Web application firewall** in the left menu, then click the linked policy name.

### 3.2 – Verify WAF Mode

1. On the **Overview** blade, locate the **Policy mode** field.
2. Confirm it is set to **Detection**.

```powershell
# CLI equivalent
az network application-gateway waf-policy show `
    --resource-group $RG `
    --name "waf-policy-workshop" `
    --query "policySettings.mode" -o tsv
```

**Expected output:** `Detection`

> **Important:** In **Detection** mode, the WAF evaluates all rules and logs matches but does **not** block any traffic. This is the recommended starting mode for new deployments.

### 3.3 – Examine Managed Rules

1. In the left menu, select **Managed rules**.
2. Verify the following rule sets are configured:

| Rule Set | Version | Description |
|----------|---------|-------------|
| **DRS** (Default Rule Set) | **2.1** | OWASP-based rules for SQL injection, XSS, LFI, RFI, command injection, and more |
| **Microsoft_BotManagerRuleSet** | **1.1** | Bot detection and classification rules |

3. Expand the **DRS 2.1** rule set to see the rule groups:
   - **General** – General rules
   - **REQUEST-911-METHOD-ENFORCEMENT** – HTTP method enforcement
   - **REQUEST-913-SCANNER-DETECTION** – Scanner and crawler detection
   - **REQUEST-920-PROTOCOL-ENFORCEMENT** – Protocol violations
   - **REQUEST-930-APPLICATION-ATTACK-LFI** – Local file inclusion
   - **REQUEST-931-APPLICATION-ATTACK-RFI** – Remote file inclusion
   - **REQUEST-932-APPLICATION-ATTACK-RCE** – Remote code execution
   - **REQUEST-933-APPLICATION-ATTACK-PHP** – PHP injection
   - **REQUEST-941-APPLICATION-ATTACK-XSS** – Cross-site scripting
   - **REQUEST-942-APPLICATION-ATTACK-SQLI** – SQL injection
   - **REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION** – Session fixation
   - **REQUEST-944-APPLICATION-ATTACK-JAVA** – Java attacks

```powershell
# CLI equivalent: List managed rule sets
az network application-gateway waf-policy managed-rule rule-set list `
    --resource-group $RG `
    --policy-name "waf-policy-workshop" `
    -o json
```

### 3.4 – Examine Policy Settings

1. In the left menu, select **Policy settings**.
2. Review the following:

| Setting | Expected Value | Description |
|---------|----------------|-------------|
| **Mode** | Detection | Log but do not block |
| **Request body inspection** | Enabled | Inspect POST body content |
| **Max request body size (KB)** | 128 | Maximum body size inspected |
| **File upload limit (MB)** | 100 | Maximum file upload size |

```powershell
# CLI equivalent
az network application-gateway waf-policy show `
    --resource-group $RG `
    --name "waf-policy-workshop" `
    --query "policySettings" -o json
```

### 3.5 – Verify Policy Association

1. In the left menu, select **Associated application gateways**.
2. Confirm the Application Gateway (`appgw-waf-workshop`) is listed.

---

## Section 4 – Test Backend Connectivity

### 4.1 – Access the Application Gateway via Browser

1. Open a new browser tab.
2. Navigate to `http://<APPGW_PIP>` (the public IP address you retrieved earlier).
3. You should see the default page of one of the backend web applications.

> **Expected result:** The web application responds with a `200 OK` status and displays its default page.

### 4.2 – Test with curl / Invoke-WebRequest

```powershell
# Test with PowerShell
$response = Invoke-WebRequest -Uri "http://$APPGW_PIP" -UseBasicParsing
Write-Host "Status: $($response.StatusCode)"
Write-Host "Content Length: $($response.Content.Length) characters"
```

**Expected output:**

```
Status: 200
Content Length: <varies>
```

### 4.3 – Verify Backend Health

1. In the Azure portal, navigate to your Application Gateway.
2. In the left menu, select **Backend health**.
3. Verify both backend targets show a status of **Healthy**.

```powershell
# CLI equivalent
az network application-gateway show-backend-health `
    --resource-group $RG `
    --name "appgw-waf-workshop" `
    --query "backendAddressPools[].backendHttpSettingsCollection[].servers[].{Address:address, Health:health}" `
    -o table
```

**Expected:** Both backends show `Healthy`.

### 4.4 – Test Multiple Requests

Send several requests to verify the load balancing distributes traffic across both backends:

```powershell
# Send 10 requests and observe responses
1..10 | ForEach-Object {
    $resp = Invoke-WebRequest -Uri "http://$APPGW_PIP" -UseBasicParsing
    Write-Host "Request $_: Status $($resp.StatusCode)"
}
```

---

## Section 5 – Examine Diagnostic Settings

### 5.1 – Verify Diagnostic Settings in Portal

1. Navigate to your Application Gateway in the Azure portal.
2. In the left menu, under **Monitoring**, select **Diagnostic settings**.
3. Verify that a diagnostic setting exists and is configured to send the following log categories to Log Analytics:

| Log Category | Description |
|-------------|-------------|
| **ApplicationGatewayAccessLog** | All access requests to the gateway |
| **ApplicationGatewayFirewallLog** | WAF rule matches and actions |
| **ApplicationGatewayPerformanceLog** | Performance metrics |

4. Confirm the **Destination** is the Log Analytics workspace (`log-waf-workshop`).

### 5.2 – Verify via CLI

```powershell
# List diagnostic settings for the Application Gateway
$APPGW_ID = az network application-gateway show `
    --resource-group $RG `
    --name "appgw-waf-workshop" `
    --query "id" -o tsv

az monitor diagnostic-settings list --resource $APPGW_ID -o json
```

### 5.3 – Verify Log Analytics Workspace

```powershell
# Confirm the workspace exists and is active
az monitor log-analytics workspace show `
    --resource-group $RG `
    --workspace-name "log-waf-workshop" `
    --query "{Name:name, Sku:sku.name, RetentionDays:retentionInDays, State:provisioningState}" `
    -o table
```

---

## Section 6 – Challenge (Optional)

### 6.1 – Query WAF Policy via CLI

Use Azure CLI to retrieve the complete WAF policy configuration as JSON and identify the following:

1. The current WAF mode.
2. The number of managed rule groups enabled.
3. Whether any custom rules exist.

```powershell
# Full WAF policy configuration
az network application-gateway waf-policy show `
    --resource-group $RG `
    --name "waf-policy-workshop" `
    -o json
```

### 6.2 – Explore with Resource Graph

Use Azure Resource Graph to find all WAF-enabled Application Gateways in your subscription:

```powershell
az graph query -q "
    Resources
    | where type == 'microsoft.network/applicationgateways'
    | where properties.sku.tier == 'WAF_v2'
    | project name, resourceGroup, location, properties.sku.tier
" -o table
```

### 6.3 – Document Your Findings

Create a summary of the deployed architecture:

| Component | Name | Key Configuration |
|-----------|------|-------------------|
| Application Gateway | `appgw-waf-workshop` | WAF_v2 tier |
| WAF Policy | `waf-policy-workshop` | Detection mode, DRS 2.1 |
| Backend App 1 | `webapp-backend-01` | Azure Web App |
| Backend App 2 | `webapp-backend-02` | Azure Web App |
| Log Analytics | `log-waf-workshop` | Central logging |

---

## Summary

In this lab you:

- ✅ Verified all workshop resources were deployed successfully
- ✅ Explored the Application Gateway WAF v2 configuration (SKU, frontends, backends, listeners, rules)
- ✅ Examined the WAF policy (Detection mode, DRS 2.1, Bot Manager 1.1)
- ✅ Confirmed backend connectivity through the gateway
- ✅ Verified diagnostic settings are sending logs to Log Analytics

### Next Steps

Proceed to **[Lab 02 – Configure WAF in Detection Mode and Generate Test Traffic](lab02.md)** to start generating attack traffic and observing WAF behavior.
