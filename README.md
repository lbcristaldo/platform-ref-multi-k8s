# Enterprise Multi-Cloud Chat Platform

> **Transforming an open-source reference platform into a production-ready, secure, and observable multi-cloud architecture**

## Project Overview

This project demonstrates the evolution of [upbound/platform-ref-multi-k8s](https://github.com/upbound/platform-ref-multi-k8s) from a basic Crossplane reference into a complete enterprise platform, featuring:

- **Multi-cloud infrastructure** governed by a single control plane
- **Security-first design** with defense-in-depth (Cilium, Istio, Gatekeeper, Trivy)
- **GitOps workflows** with ArgoCD
- **Multi-stage CI/CD pipelines** (Tekton + optimized Dockerfiles)
- **Event-driven autoscaling** (KEDA)
- **Full observability** (Prometheus, Grafana, Loki, Tempo)
- **Real workload**: [scalable-chatapp](https://github.com/naushad91/scalable-chatapp) running across multiple clouds

### Why This Matters

Most tutorials show toy examples in single clouds. This project tackles real enterprise challenges:
- How do you manage MongoDB and Redis across AWS/GCP/Azure?
- How do you ensure security compliance before code reaches production?
- How do you scale WebSocket workloads dynamically?
- How do you maintain observability across distributed systems?

## Architecture Principles

### 1. Infrastructure Layer
- **Crossplane**: Control plane for multi-cloud resource provisioning
- **Managed Services**: DocumentDB (AWS), Cloud Memorystore (GCP), CosmosDB (Azure)
- **GitOps**: ArgoCD for declarative deployments

### 2. Security Layer
- **RBAC + Namespaces**: Environment isolation (dev/staging/prod)
- **Cilium + NetworkPolicies**: Default-deny networking with label selectors
- **Istio mTLS (STRICT)**: Encrypted service mesh traffic
- **Gatekeeper (OPA)**: Policy enforcement (no :latest tags, runAsNonRoot, required labels)
- **Trivy**: Container image and IaC scanning in pipelines

### 3. CI/CD Layer (Multi-Stage)
- **Tekton Pipelines**:
  - Stage 1: Build optimized image (multi-stage Dockerfile)
  - Stage 2: Security scan (Trivy)
  - Stage 3: Load test (k6)
  - Stage 4: Sign & push to registry
  - Stage 5: Deploy via ArgoCD
- **Dockerfiles**: Build in full image, run in distroless

### 4. Scalability Layer
- **KEDA**: Event-driven autoscaling (Redis pub/sub lag, CPU metrics)
- **Karpenter** (demo): Dynamic node provisioning
- **Descheduler**: Pod optimization on saturated nodes

### 5. Observability Layer
- **Prometheus + Grafana**: Federated metrics across clusters
- **Loki + Tempo**: Distributed logs and traces with end-to-end correlation
- **Dashboards**: SLOs, security posture, autoscaling behavior, CI/CD metrics

### 6. Application Layer
- **Base App**: Distributed chat (Node.js, Socket.IO, MongoDB, Redis)
- **Multi-cloud Deployment**: Replicas across clusters, load-balanced by Istio
- **Crossplane-Managed**: DBs and queues provisioned per environment

## Repository Structure

```
platform-ref-multi-k8s/
├── apis/
│   ├── cluster/              # Crossplane XRDs for K8s clusters
│   ├── database/             # NEW: MongoDB compositions (DocumentDB, CosmosDB)
│   └── cache/                # NEW: Redis compositions (ElastiCache, Memorystore)
├── cluster/
│   ├── gitops/               # NEW: ArgoCD installation
│   ├── security/             # NEW: Cilium, Istio, Gatekeeper configs
│   ├── observability/        # NEW: Prometheus, Grafana, Loki stack
│   └── app/                  # NEW: Chat app manifests
├── pipelines/
│   ├── tekton/               # NEW: CI/CD pipeline definitions
│   └── dockerfiles/          # NEW: Multi-stage Dockerfiles
├── examples/
│   ├── aws-cluster.yaml
│   ├── gcp-cluster.yaml
│   └── chatapp-claim.yaml    # NEW: App resource claims
├── tests/
│   └── k6/                   # NEW: Load testing scenarios
└── docs/
    ├── architecture/         # NEW: Diagrams and design decisions
    ├── security/             # NEW: Compliance and threat model
    └── runbooks/             # NEW: Troubleshooting guides
```

## Implementation Roadmap

### Phase 1: Foundation (Commits 1-4)
- [x] Fork baseline + project documentation
- [ ] Crossplane compositions for managed databases (DocumentDB, CosmosDB)
- [ ] Crossplane compositions for managed cache (ElastiCache, Memorystore)
- [ ] ArgoCD installation + GitOps structure

### Phase 2: Application Bootstrap (Commits 5-8)
- [ ] Fork [scalable-chatapp](https://github.com/naushad91/scalable-chatapp)
- [ ] Add healthchecks and graceful shutdown
- [ ] Multi-stage Dockerfile (Node.js → distroless)
- [ ] Basic Kubernetes manifests (Deployment, Service, Ingress)

### Phase 3: CI/CD Pipeline (Commits 9-12)
- [ ] Tekton installation
- [ ] Build pipeline (multi-stage Docker build)
- [ ] Security scanning (Trivy for images + IaC)
- [ ] k6 load testing stage
- [ ] ArgoCD integration (automated sync on pipeline success)

### Phase 4: Security Hardening (Commits 13-17)
- [ ] RBAC policies per namespace
- [ ] Cilium installation + default-deny NetworkPolicies
- [ ] Istio service mesh with mTLS STRICT
- [ ] Gatekeeper policy pack (OPA)
- [ ] SealedSecrets or Vault integration

### Phase 5: Observability (Commits 18-21)
- [ ] Prometheus + Grafana stack
- [ ] Loki for log aggregation
- [ ] Tempo for distributed tracing
- [ ] Custom dashboards (app SLOs, security metrics, autoscaling)

### Phase 6: Autoscaling (Commits 22-25)
- [ ] KEDA installation
- [ ] Redis scaler for chat backend
- [ ] CPU-based scaler for stateless components
- [ ] Karpenter demo (AWS-specific node autoscaling)
- [ ] Descheduler for pod optimization

### Phase 7: Multi-Cloud Expansion (Commits 26-29)
- [ ] EKS cluster composition + deployment
- [ ] GKE cluster composition + deployment
- [ ] Cross-cluster Istio mesh (multi-primary)
- [ ] Load testing across regions

### Phase 8: Production Readiness (Commits 30-33)
- [ ] Disaster recovery with Velero
- [ ] Cost analysis dashboard (Kubecost/OpenCost)
- [ ] Chaos engineering experiments (Litmus Chaos)
- [ ] Complete documentation + architecture diagrams

## Local Development

### Prerequisites
- Kubernetes cluster (kind/minikube for local testing)
- kubectl, helm, crossplane CLI
- AWS/GCP/Azure credentials configured

### Quick Start
```bash
# 1. Install Crossplane
kubectl apply -f cluster/crossplane/

# 2. Configure cloud providers
kubectl apply -f examples/provider-config-aws.yaml

# 3. Deploy ArgoCD
kubectl apply -k cluster/gitops/argocd/

# 4. Create a cluster claim
kubectl apply -f examples/aws-cluster.yaml

# 5. Deploy the chat app
kubectl apply -f examples/chatapp-claim.yaml
```

## Key Metrics & Dashboards

- **Uptime SLO**: 99.9% availability target
- **Latency P95**: < 200ms for message delivery
- **Autoscaling**: KEDA triggers at 80% Redis pub/sub lag
- **Security**: 100% Gatekeeper policy compliance
- **Cost**: Per-namespace resource utilization tracking

## Testing Strategy

### Load Testing (k6)
```bash
k6 run tests/k6/websocket-spike.js \
  --vus 500 \
  --duration 5m
```

### Security Scanning
```bash
# Scan Dockerfiles
trivy config pipelines/dockerfiles/

# Scan running images
trivy image chatapp:latest
```

### Chaos Testing
```bash
# Pod deletion experiment
kubectl apply -f tests/chaos/pod-delete.yaml
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- Commit message conventions
- Branch naming strategy
- PR review process

## Learning Resources

Each major architectural decision is documented in `docs/architecture/decisions/` using ADRs (Architecture Decision Records).

Key documents:
- [ADR-001: Why Crossplane over Terraform](docs/architecture/decisions/001-crossplane-vs-terraform.md)
- [ADR-002: Flux vs ArgoCD selection](docs/architecture/decisions/002-gitops-tool-choice.md)
- [ADR-003: Multi-stage pipeline design](docs/architecture/decisions/003-pipeline-stages.md)

## Project Status

**Current Phase**: Foundation (Phase 1)  
**Last Updated**: December 2025  
**Production Ready**: Target Q1 2026

## License

This project extends [upbound/platform-ref-multi-k8s](https://github.com/upbound/platform-ref-multi-k8s) under Apache 2.0.

---

**Built with**: Crossplane • ArgoCD • Tekton • Istio • KEDA • Prometheus • k6
