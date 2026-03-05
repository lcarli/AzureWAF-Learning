# :trophy: Module 14 — Reference Architectures &Landing Zone Integration

!!! abstract "Architecture decisions, landing zone integration, and WAF limits"

*This module covers 5 topics.*

---

### WAF Architecture Decision Tree

Public web app, global audience -> Front Door Premium + WAF

Public web app, single region -> Application Gateway WAF v2

Private web app in VNet -> Application Gateway WAF v2 (private-only)

Kubernetes workloads on AKS -> Application Gateway for Containers + WAF

API behind API Management -> Application Gateway + APIM + WAF

Hybrid (public + private) -> Front Door + Application Gateway combination

Multi-cloud or on-prem backends -> Front Door Premium for global entry

All scenarios: Add DDoS Protection + Azure Firewall for complete defense


---

### Securing Workloads in Azure Virtual Network

Architecture: Internet -> DDoS -> Front Door (WAF) -> App GW (WAF) -> Backend

Or: Internet -> DDoS -> Application Gateway (WAF) -> Backend VMs/VMSS

NSGs on subnets: Control east-west traffic between tiers

UDRs: Force traffic through Azure Firewall for inspection

Private Link: Connect to PaaS services without public exposure

Service Endpoints: Restrict PaaS access to specific VNets

Azure Firewall: Filter outbound traffic and east-west between VNets

Key: WAF protects application layer, Firewall protects network layer


---

### Protecting APIs with Application Gateway and APIM

Architecture: Internet -> App GW (WAF) -> API Management -> Backend APIs

Application Gateway provides WAF protection for API traffic

APIM provides: rate limiting, authentication, throttling, transformation

WAF custom rules complement APIM policies for defense in depth

Design recommendations:

Place APIM in internal VNet mode behind Application Gateway

Use Application Gateway for SSL termination and WAF

Use APIM for API-specific security (OAuth, JWT validation, quotas)

Monitor both WAF logs and APIM analytics for comprehensive visibility


---

### WAF Best Practices - Summary

1. Deploy WAF in Detection mode first, tune, then switch to Prevention
2. Use DRS 2.1 managed ruleset with anomaly scoring
3. Enable bot protection on all deployments
4. Create specific exclusions rather than disabling rules
5. Use custom rules for application-specific logic
6. Enable JavaScript Challenge for bot-heavy endpoints
7. Implement rate limiting on auth and API endpoints
8. Use Azure Policy to enforce WAF across your organization
9. Integrate with Sentinel for automated incident response
10. Use Copilot for Security to reduce investigation time

11. Lock down origins to accept traffic only through WAF

12. Regularly review and update WAF rules as your app evolves


---

### WAF Limits & Quotas

Application Gateway WAF

Max 100 custom rules per policy

Max 5 exclusions per policy (global)

Max 40 custom rules per listener

Request body: up to 2 MB (Next-Gen)

File upload: up to 4 GB (Next-Gen)

Max 20 WAF policies per subscription

Max rule groups: depends on DRS version

Front Door Premium WAF

Max 100 custom rules per policy

Max 100 rate limit rules per policy

Max 60 geo-match custom rules

Max request size: 2 MB (Next-Gen)

Max 5000 managed rule exclusions

Max 100 WAF policies per subscription

Max 500 custom rules across all policies


---

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 13](13-copilot-sentinel.md)</div>
<div>[Module 15 :octicons-arrow-right-24:](15-labs-wrapup.md)</div>
</div>
