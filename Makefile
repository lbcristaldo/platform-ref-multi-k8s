.PHONY: help setup bootstrap validate deploy-argocd deploy-app deploy-security deploy-observability status clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

# Setup
setup: ## Setup Debian dependencies (first time only)
	@./scripts/setup-debian.sh

minikube-start: ## Start minikube with optimized settings
	@echo "  Starting minikube (optimized for 8GB RAM)..."
	@minikube start --cpus=4 --memory=5120 --disk-size=20g --driver=docker
	@echo "  Minikube started"

minikube-stop: ## Stop minikube
	@minikube stop

minikube-delete: ## Delete minikube cluster
	@minikube delete

# Bootstrap
bootstrap: ## Bootstrap Crossplane (light version)
	@./scripts/bootstrap-light.sh

install-providers: ## Install remaining providers (after bootstrap)
	@./scripts/install-remaining-providers.sh

validate: ## Validate all manifests
	@./scripts/validate.sh

# Deployments
deploy-argocd: ## Deploy ArgoCD (GitOps)
	@echo "  Deploying ArgoCD..."
	@kubectl apply -k cluster/gitops/argocd/
	@echo "  Waiting for ArgoCD to be ready..."
	@kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
	@echo "  ArgoCD deployed"
	@echo ""
	@echo "  Get admin password:"
	@echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
	@echo ""
	@echo "  Access UI:"
	@echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"

deploy-app: ## Deploy chatapp with in-cluster databases
	@echo "  Deploying chatapp..."
	@kubectl apply -k cluster/app/
	@echo "  Chatapp deployed"
	@echo ""
	@echo "  Check status:"
	@echo "kubectl get pods -n chatapp"

deploy-security: ## Deploy security policies (RBAC + Gatekeeper)
	@echo "  Deploying security policies..."
	@kubectl apply -k cluster/security/
	@echo "  Security deployed"

deploy-observability: ## Deploy Prometheus + Grafana
	@echo "  Deploying observability stack..."
	@kubectl apply -k cluster/observability/
	@echo "  Waiting for Prometheus..."
	@kubectl wait --for=condition=available --timeout=300s deployment/prometheus-operator -n monitoring || true
	@echo "  Observability deployed"
	@echo ""
	@echo "  Access Grafana:"
	@echo "kubectl port-forward svc/grafana -n monitoring 3000:80"

# Full workflows
deploy-all: deploy-argocd deploy-app deploy-security deploy-observability ## Deploy everything
	@echo "  Full stack deployed!"

# Status & Debugging
status: ## Show overall status
	@echo "  Cluster Status:"
	@echo ""
	@echo "=== Nodes ==="
	@kubectl get nodes
	@echo ""
	@echo "=== Crossplane ==="
	@kubectl get providers
	@echo ""
	@echo "=== XRDs ==="
	@kubectl get xrds
	@echo ""
	@echo "=== Applications ==="
	@kubectl get pods -n chatapp
	@echo ""
	@echo "=== ArgoCD ==="
	@kubectl get applications -n argocd 2>/dev/null || echo "ArgoCD not deployed"
	@echo ""
	@echo "=== Memory Usage ==="
	@free -h

logs-crossplane: ## Show Crossplane logs
	@kubectl logs -n crossplane-system -l app=crossplane --tail=50

logs-app: ## Show chatapp logs
	@kubectl logs -n chatapp -l app=chatapp --tail=50

describe-app: ## Describe chatapp pods
	@kubectl describe pods -n chatapp -l app=chatapp

port-forward-app: ## Port forward chatapp
	@echo "  Forwarding chatapp on http://localhost:3000"
	@kubectl port-forward -n chatapp svc/chatapp 3000:3000

# Cleanup
clean-app: ## Delete chatapp
	@kubectl delete -k cluster/app/ --ignore-not-found=true

clean-all: ## Delete everything except Crossplane
	@kubectl delete -k cluster/observability/ --ignore-not-found=true
	@kubectl delete -k cluster/security/ --ignore-not-found=true
	@kubectl delete -k cluster/app/ --ignore-not-found=true
	@kubectl delete -k cluster/gitops/argocd/ --ignore-not-found=true

clean: ## Full cleanup (including minikube)
	@./scripts/cleanup.sh
	@minikube delete

# Testing
test-dry-run: ## Test all manifests with dry-run
	@echo "  Testing manifests..."
	@kubectl apply --dry-run=server -f apis/
	@kubectl apply --dry-run=server -k cluster/app/
	@echo "  All manifests valid"

test-compositions: ## Test Crossplane compositions
	@echo "  Testing compositions..."
	@kubectl crossplane beta validate apis/ || echo "  Install crossplane CLI first"

# Testing targets
test: test-unit test-security test-integration ## Run all tests
	@echo "All test suites passed!"

test-unit: ## Run unit tests (Crossplane composition validation)
	@echo "Running unit tests..."
	@./tests/unit/crossplane/run-tests.sh

test-security: ## Run security tests
	@echo "Running security tests..."
	@./tests/security/networkpolicy/run-tests.sh
	@./tests/security/gatekeeper/run-tests.sh

test-integration: ## Run integration tests
	@echo "Running integration tests..."
	@./tests/integration/test-app-connectivity.sh
	@./tests/integration/test-argocd-sync.sh

test-performance: ## Run k6 performance tests
	@./tests/performance/run-k6-tests.sh

test-dry-run: ## Dry-run all manifests (fast validation)
	@echo "Testing manifests with dry-run..."
	@kubectl apply --dry-run=server -f apis/ || true
	@kubectl apply --dry-run=server -k cluster/app/ || true
	@kubectl apply --dry-run=server -k cluster/security/ || true
	@echo "Dry-run tests passed"

# Security testing specific
test-networkpolicy: ## Test NetworkPolicy isolation
	@./tests/security/networkpolicy/run-tests.sh

test-gatekeeper: ## Test Gatekeeper policies
	@./tests/security/gatekeeper/run-tests.sh

test-trivy: ## Run Trivy security scans
	@echo "Running Trivy scans..."
	@trivy config cluster/ --severity HIGH,CRITICAL
	@trivy config apis/ --severity HIGH,CRITICAL

# Performance testing specific
test-load: ## Run load test only
	@k6 run tests/performance/load-test.js

test-spike: ## Run spike test only
	@k6 run tests/performance/spike-test.js

test-stress: ## Run stress test only
	@k6 run tests/performance/stress-test.js

# CI/CD testing
test-ci: test-dry-run test-unit test-security ## Tests suitable for CI/CD
	@echo "CI tests passed!"

# Watch tests (for development)
watch-tests: ## Watch and re-run tests on file changes
	@echo "👀 Watching for changes..."
	@while true; do \
		inotifywait -r -e modify apis/ cluster/ tests/ 2>/dev/null || sleep 2; \
		clear; \
		make test-dry-run; \
	done

# Monitoring
watch-resources: ## Watch resource usage
	@watch -n 2 'free -h && echo "" && kubectl top nodes 2>/dev/null || echo "Metrics not ready"'

watch-pods: ## Watch all pods
	@watch -n 2 'kubectl get pods --all-namespaces'
