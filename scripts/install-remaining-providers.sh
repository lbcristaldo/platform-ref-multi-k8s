#!/bin/bash
# Install the remaining 3 providers ONE AT A TIME
 
set -euo pipefail

CROSSPLANE_NAMESPACE="crossplane-system"

echo "  Installing remaining AWS providers..."
echo "  This will install 3 more providers. Monitor RAM usage!"
echo ""

# Check current memory
AVAILABLE_MEM=$(free -g | awk '/^Mem:/{print $7}')
echo "  Available memory: ${AVAILABLE_MEM}GB"

if [ "$AVAILABLE_MEM" -lt 2 ]; then
  echo "  Less than 2GB available. Close some applications first."
  exit 1
fi

read -p "Continue with provider installation? (yes/no): " confirm
[ "$confirm" != "yes" ] && exit 0

# Function to install and wait for a provider
install_provider() {
  local PROVIDER_NAME=$1
  local PROVIDER_PACKAGE=$2
  
  echo ""
  echo "  Installing ${PROVIDER_NAME}..."
  
  cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: ${PROVIDER_NAME}
spec:
  package: ${PROVIDER_PACKAGE}
  packagePullPolicy: IfNotPresent
EOF

  echo "  Waiting for ${PROVIDER_NAME} to be healthy..."
  sleep 30
  
  kubectl wait --for=condition=installed --timeout=300s provider/${PROVIDER_NAME} || echo " ${PROVIDER_NAME} not yet installed"
  kubectl wait --for=condition=healthy --timeout=300s provider/${PROVIDER_NAME} || echo " ${PROVIDER_NAME} not yet healthy"
  
  echo "  ${PROVIDER_NAME} installed"
  echo "  Current memory usage:"
  free -h | grep Mem
  echo ""
  
  sleep 10  # Cooldown between providers
}

# Install providers one by one
install_provider "provider-aws-rds" "xpkg.upbound.io/upbound/provider-aws-rds:v1.1.0"
install_provider "provider-aws-elasticache" "xpkg.upbound.io/upbound/provider-aws-elasticache:v1.1.0"
install_provider "provider-aws-docdb" "xpkg.upbound.io/upbound/provider-aws-docdb:v1.1.0"

# Install remaining XRDs
echo ""
echo "  Installing Database and Cache XRDs..."
kubectl apply -f apis/database/definition.yaml
kubectl apply -f apis/database/composition-aws.yaml
kubectl apply -f apis/cache/definition.yaml
kubectl apply -f apis/cache/composition-aws.yaml

# Generate secrets
echo ""
echo "  Generating database secrets..."
DOCDB_PASSWORD=$(openssl rand -base64 32)
REDIS_TOKEN=$(openssl rand -base64 32)

kubectl create secret generic documentdb-admin-password \
  --from-literal=password="${DOCDB_PASSWORD}" \
  -n ${CROSSPLANE_NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic elasticache-auth-token \
  --from-literal=token="${REDIS_TOKEN}" \
  -n ${CROSSPLANE_NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "  All providers installed!"
echo ""
echo "  Final resource usage:"
free -h
echo ""
echo "  Save these credentials:"
echo "DocumentDB Password: ${DOCDB_PASSWORD}"
echo "Redis Token: ${REDIS_TOKEN}"
echo ""
echo "  Now you can create database claims:"
echo "kubectl apply -f examples/chatapp-claim.yaml"
