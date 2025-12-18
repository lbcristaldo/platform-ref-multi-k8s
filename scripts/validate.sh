#!/bin/bash
# Validate Crossplane resources

set -euo pipefail

echo "Validating Crossplane installation..."

# Check Crossplane health
echo "Checking Crossplane pods..."
kubectl get pods -n crossplane-system

# Check providers
echo ""
echo "Checking providers..."
kubectl get providers

# Check XRDs
echo ""
echo "Checking XRDs..."
kubectl get xrds

# Check Compositions
echo ""
echo "Checking Compositions..."
kubectl get compositions

# Check ProviderConfigs
echo ""
echo "Checking ProviderConfigs..."
kubectl get providerconfigs

echo ""
echo "✅ Validation complete"

