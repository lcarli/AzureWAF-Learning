# :shield: Module 02 — Introduction to Azure WAF

!!! abstract "Azure WAF features, benefits, and the application delivery product suite"

*This module covers 6 topics.*

---

### Azure Web Application Firewall (WAF) - Overview

Centralized protection for web apps against common exploits and vulnerabilities

Protects public AND private web applications in Azure, on-prem, and multi-cloud

Zero Trust network security architecture with Azure DDoS and Firewall integration

Quick response to new attacks via Microsoft Threat Intelligence

Enterprise compliance standards support (PCI-DSS, SOC, ISO)

Platform-managed, easy to use - no WAF expertise required to start

Highly available, scalable, and performant

Source: Microsoft Learn - Azure WAF Overview


---

### Azure WAF - Key Features (2026)

Preconfigured OWASP Top 10 protection with DRS 2.1+ managed rulesets

Zero-day vulnerability protection with Microsoft Threat Intelligence (MSTIC) rules

Bot protection with Microsoft Threat Intelligence feed

NEW: JavaScript Challenge for advanced bot mitigation

Conditional rate limiting with X-Forwarded-For (XFF) grouping

Powerful custom rules engine with regex support

Geo-filtering and IP restriction

NEW: Next-Gen WAF Engine - up to 8x faster, 2MB body, 4GB uploads

NEW: WAF Insights - interactive visual metrics and analytics

NEW: Copilot for Security integration for AI-driven analysis

Integration with Microsoft Sentinel (SOAR) for automated response


---

### Azure WAF Benefits

Protection

OWASP Top 10 coverage out of the box

Zero-day protection via MSTIC rules

Bot management with ML-based detection

Custom rules for application-specific needs

Rate limiting against volumetric attacks

Geo-filtering for regional compliance

JavaScript Challenge for advanced bots

DDoS protection integration

Monitoring & Response

Real-time metrics and alerts via Azure Monitor

WAF Insights for visual security analytics

Diagnostic logging with KQL queries

Microsoft Sentinel SOAR integration

Copilot for Security AI analysis

Azure Policy for governance at scale

Workbooks for custom dashboards

Integration with SIEM/SOAR tools


---

### Application Delivery Product Suite

Azure Front Door Premium: Global CDN + WAF for public-facing apps

Application Gateway v2: Regional ADC + WAF for private/public workloads

Application Gateway for Containers: Kubernetes-native L7 LB + WAF

Azure Firewall: Network-level (L3/L4) security for east-west traffic

DDoS Network Protection: Volumetric attack mitigation at network edge

DDoS IP Protection: Per-IP protection for smaller deployments

Together these form a comprehensive multi-layer security stack

Source: Microsoft Learn - WAF on Application Gateway


---

### What is ModSecurity?

ModSecurity is the open-source WAF engine that powers Azure WAF

Originally created for Apache HTTP Server, now cross-platform

Core Rule Set (CRS) provides the baseline rule definitions

Azure WAF extends ModSecurity with Microsoft-managed rules and threat intelligence

Azure WAF supports CRS 3.2 and the newer Default Rule Set (DRS) 2.1

DRS 2.1 adds Microsoft-specific rules and threat intelligence integration

IMPORTANT: Azure is migrating to a Next-Gen WAF Engine for improved performance


---

### Azure WAF vs. Other Security Services

Azure WAF

Layer 7 (HTTP/HTTPS) protection

OWASP Top 10 rule enforcement

Bot protection and rate limiting

Custom rules for app-specific logic

Integrated with App GW / Front Door / AGC

Inspects request headers, body, cookies, URI

Azure Firewall

Layer 3/4 (Network) protection

FQDN filtering and threat intelligence

Network traffic filtering (IP, port, protocol)

TLS inspection for outbound traffic

East-west and north-south traffic control

Complementary to WAF - not a replacement


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB01](../labs/lab01.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 01](01-security-fundamentals.md)</div>
<div>[Module 03 :octicons-arrow-right-24:](03-waf-policies.md)</div>
</div>
