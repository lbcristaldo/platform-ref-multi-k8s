# Contributing Guidelines

## ⋆.ᡣ𐭩.𖥔 Project Philosophy

This project is a **portfolio-driven learning journey** with production-quality standards. Each commit tells a story of architectural evolution from reference platform to enterprise-ready system.

## Commit Strategy

### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature or capability
- `infra`: Infrastructure/Crossplane changes
- `sec`: Security improvements
- `ci`: CI/CD pipeline changes
- `obs`: Observability additions
- `docs`: Documentation only
- `test`: Testing additions
- `fix`: Bug fixes

**Scopes:**
- `crossplane`: XRDs and compositions
- `gitops`: ArgoCD configurations
- `app`: Chat application changes
- `pipeline`: Tekton/CI changes
- `security`: Istio/Cilium/Gatekeeper
- `observability`: Prometheus/Grafana/Loki
- `autoscaling`: KEDA configurations

**Examples:**
```
feat(crossplane): add DocumentDB composition for AWS

- XRD for managed MongoDB databases
- Composition creates AWS DocumentDB cluster
- Connection secrets stored in app namespace
- Supports automated backups and encryption

Relates-to: #12

---

sec(security): implement default-deny network policies

- Cilium NetworkPolicies per namespace
- Whitelist app-to-db traffic only
- Block all ingress by default
- Add Gatekeeper policy to enforce

Closes: #23

---

ci(pipeline): add Trivy security scanning stage

- Scan Docker images for CVEs
- Scan IaC manifests for misconfigurations
- Fail pipeline on HIGH/CRITICAL findings
- Generate SARIF reports for GitHub Security

Closes: #15
```

## Branch Strategy

```
main                    # Production-ready state
├── phase-1-foundation  # Commits 1-4
├── phase-2-app         # Commits 5-8
├── phase-3-cicd        # Commits 9-12
├── phase-4-security    # Commits 13-17
├── phase-5-observability # Commits 18-21
├── phase-6-autoscaling # Commits 22-25
├── phase-7-multicloud  # Commits 26-29
└── phase-8-production  # Commits 30-33
```

**Workflow:**
1. Create phase branch from `main`
2. Work on commits sequentially
3. Merge phase branch to `main` when complete
4. Tag major milestones: `v0.1.0-foundation`, `v0.2.0-app`, etc.

## PR Checklist

Before submitting a PR:

- [ ] Commit follows message format
- [ ] Changes align with current phase objectives
- [ ] Manifests pass validation: `kubectl apply --dry-run=client -f`
- [ ] Documentation updated (README, ADRs, runbooks)
- [ ] No secrets committed (use SealedSecrets placeholders)
- [ ] Trivy scan passes locally (if applicable)
- [ ] Load tests run successfully (if applicable)

## Testing Requirements

### Infrastructure Changes
```bash
# Validate Crossplane compositions
kubectl crossplane build configuration
kubectl crossplane validate configuration

# Test XRD instantiation
kubectl apply -f examples/test-claim.yaml --dry-run=server
```

### Application Changes
```bash
# Lint Kubernetes manifests
kubectl apply --dry-run=client -k cluster/app/

# Test Dockerfile builds
docker build -f pipelines/dockerfiles/Dockerfile.chatapp .

# Run unit tests
npm test
```

### Security Changes
```bash
# Validate Gatekeeper policies
gator test tests/gatekeeper/

# Test NetworkPolicies
kubectl apply -f cluster/security/network-policies/ --dry-run=server
```

## Architecture Decision Records (ADRs)

For significant architectural choices, create an ADR:

```bash
# Template
cp docs/architecture/decisions/000-template.md \
   docs/architecture/decisions/XXX-your-decision.md
```

**Format:**
```markdown
# ADR-XXX: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
Why does this decision need to be made?

## Decision
What is the change we're proposing?

## Consequences
### Positive
- Benefit 1
- Benefit 2

### Negative
- Trade-off 1
- Trade-off 2

### Risks
- Risk 1 and mitigation
- Risk 2 and mitigation

## Alternatives Considered
1. Option A: Why rejected
2. Option B: Why rejected
```

## Code Review Standards

Reviewers check:

1. **Alignment**: Does this fit the roadmap phase?
2. **Security**: Any credentials, default passwords, or :latest tags?
3. **Observability**: Are metrics/logs exposed properly?
4. **Documentation**: Is the "why" explained?
5. **Reusability**: Can this be templatized for other apps?

## Anti-Patterns to Avoid

- Hardcoded IPs or credentials
- Docker images with `:latest` tag
- Running containers as root
- Missing resource limits
- No health/readiness probes
- Secrets in ConfigMaps
- Overly complex one-liner scripts without comments

## Best Practices

- Use Crossplane for managed services
- Store configs in Git, secrets in SealedSecrets
- Default-deny networking, explicit allowlists
- Multi-stage Dockerfiles (build vs runtime)
- Structured JSON logging
- Prometheus metrics on `/metrics`
- Graceful shutdown handlers

## Questions or Issues?

- Open an issue with the `question` label
- Reference the relevant phase in your issue title
- Provide context: what you're trying to achieve and what's blocking you

## Learning Goals

This project is designed to demonstrate:

1. **Multi-cloud proficiency**: Not just using one cloud, but orchestrating across them
2. **Security mindset**: Compliance and hardening aren't afterthoughts
3. **Operational excellence**: Observability, autoscaling, and reliability built-in
4. **DevOps maturity**: GitOps, IaC, automated testing, and progressive delivery

Every commit should advance at least one of these goals.

---

**Remember**: This project is both a technical implementation AND a portfolio narrative. Write commits and docs with future employers in mind.
