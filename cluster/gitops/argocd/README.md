# ArgoCD Light Configuration

This is a resource-optimized ArgoCD installation for systems with 8GB RAM.

## Access ArgoCD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser
https://localhost:8080
# User: admin
# Password: (from command above)
```

## Resource Usage

- argocd-server: 128Mi request, 256Mi limit
- argocd-repo-server: 128Mi request, 256Mi limit
- argocd-application-controller: 128Mi request, 256Mi limit

Total: ~384Mi RAM baseline
