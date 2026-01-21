# Performance Testing with k6

## Installation

```bash
# macOS
brew install k6

# Debian/Ubuntu
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```
---

## Test Scenarios

### 1. Load Test (9 minutes)
Normal traffic simulation with gradual ramp-up.

```bash
k6 run tests/performance/load-test.js
```

**Stages:**
- Warm up: 10 users for 1 minute
- Ramp up: 50 users for 3 minutes
- Peak: 100 users for 2 minutes
- Scale down: 50 users for 2 minutes
- Cool down: 0 users for 1 minute

### 2. Spike Test (3 minutes)
Sudden traffic spike simulation.

```bash
k6 run tests/performance/spike-test.js
```

**Stages:**
- Baseline: 10 users
- SPIKE: Jump to 500 users in 10 seconds
- Hold: 500 users for 1 minute
- Recovery: Back to 10 users

### 3. Stress Test (19 minutes)
Find the breaking point.

```bash
k6 run tests/performance/stress-test.js
```

**Stages:**
- Progressive load: 100 → 200 → 300 → 400 users
- Each stage: 5 minutes
- Find where system starts failing

## Running Tests

```bash
# All tests via Make
make test-performance

# Individual test
k6 run tests/performance/load-test.js

# With custom URL
BASE_URL=http://192.168.1.100:30000 k6 run tests/performance/load-test.js

# With HTML report
k6 run --out html=report.html tests/performance/load-test.js
```
---

## Expected Metrics

### Healthy System
- p95 latency: < 500ms
- Error rate: < 1%
- Throughput: > 100 req/s

### Under Load (100 users)
- p95 latency: < 1000ms
- Error rate: < 5%
- CPU usage: < 80%
- Memory usage: < 80%

## Monitoring During Tests

```bash
# Terminal 1: Run test
k6 run tests/performance/load-test.js

# Terminal 2: Watch pods
watch kubectl top pods -n chatapp

# Terminal 3: Watch KEDA scaling
watch kubectl get hpa -n chatapp
```
---

## Interpreting Results

```
✓ http_req_duration..........: avg=245ms min=12ms med=189ms max=2.1s p(95)=450ms
✓ http_req_failed............: 0.12% (12 of 10000)
  http_reqs..................: 10000 (111/s)
  iterations.................: 10000 (111/s)
  vus........................: 100
```

- **http_req_duration**: Response times (aim for p95 < 500ms)
- **http_req_failed**: Error rate (aim for < 1%)
- **http_reqs**: Throughput (requests/second)
- **vus**: Virtual users (concurrent connections)
