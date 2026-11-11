#!/usr/bin/env bash
# Module 01: reproducible performance baseline for the chat-agent service.
# Usage: ./perf_baseline.sh [BASE_URL] [REQUESTS] [CONCURRENCY]
# Run from the project root (needs docker compose for the resource/startup sections).
set -u
BASE_URL="${1:-http://localhost:8501}"
N="${2:-200}"
C="${3:-10}"

# stats: reads one latency (seconds) per line, prints min/p50/p95/p99/max in ms
stats() {
  sort -n | awk '{a[NR]=$1*1000} END {
    if (NR==0) {print "no samples"; exit 1}
    p50=a[int((NR-1)*0.50)+1]; p95=a[int((NR-1)*0.95)+1]; p99=a[int((NR-1)*0.99)+1]
    printf "n=%d min=%.1f p50=%.1f p95=%.1f p99=%.1f max=%.1f (ms)\n", NR, a[1], p50, p95, p99, a[NR]}'
}
one() { curl -s -o /dev/null --max-time 10 -w '%{time_total}\n' "$1"; }
export -f one

for path in / /_stcore/health; do
  echo "== GET $path"
  printf '  sequential    : '; for _ in $(seq "$N"); do one "$BASE_URL$path"; done | stats
  start=$(date +%s.%N)
  lat="$(seq "$N" | xargs -P "$C" -I{} bash -c "one '$BASE_URL$path'")"
  end=$(date +%s.%N)
  printf '  concurrency %-2s: ' "$C"; echo "$lat" | stats
  awk -v n="$N" -v s="$start" -v e="$end" 'BEGIN {printf "  throughput    : %.0f req/s\n", n/(e-s)}'
done

if command -v docker >/dev/null && [ -f docker-compose.yml ]; then
  echo "== Resources (idle)"
  docker stats --no-stream --format '  {{.Name}}: CPU {{.CPUPerc}}, RAM {{.MemUsage}} ({{.MemPerc}})' "$(docker compose ps -q chat-agent)"
  docker image ls --format '  image {{.Repository}}: {{.Size}}' ecommerce-chat-agent
  echo "== Startup time (restart -> healthy)"
  t0=$(date +%s.%N)
  docker compose restart chat-agent >/dev/null 2>&1
  until [ "$(curl -s --max-time 2 "$BASE_URL/_stcore/health")" = "ok" ]; do sleep 0.2; done
  awk -v s="$t0" -v e="$(date +%s.%N)" 'BEGIN {printf "  %.1f s\n", e-s}'
fi
