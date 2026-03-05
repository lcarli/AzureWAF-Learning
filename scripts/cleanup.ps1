<#
.SYNOPSIS
    Removes all Azure WAF Workshop lab resources.

.PARAMETER ResourceGroupName
    Name of the resource group to delete.

.PARAMETER Force
    Skip confirmation prompt.

.EXAMPLE
    .\cleanup.ps1 -ResourceGroupName "rg-waf-workshop"
    .\cleanup.ps1 -ResourceGroupName "rg-waf-workshop" -Force
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName = "rg-waf-workshop",

    [switch]$Force
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Azure WAF Workshop - Cleanup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will DELETE the resource group '$ResourceGroupName'" -ForegroundColor Red
Write-Host "and ALL resources within it." -ForegroundColor Red
Write-Host ""

# List resources
Write-Host "Resources in group:" -ForegroundColor Yellow
az resource list --resource-group $ResourceGroupName --output table 2>$null
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to delete everything? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Cleanup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Deleting resource group '$ResourceGroupName'..." -ForegroundColor Yellow
az group delete --name $ResourceGroupName --yes --no-wait

Write-Host ""
Write-Host "Resource group deletion initiated (running in background)." -ForegroundColor Green
Write-Host "It may take 5-10 minutes for all resources to be removed." -ForegroundColor Gray
Write-Host ""
Write-Host "Monitor progress:" -ForegroundColor Gray
Write-Host "  az group show --name $ResourceGroupName --query properties.provisioningState" -ForegroundColor White

# Clean up local files
$labOutputs = "$PSScriptRoot\..\infra\.lab-outputs.json"
if (Test-Path $labOutputs) {
    Remove-Item $labOutputs -Force
    Write-Host "  Removed local lab outputs file." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Cleanup complete!" -ForegroundColor Green
