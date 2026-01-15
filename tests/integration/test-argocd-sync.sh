#!/bin/bash
# Test ArgoCD GitOps workflow

set -euo pipefail

echo "  Testing ArgoCD sync workflow..."

FAILED=0
ARGOCD_NS="argocd"

# Test 1: ArgoCD is healthy
test_argocd_health() {
  echo "Test 1: ArgoCD health"
  
  if kubectl wait --for=condition=available deployment/argocd-server -n $ARGOCD_NS --timeout=60s; then
    echo "  ArgoCD server healthy"
  else
    echo "  FAILED: ArgoCD server not healthy"
    FAILED=$((FAILED + 1))
  fi
}

# Test 2: Create test application
test_app_creation() {
  echo "Test 2: Application creation"
  
  cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

  sleep 5
  
  if kubectl get application test-app -n $ARGOCD_NS; then
    echo "  Application created"
  else
    echo "  FAILED: Application not created"
    FAILED=$((FAILED + 1))
  fi
}

# Test 3: Application syncs
test_app_sync() {
  echo "Test 3: Application sync"
  
  # Wait for sync
  timeout=60
  while [ $timeout -gt 0 ]; do
    STATUS=$(kubectl get application test-app -n $ARGOCD_NS -o jsonpath='{.status.sync.status}')
    if [ "$STATUS" = "Synced" ]; then
      echo "  Application synced successfully"
      return 0
    fi
    sleep 2
    timeout=$((timeout - 2))
  done
  
  echo "  FAILED: Application did not sync in time"
  kubectl get application test-app -n $ARGOCD_NS -o yaml
  FAILED=$((FAILED + 1))
}

# Test 4: Application is healthy
test_app_health() {
  echo "Test 4: Application health"
  
  HEALTH=$(kubectl get application test-app -n $ARGOCD_NS -o jsonpath='{.status.health.status}')
  if [ "$HEALTH" = "Healthy" ]; then
    echo "  Application healthy"
  else
    echo "  FAILED: Application not healthy (status: $HEALTH)"
    FAILED=$((FAILED + 1))
  fi
}

# Cleanup
cleanup() {
  echo "Cleaning up test application..."
  kubectl delete application test-app -n $ARGOCD_NS --ignore-not-found=true
}

trap cleanup EXIT

# Run tests
test_argocd_health
test_app_creation
test_app_sync
test_app_health

echo ""
if [ $FAILED -eq 0 ]; then
  echo "  All ArgoCD tests passed!"
  exit 0
else
  echo "  $FAILED test(s) failed"
  exit 1
fi
