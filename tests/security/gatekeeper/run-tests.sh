# Test Gatekeeper policy enforcement

set -euo pipefail

echo "  Testing Gatekeeper policies..."

FAILED=0

# Wait for Gatekeeper to be ready
kubectl wait --for=condition=ready pod -l gatekeeper.sh/system=yes -n gatekeeper-system --timeout=60s

# Test 1: Deployment without resource limits should be REJECTED
test_no_limits_rejected() {
  echo "Test 1: Reject deployment without resource limits"
  
  if kubectl apply -f <(yq eval 'select(.metadata.name == "test-no-limits")' tests/security/gatekeeper/test-policies.yaml) 2>&1 | grep -q "denied"; then
    echo "  PASSED: Deployment without limits rejected"
  else
    echo "  FAILED: Deployment without limits was accepted"
    FAILED=$((FAILED + 1))
  fi
}

# Test 2: Deployment with :latest tag should be REJECTED
test_latest_tag_rejected() {
  echo "Test 2: Reject deployment with :latest tag"
  
  if kubectl apply -f <(yq eval 'select(.metadata.name == "test-latest-tag")' tests/security/gatekeeper/test-policies.yaml) 2>&1 | grep -q "denied"; then
    echo "  PASSED: Deployment with :latest tag rejected"
  else
    echo "  FAILED: Deployment with :latest tag was accepted"
    FAILED=$((FAILED + 1))
  fi
}

# Test 3: Valid deployment should be ACCEPTED
test_valid_accepted() {
  echo "Test 3: Accept valid deployment"
  
  if kubectl apply -f <(yq eval 'select(.metadata.name == "test-valid")' tests/security/gatekeeper/test-policies.yaml); then
    echo "  PASSED: Valid deployment accepted"
    kubectl delete deployment test-valid -n chatapp --ignore-not-found=true
  else
    echo "  FAILED: Valid deployment was rejected"
    FAILED=$((FAILED + 1))
  fi
}

# Run tests
test_no_limits_rejected
test_latest_tag_rejected
test_valid_accepted

echo ""
if [ $FAILED -eq 0 ]; then
  echo " All Gatekeeper policy tests passed!"
  exit 0
else
  echo " $FAILED test(s) failed"
  exit 1
fi
