# Security Layer

## Components

1. **RBAC**: Role-Based Access Control per namespace
2. **NetworkPolicies**: Default-deny + explicit allow rules
3. **Gatekeeper**: OPA policy enforcement

## Policies Enforced

### NetworkPolicies
- Default deny all traffic
- Explicit allow chatapp → mongodb (port 27017)
- Explicit allow chatapp → redis (port 6379)
- Allow external → chatapp (port 3000)
- Allow DNS egress

### Gatekeeper Policies
- All containers must have resource limits
- No :latest image tags allowed
- Images must have explicit tags

## Testing

```bash
# Deploy security
make deploy-security

# Test policies
kubectl apply -f cluster/security/gatekeeper/test-policy.yaml

# View violations
kubectl get k8scontainerlimits
kubectl get k8simagelatest
```
