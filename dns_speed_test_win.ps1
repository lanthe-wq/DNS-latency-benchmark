<#
.SYNOPSIS
    dns_speed_test.ps1

    Benchmarks ~50 public DNS resolvers + your currently configured DNS
    servers, and ranks them by average query latency. Windows equivalent
    of dns_speed_test.sh.

.USAGE
    Right-click this file -> "Run with PowerShell"
    -- or, from a PowerShell prompt --
    powershell -ExecutionPolicy Bypass -File .\dns_speed_test.ps1

.NOTES
    Uses Resolve-DnsName, which ships built-in with Windows (no extra
    tools required). Requires PowerShell 5.1+ (included in Windows 10/11).
#>

# Domains to test against (mix of popular + varied TLDs for realistic results)
$Domains = @("google.com", "amazon.com", "apple.com", "wikipedia.org", "cloudflare.com")

# How many times to query each domain per server (averages out jitter)
$Rounds = 3

# DNS servers to test: Name = IP
$Servers = [ordered]@{
    # Cloudflare
    "Cloudflare"                          = "1.1.1.1"
    "Cloudflare-Secondary"                = "1.0.0.1"
    "Cloudflare-Malware-Block"            = "1.1.1.2"
    "Cloudflare-Malware-Block-Secondary"  = "1.0.0.2"
    "Cloudflare-Family"                   = "1.1.1.3"
    "Cloudflare-Family-Secondary"         = "1.0.0.3"
    # Google
    "Google"                              = "8.8.8.8"
    "Google-Secondary"                    = "8.8.4.4"
    # Quad9
    "Quad9"                               = "9.9.9.9"
    "Quad9-Secondary"                     = "149.112.112.112"
    "Quad9-No-Filter"                     = "9.9.9.10"
    "Quad9-No-Filter-Secondary"           = "149.112.112.10"
    "Quad9-ECS"                           = "9.9.9.11"
    # OpenDNS (Cisco)
    "OpenDNS"                             = "208.67.222.222"
    "OpenDNS-Secondary"                   = "208.67.220.220"
    "OpenDNS-FamilyShield"                = "208.67.222.123"
    "OpenDNS-FamilyShield-Secondary"      = "208.67.220.123"
    # Control D
    "Control-D"                           = "76.76.2.0"
    "Control-D-Secondary"                 = "76.76.10.0"
    # AdGuard
    "AdGuard"                             = "94.140.14.14"
    "AdGuard-Secondary"                   = "94.140.15.15"
    "AdGuard-Family"                      = "94.140.14.15"
    "AdGuard-Family-Secondary"            = "94.140.15.16"
    "AdGuard-Unfiltered"                  = "94.140.14.140"
    "AdGuard-Unfiltered-Secondary"        = "94.140.14.141"
    # NextDNS
    "NextDNS"                             = "45.90.28.0"
    "NextDNS-Secondary"                   = "45.90.30.0"
    # CleanBrowsing
    "CleanBrowsing-Security"              = "185.228.168.9"
    "CleanBrowsing-Security-Secondary"    = "185.228.169.9"
    "CleanBrowsing-Family"                = "185.228.168.168"
    "CleanBrowsing-Family-Secondary"      = "185.228.169.168"
    "CleanBrowsing-Adult"                 = "185.228.168.10"
    "CleanBrowsing-Adult-Secondary"       = "185.228.169.11"
    # Comodo
    "Comodo-Secure"                       = "8.26.56.26"
    "Comodo-Secure-Secondary"             = "8.20.247.20"
    # Verisign
    "Verisign"                            = "64.6.64.6"
    "Verisign-Secondary"                  = "64.6.65.6"
    # Level3 / Lumen
    "Level3"                              = "4.2.2.1"
    "Level3-Secondary"                    = "4.2.2.2"
    # DNS.Watch
    "DNS-Watch"                           = "84.200.69.80"
    "DNS-Watch-Secondary"                 = "84.200.70.40"
    # Yandex
    "Yandex"                              = "77.88.8.8"
    "Yandex-Secondary"                    = "77.88.8.1"
    "Yandex-Safe"                         = "77.88.8.88"
    "Yandex-Family"                       = "77.88.8.7"
    # Alternate DNS
    "Alternate-DNS"                       = "76.76.19.19"
    "Alternate-DNS-Secondary"             = "76.223.122.150"
    # UncensoredDNS
    "UncensoredDNS"                       = "91.239.100.100"
    "UncensoredDNS-Secondary"             = "89.233.43.71"
    # Neustar
    "Neustar"                             = "156.154.70.1"
    "Neustar-Secondary"                   = "156.154.71.1"
    # Mullvad
    "Mullvad"                             = "194.242.2.2"
    "Mullvad-Adblock"                     = "194.242.2.3"
    # dns0.eu
    "dns0.eu"                             = "193.110.81.0"
    "dns0.eu-Secondary"                   = "185.253.5.0"
    # DNS4EU
    "DNS4EU"                              = "86.54.11.1"
    "DNS4EU-Secondary"                    = "86.54.11.100"
    # FreeDNS (Freenom World)
    "FreeDNS-Freenom"                     = "80.80.60.60"
    "FreeDNS-Freenom-Secondary"           = "80.80.81.81"
    # Gcore
    "Gcore"                               = "95.85.95.85"
    "Gcore-Secondary"                     = "2.56.220.2"
}

# --- Detect current DNS servers configured on active network adapters ---
Write-Host "Detecting your current DNS servers..." -ForegroundColor Cyan
try {
    $currentDns = Get-DnsClientServerAddress -AddressFamily IPv4 |
        Where-Object { $_.ServerAddresses.Count -gt 0 -and $_.InterfaceAlias -notmatch "Loopback" } |
        Select-Object -ExpandProperty ServerAddresses -Unique
} catch {
    $currentDns = @()
}

$i = 1
foreach ($ip in $currentDns) {
    # Skip private/router addresses -- these just measure the hop to your
    # router, not real upstream latency.
    if ($ip -match "^192\.168\." -or $ip -match "^10\." -or $ip -match "^172\.(1[6-9]|2[0-9]|3[0-1])\.") {
        Write-Host ("Note: skipping {0,-16} -- private/router address, not a real upstream DNS" -f $ip) -ForegroundColor DarkYellow
        continue
    }
    $Servers["Current-DNS-$i"] = $ip
    $i++
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host " Windows DNS Latency Benchmark"
Write-Host " Testing $($Servers.Count) servers x $($Domains.Count) domains x $Rounds rounds"
Write-Host " (this may take several minutes with the full list)"
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""

$results = @()

foreach ($name in $Servers.Keys) {
    $ip = $Servers[$name]
    $totalTime = 0
    $successCount = 0
    $totalAttempts = $Domains.Count * $Rounds

    foreach ($domain in $Domains) {
        for ($r = 1; $r -le $Rounds; $r++) {
            try {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                Resolve-DnsName -Name $domain -Server $ip -Type A -DnsOnly -ErrorAction Stop -QuickTimeout | Out-Null
                $sw.Stop()
                $totalTime += $sw.Elapsed.TotalMilliseconds
                $successCount++
            } catch {
                # query failed or timed out -- skip, counted as a failure below
            }
        }
    }

    if ($successCount -gt 0) {
        $avg = [math]::Round($totalTime / $successCount, 0)
        $failRate = [math]::Round((($totalAttempts - $successCount) / $totalAttempts) * 100, 0)
        Write-Host ("{0,-36} {1,-18} avg: {2,4} ms   (failures: {3}%)" -f $name, $ip, $avg, $failRate)
        $results += [PSCustomObject]@{ Name = $name; IP = $ip; AvgMs = $avg; FailPct = $failRate }
    } else {
        Write-Host ("{0,-36} {1,-18} UNREACHABLE" -f $name, $ip) -ForegroundColor DarkRed
    }
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host " Ranked results (fastest first):"
Write-Host "======================================================" -ForegroundColor Green

$rank = 1
$results | Sort-Object AvgMs | ForEach-Object {
    Write-Host ("{0,2}. {1,-36} {2,-18} {3} ms" -f $rank, $_.Name, $_.IP, $_.AvgMs)
    $rank++
}

Write-Host ""
Write-Host "Tip: run this a few times (e.g. morning/evening) since results can vary"
Write-Host "with network conditions and time of day."
