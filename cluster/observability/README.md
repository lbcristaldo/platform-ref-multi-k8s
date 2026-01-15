# Observability Stack (Light)

## Components

- **Prometheus**: Metrics collection (400Mi-800Mi)
- **Grafana**: Visualization (100Mi-200Mi)
- **Node Exporter**: Host metrics (50Mi-100Mi)
- **Alertmanager**: Alert routing (100Mi-200Mi)

Total: ~650Mi-1300Mi RAM

## Installation

```bash
# Install via Helm (recommended for observability)
kubectl apply -f cluster/observability/namespace.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.resources.requests.memory=400Mi \
  --set prometheus.prometheusSpec.resources.limits.memory=800Mi \
  --set alertmanager.alertmanagerSpec.resources.requests.memory=100Mi \
  --set alertmanager.alertmanagerSpec.resources.limits.memory=200Mi \
  --set grafana.resources.requests.memory=100Mi \
  --set grafana.resources.limits.memory=200Mi \
  --set prometheus-node-exporter.resources.requests.memory=50Mi \
  --set prometheus-node-exporter.resources.limits.memory=100Mi
```

## Access

### Grafana
```bash
# Get admin password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d

# Port forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open http://localhost:3000
# User: admin
# Password: (from command above)
```

### Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open http://localhost:9090
```

## Custom Dashboards

Add chatapp metrics:
```bash
kubectl apply -f cluster/observability/prometheus/servicemonitor-chatapp.yaml
kubectl apply -f cluster/observability/grafana/dashboards/chatapp-dashboard.yaml
```

## Resource Usage

Monitor observability stack itself:
```bash
kubectl top pods -n monitoring
```

If memory is tight, you can disable Alertmanager:
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set alertmanager.enabled=false \
  --reuse-values
```
