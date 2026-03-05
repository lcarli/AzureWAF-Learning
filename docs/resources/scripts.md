# :wrench: Scripts Reference

## Traffic Generation Scripts

### simulate-waf-traffic.ps1

Generates **sustained, realistic WAF traffic** for populating Log Analytics logs.
Run this before analysis labs (Lab 03+) to ensure data is available.

```powershell
# Basic usage - 15 minutes of mixed traffic
.\simulate-waf-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>"

# Extended run with higher attack ratio
.\simulate-waf-traffic.ps1 -TargetUrl "https://<fd-endpoint>.azurefd.net" `
    -DurationMinutes 30 -AttackRatio 40

# Quick burst for testing
.\simulate-waf-traffic.ps1 -TargetUrl "http://myappgw.com" `
    -DurationMinutes 5 -RequestsPerSecond 5
```

| Parameter | Default | Description |
|---|---|---|
| `TargetUrl` | (required) | WAF-protected endpoint |
| `DurationMinutes` | 15 | How long to run |
| `RequestsPerSecond` | 3 | Approximate request rate |
| `AttackRatio` | 30 | % of requests that are attacks |

**Traffic mix includes:**

- :white_check_mark: Legitimate browsing (page views, searches, API calls)
- :x: SQL Injection (12 variants)
- :x: Cross-Site Scripting (10 variants)
- :x: Command Injection (8 variants)
- :x: Path Traversal (7 variants)
- :x: Remote File Inclusion (4 variants)
- :x: Scanner probes (15 variants)
- :x: Bot user-agents (8 variants)

---

### generate-traffic.ps1

**One-shot attack simulation** for targeted testing in labs.

```powershell
# Run all attack types
.\generate-traffic.ps1 -TargetUrl "http://<appgw-url>"

# Run specific attack type
.\generate-traffic.ps1 -TargetUrl "http://<url>" -AttackType SQLi

# Rate limit testing
.\generate-traffic.ps1 -TargetUrl "http://<url>" -AttackType RateLimit -Count 200
```

| Attack Types | Description |
|---|---|
| `SQLi` | SQL Injection payloads |
| `XSS` | Cross-Site Scripting |
| `CommandInjection` | OS command injection |
| `PathTraversal` | Directory traversal |
| `RFI` | Remote File Inclusion |
| `Scanner` | Scanner/tool signatures |
| `Bot` | Bot user-agent strings |
| `RateLimit` | Burst traffic for rate limiting |
| `Legitimate` | Normal traffic patterns |
| `All` | All attack types (default) |

---

## Infrastructure Scripts

### deploy.ps1

One-click infrastructure deployment.

```powershell
# Standard deployment
.\deploy.ps1 -ResourceGroupName "rg-waf-workshop" -Location "eastus2"

# With Sentinel (optional)
.\deploy.ps1 -ResourceGroupName "rg-waf-workshop" -Location "eastus2" -DeploySentinel
```

### cleanup.ps1

Remove all lab resources.

```powershell
# Interactive (asks for confirmation)
.\cleanup.ps1 -ResourceGroupName "rg-waf-workshop"

# Non-interactive
.\cleanup.ps1 -ResourceGroupName "rg-waf-workshop" -Force
```
