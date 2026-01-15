#!/bin/bash
# Unit tests for Crossplane compositions

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0

echo " Running Crossplane composition tests..."

# Test 1: Validate XRD schemas
test_xrd_validation() {
  echo "Test 1: XRD Schema Validation"
  
  for xrd in apis/*/definition.yaml; do
    echo "  Testing $xrd..."
    kubectl apply --dry-run=client -f "$xrd" || {
      echo "  FAILED: $xrd"
      FAILED=$((FAILED + 1))
      return 1
    }
  done
  
  echo "   PASSED"
}

# Test 2: Validate compositions
test_composition_validation() {
  echo "Test 2: Composition Validation"
  
  for comp in apis/*/composition-aws.yaml; do
    echo "  Testing $comp..."
    kubectl apply --dry-run=client -f "$comp" || {
      echo "   FAILED: $comp"
      FAILED=$((FAILED + 1))
      return 1
    }
  done
  
  echo "  PASSED"
}

# Test 3: Render compositions with different inputs
test_composition_rendering() {
  echo "Test 3: Composition Rendering"
  
  if ! command -v crossplane &> /dev/null; then
    echo "   SKIPPED: crossplane CLI not installed"
    return 0
  fi
  
  # Test small database claim
  echo "  Rendering small database claim..."
  crossplane beta render \
    <(kubectl get configmap composition-test-cases -o jsonpath='{.data.test-small-db\.yaml}') \
    apis/database/ \
    > /tmp/render-small.yaml || {
    echo "  FAILED: Small DB rendering"
    FAILED=$((FAILED + 1))
    return 1
  }
  
  # Verify expected resources
  if ! grep -q "kind: Cluster" /tmp/render-small.yaml; then
    echo "  FAILED: DocumentDB Cluster not rendered"
    FAILED=$((FAILED + 1))
    return 1
  fi
  
  if ! grep -q "instanceClass: db.t3.medium" /tmp/render-small.yaml; then
    echo "  FAILED: Instance class not mapped correctly"
    FAILED=$((FAILED + 1))
    return 1
  fi
  
  echo "  PASSED"
}

# Test 4: Patch transformations
test_patch_transforms() {
  echo "Test 4: Patch Transform Logic"
  
  # Verify instance class mapping (small -> db.t3.medium)
  if ! grep -q "small: db.t3.medium" apis/database/composition-aws.yaml; then
    echo "  FAILED: Instance class mapping missing"
    FAILED=$((FAILED + 1))
    return 1
  fi
  
  # Verify region patching
  if ! grep -q "fromFieldPath: spec.parameters.region" apis/database/composition-aws.yaml; then
    echo "  FAILED: Region patching missing"
    FAILED=$((FAILED + 1))
    return 1
  fi
  
  echo "  PASSED"
}

# Run all tests
test_xrd_validation
test_composition_validation
test_composition_rendering
test_patch_transforms

echo ""
if [ $FAILED -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "$FAILED test(s) failed"
  exit 1
fi
