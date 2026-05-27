# MISP Kubernetes Deployment

**Jira:** ISM-15510 | **GitLab:** https://gitlab.com/devo_corp/engineering/infra-deployment/misp
**Status:** Initial Draft (2026-04-20) — Kubernetes migration from legacy EC2 Docker instance

## Architecture

MISP StatefulSet + MySQL (50Gi) + Redis (10Gi) + Lookup Generator CronJob (daily 00:00 UTC)
Clusters: **Hydra** (US, prod) or **Cerberus** | Namespace: `misp-prod`

## Components

| Component | Image | Notes |
|-----------|-------|-------|
| MISP Server | `docker.devo.internal/devo/misp:latest` | Apache/PHP, port 443 |
| MySQL | `mysql:8.0` | Database: `misp`, 50Gi PV |
| Redis | `redis:7-alpine` | Background jobs, 10Gi PV |
| Lookup Generator | `docker.devo.internal/devo/misp-lookup-generator:v1.0.0` | PyMISP → CSV → Devo lookups |

## Helm Deploy

```bash
# Create namespace + secrets
kubectl create namespace misp-prod
kubectl create secret generic misp-secrets \
  --from-literal=mysql-root-password='CHANGE_ME' \
  --from-literal=misp-admin-password='CHANGE_ME' \
  --from-literal=devo-api-key='YOUR_DEVO_API_KEY' \
  -n misp-prod

# Deploy
helm install misp ./helm -n misp-prod -f helm/values-prod.yaml

# Or with raw manifests
kubectl apply -f k8s-manifests/
```

## Verification & Ops

```bash
# Pod/service status
kubectl get pods -n misp-prod
kubectl get svc -n misp-prod

# Pod logs
kubectl logs -n misp-prod deployment/misp-server

# MySQL connectivity check
kubectl exec -it -n misp-prod mysql-0 -- mysql -u root -p

# Redis check
kubectl exec -it -n misp-prod redis-0 -- redis-cli ping

# Manual lookup generation trigger
kubectl create job --from=cronjob/misp-lookup-generator manual-run-$(date +%s) -n misp-prod

# Lookup generator job logs
kubectl logs -n misp-prod job/misp-lookup-generator-<timestamp>

# Backup MySQL
scripts/backup-mysql.sh misp-prod

# Upgrade MISP
scripts/upgrade.sh v2.0.1
```

## Production Config (US)

```yaml
# helm/values-prod.yaml
environment: production
region: us-east-1
replicas: 2
resources:
  misp:   { requests: {cpu: 2, memory: 4Gi}, limits: {cpu: 4, memory: 8Gi} }
  mysql:  { requests: {cpu: 2, memory: 4Gi}, limits: {cpu: 4, memory: 8Gi} }
```

APAC: `helm/values-apac.yaml` — `region: ap-southeast-1`, `replicas: 1`

## Directory Structure

```
misp/
├── helm/               # Helm chart (Chart.yaml, values.yaml, values-prod.yaml, templates/)
├── k8s-manifests/      # Raw K8s manifests (alternative to Helm)
├── docker/
│   ├── misp-server/    # Dockerfile + scripts
│   └── lookup-generator/ # Dockerfile, create-lookups.py, json2lookups.py, requirements.txt
├── scripts/            # deploy.sh, upgrade.sh, backup-mysql.sh, test-lookup-generation.sh
└── docs/               # ARCHITECTURE.md, MONITORING.md, TROUBLESHOOTING.md
```

## Legacy Migration

- Old: `misp.devo.com` (EC2, manual Docker)
- New: Kubernetes StatefulSet with Prometheus/Dynatrace/Grafana monitoring
