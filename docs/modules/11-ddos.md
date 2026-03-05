# :no_entry_sign: Module 11 — DDoS Protection &Layered Defense

!!! abstract "Azure DDoS Protection and layered defense strategy"

*This module covers 3 topics.*

---

### Azure DDoS Protection - Overview

DDoS attacks target availability: volumetric, protocol, and application-layer

Azure DDoS Protection is built into the Azure global network

Global distribution absorbs attack traffic during large-scale attacks

Protection policies auto-tuned to your application traffic profile

Continuously profiles normal Public IP traffic to detect anomalies

Near real-time attack metrics and flow logs

DDoS Rapid Response (DRR) team for active attack support

99.99% SLA guarantee during attacks


---

### DDoS Protection Tiers

DDoS Network Protection

Protects all public IPs in a VNet

Auto-tuned mitigation policies

Near real-time attack metrics and logs

DDoS Rapid Response (DRR) team access

99.99% SLA during attacks

Cost protection: credits for scale-out

WAF integration for L7 protection

DDoS IP Protection

Per-IP protection (smaller deployments)

Same mitigation engine as Network Protection

Telemetry through Azure Monitor

No DDoS Rapid Response access

No cost protection credits

Ideal for: individual IPs, dev/test

Lower cost than Network Protection


---

### Layered Defense Strategy: DDoS + WAF

Layer 3/4: Azure DDoS Protection handles volumetric and protocol attacks

Layer 7: Azure WAF handles application-layer attacks (SQLi, XSS, bots)

Front Door: Built-in DDoS + WAF at the edge for global apps

Application Gateway + DDoS: Regional protection for private/public apps

Azure Firewall: Network-level filtering for east-west traffic

NSG: Micro-segmentation at the subnet/NIC level

Private Link: Eliminate public exposure for backend services

Together: Comprehensive defense-in-depth architecture


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB05](../labs/lab05.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 10](10-agc.md)</div>
<div>[Module 12 :octicons-arrow-right-24:](12-monitoring.md)</div>
</div>
