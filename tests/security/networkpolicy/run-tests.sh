#!/bin/bash
# Test NetworkPolicy enforcement

set -euo pipefail

echo " Testing NetworkPolicy isolation..."

FAILED=0

# Deploy test pods
kubectl apply -f tests/security/networkpolicy/test-isolation.yaml
sleep 5

# Test 1: External pod CANNOT reach MongoDB
test_external_blocked() {
  echo "Test 1: External → MongoDB (should be blocked)"
  
  if kubectl exec -n default test-external-pod -- nc -zv -w 2 mongodb.chatapp 27017 2>&1 | grep -q "open"; then
    echo "  FAILED: External pod can reach MongoDB"
    FAILED=$((FAILED + 1))
  else
    echo "  PASSED: External access blocked"
  fi
}

# Test 2: External pod CANNOT reach Redis
test_external_redis_blocked() {
  echo "Test 2: External → Redis (should be blocked)"
  
  if kubectl exec -n default test-external-pod -- nc -zv -w 2 redis.chatapp 6379 2>&1 | grep -q "open"; then
    echo "  FAILED: External pod can reach Redis"
    FAILED=$((FAILED + 1))
  else
    echo "  PASSED: External access blocked"
  fi
}

# Test 3: Internal pod (without correct label) CANNOT reach MongoDB
test_internal_unlabeled_blocked() {
  echo "Test 3: Internal unlabeled pod → MongoDB (should be blocked)"
  
  if kubectl exec -n chatapp test-internal-pod -- nc -zv -w 2 mongodb 27017 2>&1 | grep -q "open"; then
    echo "  FAILED: Unlabeled pod can reach MongoDB"
    FAILED=$((FAILED + 1))
  else
    echo "  PASSED: Unlabeled access blocked"
  fi
}

# Test 4: Chatapp pod CAN reach MongoDB
test_chatapp_allowed() {
  echo "Test 4: Chatapp → MongoDB (should be allowed)"
  
  CHATAPP_POD=$(kubectl get pod -n chatapp -l app=chatapp -o jsonpath='{.items[0].metadata.name}')
  
  if kubectl exec -n chatapp "$CHATAPP_POD" -- nc -zv -w 2 mongodb 27017 2>&1 | grep -q "open"; then
    echo "  PASSED: Chatapp can reach MongoDB"
  else
    echo "  FAILED: Chatapp cannot reach MongoDB"
    FAILED=$((FAILED + 1))
  fi
}

# Run tests
test_external_blocked
test_external_redis_blocked
test_internal_unlabeled_blocked
test_chatapp_allowed

# Cleanup
kubectl delete -f tests/security/networkpolicy/test-isolation.yaml --ignore-not-found=true

echo ""
if [ $FAILED -eq 0 ]; then
  echo " All NetworkPolicy tests passed!"
  exit 0
else
  echo " $FAILED test(s) failed"
  exit 1
fi


