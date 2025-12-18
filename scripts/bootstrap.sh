#!/bin/bash
# Bootstrap Crossplane and prerequisites

set -euo pipefail

CROSSPLANE_VERSION="1.14.0"
CROSSPLANE_NAMESPACE="crossplane-system"

echo "Starting platform bootstrap..."

# 1. Create namespace
echo "Creating Crossplane namespace..."
kubectl create namespace ${CROSSPLANE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 2. Install Crossplane
echo "Installing Crossplane ${CROSSPLANE_VERSION}..."
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm upgrade --install crossplane \
  crossplane-stable/crossplane \
  --namespace ${CROSSPLANE_NAMESPACE} \
  --version ${CROSSPLANE_VERSION} \
  --create-namespace \
  --wait

echo "Crossplane installed"

# 3. Wait for Crossplane to be ready
echo "Waiting for Crossplane pods..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/crossplane -n ${CROSSPLANE_NAMESPACE}

echo "Crossplane is ready"

# 4. Install AWS Providers
echo "Installing AWS Providers..."
kubectl apply -f cluster/providers/aws/provider.yaml

echo "Waiting for providers to be healthy..."
sleep 30  # Give providers time to install

kubectl wait --for=condition=healthy --timeout=300s \
  provider/provider-aws-ec2 || echo "⚠️  provider-aws-ec2 not yet healthy"

kubectl wait --for=condition=healthy --timeout=300s \
  provider/provider-aws-elasticache || echo "⚠️  provider-aws-elasticache not yet healthy"

kubectl wait --for=condition=healthy --timeout=300s \
  provider/provider-aws-docdb || echo "⚠️ provider-aws-docdb not yet healthy"

echo "Providers installed"

# 5. Configure AWS credentials
if [ ! -f "cluster/providers/aws/credentials-secret.yaml" ]; then
  echo "AWS credentials not found!"
  echo "Please create cluster/providers/aws/credentials-secret.yaml"
  echo "Example:"
  echo "  kubectl create secret generic aws-credentials \\"
  echo "    --from-file=credentials=~/.aws/credentials \\"
  echo "    -n ${CROSSPLANE_NAMESPACE}"
  exit 1
fi

echo "Applying AWS credentials..."
kubectl apply -f cluster/providers/aws/credentials-secret.yaml

# 6. Apply ProviderConfig
echo "Configuring AWS provider..."
kubectl apply -f cluster/providers/aws/provider-config.yaml

echo "AWS provider configured"

# 7. Install XRDs and Compositions
echo "Installing Crossplane definitions..."
kubectl apply -f apis/network/definition.yaml
kubectl apply -f apis/network/composition-aws.yaml
kubectl apply -f apis/database/definition.yaml
kubectl apply -f apis/database/composition-aws.yaml
kubectl apply -f apis/cache/definition.yaml
kubectl apply -f apis/cache/composition-aws.yaml

echo "XRDs and Compositions installed"

# 8. Generate secrets for databases
echo "Generating database secrets..."
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

echo "Secrets generated"

echo ""
echo "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "1. Create network: kubectl apply -f examples/aws-network.yaml"
echo "2. Wait for network: kubectl get network -w"
echo "3. Create database: kubectl apply -f examples/chatapp-claim.yaml"
echo ""
echo "Save these credentials securely:"
echo "DocumentDB Password: ${DOCDB_PASSWORD}"
echo "Redis Token: ${REDIS_TOKEN}"
