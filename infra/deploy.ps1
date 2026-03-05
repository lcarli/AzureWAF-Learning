<#
.SYNOPSIS
    Deploys all Azure WAF Workshop lab infrastructure.

.DESCRIPTION
    One-click deployment script for the Azure WAF Workshop.
    Deploys VNet, Web Apps, Application Gateway WAF v2, Front Door Premium,
    Application Gateway for Containers, and Log Analytics.

.PARAMETER ResourceGroupName
    Name of the resource group to create/use.

.PARAMETER Location
    Azure region for deployment.

.PARAMETER Prefix
    Resource name prefix.

.PARAMETER DeploySentinel
    If specified, also deploys Microsoft Sentinel.

.EXAMPLE
    .\deploy.ps1 -ResourceGroupName "rg-waf-workshop" -Location "eastus2"

.EXAMPLE
    .\deploy.ps1 -ResourceGroupName "rg-waf-workshop" -Location "eastus2" -DeploySentinel
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName = "rg-waf-workshop",

    [Parameter(Mandatory = $true)]
    [string]$Location = "eastus2",

    [string]$Prefix = "waf-workshop",

    [switch]$DeploySentinel
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Azure WAF Workshop - Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check Azure CLI
Write-Host "[1/4] Checking prerequisites..." -ForegroundColor Yellow
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "  Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "  Subscription: $($account.name)" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI not logged in. Run 'az login' first."
    exit 1
}

# Create resource group
Write-Host ""
Write-Host "[2/4] Creating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location --output none
Write-Host "  Resource group ready." -ForegroundColor Green

# Deploy Bicep
Write-Host ""
Write-Host "[3/4] Deploying infrastructure (this may take 15-25 minutes)..." -ForegroundColor Yellow
Write-Host "  Deploying: VNet, Web Apps, App Gateway WAF v2, Front Door Premium, AGC, Log Analytics" -ForegroundColor Gray

$deployParams = @(
    "group", "create",
    "--resource-group", $ResourceGroupName,
    "--template-file", "$PSScriptRoot\main.bicep",
    "--parameters", "prefix=$Prefix", "deploySentinel=$($DeploySentinel.IsPresent.ToString().ToLower())",
    "--query", "properties.outputs",
    "--output", "json"
)

$result = az deployment @deployParams 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed:`n$result"
    exit 1
}

$outputs = $result | ConvertFrom-Json

# Display results
Write-Host ""
Write-Host "[4/4] Deployment Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resource Group:         $ResourceGroupName" -ForegroundColor White
Write-Host ""
Write-Host "--- Application Gateway ---" -ForegroundColor Yellow
Write-Host "  Public IP:            $($outputs.appgwPublicIp.value)" -ForegroundColor White
Write-Host "  FQDN:                 $($outputs.appgwFqdn.value)" -ForegroundColor White
Write-Host "  WAF Policy:           $($outputs.appgwWafPolicyName.value)" -ForegroundColor White
Write-Host ""
Write-Host "--- Front Door ---" -ForegroundColor Yellow
Write-Host "  Endpoint:             $($outputs.frontDoorEndpoint.value)" -ForegroundColor White
Write-Host "  WAF Policy:           $($outputs.frontDoorWafPolicyName.value)" -ForegroundColor White
Write-Host ""
Write-Host "--- Backend Web Apps ---" -ForegroundColor Yellow
Write-Host "  Web App 1:            $($outputs.app1Hostname.value)" -ForegroundColor White
Write-Host "  Web App 2:            $($outputs.app2Hostname.value)" -ForegroundColor White
Write-Host ""
Write-Host "--- AGC ---" -ForegroundColor Yellow
Write-Host "  Name:                 $($outputs.agcName.value)" -ForegroundColor White
Write-Host ""
Write-Host "--- Monitoring ---" -ForegroundColor Yellow
Write-Host "  Log Analytics:        $($outputs.logAnalyticsWorkspace.value)" -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Ready for labs! Open the Azure portal to begin." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

# Save outputs for lab scripts
$outputs | ConvertTo-Json -Depth 5 | Out-File "$PSScriptRoot\.lab-outputs.json" -Encoding utf8
Write-Host ""
Write-Host "Outputs saved to: $PSScriptRoot\.lab-outputs.json" -ForegroundColor Gray
