#!/bin/bash
# Setup all dependencies on Debian

set -euo pipefail

echo "  Setting up Debian for Kubernetes development..."

# Update system
echo "  Updating system..."
sudo apt update

# Install basic dependencies
echo "  Installing dependencies..."
sudo apt install -y \
  curl \
  wget \
  git \
  make \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release \
  openssl

# Install Docker
if ! command -v docker &> /dev/null; then
  echo "  Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  rm get-docker.sh
  
  # Add user to docker group
  sudo usermod -aG docker $USER
  echo "  You need to log out and back in for docker group to take effect"
else
  echo "  Docker already installed"
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
  echo "  Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
else
  echo "  kubectl already installed"
fi

# Install minikube
if ! command -v minikube &> /dev/null; then
  echo "  Installing minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64
else
  echo "  minikube already installed"
fi

# Install helm
if ! command -v helm &> /dev/null; then
  echo "⎈ Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "  Helm already installed"
fi

# Install Crossplane CLI (optional but useful)
if ! command -v crossplane &> /dev/null; then
  echo "  Installing Crossplane CLI..."
  curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
  sudo mv crossplane /usr/local/bin/
else
  echo "  Crossplane CLI already installed"
fi

# Setup swap (critical for 8GB RAM)
if [ $(swapon --show | wc -l) -eq 0 ]; then
  echo "  Setting up 4GB swap..."
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  echo "  Swap configured"
else
  echo "  Swap already configured"
fi

# Verify installations
echo ""
echo "  Setup complete! Verifying installations:"
echo ""
docker --version
kubectl version --client --short
minikube version
helm version --short
crossplane --version 2>/dev/null || echo "Crossplane CLI: Not installed (optional)"
echo ""
echo "  Swap status:"
free -h | grep Swap
echo ""
echo "   Next steps:"
echo "1. Log out and back in (for docker group)"
echo "2. Run: make minikube-start"
echo "3. Run: make bootstrap"
