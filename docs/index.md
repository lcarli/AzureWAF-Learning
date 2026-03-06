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
[:octicons-trophy-24: Challenges](challenges/index.md){ .md-button }

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
<div class="number">6</div>
<div class="label">Challenges</div>
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

## :compass: Choose Your Path

<div class="grid cards" markdown>

-   :rocket: **Full Workshop (New Infrastructure)**

    ---

    Deploy the lab infrastructure from scratch and follow all labs in order.

    [:octicons-arrow-right-24: Deploy & Start](labs/setup.md)

-   :wrench: **Bring Your Own WAF**

    ---

    Already have Application Gateway WAF or Front Door WAF? Skip the deploy — download the scripts and jump straight to any lab or challenge.

    [:octicons-arrow-right-24: See instructions below](#bring-your-own-waf)

-   :books: **Self-Study (Theory Only)**

    ---

    Read through the 15 modules as a learning resource — no Azure subscription needed.

    [:octicons-arrow-right-24: Start with Module 01](modules/01-security-fundamentals.md)

-   :trophy: **Challenges Only**

    ---

    Have a WAF running? Download the challenge script, generate traffic, and test your investigation skills.

    [:octicons-arrow-right-24: Start Challenges](challenges/index.md)

</div>

---

## :books: Modules { #modules }

<div class="grid cards" markdown>

-   :wave: **[00 — Introduction](modules/00-introduction.md)**

    ---

    Workshop logistics, agenda, and introductions

-   :lock: **[01 — Security Fundamentals](modules/01-security-fundamentals.md)**

    ---

    Zero Trust, shared responsibility, and threat landscape

-   :shield: **[02 — Azure WAF Overview](modules/02-waf-overview.md)**

    ---

    Features, benefits, and product suite

-   :gear: **[03 — WAF Policies](modules/03-waf-policies.md)**

    ---

    Configuration, modes, and Next-Gen Engine

-   :bookmark_tabs: **[04 — Managed Rules](modules/04-managed-rules.md)**

    ---

    DRS 2.1, anomaly scoring, and rule groups

-   :wrench: **[05 — Exclusions & Tuning](modules/05-exclusions.md)**

    ---

    False positive tuning and best practices

-   :pencil2: **[06 — Custom Rules](modules/06-custom-rules.md)**

    ---

    Geo-filtering, rate limiting, and match conditions

-   :robot: **[07 — Bot Protection](modules/07-bot-protection.md)**

    ---

    Bot Manager, JavaScript Challenge

-   :globe_with_meridians: **[08 — Application Gateway](modules/08-application-gateway.md)**

    ---

    Regional WAF with App Gateway v2

-   :earth_americas: **[09 — Front Door](modules/09-front-door.md)**

    ---

    Global edge WAF with Front Door Premium

-   :whale: **[10 — AGC (Containers)](modules/10-agc.md)**

    ---

    Application Gateway for Containers with WAF

-   :no_entry_sign: **[11 — DDoS Protection](modules/11-ddos.md)**

    ---

    Layered defense strategy

-   :bar_chart: **[12 — Monitoring](modules/12-monitoring.md)**

    ---

    WAF Insights, logs, metrics, and KQL

-   :sparkles: **[13 — Copilot & Sentinel](modules/13-copilot-sentinel.md)**

    ---

    AI-powered security operations

-   :trophy: **[14 — Best Practices](modules/14-best-practices.md)**

    ---

    Architecture decisions and landing zones

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

## :trophy: Challenges

Test your WAF investigation skills! Run the challenge traffic generator, analyze the logs, and answer 6 questions with real-time validation.

[:octicons-trophy-24: Start Challenges](challenges/index.md){ .md-button .md-button--primary }

---

## :electric_plug: Bring Your Own WAF { #bring-your-own-waf }

Already have an Application Gateway WAF or Front Door WAF in your environment? You don't need to deploy the workshop infrastructure — just download the scripts and point them at your WAF endpoint.

### What you need

- [x] An Application Gateway **WAF_v2** or Front Door **Premium** with a WAF Policy
- [x] WAF diagnostic logs enabled and flowing to a **Log Analytics workspace**
- [x] **PowerShell 7+** installed on your machine

### Download the scripts

| Script | Purpose | Download |
|--------|---------|----------|
| **generate-traffic.ps1** | One-shot attack simulation (for labs) | [:octicons-download-24: Download](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/generate-traffic.ps1) |
| **simulate-waf-traffic.ps1** | Continuous traffic generator (pre-populate logs) | [:octicons-download-24: Download](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/simulate-waf-traffic.ps1) |
| **challenge-traffic.ps1** | Deterministic traffic for challenges | [:octicons-download-24: Download](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/challenge-traffic.ps1) |

### Quick start with your own WAF

```powershell
# 1. Generate traffic against YOUR WAF endpoint
.\simulate-waf-traffic.ps1 -TargetUrl "http://<your-waf-endpoint>" -DurationMinutes 15

# 2. Wait 10 minutes for logs, then do any lab (e.g., Lab 03 - KQL Analysis)
#    Just replace the endpoint URLs in the lab instructions with yours

# 3. Or go straight to Challenges
.\challenge-traffic.ps1 -TargetUrl "http://<your-waf-endpoint>" -Challenge All
```

!!! tip "Which labs work with your own WAF?"
    | Works directly | Needs adaptation | Needs workshop infra |
    |:-:|:-:|:-:|
    | Lab 02, 03, 03B, 04, 05 | Lab 06, 07, 08 (adjust for your FD/AppGW) | Lab 01, 09, 10, 11 |
    | All 6 Challenges | — | — |

---

## :rocket: Quick Start (New Infrastructure)

```powershell
# 1. Clone the repository
git clone https://github.com/lcarli/AzureWAF-Learning.git
cd AzureWAF-Learning

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
