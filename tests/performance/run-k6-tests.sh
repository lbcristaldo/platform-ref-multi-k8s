#!/bin/bash
# Run k6 performance tests

set -euo pipefail

echo "Running k6 performance tests..."

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
  echo "k6 is not installed"
  echo "Install: brew install k6  (macOS) or  apt install k6  (Linux)"
  exit 1
fi

# Get chatapp URL
CHATAPP_URL=$(minikube service chatapp -n chatapp --url 2>/dev/null || echo "http://localhost:3000")
export BASE_URL=$CHATAPP_URL

echo "Target URL: $BASE_URL"
echo ""

# Verify app is reachable
if ! curl -s "$BASE_URL/health" > /dev/null; then
  echo "App not reachable at $BASE_URL"
  echo "Make sure chatapp is deployed and accessible"
  exit 1
fi

echo "App is reachable"
echo ""

# Test 1: Load test
echo "Running load test (9 minutes)..."
k6 run tests/performance/load-test.js \
  --out json=tests/performance/results/load-test-results.json \
  --summary-export=tests/performance/results/load-test-summary.json

echo ""

# Test 2: Spike test
read -p "Run spike test? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Running spike test (3 minutes)..."
  k6 run tests/performance/spike-test.js \
    --out json=tests/performance/results/spike-test-results.json \
    --summary-export=tests/performance/results/spike-test-summary.json
  echo ""
fi

# Test 3: Stress test
read -p "Run stress test? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Running stress test (19 minutes)..."
  k6 run tests/performance/stress-test.js \
    --out json=tests/performance/results/stress-test-results.json \
    --summary-export=tests/performance/results/stress-test-summary.json
  echo ""
fi

echo "Performance tests complete!"
echo "Results saved in tests/performance/results/"
