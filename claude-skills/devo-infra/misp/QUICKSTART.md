# MISP Kubernetes Deployment - Quick Start

**Status:** ✅ Phase 1 Complete - All files created, ready for Phase 2 (Build & Test)

---

## What We Have

Complete Kubernetes-based MISP deployment infrastructure:

```
~/.claude/skills/devo-infra/misp/
├── README.md                       # Architecture overview
├── DEPLOYMENT-PLAN.md              # 10-day phased deployment plan
├── DEPLOYMENT-STATUS.md            # Current status tracker
├── QUICKSTART.md                   # This file
│
├── docker/
│   ├── misp-server/                # MISP server Docker image
│   │   ├── Dockerfile
│   │   └── scripts/                # Startup scripts
│   └── lookup-generator/           # Lookup generation Docker image
│       ├── Dockerfile
│       ├── requirements.txt
│       ├── generate-misp-lookup.sh
│       ├── create-lookups.py
│       └── json2lookups.py
│
├── k8s-manifests/                  # Kubernetes resources
│   ├── namespace.yaml              # misp-prod namespace
│   ├── storage.yaml                # PVCs (MySQL 100Gi, Redis 20Gi, MISP files 50Gi)
│   ├── configmap.yaml              # Configuration
│   ├── secrets.yaml.template       # Secret templates (fill before use)
│   ├── mysql-statefulset.yaml      # MySQL database
│   ├── redis-statefulset.yaml      # Redis cache
│   ├── misp-deployment.yaml        # MISP server (2 replicas)
│   ├── lookup-cronjob.yaml         # Daily lookup generation (00:00 UTC)
│   ├── services.yaml               # LoadBalancer + ClusterIP services
│   ├── ingress.yaml                # NGINX ingress (misp.internal.devo.com)
│   └── monitoring/
│       ├── servicemonitor.yaml     # Prometheus exporters (MISP, MySQL, Redis)
│       ├── prometheus-rules.yaml   # 15 alert rules
│       └── grafana-dashboard.json  # 13-panel dashboard
│
└── scripts/                        # Deployment automation
    ├── deploy.sh                   # One-command deployment
    ├── backup-mysql.sh             # Database backup
    ├── restore-mysql.sh            # Database restore
    └── test-lookup-generation.sh   # Test lookup generation

Total: 32 files created
```

---

## Phase 2: Build & Deploy (Next Steps)

### Step 1: Build Docker Images

```bash
cd ~/.claude/skills/devo-infra/misp

# Build MISP server image
cd docker/misp-server
docker build -t docker.devo.internal/devo/misp:v2.0.0 .
docker push docker.devo.internal/devo/misp:v2.0.0

# Build lookup generator image
cd ../lookup-generator
docker build -t docker.devo.internal/devo/misp-lookup-generator:v1.0.0 .
docker push docker.devo.internal/devo/misp-lookup-generator:v1.0.0
```

### Step 2: Create Kubernetes Secrets

```bash
cd ~/.claude/skills/devo-infra/misp/k8s-manifests

# Generate strong passwords
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_MISP_PASSWORD=$(openssl rand -base64 32)
MISP_ADMIN_PASSWORD=$(openssl rand -base64 32)

# Create MySQL secret
source ~/.zshrc && kube create secret generic misp-mysql-secret \
  --from-literal=root-password="${MYSQL_ROOT_PASSWORD}" \
  --from-literal=misp-db-password="${MYSQL_MISP_PASSWORD}" \
  -n misp-prod

# Create MISP admin secret
source ~/.zshrc && kube create secret generic misp-admin-secret \
  --from-literal=admin-email='misp-admin@devo.com' \
  --from-literal=admin-password="${MISP_ADMIN_PASSWORD}" \
  -n misp-prod

# Create Devo API secret (get credentials from Devo platform)
source ~/.zshrc && kube create secret generic devo-api-secret \
  --from-literal=api-key='YOUR_DEVO_API_KEY' \
  --from-literal=api-secret='YOUR_DEVO_API_SECRET' \
  --from-literal=api-url='https://apiv2-us.devo.com' \
  -n misp-prod

# Save credentials securely
echo "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" > ~/.misp-credentials
echo "MYSQL_MISP_PASSWORD=${MYSQL_MISP_PASSWORD}" >> ~/.misp-credentials
echo "MISP_ADMIN_PASSWORD=${MISP_ADMIN_PASSWORD}" >> ~/.misp-credentials
chmod 600 ~/.misp-credentials
```

### Step 3: Deploy to Kubernetes

```bash
cd ~/.claude/skills/devo-infra/misp/scripts

# Run automated deployment
./deploy.sh

# Or deploy manually:
source ~/.zshrc && kube apply -f ../k8s-manifests/namespace.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/configmap.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/storage.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/mysql-statefulset.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/redis-statefulset.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/misp-deployment.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/services.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/ingress.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/lookup-cronjob.yaml
source ~/.zshrc && kube apply -f ../k8s-manifests/monitoring/
```

### Step 4: Configure DNS

```bash
# Get LoadBalancer IP
LOADBALANCER_IP=$(source ~/.zshrc && kube get svc misp-server -n misp-prod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Update DNS: misp.internal.devo.com → ${LOADBALANCER_IP}"

# Or use hostname (AWS)
LOADBALANCER_HOSTNAME=$(source ~/.zshrc && kube get svc misp-server -n misp-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Create CNAME: misp.internal.devo.com → ${LOADBALANCER_HOSTNAME}"
```

### Step 5: Initial MISP Setup

```bash
# Access MISP web interface
open https://misp.internal.devo.com

# Default credentials (change immediately)
Username: admin@admin.test
Password: admin

# After login:
# 1. Change admin password (use password from misp-admin-secret)
# 2. Set MISP.baseurl: https://misp.internal.devo.com
# 3. Configure email settings
# 4. Enable background workers
# 5. Add MISP feeds (CIRCL OSINT, Botvrij.eu, URLhaus, etc.)
# 6. Generate API key for lookup generation
```

### Step 6: Configure Lookup Generation

```bash
# Get API key from MISP web interface
# Administration > List Auth Keys > Add Authentication Key

# Update secret with MISP API key
source ~/.zshrc && kube patch secret misp-admin-secret -n misp-prod \
  --type merge \
  -p '{"stringData":{"api-key":"YOUR_MISP_API_KEY"}}'

# Test lookup generation manually
cd ~/.claude/skills/devo-infra/misp/scripts
./test-lookup-generation.sh
```

### Step 7: Verify Lookup in Devo

```bash
# Query Devo to verify lookup exists
from lookup.mispIndicator
group
select count() as total_indicators

# Expected: 10M-20M indicators (similar to legacy lookup)
```

---

## Monitoring

### Prometheus Metrics

```bash
# View ServiceMonitors
source ~/.zshrc && kube get servicemonitor -n misp-prod

# Check Prometheus targets
# Navigate to Prometheus UI → Status → Targets
# Should see: misp-metrics, mysql-metrics, redis-metrics
```

### Grafana Dashboard

```bash
# Import dashboard
source ~/.zshrc && kube apply -f k8s-manifests/monitoring/grafana-dashboard.json

# View in Grafana:
# Dashboards → MISP Threat Intelligence Platform
```

### Alert Rules

```bash
# View PrometheusRules
source ~/.zshrc && kube get prometheusrules -n misp-prod

# 15 alerts configured:
# - MISPServerDown, MISPServerHighResponseTime
# - MySQLDown, MySQLHighConnections, MySQLSlowQueries
# - RedisDown, RedisHighMemoryUsage
# - LookupGenerationFailed, LookupGenerationNotRun
# - MISPHighMemoryUsage, MISPHighCPUUsage, MISPPodRestarting
```

---

## Useful Commands

### Check Deployment Status

```bash
# All resources
source ~/.zshrc && kube get all -n misp-prod

# Pods
source ~/.zshrc && kube get pods -n misp-prod

# Services
source ~/.zshrc && kube get svc -n misp-prod

# Ingress
source ~/.zshrc && kube get ingress -n misp-prod

# CronJobs
source ~/.zshrc && kube get cronjob -n misp-prod
```

### View Logs

```bash
# MISP server
source ~/.zshrc && kube logs -f deployment/misp-server -n misp-prod

# MySQL
source ~/.zshrc && kube logs -f statefulset/mysql -n misp-prod

# Redis
source ~/.zshrc && kube logs -f statefulset/redis -n misp-prod

# Lookup generation (latest job)
source ~/.zshrc && kube logs -f job/misp-lookup-generator-XXXXX -n misp-prod
```

### Database Operations

```bash
# Backup
./scripts/backup-mysql.sh

# Restore
./scripts/restore-mysql.sh misp-backup-YYYYMMDD-HHMMSS.sql.gz

# Connect to MySQL
source ~/.zshrc && kube exec -it mysql-0 -n misp-prod -- mysql -u root -p
```

### Scaling

```bash
# Scale MISP replicas
source ~/.zshrc && kube scale deployment misp-server --replicas=3 -n misp-prod

# Check replica status
source ~/.zshrc && kube get pods -l app=misp-server -n misp-prod
```

---

## Troubleshooting

### MISP Not Starting

```bash
# Check init containers
source ~/.zshrc && kube describe pod -l app=misp-server -n misp-prod

# Check logs
source ~/.zshrc && kube logs -f deployment/misp-server -n misp-prod --previous

# Common issues:
# - MySQL not ready (wait for mysql-0 pod)
# - Redis not ready (wait for redis-0 pod)
# - Secrets missing (create secrets first)
```

### Lookup Generation Failing

```bash
# Check CronJob
source ~/.zshrc && kube get cronjob misp-lookup-generator -n misp-prod

# Check last job
source ~/.zshrc && kube get jobs -n misp-prod

# View logs
source ~/.zshrc && kube logs job/misp-lookup-generator-XXXXX -n misp-prod

# Common issues:
# - MISP API key not set (update misp-admin-secret)
# - Devo API credentials invalid (check devo-api-secret)
# - No MISP events (add feeds to MISP)
```

### LoadBalancer Not Assigning IP

```bash
# Check service
source ~/.zshrc && kube describe svc misp-server -n misp-prod

# Events show issues
source ~/.zshrc && kube get events -n misp-prod --sort-by='.lastTimestamp'

# Common issues:
# - No available LoadBalancer IPs
# - Security group restrictions
# - VPC configuration issues
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Kubernetes Cluster (Hydra/Cerberus)                   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │ MISP Server Deployment (2 replicas)             │  │
│  │ - Image: docker.devo.internal/devo/misp:v2.0.0  │  │
│  │ - CPU: 1 core, Memory: 2Gi                      │  │
│  └──────────┬──────────────────────────────────────┘  │
│             │                                          │
│  ┌──────────┴────────────┬──────────────────────┐    │
│  │                       │                      │    │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────┐│
│  │ MySQL        │  │ Redis       │  │ MISP Files   ││
│  │ StatefulSet  │  │ StatefulSet │  │ PVC (50Gi)   ││
│  │ - 100Gi PVC  │  │ - 20Gi PVC  │  │ (ReadWriteMany)││
│  └──────────────┘  └─────────────┘  └──────────────┘│
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │ Lookup Generator CronJob                        │  │
│  │ - Schedule: 0 0 * * * (daily at 00:00 UTC)     │  │
│  │ - Downloads MISP events                         │  │
│  │ - Generates mispIndicator lookup                │  │
│  │ - Uploads to Devo platform                      │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │ Monitoring (Prometheus + Dynatrace)             │  │
│  │ - MySQL Exporter                                 │  │
│  │ - Redis Exporter                                 │  │
│  │ - MISP Metrics                                   │  │
│  │ - 15 Alert Rules                                 │  │
│  │ - Grafana Dashboard (13 panels)                 │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
          │
          │ HTTPS (TLS)
          ▼
┌─────────────────────────────────────┐
│ Ingress: misp.internal.devo.com    │
│ - NGINX Ingress Controller          │
│ - TLS Certificate (cert-manager)    │
└─────────────────────────────────────┘
```

---

## Resource Requirements

### Production

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage |
|-----------|-------------|-----------|----------------|--------------|---------|
| MISP Server (×2) | 1 core | 2 cores | 2Gi | 4Gi | 50Gi (shared) |
| MySQL | 1 core | 2 cores | 2Gi | 4Gi | 100Gi |
| Redis | 250m | 1 core | 512Mi | 2Gi | 20Gi |
| Lookup Generator | 500m | 1 core | 512Mi | 2Gi | 5Gi (temp) |
| **Total** | **3.75 cores** | **8 cores** | **7.5Gi** | **16Gi** | **175Gi** |

### Staging/Test

Reduce replicas to 1 and halve resources for cost savings.

---

## Success Criteria

✅ **Deployment Successful When:**

1. MISP server accessible via https://misp.internal.devo.com
2. mispIndicator lookup populated with >10M indicators
3. Lookup updates daily without errors
4. Customer queries return results (resolves ISM-15510)
5. All monitoring alerts configured
6. Documentation complete
7. Operations team trained

---

## Support

**Owner:** Vikash Jaiswal (vikash.jaiswal@devo.com)
**Team:** Platform Engineering
**Jira:** ISM-15510
**Documentation:** `~/.claude/skills/devo-infra/misp/`

---

**Created:** 2026-04-20
**Status:** Phase 1 Complete - Ready for Build & Test
