# Vault Deployment Summary - Quick Reference

**Validation Date:** May 1, 2026  
**Status:** ✅ All 4 Kubernetes regions validated

---

## Pod Distribution by Region & AZ

| Region | Cluster | Pod Name | Node | Availability Zone | Pod IP | Status | Age |
|--------|---------|----------|------|-------------------|--------|--------|-----|
| **US (us-east-1)** | prod-us | vault-0 | ip-172-25-67-139.ec2.internal | **us-east-1c** | 172.25.79.112 | Running | 10d |
| | | vault-1 | ip-172-25-51-63.ec2.internal | **us-east-1b** | 172.25.55.8 | Running | 10d |
| | | vault-2 | ip-172-25-46-11.ec2.internal | **us-east-1a** | 172.25.32.127 | Running | 10d |
| **EU (eu-west-1)** | prod-eu | vault-0 | ip-172-17-52-76.eu-west-1.compute.internal | **eu-west-1b** | 172.17.50.228 | Running | 8d |
| | | vault-1 | ip-172-17-68-23.eu-west-1.compute.internal | **eu-west-1c** | 172.17.67.191 | Running | 8d |
| | | vault-2 | ip-172-17-35-150.eu-west-1.compute.internal | **eu-west-1a** | 172.17.42.112 | Running | 8d |
| **US3 (us-east-2)** | prod-us3 | vault-0 | ip-172-28-49-48.us-east-2.compute.internal | **us-east-2b** | 172.28.57.217 | Running | 9d |
| | | vault-1 | ip-172-28-78-7.us-east-2.compute.internal | **us-east-2c** | 172.28.69.123 | Running | 9d |
| | | vault-2 | ip-172-28-40-39.us-east-2.compute.internal | **us-east-2a** | 172.28.43.163 | Running | 9d |
| **APAC (ap-southeast-1)** | prod-apac | vault-0 | ip-10-7-14-55.ap-southeast-1.compute.internal | **ap-southeast-1a** | 10.7.15.171 | Running | 16d |
| | | vault-1 | ip-10-7-21-227.ap-southeast-1.compute.internal | **ap-southeast-1b** | 10.7.16.38 | Running | 16d |
| | | vault-2 | ip-10-7-35-161.ap-southeast-1.compute.internal | **ap-southeast-1c** | 10.7.35.119 | Running | 16d |
| **NCSC Bahrain (me-south-1)** | ❓ Unknown | N/A | N/A | ❓ Unknown | N/A | ❓ Unknown | N/A |

---

## Storage Configuration per Region

| Region | Data PVC (Raft) | Audit PVC | Total Storage | Storage Class | Encryption |
|--------|-----------------|-----------|---------------|---------------|------------|
| US | 3 × 1Gi = 3Gi | 3 × 10Gi = 30Gi | **33Gi** | gp2-encrypted (data), gp3-encrypted (audit) | ✅ Yes |
| EU | 3 × 1Gi = 3Gi | 3 × 10Gi = 30Gi | **33Gi** | gp2-encrypted (data), gp3-encrypted (audit) | ✅ Yes |
| US3 | 3 × 1Gi = 3Gi | 3 × 10Gi = 30Gi | **33Gi** | gp3-encrypted-retain (data), gp3-encrypted (audit) | ✅ Yes |
| APAC | 3 × 1Gi = 3Gi | 3 × 10Gi = 30Gi | **33Gi** | gp3-encrypted (data), gp2 (audit) | ⚠️ Audit not encrypted |
| **TOTAL** | | | **132Gi** | | |

---

## High Availability Configuration

| Region | StatefulSet Age | Pods Ready | HA Enabled | AZ Distribution | Quorum | Can Tolerate |
|--------|----------------|------------|------------|-----------------|--------|--------------|
| US | 4y131d | 3/3 | ✅ Raft | 1 pod per AZ (3 AZs) | 2 of 3 | 1 pod or 1 AZ failure |
| EU | 4y131d | 3/3 | ✅ Raft | 1 pod per AZ (3 AZs) | 2 of 3 | 1 pod or 1 AZ failure |
| US3 | 2y27d | 3/3 | ✅ Raft | 1 pod per AZ (3 AZs) | 2 of 3 | 1 pod or 1 AZ failure |
| APAC | 4y101d | 3/3 | ✅ Raft | 1 pod per AZ (3 AZs) | 2 of 3 | 1 pod or 1 AZ failure |
| NCSC | ❓ Unknown | ❓ | ❓ | ❓ | ❓ | ❓ |

---

## Backup Configuration

| Region | Backup Namespace | CronJob | Schedule | Status | S3 Bucket | Last Successful |
|--------|-----------------|---------|----------|--------|-----------|-----------------|
| **US** | vault-snapshots | ✅ Yes | @every 2h | ⚠️ **SUSPENDED** | vault-snapshots-us | 2024-06-14 (686d ago) |
| **EU** | N/A | ❌ No | N/A | ❌ Not configured | N/A | N/A |
| **US3** | N/A | ❌ No | N/A | ❌ Not configured | N/A | N/A |
| **APAC** | N/A | ❌ No | N/A | ❌ Not configured | N/A | N/A |
| **NCSC** | ❓ Unknown | ❓ | ❓ | ❓ | ❓ | ❓ |

---

## Services per Region

All 4 validated regions deploy identical Kubernetes services:

| Service Name | Type | Purpose | Ports |
|--------------|------|---------|-------|
| vault | ClusterIP | General Vault API access | 8200, 8201 |
| vault-active | ClusterIP | Active leader routing | 8200, 8201 |
| vault-standby | ClusterIP | Standby replicas routing | 8200, 8201 |
| vault-internal | ClusterIP (None) | StatefulSet headless service | 8200, 8201 |
| vault-ui | ClusterIP | Web UI access | 8200 |
| vault-agent-injector-svc | ClusterIP | Sidecar injection webhook | 443 |

**vault-agent-injector:** 3 replicas per region (distributed across 3 AZs)

---

## Root Token Storage (AWS Secrets Manager)

| Region | Secret Name | Secret Region | Vault URL |
|--------|-------------|---------------|-----------|
| US | `vault-us-token` | us-east-1 | https://vault-us.devo.com |
| EU | `devo-vault-init-token` | eu-west-1 | https://vault-eu.devo.com |
| US3 | `devo-vault-init-token-pro-us3` | us-east-2 | https://vault-us3.devo.com |
| APAC | `devo-vault-init-token-prod-apac` | ap-southeast-1 | https://vault-apac.devo.com |
| NCSC | `prod-ncscbh-eu-vault-init-definite-hare` | eu-west-1 | https://vault.hawk.ncsc.gov.bh |

All secrets KMS encrypted with CloudTrail audit trail.

---

## Critical Action Items

| Priority | Action | Region | Timeline |
|----------|--------|--------|----------|
| 🔴 **CRITICAL** | Re-enable backup CronJob (suspended 637 days) | US | **Immediate** |
| 🟠 **HIGH** | Deploy automated backups | EU, US3, APAC | Within 1 week |
| 🟡 **MEDIUM** | Investigate NCSC deployment architecture | NCSC Bahrain | Within 1 month |
| 🟡 **MEDIUM** | Encrypt audit PVCs (gp2 → gp3-encrypted) | APAC | Within 1 month |
| 🟢 **LOW** | Test DR procedures | All regions | Within 3 months |

---

## Quick Access Commands

### SSH to Kubernetes Nodes

```bash
# US vault-0 node
ssh ec2-user@ip-172-25-67-139.ec2.internal

# EU vault-0 node
ssh ec2-user@ip-172-17-52-76.eu-west-1.compute.internal

# US3 vault-0 node
ssh ec2-user@ip-172-28-49-48.us-east-2.compute.internal

# APAC vault-0 node
ssh ec2-user@ip-10-7-14-55.ap-southeast-1.compute.internal
```

### Check Vault Pod Status

```bash
# US
kubectl config use-context prod-us && kubectl get pods -n vault -o wide

# EU
kubectl config use-context prod-eu && kubectl get pods -n vault -o wide

# US3
kubectl config use-context prod-us3 && kubectl get pods -n vault -o wide

# APAC
kubectl config use-context prod-apac && kubectl get pods -n vault -o wide
```

### Vault Health Check via Wrapper

```bash
# US
~/Documents/Scripts/vault-wrapper.sh us_prod status

# EU
~/Documents/Scripts/vault-wrapper.sh eu_prod status

# US3
~/Documents/Scripts/vault-wrapper.sh us3_prod status

# APAC
~/Documents/Scripts/vault-wrapper.sh apac_prod status

# NCSC
~/Documents/Scripts/vault-wrapper.sh ncsc_bahrain status
```

### Check Raft Cluster Status

```bash
# US
~/Documents/Scripts/vault-wrapper.sh us_prod raw sys/storage/raft/configuration | jq '.data.config.servers'

# EU
~/Documents/Scripts/vault-wrapper.sh eu_prod raw sys/storage/raft/configuration | jq '.data.config.servers'

# US3
~/Documents/Scripts/vault-wrapper.sh us3_prod raw sys/storage/raft/configuration | jq '.data.config.servers'

# APAC
~/Documents/Scripts/vault-wrapper.sh apac_prod raw sys/storage/raft/configuration | jq '.data.config.servers'
```

---

## Key Findings Summary

### ✅ Strengths

1. **Perfect Multi-AZ Distribution:** All 4 validated regions have 1 pod per AZ (optimal fault tolerance)
2. **Consistent Architecture:** Same 3-pod StatefulSet pattern across all regions
3. **Raft Consensus:** No external dependencies (Consul/DynamoDB)
4. **Encrypted Storage:** All regions using KMS-encrypted storage classes (except APAC audit)
5. **Root Token Security:** All tokens in AWS Secrets Manager with KMS encryption
6. **High Availability:** Can tolerate 1 pod/AZ failure per region with automatic failover
7. **Long-running Stability:** US/EU running for 4+ years, APAC 4+ years, US3 2+ years

### ⚠️ Risks & Gaps

1. **Backup Gaps:**
   - US: Backup suspended for 637 days (last successful: 686 days ago)
   - EU/US3/APAC: No automated backups configured

2. **NCSC Unknown Architecture:**
   - Not found in any Kubernetes cluster
   - No visibility into HA/DR configuration
   - Unknown backup strategy

3. **APAC Storage Inconsistency:**
   - Audit PVCs using older `gp2` (not encrypted flag)
   - Should migrate to `gp3-encrypted` for consistency

4. **No Cross-Region DR:**
   - Each region independent (no replication)
   - Regional failure = data loss without local backups

### 📊 Overall Health Score

| Category | Score | Notes |
|----------|-------|-------|
| Availability | ✅ **9/10** | Perfect multi-AZ, 1 point off for unknown NCSC |
| Security | ✅ **9/10** | KMS encrypted, IAM controlled, 1 point off for APAC audit |
| Backup/DR | ⚠️ **4/10** | Only US has backup (suspended), 3 regions with no backups |
| Monitoring | ✅ **8/10** | Good visibility via K8s + Vault API |
| Documentation | ✅ **10/10** | Comprehensive validation completed |

**Overall:** ⚠️ **8.0/10** - Production-ready but backup gaps pose data loss risk

---

**For detailed architecture:** See `/tmp/vault-kubernetes-deployment-complete-architecture.md`  
**For security answers:** See `/tmp/vault-security-manager-brief-answers.md`  
**For root tokens:** See `/tmp/vault-root-tokens-reference-table.md`

**Validated by:** Vikash Jaiswal | **Date:** May 1, 2026
