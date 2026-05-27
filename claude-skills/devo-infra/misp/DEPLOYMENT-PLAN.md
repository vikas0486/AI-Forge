# MISP Kubernetes Deployment Plan

**Issue**: ISM-15510 - mispIndicator lookup showing 0 rows since Jan 23, 2026
**Root Cause**: Legacy MISP server (misp.devo.com) decommissioned, no monitoring/infrastructure
**Solution**: Deploy modern Kubernetes-based MISP with proper monitoring

---

## Phase 1: Preparation (Day 1-2)

### 1.1 Build Docker Images

**MISP Server Image** (modernized from legacy repo):
```bash
cd ~/.claude/skills/devo-infra/misp/docker/misp-server
docker build -t docker.devo.internal/devo/misp:v2.0.0 .
docker push docker.devo.internal/devo/misp:v2.0.0
```

**Lookup Generator Image** (new):
```bash
cd ~/.claude/skills/devo-infra/misp/docker/lookup-generator
docker build -t docker.devo.internal/devo/misp-lookup-generator:v1.0.0 .
docker push docker.devo.internal/devo/misp-lookup-generator:v1.0.0
```

### 1.2 DNS & Certificates

**DNS Record**:
- Old: `misp.devo.com` (REMOVED)
- New: `misp.internal.devo.com` (internal only, K8s Ingress)
- **Action**: Create A record pointing to K8s Ingress LoadBalancer

**TLS Certificate**:
- Use cert-manager to generate Let's Encrypt certificate
- Or: Use internal Devo CA certificate

### 1.3 Secrets Management

Create Kubernetes secrets for sensitive data:

```bash
# MySQL credentials
source ~/.zshrc && kube create secret generic misp-mysql-secret \
  --from-literal=root-password='GENERATE_STRONG_PASSWORD' \
  --from-literal=misp-db-password='GENERATE_STRONG_PASSWORD' \
  -n misp-prod

# MISP admin credentials
source ~/.zshrc && kube create secret generic misp-admin-secret \
  --from-literal=admin-email='misp-admin@devo.com' \
  --from-literal=admin-password='GENERATE_STRONG_PASSWORD' \
  -n misp-prod

# Devo API credentials (for lookup upload)
source ~/.zshrc && kube create secret generic devo-api-secret \
  --from-literal=api-key='YOUR_DEVO_API_KEY' \
  --from-literal=api-secret='YOUR_DEVO_API_SECRET' \
  --from-literal=api-url='https://apiv2-us.devo.com' \
  -n misp-prod
```

---

## Phase 2: Infrastructure Deployment (Day 3-4)

### 2.1 Deploy Storage (PVCs)

```bash
# Create persistent volumes for data
source ~/.zshrc && kube apply -f k8s-manifests/storage/
# - MySQL data: 100Gi SSD
# - Redis data: 20Gi SSD
# - MISP files: 50Gi SSD
```

### 2.2 Deploy MySQL StatefulSet

```bash
source ~/.zshrc && kube apply -f k8s-manifests/mysql-statefulset.yaml

# Wait for MySQL to be ready
source ~/.zshrc && kube wait --for=condition=ready pod/mysql-0 -n misp-prod --timeout=300s

# Initialize database
source ~/.zshrc && kube exec -it mysql-0 -n misp-prod -- mysql -u root -p < scripts/init-database.sql
```

### 2.3 Deploy Redis StatefulSet

```bash
source ~/.zshrc && kube apply -f k8s-manifests/redis-statefulset.yaml

# Verify Redis
source ~/.zshrc && kube exec -it redis-0 -n misp-prod -- redis-cli ping
# Expected: PONG
```

### 2.4 Deploy MISP Server

```bash
source ~/.zshrc && kube apply -f k8s-manifests/misp-deployment.yaml

# Wait for MISP to be ready (may take 5-10 minutes on first start)
source ~/.zshrc && kube wait --for=condition=ready pod -l app=misp-server -n misp-prod --timeout=600s

# Check logs
source ~/.zshrc && kube logs -f -n misp-prod deployment/misp-server
```

### 2.5 Deploy Services & Ingress

```bash
# Create Service (LoadBalancer or ClusterIP)
source ~/.zshrc && kube apply -f k8s-manifests/services.yaml

# Create Ingress (with TLS)
source ~/.zshrc && kube apply -f k8s-manifests/ingress.yaml

# Get external IP
source ~/.zshrc && kube get svc misp-server -n misp-prod
```

---

## Phase 3: MISP Configuration (Day 5)

### 3.1 Initial MISP Setup

Access MISP web interface:
```
https://misp.internal.devo.com
Username: admin@admin.test (default)
Password: admin (change immediately!)
```

**Configure MISP**:
1. Change admin password
2. Set MISP.baseurl: `https://misp.internal.devo.com`
3. Configure email settings (optional)
4. Enable background workers
5. Update taxonomies, galaxies, warning lists

### 3.2 Add MISP Feeds

**Recommended Free Feeds**:
- CIRCL OSINT Feed
- Botvrij.eu
- Blocklist.de
- URLhaus
- MISP Standard Feeds

**Configuration**:
1. Navigate to: Sync Actions > List Feeds
2. Enable desired feeds
3. Configure feed fetching schedule

### 3.3 Create API Key for Lookup Generation

1. Navigate to: Administration > Add User (or use admin)
2. Generate Auth Key
3. Copy API key
4. Store in Kubernetes secret:

```bash
source ~/.zshrc && kube create secret generic misp-api-key \
  --from-literal=api-key='YOUR_MISP_API_KEY' \
  -n misp-prod
```

---

## Phase 4: Lookup Generation Setup (Day 6)

### 4.1 Deploy Lookup Generator CronJob

```bash
source ~/.zshrc && kube apply -f k8s-manifests/lookup-cronjob.yaml

# Schedule: Daily at 00:00 UTC
# Generates mispIndicator lookup from MISP events
```

### 4.2 Test Lookup Generation (Manual Run)

```bash
# Create manual job from cronjob
source ~/.zshrc && kube create job --from=cronjob/misp-lookup-generator \
  manual-test-$(date +%s) -n misp-prod

# Watch logs
source ~/.zshrc && kube logs -f job/manual-test-XXXXX -n misp-prod

# Expected output:
# 1. Downloading MISP events...
# 2. Found XXXX events
# 3. Converting to CSV...
# 4. Uploading to Devo lookup 'mispIndicator'...
# 5. Upload complete: XXXX indicators
```

### 4.3 Verify Lookup in Devo

```bash
# Query Devo to verify lookup
from lookup.mispIndicator
group
select count() as total_indicators
```

Expected result: 20M+ indicators (similar to old mispIndicator lookup)

---

## Phase 5: Monitoring Setup (Day 7)

### 5.1 Prometheus Metrics

Deploy ServiceMonitor for Prometheus scraping:

```bash
source ~/.zshrc && kube apply -f k8s-manifests/monitoring/servicemonitor.yaml
```

**Metrics to monitor**:
- `misp_server_up` - MISP server health (1=up, 0=down)
- `misp_mysql_connections` - MySQL connection count
- `misp_redis_memory_usage` - Redis memory usage
- `misp_lookup_generation_success` - Last lookup generation status
- `misp_lookup_generation_duration` - Lookup generation time
- `misp_lookup_indicator_count` - Number of indicators in lookup

### 5.2 Dynatrace Integration

Configure Dynatrace OneAgent:

```bash
source ~/.zshrc && kube apply -f k8s-manifests/monitoring/dynatrace-oneagent.yaml
```

**Dynatrace Dashboards**:
1. MISP Server Performance
2. MySQL Database Performance
3. Lookup Generation Metrics

### 5.3 Alerts

**Critical Alerts** (PagerDuty/Slack):
- MISP server down > 5 minutes
- MySQL database unreachable
- Lookup generation failed 2 consecutive days
- mispIndicator lookup empty

**Warning Alerts** (Slack):
- MISP server response time > 5s
- MySQL disk usage > 80%
- Redis memory > 80%
- Lookup generation time > 2 hours

---

## Phase 6: Testing & Validation (Day 8-9)

### 6.1 Functional Tests

**Test Checklist**:
- [ ] MISP web interface accessible
- [ ] Can create/edit events
- [ ] Feeds are fetching data
- [ ] Background workers running
- [ ] API authentication works
- [ ] Lookup generation completes
- [ ] mispIndicator lookup populated in Devo
- [ ] Customer queries return results

### 6.2 Performance Tests

```bash
# Load test MISP API
scripts/load-test-misp-api.sh

# Test lookup generation with 1M+ events
scripts/test-lookup-generation.sh --events=1000000
```

### 6.3 Disaster Recovery Test

**Backup**:
```bash
scripts/backup-mysql.sh misp-prod
```

**Restore**:
```bash
scripts/restore-mysql.sh misp-prod backup-2026-04-20.sql
```

---

## Phase 7: Production Cutover (Day 10)

### 7.1 Communication

**Announce to stakeholders**:
- Customer Success team
- Security Operations team
- Platform Engineering team

**Email Template**:
```
Subject: MISP Threat Intelligence Platform - Production Deployment

Team,

We have deployed a new Kubernetes-based MISP platform to replace the
legacy misp.devo.com server that was decommissioned in January 2026.

New Details:
- URL: https://misp.internal.devo.com (internal only)
- Lookup: mispIndicator (common lookup, all regions)
- Update Schedule: Daily at 00:00 UTC
- Monitoring: Dynatrace dashboard available

This resolves ISM-15510 (mispIndicator showing 0 rows).

For questions or issues, contact Platform Engineering team.

Thanks,
Platform Engineering Team
```

### 7.2 Update Documentation

**Confluence Pages to Update**:
1. MISP Architecture & Operations
2. Threat Intelligence Integration Guide
3. mispIndicator Lookup Usage
4. Platform Runbooks

**Update Jira Ticket**:
- ISM-15510: Mark as resolved
- Add resolution notes
- Link to new documentation

### 7.3 Handoff to Operations

**Runbook for NOC/SRE**:
1. How to check MISP health
2. How to manually trigger lookup generation
3. How to restart MISP services
4. Escalation procedures

---

## Phase 8: Monitoring & Optimization (Day 11+)

### 8.1 Week 1 Monitoring

**Daily checks**:
- Lookup generation success rate
- MISP server uptime
- Customer query performance
- Resource utilization

### 8.2 Performance Tuning

**Optimize if needed**:
- MySQL query performance
- Redis memory configuration
- MISP worker count
- Lookup generation parallelization

### 8.3 Cost Optimization

**Resources to monitor**:
- K8s node usage
- Storage costs (PVCs)
- Network egress (if applicable)

---

## Rollback Plan

If deployment fails or critical issues occur:

### Rollback Steps

1. **Disable new MISP**:
   ```bash
   source ~/.zshrc && kube scale deployment misp-server --replicas=0 -n misp-prod
   ```

2. **Revert mispIndicator lookup** (if corrupted):
   ```bash
   # Restore from backup (if available)
   # Or: Point to alternative threat intel source
   ```

3. **Notify stakeholders**:
   - Incident ticket
   - Slack announcement
   - Root cause analysis

4. **Alternative solution**:
   - Use ThreatConnect integration (already available)
   - Use Recorded Future integration
   - Manual threat intel updates

---

## Success Criteria

✅ **Deployment successful if**:
1. MISP server accessible and responding
2. mispIndicator lookup populated (>10M indicators)
3. Lookup updates daily without errors
4. Customer queries return expected results
5. All monitoring alerts configured
6. Zero downtime during operation
7. Performance meets SLA (response time <2s)

---

## Timeline Summary

| Phase | Duration | Days | Status |
|-------|----------|------|--------|
| 1. Preparation | 2 days | Day 1-2 | ⏳ Not Started |
| 2. Infrastructure | 2 days | Day 3-4 | ⏳ Not Started |
| 3. MISP Config | 1 day | Day 5 | ⏳ Not Started |
| 4. Lookup Setup | 1 day | Day 6 | ⏳ Not Started |
| 5. Monitoring | 1 day | Day 7 | ⏳ Not Started |
| 6. Testing | 2 days | Day 8-9 | ⏳ Not Started |
| 7. Production | 1 day | Day 10 | ⏳ Not Started |
| 8. Optimization | Ongoing | Day 11+ | ⏳ Not Started |

**Total Estimated Time**: 10 working days (2 weeks)

---

## Budget Estimate

**Infrastructure Costs** (monthly):
- K8s nodes (3x m5.xlarge): ~$450/month
- Storage (170Gi SSD): ~$20/month
- Load Balancer: ~$20/month
- **Total**: ~$490/month

**One-time Costs**:
- Development/deployment effort: 10 days
- Testing/validation: 2 days
- Documentation: 1 day

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Docker build fails | Low | Medium | Test build locally first |
| MySQL performance issues | Medium | High | Use SSD storage, tune configs |
| Lookup generation timeout | Medium | High | Implement chunked processing |
| Customer data loss | Low | Critical | Maintain old lookup as backup |
| K8s resource exhaustion | Medium | High | Set resource limits, monitoring |

---

## Next Steps

1. ✅ Create deployment plan (this document)
2. ⏳ Review plan with Platform Engineering team
3. ⏳ Get approval for production deployment
4. ⏳ Build Docker images
5. ⏳ Deploy to staging environment
6. ⏳ Execute deployment plan

---

**Created**: 2026-04-20
**Author**: Vikash Jaiswal (vikash.jaiswal@devo.com)
**Reviewers**: Platform Engineering Team
**Status**: Draft - Awaiting Review
**Jira**: ISM-15510
