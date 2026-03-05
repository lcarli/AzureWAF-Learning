# :pencil2: Module 06 — Custom Rules, Rate Limiting& Geo-Filtering

!!! abstract "Custom rules for geo-filtering, rate limiting, and advanced scenarios"

*This module covers 5 topics.*

---

### When Managed Rules Are Not Enough

Managed rules cover general web attacks - your app may have unique needs

Custom rules allow you to create application-specific protection logic

Custom rules are processed BEFORE managed rules (higher priority)

Maximum 100 custom rules per WAF policy

Each rule has a unique priority (1-100, lower = evaluated first)

Redirect rules at the Application Gateway level bypass WAF custom rules

Good documentation of your application helps create effective custom rules

Azure Portal: Custom Rules


---

### Custom Rule Types

Match Rules

Control access based on matching conditions

Variables: RemoteAddr, RequestMethod, QueryString,

PostArgs, RequestUri, RequestHeaders, RequestBody,

RequestCookies

Operators: IPMatch, GeoMatch, Equal, Contains,

Regex, BeginsWith, EndsWith, LessThan, GreaterThan

Transforms: Lowercase, Uppercase, Trim, UrlDecode,

UrlEncode, HtmlEntityDecode, RemoveNulls

Actions: Allow, Block, Log, Redirect, JSChallenge (NEW)

Rate Limit Rules

Control access based on rate + matching conditions

Duration: 1 to 5 minutes counting window

Threshold: Max requests in the duration

Group By: Client IP, Socket IP, XFF (NEW)

XFF grouping: rate limit behind proxies/NATs

Actions: Block, Log, Redirect when exceeded

Use for: API abuse, brute force, credential stuffing

Combine with match conditions for targeted limiting


---

### Custom Rules - Match Conditions

Multiple conditions within a rule use AND logic (all must match)

Use multiple rules with different priorities for OR logic

Negation: Match if condition does NOT match (invert the logic)

Match variables can reference specific keys (e.g., RequestHeaders[User-Agent])

Transforms applied before comparison (e.g., Lowercase before Equals)

GeoMatch: Match by ISO 3166-1 country codes (e.g., BR, US, CN)

IPMatch: Supports CIDR notation (e.g., 10.0.0.0/8, 192.168.1.0/24)

Regex: Use regular expressions for complex pattern matching

Azure Portal: Custom Rule Configuration


---

### Geo-Filtering with Custom Rules

Use GeoMatch operator to allow/block traffic from specific countries

Example: Block all traffic from specific countries

Variable: RemoteAddr | Operator: GeoMatch | Values: CN, RU | Action: Block

Example: Allow traffic only from specific countries

Variable: RemoteAddr | Operator: GeoMatch | Values: BR, US | Negate | Action: Block

Combine with other conditions for granular control

Consider compliance requirements (LGPD, GDPR) when implementing geo-filtering


---

### Advanced Rate Limiting (Updated 2026)

Rate limiting protects against volumetric Layer 7 attacks and API abuse

Group By options:

Client IP: Rate limit by source IP address (direct connections)

Client Socket IP: Rate limit by socket address

X-Forwarded-For (NEW): Rate limit by original client IP behind proxies

XFF grouping is critical for apps behind CDNs, load balancers, or proxies

Without XFF grouping, all traffic from a shared proxy appears as one client

Duration: 1-5 minute windows for rate counting

Example: Limit login endpoint to 10 requests/minute per XFF IP

Example: Limit API calls to 100 requests/minute per client IP


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB04](../labs/lab04.md)
- [:octicons-beaker-24: LAB08](../labs/lab08.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 05](05-exclusions.md)</div>
<div>[Module 07 :octicons-arrow-right-24:](07-bot-protection.md)</div>
</div>
