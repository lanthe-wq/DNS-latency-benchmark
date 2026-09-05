# DNS Latency Benchmark

Scripts that benchmark ~50 public DNS resolvers (Cloudflare, Google, Quad9,
OpenDNS, AdGuard, NextDNS, Mullvad, DNS4EU, and more) plus your machine's
currently configured DNS servers, and rank them by average query latency —
so you can find the fastest DNS for your network.

Two versions are included:

| Script                | Platform      | Requirements                          |
|-----------------------|---------------|----------------------------------------|
| `dns_speed_test_macos.sh`   | macOS         | `dig` + `scutil` (both built in)       |
| `dns_speed_test_win.ps1`  | Windows       | PowerShell 5.1+ (built into Win 10/11) |

Neither script requires installing anything extra.

## Why

DNS latency depends heavily on your physical location and your ISP's
peering, so there's no universal "fastest" DNS server — it varies from
network to network. These scripts measure actual round-trip time from
**your** machine against a wide range of well-known resolvers, so you can
make a decision based on real data instead of guesswork.

## macOS usage

```bash
git clone https://github.com/lanthe-wq/DNS-latency-benchmark.git
cd dns-latency-benchmark
chmod +x dns_speed_test_macos.sh
./dns_speed_test_macos.sh
```

The script will:

1. Detect your Mac's currently configured DNS servers via `scutil` (IPv4 and
   IPv6), skipping private/router addresses like `192.168.x.x` since those
   only measure the hop to your router, not real upstream latency
2. Query each of the ~50 servers against 5 popular domains, 3 times each,
   using `dig`
3. Print a live result per server as it completes
4. Print a final ranked list, fastest to slowest, with average latency in ms
   and failure rate

## Windows usage

Right-click `dns_speed_test_win.ps1` → **Run with PowerShell**, or from a
PowerShell prompt:

```powershell
powershell -ExecutionPolicy Bypass -File .\dns_speed_test_win.ps1
```

> If PowerShell blocks the script due to execution policy, the command above
> bypasses that for this one run without changing your system-wide policy.

The script will:

1. Detect your currently configured DNS servers via `Get-DnsClientServerAddress`,
   skipping private/router addresses the same way the macOS version does
2. Query each of the ~50 servers against 5 popular domains, 3 times each,
   using `Resolve-DnsName` (built into Windows — no `dig` or third-party
   tools needed)
3. Print a live result per server as it completes
4. Print a final ranked list, fastest to slowest, with average latency in ms
   and failure rate

Both scripts take roughly 5–10 minutes to run against the full ~50-server
list, depending on your connection and how many servers time out.

### Example output

```
======================================================
 Ranked results (fastest first):
======================================================
 1. ISP-DNS                203.0.113.1      2 ms
 2. Google-Secondary       8.8.4.4          8 ms
 3. Cloudflare             1.1.1.1          10 ms
 4. Quad9                  9.9.9.9          9 ms
 ...
```

## What's included

The built-in list covers ~50 servers across these providers:

- **Cloudflare** — standard, malware-blocking, and family-filtering variants
- **Google Public DNS**
- **Quad9** — standard, secondary, no-filter, and ECS variants
- **OpenDNS (Cisco)** — standard and FamilyShield variants
- **Control D**
- **AdGuard DNS** — standard, family, and unfiltered variants
- **NextDNS**
- **CleanBrowsing** — security, family, and adult-content filters
- **Comodo Secure DNS**
- **Verisign**
- **Level3 / Lumen**
- **DNS.Watch**
- **Yandex DNS** — standard, safe, and family variants
- **Alternate DNS**
- **UncensoredDNS**
- **Neustar**
- **Mullvad** — standard and adblock variants
- **dns0.eu**
- **DNS4EU** (EU-operated public resolver initiative)
- **FreeDNS (Freenom World)**
- **Gcore Public DNS**

Plus whatever your machine is currently configured to use.

All IPs are drawn from each provider's official documentation as of the
last update to this repo. DNS infrastructure occasionally changes — if a
server shows 100% failures, it's worth checking whether the provider has
published a new address before assuming your network is at fault.

## Customizing

Open the script for your platform and edit these variables near the top:

- **Domains tested** (`DOMAINS` in bash / `$Domains` in PowerShell) — the
  list of domains queried during testing
- **Rounds** (`ROUNDS` / `$Rounds`) — how many times each domain is queried
  per server (higher = more accurate average, but slower)
- **Servers** (`SERVERS` / `$Servers`) — add or remove any name/IP entries
  you want tested

## Interpreting results

- **Small differences (a few ms) rarely matter in practice** — DNS lookups
  are cached, so this latency only affects the *first* request to a new
  domain, not every subsequent page load.
- **Your ISP's own DNS is often fastest**, since it's typically the closest
  resolver on the network path. Public DNS providers can still be worth
  using for privacy, malware filtering, or content filtering features, even
  if they're a few ms slower.
- **A high failure rate** for a given server usually means it's blocked,
  rate-limiting you, or poorly peered with your network — worth avoiding
  regardless of its average latency.

## Applying your results

Once you've found the fastest option, set it at the **router level**
(Settings → DNS, varies by router) so it applies to every device on your
network — rather than configuring each device individually.

- **macOS:** System Settings → Network → [your connection] → DNS
- **Windows:** Settings → Network & Internet → [your connection] → DNS
  server assignment → Edit → Manual

## License

MIT — do whatever you'd like with this.
