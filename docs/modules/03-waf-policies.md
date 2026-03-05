# :gear: Module 03 — WAF Policy Configuration& Next-Gen Engine

!!! abstract "WAF Policy configuration, Detection vs Prevention modes, and the Next-Gen Engine"

*This module covers 5 topics.*

---

### WAF Policy - Single Pane of Glass

WAF Policy is now the ONLY supported config model (legacy deprecated March 2025)

Full retirement of legacy configuration by March 2027

All WAF settings in a single resource: managed rules, custom rules, exclusions, bot protection

Can be associated with multiple Application Gateways, listeners, or URL paths

Front Door Premium uses WAF Policy natively

Application Gateway for Containers defines policies as Kubernetes CRDs

No additional cost to migrate from legacy config to WAF Policy

All new features are delivered ONLY through WAF Policy

Azure Portal: Create WAF Policy


---

### WAF Policy Scope & Association

Application Gateway

Global policy: applies to all listeners/paths

Per-site policy: applies to a specific listener

Per-URI policy: applies to a specific URL path

Child policy inherits parent settings

Supports WAF v2 SKU only

Can associate single policy with multiple gateways

Front Door Premium

Global policy for entire Front Door profile

Per-endpoint policy

Per-route policy

Supports DRS 2.1 with anomaly scoring

Managed and custom rules

Bot protection with JavaScript Challenge


---

### WAF Modes: Detection vs. Prevention

Detection Mode

Monitors and logs all rule matches

Does NOT block any traffic

Ideal for initial deployment and tuning

Use to identify false positives before enforcing

All triggered rules logged in diagnostics

RECOMMENDED: Start here for 2-4 weeks

Analyze logs before switching to Prevention

Prevention Mode

Actively blocks matching requests

Returns 403 Forbidden by default (customizable)

Logs all blocked and detected requests

Use after tuning is complete

Can configure custom error pages

Anomaly scoring: blocks based on threshold

Traditional mode: blocks on first match


---

### Next-Gen WAF Engine (NEW)

Completely redesigned engine for dramatically improved performance

Up to 8x faster for POST requests, 4x faster for GET requests

Up to 8x more requests per second with the same compute resources

Request body inspection up to 2 MB (vs. 128 KB in legacy engine)

File upload support up to 4 GB

Advanced regex processing - protection against ReDoS (Regex DoS) attacks

Improved custom rule logging: distinguishes Log, Detected, and Blocked actions

All new features built exclusively on the Next-Gen Engine

Recommended: Migrate existing deployments to Next-Gen Engine


---

### WAF Policy Settings - Key Configurations

Body Inspection: Enable/disable request body evaluation

Request Body Size Limit: Up to 2 MB on Next-Gen Engine

File Upload Limit: Up to 4 GB on Next-Gen Engine

Request Body Enforcement: Block requests exceeding size limits

Response Body Inspection: Inspect outbound responses for data leakage

Custom Error Pages: Return branded error pages instead of generic 403

Log Level: Control verbosity of WAF diagnostic logs

Enable/Disable individual rule groups or specific rules


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB01](../labs/lab01.md)
- [:octicons-beaker-24: LAB02](../labs/lab02.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 02](02-waf-overview.md)</div>
<div>[Module 04 :octicons-arrow-right-24:](04-managed-rules.md)</div>
</div>
