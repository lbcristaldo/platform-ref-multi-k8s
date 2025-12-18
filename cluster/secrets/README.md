# Secret Management

## ⚠️ NEVER COMMIT ACTUAL SECRETS

This directory contains **example** secret templates. In production, use one of these approaches:

### Option 1: SealedSecrets (Recommended for GitOps)

```bash
# Install sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create a secret
kubectl create secret generic documentdb-admin-password \
  --from-literal=password=$(openssl rand -base64 32) \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > documentdb-password-sealed.yaml

# Commit the sealed secret (safe to commit)
git add documentdb-password-sealed.yaml
git commit -m "sec(secrets): add DocumentDB sealed secret"
```

### Option 2: External Secrets Operator

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: documentdb-admin-password
  namespace: crossplane-system
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: documentdb-admin-password
  data:
    - secretKey: password
      remoteRef:
        key: prod/documentdb/admin-password
```

### Option 3: HashiCorp Vault

```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: documentdb-admin-password
  namespace: crossplane-system
spec:
  vaultAuthRef: vault-auth
  mount: secret
  path: database/documentdb/admin
  destination:
    name: documentdb-admin-password
    create: true
  refreshAfter: 1h
```

## Local Development

For local testing only:

```bash
# Generate secure passwords
export DOCDB_PASSWORD=$(openssl rand -base64 32)
export REDIS_TOKEN=$(openssl rand -base64 32)

# Create secrets locally (NOT for production)
kubectl create secret generic documentdb-admin-password \
  --from-literal=password=$DOCDB_PASSWORD \
  -n crossplane-system

kubectl create secret generic elasticache-auth-token \
  --from-literal=token=$REDIS_TOKEN \
  -n crossplane-system

# Verify (without showing values)
kubectl get secrets -n crossplane-system
```

## Production Checklist

- [ ] Secrets encrypted at rest in etcd
- [ ] Secrets never committed to Git
- [ ] Using SealedSecrets, ESO, or Vault
- [ ] Rotation policy implemented
- [ ] Access audited via RBAC
- [ ] Backup includes secret recovery process

## Secret Rotation

DocumentDB and ElastiCache support secret rotation. Example with AWS Secrets Manager:

```bash
# Enable rotation for DocumentDB
aws secretsmanager rotate-secret \
  --secret-id prod/documentdb/admin-password \
  --rotation-lambda-arn arn:aws:lambda:REGION:ACCOUNT:function:SecretsManagerRotation \
  --rotation-rules AutomaticallyAfterDays=30
```
