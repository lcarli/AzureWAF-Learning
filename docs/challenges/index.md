# :trophy: WAF Challenges

Test your Azure WAF investigation skills! Each challenge requires you to generate specific attack traffic, analyze WAF logs, and find the answer.

---

## :rocket: Before You Begin

### Prerequisites

- [x] Lab infrastructure deployed ([Setup Guide](../labs/setup.md))
- [x] WAF in **Detection** or **Prevention** mode
- [x] Log Analytics workspace receiving WAF logs

### Tools You'll Use

| Tool | Purpose |
|---|---|
| **WAF Insights** | Visual dashboard in Azure Portal |
| **Log Analytics** | KQL queries against WAF logs |
| **WAF Triage Workbook** | Visual triage (if deployed in Lab 03B) |

---

## :dart: Challenges

| # | Challenge | Difficulty | Skills |
|:--:|-----------|:----------:|--------|
| 1 | [Identify the Attacker](challenge-01.md) | :green_circle: Easy | KQL, IP analysis |
| 2 | [Name the Rule](challenge-02.md) | :green_circle: Easy | Rule ID lookup |
| 3 | [The Secret Path](challenge-03.md) | :yellow_circle: Medium | URI analysis |
| 4 | [Bot Detective](challenge-04.md) | :yellow_circle: Medium | User-Agent analysis |
| 5 | [The Poisoned Parameter](challenge-05.md) | :orange_circle: Hard | Parameter extraction |
| 6 | [Count the Scanners](challenge-06.md) | :orange_circle: Hard | Aggregation, dedup |

---

## :bulb: Tips

!!! tip "General Approach"
    1. Run the challenge traffic script for the specific challenge
    2. Wait **10-15 minutes** for logs to appear
    3. Use KQL queries in Log Analytics to investigate
    4. Submit your answer on the challenge page

!!! info "Running Individual Challenges"
    :octicons-download-24: **Script**: [challenge-traffic.ps1](https://github.com/lcarli/AzureWAF-Learning/blob/main/scripts/challenge-traffic.ps1)

    ```powershell
    # Run a specific challenge
    .\scripts\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge 1

    # Or run all challenges at once
    .\scripts\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge All
    ```
