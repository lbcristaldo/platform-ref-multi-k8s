#!/bin/bash
# Test application connectivity to databases

set -euo pipefail

echo " Testing application connectivity..."

FAILED=0
CHATAPP_NS="chatapp"

# Wait for pods to be ready
wait_for_pods() {
  echo "Waiting for pods to be ready..."
  kubectl wait --for=condition=ready pod -l app=mongodb -n $CHATAPP_NS --timeout=120s
  kubectl wait --for=condition=ready pod -l app=redis -n $CHATAPP_NS --timeout=120s
  kubectl wait --for=condition=ready pod -l app=chatapp -n $CHATAPP_NS --timeout=120s
}

# Test 1: MongoDB connectivity
test_mongodb_connectivity() {
  echo "Test 1: Chatapp → MongoDB connectivity"
  
  CHATAPP_POD=$(kubectl get pod -n $CHATAPP_NS -l app=chatapp -o jsonpath='{.items[0].metadata.name}')
  
  # Test TCP connectivity
  if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- nc -zv -w 5 mongodb 27017; then
    echo "  TCP connection successful"
  else
    echo "  FAILED: Cannot reach MongoDB"
    FAILED=$((FAILED + 1))
    return 1
  fi
  
  # Test MongoDB protocol (if mongo client available)
  if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- which mongo &>/dev/null; then
    if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- mongo mongodb://mongodb:27017/test --eval "db.version()" &>/dev/null; then
      echo "  MongoDB protocol working"
    else
      echo "  FAILED: MongoDB protocol error"
      FAILED=$((FAILED + 1))
    fi
  else
    echo "  Mongo client not available, skipping protocol test"
  fi
}

# Test 2: Redis connectivity
test_redis_connectivity() {
  echo "Test 2: Chatapp → Redis connectivity"
  
  CHATAPP_POD=$(kubectl get pod -n $CHATAPP_NS -l app=chatapp -o jsonpath='{.items[0].metadata.name}')
  
  # Test TCP connectivity
  if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- nc -zv -w 5 redis 6379; then
    echo "  TCP connection successful"
  else
    echo "  FAILED: Cannot reach Redis"
    FAILED=$((FAILED + 1))
    return 1
  fi
  
  # Test Redis protocol (if redis-cli available)
  if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- which redis-cli &>/dev/null; then
    if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- redis-cli -h redis PING | grep -q "PONG"; then
      echo "  Redis protocol working"
    else
      echo "  FAILED: Redis protocol error"
      FAILED=$((FAILED + 1))
    fi
  else
    echo "  Redis CLI not available, skipping protocol test"
  fi
}

# Test 3: DNS resolution
test_dns_resolution() {
  echo "Test 3: DNS resolution"
  
  CHATAPP_POD=$(kubectl get pod -n $CHATAPP_NS -l app=chatapp -o jsonpath='{.items[0].metadata.name}')
  
  # Test MongoDB DNS
  if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- nslookup mongodb; then
    echo "  MongoDB DNS resolved"
  else
    echo "  FAILED: MongoDB DNS resolution failed"
    FAILED=$((FAILED + 1))
  fi
  
  # Test Redis DNS
  if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- nslookup redis; then
    echo "  Redis DNS resolved"
  else
    echo "  FAILED: Redis DNS resolution failed"
    FAILED=$((FAILED + 1))
  fi
}

# Test 4: Service endpoints
test_service_endpoints() {
  echo "Test 4: Service endpoints"
  
  # Check MongoDB service has endpoints
  MONGO_ENDPOINTS=$(kubectl get endpoints mongodb -n $CHATAPP_NS -o jsonpath='{.subsets[*].addresses[*].ip}')
  if [ -n "$MONGO_ENDPOINTS" ]; then
    echo "  MongoDB service has endpoints: $MONGO_ENDPOINTS"
  else
    echo "  FAILED: MongoDB service has no endpoints"
    FAILED=$((FAILED + 1))
  fi
  
  # Check Redis service has endpoints
  REDIS_ENDPOINTS=$(kubectl get endpoints redis -n $CHATAPP_NS -o jsonpath='{.subsets[*].addresses[*].ip}')
  if [ -n "$REDIS_ENDPOINTS" ]; then
    echo "  Redis service has endpoints: $REDIS_ENDPOINTS"
  else
    echo "  FAILED: Redis service has no endpoints"
    FAILED=$((FAILED + 1))
  fi
}

# Test 5: ConfigMap injection
test_configmap_injection() {
  echo "Test 5: ConfigMap environment variables"
  
  CHATAPP_POD=$(kubectl get pod -n $CHATAPP_NS -l app=chatapp -o jsonpath='{.items[0].metadata.name}')
  
  # Check MONGODB_URI
  if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- env | grep -q "MONGODB_URI"; then
    echo "  MONGODB_URI injected"
  else
    echo "  FAILED: MONGODB_URI not found"
    FAILED=$((FAILED + 1))
  fi
  
  # Check REDIS_HOST
  if kubectl exec -n $CHATAPP_NS "$CHATAPP_POD" -- env | grep -q "REDIS_HOST"; then
    echo "  REDIS_HOST injected"
  else
    echo "  FAILED: REDIS_HOST not found"
    FAILED=$((FAILED + 1))
  fi
}

# Run all tests
wait_for_pods
test_mongodb_connectivity
test_redis_connectivity
test_dns_resolution
test_service_endpoints
test_configmap_injection

echo ""
if [ $FAILED -eq 0 ]; then
  echo " All connectivity tests passed!"
  exit 0
else
  echo " $FAILED test(s) failed"
  exit 1
fi
