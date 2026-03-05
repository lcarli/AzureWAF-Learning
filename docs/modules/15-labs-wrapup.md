# :test_tube: Module 15 — Hands-on Labs &Wrap-up

!!! abstract "Hands-on labs overview and key takeaways"

*This module covers 5 topics.*

---

### Lab Exercises

Lab 1: Deploy Application Gateway WAF v2 with DRS 2.1 managed rules

Lab 2: Configure WAF in Detection mode and generate test traffic

Lab 3: Analyze WAF logs with KQL and identify false positives

Lab 3B: WAF Fine Tuning with Triage Workbooks (AppGW + Front Door)  🆕 NEW

Lab 4: Create exclusions and custom rules for tuning

Lab 5: Switch to Prevention mode and validate protection

Lab 6: Deploy Front Door Premium with WAF and origin lockdown

Lab 7: Configure bot protection and JavaScript Challenge

Lab 8: Set up rate limiting with XFF grouping

Lab 9: Application Gateway for Containers (AGC) with WAF

Lab 10: Configure Microsoft Sentinel with WAF data connector  ⚠️ OPTIONAL

Lab 11: Use Copilot for Security to investigate WAF events  ⚠️ OPTIONAL

⚠️ Labs 10-11 require additional licensing (Microsoft Sentinel / Copilot for Security)

💡 Run simulate-waf-traffic.ps1 before Lab 3 to pre-populate WAF logs!


---

### Testing WAF Rules - PowerShell Examples

# Test SQL Injection detection

Invoke-WebRequest -Uri 'https://app.com/?id=1 OR 1=1' -Method GET

# Test XSS detection

Invoke-WebRequest -Uri 'https://app.com/?q=<script>alert(1)</script>' -Method GET

# Test command injection

Invoke-WebRequest -Uri 'https://app.com/?cmd=; cat /etc/passwd' -Method GET

# Test path traversal

Invoke-WebRequest -Uri 'https://app.com/?file=../../etc/passwd' -Method GET


---

### Key Takeaways

Azure WAF is the essential Layer 7 protection for web apps in Azure

Next-Gen Engine delivers dramatically better performance and new capabilities

WAF Policy is the only supported model - migrate from legacy configurations

DRS 2.1 with anomaly scoring provides the best protection with fewer false positives

Bot protection + JavaScript Challenge addresses the growing bot threat

Application Gateway for Containers brings WAF to Kubernetes workloads

Copilot for Security transforms WAF operations with AI-powered analysis

Defense in depth: WAF + DDoS + Azure Firewall + NSG + Private Link

Continuous tuning and monitoring are essential for optimal WAF effectiveness


---

### Questions & Answers

Thank you for attending!


---

### Thank You

WorkshopPLUS: Azure Web Application Firewall (WAF) - 2026 Edition

https://learn.microsoft.com/azure/web-application-firewall/


---

---

<div style="display: flex; justify-content: space-between;">
<div>[:octicons-arrow-left-24: Module 14](14-best-practices.md)</div>
<div></div>
</div>
