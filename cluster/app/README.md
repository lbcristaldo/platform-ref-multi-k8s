# Chatapp In-Cluster Deployment

This deploys the chatapp with MongoDB and Redis running in-cluster (not managed services).

## Architecture

```
chatapp (2 replicas)
├─ MongoDB StatefulSet (1 replica)
└─ Redis Deployment (1 replica)
```

## Resource Allocation

| Component | Request | Limit | Count | Total Request |
|-----------|---------|-------|-------|---------------|
| MongoDB   | 256Mi   | 512Mi | 1     | 256Mi         |
| Redis     | 128Mi   | 256Mi | 1     | 128Mi         |
| Chatapp   | 128Mi   | 256Mi | 2     | 256Mi         |
| **Total** |         |       |       | **640Mi**     |

## Access the app

```bash
# Port forward
kubectl port-forward -n chatapp svc/chatapp 3000:3000

# Or use minikube service
minikube service chatapp -n chatapp
```

## Phase 2 TODO

- [ ] Fork naushad91/scalable-chatapp
- [ ] Add healthchecks (/health, /ready)
- [ ] Build multi-stage Dockerfile
- [ ] Push to registry
- [ ] Update deployment to use real image
