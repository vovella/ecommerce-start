# Module 01 — Performance Baseline

Baseline for the `chat-agent` service, measured on 2026-11-11 inside the VM (requests sent from the VM to `localhost:8501`, so no host-to-VM network hop is included).

## Test environment

| | |
|---|---|
| VM | 4 vCPU, 7.7 GB RAM, Ubuntu 22.04.5, kernel 5.15 |
| Runtime | Docker 29.9.3, Compose v5.7.0 |
| Service | Streamlit 1.38.0, Python 3.11.18, pandas 2.2.2 |
| Data | 500 products (`products.csv`, 199 KB) |

## How to reproduce

```bash
cd ~/ecommerce
./homework/module-01/submission/perf_baseline.sh            # 200 requests, concurrency 10
./homework/module-01/submission/perf_baseline.sh http://localhost:8501 1000 20
```

The script uses only `curl`, `xargs` and `awk`. It restarts the service at the end to measure startup time.

## HTTP latency (200 requests per run)

| Endpoint | Mode | p50 | p95 | p99 | max |
|---|---|---|---|---|---|
| `GET /` | sequential | 1.7 ms | 2.7 ms | 5.2 ms | 6.5 ms |
| `GET /` | 10 concurrent | 2.0 ms | 4.3 ms | 5.0 ms | 6.3 ms |
| `GET /_stcore/health` | sequential | 1.4 ms | 1.8 ms | 2.0 ms | 2.3 ms |
| `GET /_stcore/health` | 10 concurrent | 2.1 ms | 7.3 ms | 11.6 ms | 12.7 ms |

Throughput at concurrency 10 was 281–355 req/s. This number is limited by the client (one `curl` process per request), so treat it as a lower bound, not the server's capacity.

## Application logic

Measured inside the container, 200 runs of the search used by the chat (`"phone"`, 30 matches out of 500 products):

| Operation | Result |
|---|---|
| Load `products.csv` (cold) | 9.4 ms |
| Product search, p50 | 2.8 ms |
| Product search, p95 | 3.7 ms |

The search is a linear substring scan over three text columns, so its cost grows with the catalogue size.

## Resources

| Metric | Value |
|---|---|
| CPU, idle | 0.06 % |
| RAM, idle | 77 MiB of 7.75 GiB (1 %) |
| Image size | 862 MB |
| Startup (`docker compose restart` → health `ok`) | 1.3 s |

## Reading the numbers

- The service is far from any limit at this data size: single-digit millisecond responses and under 100 MiB of memory.
- Chat messages travel over a WebSocket, which `curl` does not exercise. The search timing above stands in for that path; a real end-to-end chat load test needs a WebSocket or browser-driven tool.
- These values are the reference for later modules: a regression is a p95 above roughly 10 ms on `GET /` or idle memory well above 100 MiB with the same data.
