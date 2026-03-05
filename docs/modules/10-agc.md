# :whale: Module 10 — Azure WAF on ApplicationGateway for Containers

!!! abstract "Application Gateway for Containers — Kubernetes-native WAF"

*This module covers 3 topics.*

---

### Application Gateway for Containers (AGC) - Overview

NEW: First-party, Kubernetes-native Layer 7 load balancer for AKS

Replaces NGINX Ingress Controller (being retired March 2026)

Managed by Azure - no infrastructure to maintain

Supports both Ingress API and Gateway API for Kubernetes

Auto-scaling and high availability built-in

Native integration with AKS for seamless deployment

WAF integration via WAF policies as Kubernetes CRDs

Ideal for modern containerized and microservices architectures


---

### WAF Policies as Kubernetes CRDs (NEW)

Define WAF security policies directly as Kubernetes Custom Resource Definitions

GitOps-friendly: WAF configuration as code, versioned with your app

Flexible scope: Global (entire AGC), per-listener, or per-route

Example: Strict WAF rules on /login and /admin, relaxed on /api/public

Custom rules supported: IP blocking, geo-filtering, rate limiting

Bot protection with Microsoft Threat Intelligence

Real-time logging integrated with Kubernetes observability stack

Managed rules (DRS 2.1) with exclusions and tuning support


---

### AGC vs. Traditional Application Gateway

Application Gateway for Containers

Kubernetes-native (CRDs and Gateway API)

Auto-scaling and managed infrastructure

GitOps and DevOps friendly

Supports Gateway API specification

Ideal for AKS microservices

Newer - evolving feature set

Traditional Application Gateway

Infrastructure-managed via ARM/Portal/CLI

Manual or auto-scaling with VMSS

Broader feature set (mature product)

Supports more backend types

Per-site and per-URI policies

Mature - battle-tested in production


---

## :test_tube: Related Labs

- [:octicons-beaker-24: LAB09](../labs/lab09.md)

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 09](09-front-door.md)</div>
<div>[Module 11 :octicons-arrow-right-24:](11-ddos.md)</div>
</div>
