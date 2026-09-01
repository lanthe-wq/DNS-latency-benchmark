# DNS Latency Benchmark

A simple bash script that benchmarks nearly 30 public DNS resolvers (Cloudflare,
Google, Quad9, OpenDNS, NextDNS, and more) plus your machine's currently
configured DNS servers, and ranks them by average query latency — so you can
find the fastest DNS for your network.

## Why

DNS latency depends heavily on your physical location and your ISP's peering,
so there's no universal "fastest" DNS server — it varies from network to
network. This script measures actual round-trip time from **your** machine
against a range of well-known resolvers, so you can make a decision based on
real data instead of guesswork.

## Requirements

- macOS (uses `scutil` to detect your current DNS servers)
- `dig`, which ships with macOS by default
- Bash (also ships with macOS by default)

> **Note:** the current-DNS auto-detection is macOS-specific. The rest of the
> script (testing the built-in server list) will work on any Linux/Unix
> system with `dig` installed.

## Usage

```bash
git clone https://github.com/<your-username>/dns-latency-benchmark.git
cd dns-latency-benchmark
chmod +x dns_speed_test.sh
./dns_speed_test.sh
```

The script will:

1. Detect your Mac's currently configured DNS servers (skipping private/router
   addresses like `192.168.x.x`, since those only measure the hop to your
   router, not real upstream latency)
2. Query each server against 5 popular domains, 3 times each
3. Print a live result per server as it completes
4. Print a final ranked list, fastest to slowest, with average latency in ms
   and failure rate

Takes roughly 3–5 minutes to run against the full server list.

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

The built-in list covers:

- **Cloudflare** (1.1.1.1, 1.0.0.1, malware-blocking variant)
- **Google** (8.8.8.8, 8.8.4.4)
- **Quad9** (9.9.9.9, secondary, and no-filter variant)
- **OpenDNS** (208.67.222.222, 208.67.220.220)
- **Control D** (76.76.2.0, 76.76.10.0)
- **AdGuard** (94.140.14.14, 94.140.15.15)
- **NextDNS** (45.90.28.0, 45.90.30.0)
- **CleanBrowsing** (185.228.168.9, 185.228.169.9)
- **Comodo Secure DNS**
- **Verisign**
- **Level3**
- **DNS.Watch**
- **Yandex DNS**
- **Alternate DNS**
- **UncensoredDNS**

Plus whatever your Mac is currently configured to use (IPv4 and IPv6).

## Customizing

Open `dns_speed_test.sh` and edit these variables near the top:

- `DOMAINS` — the list of domains queried during testing
- `ROUNDS` — how many times each domain is queried per server (higher = more
  accurate average, but slower)
- `SERVERS` — add or remove any `"Name:IP"` entries you want tested

## Interpreting results

- **Small differences (a few ms) rarely matter in practice** — DNS lookups
  are cached, so this latency only affects the *first* request to a new
  domain, not every subsequent page load.
- **Your ISP's own DNS is often fastest**, since it's typically the closest
  resolver on the network path. Public DNS providers can still be worth using
  for privacy, malware filtering, or content filtering features, even if
  they're a few ms slower.
- **A high failure rate** for a given server usually means it's blocked,
  rate-limiting you, or poorly peered with your network — worth avoiding
  regardless of its average latency.

## Applying your results

Once you've found the fastest option, set it at the **router level**
(Settings → DNS, varies by router) so it applies to every device on your
network — rather than configuring each device individually. Alternatively,
set it per-Mac in **System Settings → Network → [your connection] → DNS**.

## License

MIT — do whatever you'd like with this.
