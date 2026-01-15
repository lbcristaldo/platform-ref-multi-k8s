# Testing Strategy

## Testing Layers

```
tests/
├── unit/               # Crossplane composition validation
├── integration/        # Multi-component interactions
├── security/           # Security policy testing
├── performance/        # Load testing with k6
└── e2e/               # End-to-end workflows
```

## Test Categories

### 1. Configuration Testing
- XRD schema validation
- Composition rendering
- Resource patching logic
- RBAC permissions

### 2. Security Testing
- NetworkPolicy effectiveness
- Gatekeeper policy enforcement
- Container security scanning
- Secret management

### 3. Integration Testing
- App → Database connectivity
- App → Cache connectivity
- ArgoCD sync workflows
- KEDA autoscaling triggers

### 4. Performance Testing
- Load testing with k6
- Resource usage under load
- Autoscaling behavior
- Database connection pooling

## Running Tests

```bash
# All tests
make test

# Specific categories
make test-unit
make test-security
make test-integration
make test-performance
```
