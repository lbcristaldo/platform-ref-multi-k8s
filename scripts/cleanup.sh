#!/bin/bash
# scripts/cleanup.sh
# Clean up Crossplane resources

set -euo pipefail

echo "⚠️  WARNING: This will delete ALL Crossplane resources!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted"
  exit 0
fi

echo "🧹 Cleaning up resources..."

# Delete claims (if any exist)
kubectl delete networks.network.platform.example.com --all --all-namespaces || true
kubectl delete mongodatabases.database.platform.example.com --all --all-namespaces || true
kubectl delete rediscaches.cache.platform.example.com --all --all-namespaces || true

# Wait for resources to be deleted
echo "Waiting for resources to be cleaned up..."
sleep 30

# Delete compositions and XRDs
kubectl delete compositions --all || true
kubectl delete xrds --all || true

# Uninstall providers
kubectl delete providers --all || true

# Uninstall Crossplane
helm uninstall crossplane -n crossplane-system || true

# Delete namespace
kubectl delete namespace crossplane-system || true

echo "✅ Cleanup complete"
