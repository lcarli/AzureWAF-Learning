# :earth_americas: Module 09 — Azure WAF onFront Door Premium

!!! abstract "Global edge WAF protection with Azure Front Door Premium"

*This module covers 4 topics.*

---

### Azure Front Door Premium - Overview

Global, cloud-native CDN with intelligent threat protection

Combines app acceleration, caching, and WAF protection at the edge

Anycast-based routing for lowest latency to users worldwide

Dynamic site acceleration for non-cacheable content

Built-in DDoS protection at the edge

Origin protection: Private Link to backend services

Managed certificates and custom domain support

Standard tier (CDN only) and Premium tier (CDN + WAF)

Migration from classic Front Door to Standard/Premium is GA

Upgrade from Standard to Premium is supported (GA)

Azure Portal: Create Front Door WAF Policy


---

### Azure WAF with Front Door - Key Capabilities

WAF at the edge: requests inspected at Microsoft POP closest to the user

Protects against attacks before they reach your origin servers

DRS 2.1 managed rules with anomaly scoring

Bot protection with managed rule set

JavaScript Challenge support for advanced bot mitigation

Custom rules with geo-filtering, IP restriction, rate limiting

Rule Engine for advanced routing decisions based on WAF results

Origin protection via Private Link (traffic cannot bypass WAF)

Azure Portal: Frontend Configuration


---

### Front Door WAF - Advantages

Global Protection

WAF evaluation at 180+ edge locations worldwide

Attacks blocked closest to the attacker

Built-in DDoS protection at edge

Origin lockdown via Private Link or IP filtering

No additional network hops for cached content

Scales automatically to absorb volumetric attacks

Advanced Features

Rule Engine: modify requests/responses

AFD Rings Setup for gradual policy rollout

Managed identity integration for cert mgmt

Domain fronting protection (GA)

Dynamic app acceleration for API traffic

Bring your own certificate with domain validation


---

### WAF Protecting Public Web Sites on App Service

Architecture: Users -> Front Door Premium (WAF) -> App Service

Configure origin access restrictions to accept traffic ONLY from Front Door

Use Service Tag "AzureFrontDoor.Backend" in App Service access restrictions

Validate X-Azure-FDID header to prevent traffic from other Front Door instances

Enable Private Link between Front Door and App Service for max security

This ensures ALL traffic passes through WAF - no bypass possible

Works with: App Service, Functions, Container Apps, AKS, VMs


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB06](../labs/lab06.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 08](08-application-gateway.md)</div>
<div>[Module 10 :octicons-arrow-right-24:](10-agc.md)</div>
</div>
