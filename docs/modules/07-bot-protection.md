# :robot: Module 07 — Bot Protection &JavaScript Challenge

!!! abstract "Bot Manager ruleset and the new JavaScript Challenge action"

*This module covers 3 topics.*

---

### Bot Protection Overview

Roughly 20-30% of all internet traffic comes from bad bots

Bad bots: scanning, scraping, credential stuffing, inventory hoarding, DDoS

Azure WAF Bot Protection uses Microsoft Threat Intelligence to identify malicious IPs

Bot categories: Good Bots (search engines), Bad Bots (known malicious), Unknown Bots

Managed bot protection rule set blocks/logs requests from known malicious IPs

IP addresses sourced from Microsoft Threat Intelligence Feed

Enable bot protection as a baseline for all WAF deployments

Azure Portal: Bot Manager Ruleset


---

### JavaScript Challenge (NEW - 2025/2026)

New action type available in custom rules and bot protection

Issues a lightweight JavaScript computation to suspicious clients

Legitimate browsers execute the JS challenge transparently (no user impact)

Bots and automated tools that lack JavaScript support are blocked

More user-friendly than CAPTCHA - no visual puzzle to solve

Effective against: volumetric L7 attacks, high-rate bots, scraping tools

Available on both Application Gateway and Front Door WAF

Use as a "soft" challenge before blocking - reduces false positive impact

Combine with rate limiting for layered bot defense

Azure Portal: Bot Protection Rule Set


---

### Bot Protection Zero Trust Approach

Step 1: Enable managed bot protection ruleset

Step 2: Set bot protection to Detection mode initially

Step 3: Analyze logs to identify bot traffic patterns

Step 4: Create custom rules to handle specific bot scenarios

Step 5: Enable JavaScript Challenge for suspicious traffic

Step 6: Implement rate limiting for API endpoints

Step 7: Switch to Prevention mode

Step 8: Continuously monitor and adjust

Combine with: IP reputation, geo-filtering, user-agent analysis


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB07](../labs/lab07.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 06](06-custom-rules.md)</div>
<div>[Module 08 :octicons-arrow-right-24:](08-application-gateway.md)</div>
</div>
