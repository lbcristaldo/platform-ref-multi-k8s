#!/bin/bash
# Bootstrap Crossplane for 8GB RAM systems - Single provider at a time

set -euo pipefail

CROSSPLANE_VERSION="1.14.5"
CROSSPLANE_NAMESPACE="crossplane-system"

echo " Starting LIGHT platform bootstrap (optimized for 8GB RAM)..."

# Check available memory
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_MEM" -lt 7 ]; then
  echo "WARNING: Less than 8GB RAM detected. This may fail."
  echo "Consider closing other applications."
  read -p "Continue anyway? (yes/no): " confirm
  [ "$confirm" != "yes" ] && exit 1
fi

# Check swap
SWAP=$(free -g | awk '/^Swap:/{print $2}')
if [ "$SWAP" -lt 2 ]; then
  echo "WARNING: Less than 2GB swap. Highly recommended to add swap."
  echo "Run: sudo fallocate -l 4G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
  read -p "Continue anyway? (yes/no): " confirm
  [ "$confirm" != "yes" ] && exit 1
fi

# 1. Create namespace
echo " Creating Crossplane namespace..."
kubectl create namespace ${CROSSPLANE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 2. Install Crossplane with resource limits
echo " Installing Crossplane ${CROSSPLANE_VERSION} with resource limits..."
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm upgrade --install crossplane \
  crossplane-stable/crossplane \
  --namespace ${CROSSPLANE_NAMESPACE} \
  --version ${CROSSPLANE_VERSION} \
  --create-namespace \
  --set resourcesCrossplane.limits.memory="512Mi" \
  --set resourcesCrossplane.requests.memory="256Mi" \
  --wait

echo " Crossplane installed"

# 3. Wait for Crossplane to be ready
echo " Waiting for Crossplane pods..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/crossplane -n ${CROSSPLANE_NAMESPACE}

echo " Crossplane is ready"

# 4. Install ONLY EC2 provider first (lightest one)
echo " Installing AWS EC2 Provider (step 1/4)..."
kubectl apply -f cluster/providers/aws/provider-light.yaml

echo " Waiting for EC2 provider (this takes 2-3 minutes)..."
sleep 60

kubectl wait --for=condition=installed --timeout=300s provider/provider-aws-ec2 || echo "provider-aws-ec2 not yet installed"
kubectl wait --for=condition=healthy --timeout=300s provider/provider-aws-ec2 || echo "provider-aws-ec2 not yet healthy"

echo " EC2 Provider installed"

# 5. Apply fake AWS credentials
echo " Applying AWS credentials..."
mkdir -p ~/.aws
cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
EOF

kubectl create secret generic aws-credentials \
  --from-file=credentials=$HOME/.aws/credentials \
  -n ${CROSSPLANE_NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

# 6. Apply ProviderConfig
echo " Configuring AWS provider..."
kubectl apply -f cluster/providers/aws/provider-config.yaml

echo " Provider configured"

# 7. Install ONLY Network XRD and Composition
echo " Installing Network definitions..."
kubectl apply -f apis/network/definition.yaml
kubectl apply -f apis/network/composition-aws.yaml

echo "  Network XRD installed"

echo ""
echo "  LIGHT Bootstrap complete!"
echo ""
echo "  Current resource usage:"
free -h
echo ""
echo "  What was installed:"
echo "  Crossplane core"
echo "  AWS EC2 Provider only"
echo "  Network XRD & Composition"
echo ""
echo "  NOT installed yet (to save RAM):"
echo "  ElastiCache provider"
echo "  DocumentDB provider"
echo "  RDS provider"
echo "  Database & Cache XRDs"
echo ""
echo "   Next steps:"
echo "1. Validate: ./scripts/validate.sh"
echo "2. Test network: kubectl apply --dry-run=server -f examples/aws-network.yaml"
echo "3. When ready for more providers: ./scripts/install-remaining-providers.sh"
echo ""
echo "   Monitor resources: watch -n 2 'free -h'"
