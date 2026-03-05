# :globe_with_meridians: Module 08 — Azure WAF onApplication Gateway

!!! abstract "Regional WAF protection with Application Gateway v2"

*This module covers 4 topics.*

---

### Azure Application Gateway - Overview

Regional Layer 7 load balancer and application delivery controller (ADC)

WAF v2 SKU includes Web Application Firewall capability

SSL/TLS termination, URL-based routing, multi-site hosting, session affinity

Supports both public and private web applications

Auto-scaling and zone redundancy for high availability

Private Link support for secure backend connectivity (GA)

Private-only deployments supported (no public IP required)

Common port for public and private listeners

Architecture: Application Gateway with WAF


---

### Application Gateway WAF Features (2026)

DRS 2.1 managed ruleset with anomaly scoring (RECOMMENDED)

Bot Manager integration with Microsoft Threat Intelligence

Rate limiting with client IP, socket IP, and XFF grouping

Custom error pages for WAF-blocked requests

Next-Gen WAF Engine support (opt-in)

Per-site and per-URI WAF policy association

Header rewrite for security headers (X-Frame-Options, CSP, HSTS, etc.)

Integration with Azure Monitor, Log Analytics, and Sentinel

Private Link support for secure origin access

TLS 1.3 support and mutual TLS (mTLS) authentication

Azure Portal: Create Application Gateway with WAF


---

### Security Headers via Header Rewrite

Application Gateway can inject security HTTP headers to prevent vulnerabilities

X-Frame-Options: DENY or SAMEORIGIN (prevent clickjacking)

Content-Security-Policy: Restrict sources for scripts, styles, images

X-Content-Type-Options: nosniff (prevent MIME-type sniffing)

Strict-Transport-Security: max-age=31536000 (enforce HTTPS)

X-XSS-Protection: 1; mode=block (legacy XSS filter)

Remove server version headers to prevent information disclosure

Remove port information from X-Forwarded-For header

These are complementary to WAF rules - defense in depth


---

### WAF on Application Gateway - Advantages

Protects both public AND private web applications (unique to App GW)

Per-site and per-URI policies for multi-tenant scenarios

Backend: VMs, VMSS, App Service, AKS, on-prem (hybrid)

SSL offloading reduces compute load on backend servers

Health probes ensure traffic goes only to healthy backends

Auto-scaling adapts to traffic patterns automatically

Zone redundancy for regional high availability

Can be combined with Front Door for global + regional protection


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB01](../labs/lab01.md)
- [:octicons-beaker-24: LAB02](../labs/lab02.md)
- [:octicons-beaker-24: LAB05](../labs/lab05.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 07](07-bot-protection.md)</div>
<div>[Module 09 :octicons-arrow-right-24:](09-front-door.md)</div>
</div>
