# :lock: Module 01 — Web Application SecurityFundamentals & Zero Trust

!!! abstract "Zero Trust, cloud security, and the modern threat landscape"

*This module covers 6 topics.*

---

### Network Security in the Cloud

Cloud-native security requires a fundamentally different approach than on-premises

Multi-level segmentation: network, identity, application, and data layers

The perimeter is no longer a single firewall - it is distributed across the stack

Protection services must enable Zero Trust across all layers

Azure integrated security: Azure Firewall, WAF, DDoS Protection, NSG, Private Link

Defense in depth: multiple layers of security controls work together


---

### Shared Responsibility Model

Cloud security is a shared responsibility between Microsoft and the customer

Microsoft responsible for: Physical infrastructure, network, hypervisor, host OS

Customer responsible for: Data, endpoints, account management, access control

Shared responsibilities vary by service model (IaaS, PaaS, SaaS)

WAF is a customer-managed control that protects the application layer (Layer 7)

Understanding this model is critical for proper security posture

COMPLIANT does NOT equal SECURE - compliance is the minimum, not the goal


---

### Introduction to Zero Trust

Traditional perimeter-based security is no longer sufficient

Attackers are like water - they find any gap in your defenses

Attack surfaces are increasing: APIs, microservices, containers, multi-cloud

Security goal: Disrupt attackers by increasing cost and complexity of attacks


---

### Zero Trust Principles

VERIFY EXPLICITLY: Always authenticate and authorize based on all available data

Identity, location, device health, service/workload, data classification, anomalies

USE LEAST PRIVILEGE ACCESS: Limit user access with JIT and JEA policies

Risk-based adaptive policies, data protection

ASSUME BREACH: Minimize blast radius and segment access

Verify end-to-end encryption, use analytics for visibility and threat detection

Azure WAF plays a critical role in the Zero Trust network security architecture


---

### Modern Web Application Attack Landscape

OWASP Top 10 (2021): Injection, Broken Access Control, Cryptographic Failures, XSS...

API-specific threats: OWASP API Top 10 - BOLA, Broken Authentication, Mass Assignment

Bot attacks: credential stuffing, web scraping, inventory hoarding, DDoS

Supply chain attacks: compromised dependencies, malicious packages

AI-powered attacks: GenAI-driven vulnerability discovery and exploitation

Zero-day exploits: Log4Shell, Spring4Shell, MOVEit - rapid weaponization

Azure WAF protects against all of the above with managed + custom rules


---

### Input Sanitization - The First Line of Defense

All user input must be treated as untrusted - validation is mandatory

Common injection vectors: SQL Injection, XSS, Command Injection, LDAP Injection

Server-side validation is essential - client-side validation can be bypassed

Use parameterized queries and prepared statements

Encode output appropriately (HTML, URL, JavaScript encoding)

Content Security Policy (CSP) headers prevent XSS execution

WAF provides defense BEFORE requests reach your application

However, WAF does NOT replace secure coding practices - defense in depth!


---

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 00](00-introduction.md)</div>
<div>[Module 02 :octicons-arrow-right-24:](02-waf-overview.md)</div>
</div>
