#!/bin/bash
#
# dns_speed_test.sh
# Benchmarks common public DNS resolvers + your current DNS from macOS
# and ranks them by average query latency.
#
# Usage:
#   chmod +x dns_speed_test.sh
#   ./dns_speed_test.sh
#

# Domains to test against (mix of popular + varied TLDs for realistic results)
DOMAINS=("google.com" "amazon.com" "apple.com" "wikipedia.org" "cloudflare.com")

# How many times to query each domain per server (averages out jitter)
ROUNDS=3

# DNS servers to test: "Name:IP"
SERVERS=(
  "Cloudflare:1.1.1.1"
  "Cloudflare-Secondary:1.0.0.1"
  "Cloudflare-Malware-Block:1.1.1.2"
  "Google:8.8.8.8"
  "Google-Secondary:8.8.4.4"
  "Quad9:9.9.9.9"
  "Quad9-Secondary:149.112.112.112"
  "Quad9-No-Filter:9.9.9.10"
  "OpenDNS:208.67.222.222"
  "OpenDNS-Secondary:208.67.220.220"
  "Control-D:76.76.2.0"
  "Control-D-Secondary:76.76.10.0"
  "AdGuard:94.140.14.14"
  "AdGuard-Secondary:94.140.15.15"
  "NextDNS:45.90.28.0"
  "NextDNS-Secondary:45.90.30.0"
  "CleanBrowsing:185.228.168.9"
  "CleanBrowsing-Secondary:185.228.169.9"
  "Comodo-Secure:8.26.56.26"
  "Comodo-Secure-Secondary:8.20.247.20"
  "Verisign:64.6.64.6"
  "Verisign-Secondary:64.6.65.6"
  "Level3:4.2.2.1"
  "Level3-Secondary:4.2.2.2"
  "DNS-Watch:84.200.69.80"
  "Yandex:77.88.8.8"
  "Alternate-DNS:76.76.19.19"
  "UncensoredDNS:91.239.100.100"
)

# Grab your current/default DNS servers from macOS network settings (IPv4 + IPv6) and add them
CURRENT_DNS=$(scutil --dns 2>/dev/null | grep 'nameserver\[[0-9]*\]' | awk '{print $3}' | sort -u)
i=1
for ip in $CURRENT_DNS; do
  # Skip private/local IPv4 addresses (e.g. 192.168.x.x, 10.x.x.x) — these are just
  # your router, not the actual upstream DNS, so testing them isn't meaningful.
  if [[ "$ip" =~ ^192\.168\. ]] || [[ "$ip" =~ ^10\. ]] || [[ "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
    printf "Note: skipping %-16s — this is a private/router address, not a real upstream DNS\n" "$ip"
    continue
  fi
  SERVERS+=("Current-DNS-$i:$ip")
  i=$((i+1))
done

# Your ISP/router's IPv6 DNS server (from your network settings screenshot) — added directly
# since it may not always be picked up by scutil depending on active interface.
SERVERS+=("ISP-IPv6-DNS:2405:201:4018:6235::1")

echo "======================================================"
echo " macOS DNS Latency Benchmark"
echo " Testing ${#SERVERS[@]} servers x ${#DOMAINS[@]} domains x $ROUNDS rounds"
echo " (this list is longer now — expect this to take a few minutes)"
echo "======================================================"
echo ""

# temp file to store results
RESULTS_FILE=$(mktemp)

for entry in "${SERVERS[@]}"; do
  # Split on the FIRST colon only (name never contains a colon, but IPv6
  # addresses do, so we can't just split on the last or use %%/## naively).
  name="${entry%%:*}"
  ip="${entry#*:}"

  total_time=0
  successful_queries=0

  for domain in "${DOMAINS[@]}"; do
    for ((r=1; r<=ROUNDS; r++)); do
      # dig returns query time in ms via the "Query time:" line
      qtime=$(dig @"$ip" "$domain" +time=2 +tries=1 2>/dev/null | grep "Query time:" | awk '{print $4}')
      if [[ -n "$qtime" ]]; then
        total_time=$((total_time + qtime))
        successful_queries=$((successful_queries + 1))
      fi
    done
  done

  if [[ $successful_queries -gt 0 ]]; then
    avg=$((total_time / successful_queries))
    fail_rate=$(( ( (ROUNDS * ${#DOMAINS[@]}) - successful_queries ) * 100 / (ROUNDS * ${#DOMAINS[@]}) ))
    printf "%-22s %-16s avg: %4d ms   (failures: %d%%)\n" "$name" "$ip" "$avg" "$fail_rate"
    echo "$avg|$name|$ip" >> "$RESULTS_FILE"
  else
    printf "%-22s %-16s UNREACHABLE\n" "$name" "$ip"
  fi
done

echo ""
echo "======================================================"
echo " Ranked results (fastest first):"
echo "======================================================"
sort -n -t'|' -k1 "$RESULTS_FILE" | awk -F'|' '{printf "%2d. %-22s %-16s %s ms\n", NR, $2, $3, $1}'

rm -f "$RESULTS_FILE"

echo ""
echo "Tip: run this a few times (e.g. morning/evening) since results can vary"
echo "with network conditions and time of day."
