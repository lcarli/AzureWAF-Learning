---
hide:
  - navigation
  - toc
---

<div class="hero" markdown>

# :shield: Azure WAF Workshop 2026

**WorkshopPLUS: Azure Web Application Firewall — Modern Edition**

Centralized Layer 7 protection for your web applications with the latest Azure WAF features.

[:octicons-rocket-24: Start Learning](#modules){ .md-button .md-button--primary }
[:octicons-beaker-24: Jump to Labs](labs/index.md){ .md-button }

</div>

<div class="stats-grid" markdown>

<div class="stat-card" markdown>
<div class="number">15</div>
<div class="label">Modules</div>
</div>

<div class="stat-card" markdown>
<div class="number">12</div>
<div class="label">Hands-on Labs</div>
</div>

<div class="stat-card" markdown>
<div class="number">89</div>
<div class="label">Topics Covered</div>
</div>

<div class="stat-card" markdown>
<div class="number">50+</div>
<div class="label">Attack Payloads</div>
</div>

</div>

---

## :dart: What You'll Learn

This workshop covers Azure Web Application Firewall from fundamentals to advanced operations, including the **latest 2025-2026 features**:

- :new: **Next-Gen WAF Engine** — 8x faster performance
- :new: **JavaScript Challenge** — Advanced bot mitigation
- :new: **Copilot for Security** — AI-powered WAF operations
- :new: **Application Gateway for Containers** — Kubernetes-native WAF
- :new: **WAF Insights** — Built-in analytics dashboard

---

## :books: Modules { #modules }

<div class="module-grid" markdown>

<a class="module-card" href="modules/00-introduction/" markdown>
### :wave: 00 — Introduction
Workshop logistics, agenda, and introductions
</a>

<a class="module-card" href="modules/01-security-fundamentals/" markdown>
### :lock: 01 — Security Fundamentals
Zero Trust, shared responsibility, and threat landscape
</a>

<a class="module-card" href="modules/02-waf-overview/" markdown>
### :shield: 02 — Azure WAF Overview
Features, benefits, and product suite
</a>

<a class="module-card" href="modules/03-waf-policies/" markdown>
### :gear: 03 — WAF Policies
Configuration, modes, and Next-Gen Engine
</a>

<a class="module-card" href="modules/04-managed-rules/" markdown>
### :bookmark_tabs: 04 — Managed Rules
DRS 2.1, anomaly scoring, and rule groups
</a>

<a class="module-card" href="modules/05-exclusions/" markdown>
### :wrench: 05 — Exclusions & Tuning
False positive tuning and best practices
</a>

<a class="module-card" href="modules/06-custom-rules/" markdown>
### :pencil2: 06 — Custom Rules
Geo-filtering, rate limiting, and match conditions
</a>

<a class="module-card" href="modules/07-bot-protection/" markdown>
### :robot: 07 — Bot Protection
Bot Manager, JavaScript Challenge
</a>

<a class="module-card" href="modules/08-application-gateway/" markdown>
### :globe_with_meridians: 08 — Application Gateway
Regional WAF with App Gateway v2
</a>

<a class="module-card" href="modules/09-front-door/" markdown>
### :earth_americas: 09 — Front Door
Global edge WAF with Front Door Premium
</a>

<a class="module-card" href="modules/10-agc/" markdown>
### :whale: 10 — AGC (Containers)
Application Gateway for Containers with WAF
</a>

<a class="module-card" href="modules/11-ddos/" markdown>
### :no_entry_sign: 11 — DDoS Protection
Layered defense strategy
</a>

<a class="module-card" href="modules/12-monitoring/" markdown>
### :bar_chart: 12 — Monitoring
WAF Insights, logs, metrics, and KQL
</a>

<a class="module-card" href="modules/13-copilot-sentinel/" markdown>
### :sparkles: 13 — Copilot & Sentinel
AI-powered security operations
</a>

<a class="module-card" href="modules/14-best-practices/" markdown>
### :trophy: 14 — Best Practices
Architecture decisions and landing zones
</a>

</div>

---

## :test_tube: Hands-on Labs

All labs include **one-click Deploy to Azure** buttons and step-by-step instructions.

[:octicons-rocket-24: Deploy Lab Infrastructure](labs/setup.md){ .md-button .md-button--primary }

| # | Lab | Type |
|:--:|-----|:----:|
| 01 | [Deploy Application Gateway WAF v2](labs/lab01.md) | :green_circle: Core |
| 02 | [Detection Mode & Traffic Generation](labs/lab02.md) | :green_circle: Core |
| 03 | [KQL Log Analysis](labs/lab03.md) | :green_circle: Core |
| 03B | [WAF Triage Workbook (Fine Tuning)](labs/lab03b.md) | :blue_circle: New |
| 04 | [Exclusions & Custom Rules](labs/lab04.md) | :green_circle: Core |
| 05 | [Prevention Mode Validation](labs/lab05.md) | :green_circle: Core |
| 06 | [Front Door Premium WAF](labs/lab06.md) | :green_circle: Core |
| 07 | [Bot Protection & JavaScript Challenge](labs/lab07.md) | :green_circle: Core |
| 08 | [Rate Limiting with XFF](labs/lab08.md) | :green_circle: Core |
| 09 | [Application Gateway for Containers](labs/lab09.md) | :green_circle: Core |
| 10 | [Microsoft Sentinel Integration](labs/lab10.md) | :yellow_circle: Optional |
| 11 | [Copilot for Security](labs/lab11.md) | :yellow_circle: Optional |

!!! warning "Labs 10-11 require additional licensing"
    Microsoft Sentinel and Copilot for Security require separate licenses.

---

## :rocket: Quick Start

```powershell
# 1. Clone the repository
git clone https://github.com/<your-org>/azure-waf-workshop.git
cd azure-waf-workshop

# 2. Login to Azure
az login

# 3. Deploy all lab infrastructure (~20 minutes)
cd infra/
.\deploy.ps1 -ResourceGroupName "rg-waf-workshop" -Location "eastus2"

# 4. Pre-populate WAF logs (recommended before Lab 03)
cd ../scripts/
.\simulate-waf-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -DurationMinutes 15
```

---

<div style="text-align: center; opacity: 0.6; margin-top: 2rem;" markdown>
Built with :blue_heart: for the Azure community | Powered by [MkDocs Material](https://squidfunk.github.io/mkdocs-material/)
</div>
