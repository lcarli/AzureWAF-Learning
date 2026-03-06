# :trophy: WAF Challenges

Test your Azure WAF investigation skills! Run the challenge traffic generator, analyze the WAF logs, and answer the questions below.

---

## :rocket: Getting Started

### Step 1: Generate Challenge Traffic

Run the challenge traffic script against your WAF endpoint:

```powershell
cd scripts/
.\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge All
```

!!! warning "Wait for Logs"
    After running the script, wait **10-15 minutes** for WAF logs to appear in Log Analytics before attempting the challenges.

### Step 2: Investigate Using WAF Tools

Use any of these tools to find the answers:

- **WAF Insights** — WAF Policy → Insights blade in Azure Portal
- **Log Analytics** — Run KQL queries against `ApplicationGatewayFirewallLog`
- **WAF Triage Workbook** — If deployed (see Lab 03B)

### Step 3: Submit Your Answers

Type your answer in each challenge box below and click **Check**. Answers are validated locally in your browser.

!!! tip "Hints"
    - All answers are case-insensitive
    - Trim any leading/trailing spaces
    - For IPs, use dotted notation (e.g., `10.0.0.1`)
    - For Rule IDs, use just the number (e.g., `942100`)

---

## :one: Challenge 1 — Identify the Attacker

A single IP address has been sending **50 SQL injection attacks** against your application. All the attacks came from the same source.

**Your mission**: Find the attacker's IP address.

??? example "Hint"
    Try this KQL query:
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where ruleSetType_s == "Microsoft_DefaultRuleSet"
    | where ruleGroup_s == "SQLI"
    | summarize AttackCount = count() by clientIp_s
    | order by AttackCount desc
    | take 5
    ```

<div class="challenge-box" id="challenge-1">
  <input type="text" id="answer-1" placeholder="Enter the attacker IP address..." class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer(1)">
  <button onclick="checkAnswer(1)" class="challenge-btn">Check Answer</button>
  <div id="result-1" class="challenge-result"></div>
</div>

---

## :two: Challenge 2 — Name the Rule

Multiple XSS attacks were sent containing the payload `WAF-CHALLENGE-2026`. A specific WAF rule detected and flagged all of them.

**Your mission**: Find the Rule ID that detected these XSS attacks.

??? example "Hint"
    Try this KQL query:
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where details_data_s contains "WAF-CHALLENGE-2026"
       or requestUri_s contains "WAF-CHALLENGE-2026"
    | summarize Count = count() by ruleId_s, message_s
    | order by Count desc
    ```

<div class="challenge-box" id="challenge-2">
  <input type="text" id="answer-2" placeholder="Enter the Rule ID..." class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer(2)">
  <button onclick="checkAnswer(2)" class="challenge-btn">Check Answer</button>
  <div id="result-2" class="challenge-result"></div>
</div>

---

## :three: Challenge 3 — The Secret Path

An attacker is probing a specific API endpoint with multiple attack types (SQLi, XSS, command injection, path traversal, RFI). All attacks target the same URI path.

**Your mission**: What URI path is the attacker targeting?

??? example "Hint"
    Try this KQL query:
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where clientIp_s == "203.0.113.77"
    | extend Path = tostring(split(requestUri_s, "?")[0])
    | summarize AttackTypes = dcount(ruleGroup_s), Count = count() by Path
    | order by Count desc
    ```

<div class="challenge-box" id="challenge-3">
  <input type="text" id="answer-3" placeholder="Enter the URI path..." class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer(3)">
  <button onclick="checkAnswer(3)" class="challenge-btn">Check Answer</button>
  <div id="result-3" class="challenge-result"></div>
</div>

---

## :four: Challenge 4 — Bot Detective

A malicious bot has been crawling your entire site — scanning admin pages, config files, and sensitive endpoints. It uses a **custom User-Agent string** that doesn't match any known browser.

**Your mission**: What is the bot's User-Agent string?

??? example "Hint"
    Try this KQL query:
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where ruleSetType_s == "Microsoft_BotManagerRuleSet"
    | extend UA = column_ifexists("userAgent_s", "")
    | summarize Count = count() by UA
    | where UA !contains "Mozilla" and UA != ""
    | order by Count desc
    ```
    Or check the Access Log for unusual User-Agents.

<div class="challenge-box" id="challenge-4">
  <input type="text" id="answer-4" placeholder="Enter the User-Agent string..." class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer(4)">
  <button onclick="checkAnswer(4)" class="challenge-btn">Check Answer</button>
  <div id="result-4" class="challenge-result"></div>
</div>

---

## :five: Challenge 5 — The Poisoned Parameter

An attacker is injecting XSS payloads through a specific **query parameter**. All XSS attacks from IP `172.16.99.5` use the same parameter name to deliver their payloads.

**Your mission**: What is the name of the query parameter being used for XSS injection?

??? example "Hint"
    Try this KQL query:
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where clientIp_s == "172.16.99.5"
    | where ruleGroup_s contains "XSS"
    | project requestUri_s
    | extend QueryString = tostring(split(requestUri_s, "?")[1])
    | extend ParamName = tostring(split(QueryString, "=")[0])
    | summarize Count = count() by ParamName
    ```

<div class="challenge-box" id="challenge-5">
  <input type="text" id="answer-5" placeholder="Enter the parameter name..." class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer(5)">
  <button onclick="checkAnswer(5)" class="challenge-btn">Check Answer</button>
  <div id="result-5" class="challenge-result"></div>
</div>

---

## :six: Challenge 6 — Count the Scanners

Multiple automated vulnerability scanners were detected probing your application. Each scanner uses a different User-Agent string.

**Your mission**: How many **distinct** scanner tools were detected?

??? example "Hint"
    Try this KQL query:
    ```kql
    AzureDiagnostics
    | where Category == "ApplicationGatewayFirewallLog"
    | where clientIp_s startswith "10.99.1."
    | extend UA = column_ifexists("userAgent_s", "")
    | summarize Count = count() by UA
    | where UA != ""
    | count
    ```

<div class="challenge-box" id="challenge-6">
  <input type="text" id="answer-6" placeholder="Enter the number..." class="challenge-input" onkeydown="if(event.key==='Enter')checkAnswer(6)">
  <button onclick="checkAnswer(6)" class="challenge-btn">Check Answer</button>
  <div id="result-6" class="challenge-result"></div>
</div>

---

## :bar_chart: Your Score

<div id="scoreboard" class="scoreboard">
  <div class="score-text">Completed: <span id="score-count">0</span> / 6</div>
  <div class="score-bar-bg"><div id="score-bar" class="score-bar" style="width: 0%"></div></div>
</div>

---

## :bulb: After the Challenges

Once you've completed all challenges, you should feel comfortable:

- Navigating WAF logs in Log Analytics
- Writing KQL queries to investigate security events
- Identifying attack patterns, sources, and targets
- Using WAF Insights for visual analysis
- Determining which rules are triggered by specific attacks

These are the core skills for WAF operations and tuning in production!

<script>
// SHA-256 hashes of correct answers (lowercase, trimmed)
const ANSWERS = {
  1: 'dc6693d50f7d237af8a04dd3b9a42e37c4978979aedc7dc60723b3df22a880af',
  2: 'b28161474e6d3bb6240da827a2dd52450cb7cfaacd38ef41988f060611e1c3c1',
  3: '7c08f0b9b38ec31c605bbb3acaac74b8c820513967e7d8760b9bc4aef8df52f3',
  4: '26e83c1300782d73ed80324165739c40102a0713b64790e643b64855f009454f',
  5: 'f2579d976934c7888785842d8e5a48a140453222e5dbca50d5a1226cd63a8dc7',
  6: '4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a'
};

const solved = new Set();

async function sha256(message) {
  const msgBuffer = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

async function checkAnswer(n) {
  const input = document.getElementById('answer-' + n);
  const result = document.getElementById('result-' + n);
  const answer = input.value.trim().toLowerCase();

  if (!answer) {
    result.innerHTML = '⚠️ Please enter an answer';
    result.className = 'challenge-result challenge-warn';
    return;
  }

  const hash = await sha256(answer);

  if (hash === ANSWERS[n]) {
    result.innerHTML = '✅ Correct! Great investigation work!';
    result.className = 'challenge-result challenge-correct';
    input.disabled = true;
    input.style.borderColor = '#107C10';
    solved.add(n);
    updateScore();
  } else {
    result.innerHTML = '❌ Incorrect. Check the WAF logs and try again.';
    result.className = 'challenge-result challenge-wrong';
    input.style.borderColor = '#D13438';
    setTimeout(() => { input.style.borderColor = ''; }, 2000);
  }
}

function updateScore() {
  const count = solved.size;
  document.getElementById('score-count').textContent = count;
  document.getElementById('score-bar').style.width = (count / 6 * 100) + '%';

  if (count === 6) {
    document.getElementById('scoreboard').innerHTML += '<div class="score-complete">🏆 Congratulations! You completed all challenges!</div>';
  }
}
</script>

<style>
.challenge-box {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
  margin: 1rem 0;
}
.challenge-input {
  flex: 1;
  min-width: 250px;
  padding: 10px 14px;
  border: 2px solid var(--md-default-fg-color--lightest);
  border-radius: 6px;
  background: var(--md-code-bg-color);
  color: var(--md-default-fg-color);
  font-size: 0.95rem;
  font-family: 'Cascadia Code', monospace;
  outline: none;
  transition: border-color 0.3s;
}
.challenge-input:focus {
  border-color: #0078D4;
}
.challenge-input:disabled {
  opacity: 0.7;
}
.challenge-btn {
  padding: 10px 20px;
  background: linear-gradient(135deg, #0078D4, #106EBE);
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.9rem;
  transition: all 0.2s;
}
.challenge-btn:hover {
  background: linear-gradient(135deg, #106EBE, #005A9E);
  transform: translateY(-1px);
}
.challenge-result {
  width: 100%;
  padding: 8px 12px;
  border-radius: 4px;
  font-size: 0.9rem;
  min-height: 20px;
}
.challenge-correct {
  background: rgba(16, 124, 16, 0.15);
  color: #107C10;
  border-left: 3px solid #107C10;
}
.challenge-wrong {
  background: rgba(209, 52, 56, 0.15);
  color: #D13438;
  border-left: 3px solid #D13438;
}
.challenge-warn {
  background: rgba(255, 185, 0, 0.15);
  color: #FFB900;
  border-left: 3px solid #FFB900;
}
.scoreboard {
  background: var(--md-code-bg-color);
  border-radius: 8px;
  padding: 1.5rem;
  text-align: center;
}
.score-text {
  font-size: 1.3rem;
  font-weight: 700;
  margin-bottom: 1rem;
}
.score-bar-bg {
  width: 100%;
  height: 12px;
  background: var(--md-default-fg-color--lightest);
  border-radius: 6px;
  overflow: hidden;
}
.score-bar {
  height: 100%;
  background: linear-gradient(90deg, #107C10, #00BCF2);
  border-radius: 6px;
  transition: width 0.5s ease;
}
.score-complete {
  margin-top: 1rem;
  font-size: 1.2rem;
  color: #FFB900;
}
</style>
