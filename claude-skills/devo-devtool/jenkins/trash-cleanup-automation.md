# Datanode Trash Cleanup Automation Framework

**Confluence Documentation:** https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/5553946635

## Overview

Automated framework for managing "Trash" and "Archive" directory lifecycle across global Datanode clusters (AWS & GCP). Uses **Wrapper-Master Architecture** for centralized logic with decentralized regional scheduling.

**Purpose:** Proactive cleanup to avoid automatic EBS expansion and reduce AWS costs.

---

## Architecture

### Wrapper-Master Model

| Component | Responsibility | Location |
|-----------|----------------|----------|
| **Master** | Execute Ansible playbooks, handle SSH, disk space verification | `RaD-Deployments/datanode-trash-deletion-http` |
| **Wrappers** | Regional schedules (Weekly), environment-specific parameters | `Weekly-Schedules_Trash-Cleaner` (per region) |

**Benefits:**
- ✅ Centralized logic (no configuration drift)
- ✅ Decentralized scheduling (regional flexibility)
- ✅ Load distribution (cron hash prevents simultaneous execution)

---

## Core Components

### 1. Ansible Playbook

**File:** `datanode-trash-cleanup.yml`
**Source:** https://gitlab.com/devo_corp/platform/ansible/environments/automation/-/blob/master/ansible/playbooks/datanode-trash-cleanup.yml

**What It Does:**
- Connects to datanodes via SSH
- Verifies disk space before cleanup
- Removes trash/archive files older than retention window
- Verifies disk space after cleanup
- Reports space reclaimed

### 2. Master Pipeline

**Job:** `RaD-Deployments/datanode-trash-deletion-http`
**URL:** https://jenkins.devotools.com/job/RaD-Deployments/job/datanode-trash-deletion-http/
**Groovy:** https://gitlab.devotools.com/devops/jenkins/jenkinsfiles/-/blob/master/jobs/job_ops_datanode_trash_deletion_http.groovy

**Description:**
```
Trash clean-up with http authentication
Proactive Trash and Trash-Amnesia Cleanup to avoid automatic
expansion for all Cloud Infra Data Management
```

**Parameters:**
- `ANSIBLE_HOST` - Target hostgroups (e.g., `datanode-shared:datanode-nielsen`)
- `ANSIBLE_ENVIRONMENT` - Environment (`pro`, `tef`, etc.)
- `CLEANUP_STRATEGY` - Strategy name (e.g., `trash-amnesia-archive-365d`)
- `CLEANUP_DAYS` - Retention window (usually `7` for weekly)
- `ANSIBLE_REGION` - Cloud region (e.g., `eu`, `us`, `ap`)
- `ANSIBLE_CLOUD` - Cloud provider (`aws`, `gcp`)
- `VERIFY_DF_CMD` - Disk space check command
- `VERIFY_DU_CMD` - Directory size check command

**Recent Builds:** 366, 365, 364, 363, 362...

### 3. Wrapper Pipelines (Regional Schedules)

**GitLab Source:** https://gitlab.devotools.com/devops/jenkins/jenkinsfiles/-/tree/master/jobs/trash_clean-up_schedules

#### APAC (AWS)
- **Job:** `RaD-Deployments/aws-ap-pro/Weekly-Schedules_Trash-Cleaner`
- **URL:** https://jenkins.devotools.com/job/RaD-Deployments/job/aws-ap-pro/job/Weekly-Schedules_Trash-Cleaner/
- **Description:** WRAPPER PIPELINE: APAC AWS Datanode Trash-Amnesia Weekly Cleanup
- **Schedule:** `cron('H 6 * * 0')` - Every Sunday at 06:00 AM
- **Target:** `datanode-shared:datanode-nielsen` (APAC hosts)

#### US (AWS)
- **Job:** `RaD-Deployments/aws-us-pro/Weekly-Schedules_Trash-Cleaner`
- **URL:** https://jenkins.devotools.com/job/RaD-Deployments/job/aws-us-pro/job/Weekly-Schedules_Trash-Cleaner/
- **Description:** WRAPPER PIPELINE: US AWS Datanode Trash-Amnesia Weekly Cleanup
- **Schedule:** `cron('H 6 * * 0')` - Every Sunday at 06:00 AM
- **Target:** US datanode hostgroups

#### EU (AWS)
- **Job:** `RaD-Deployments/aws-eu-pro/Weekly-Schedules_Trash-Cleaner`
- **URL:** https://jenkins.devotools.com/job/RaD-Deployments/job/aws-eu-pro/job/Weekly-Schedules_Trash-Cleaner/
- **Description:** WRAPPER PIPELINE: EU AWS Datanode Trash-Amnesia Weekly Cleanup
- **Schedule:** `cron('H 6 * * 0')` - Every Sunday at 06:00 AM
- **Target:** EU datanode hostgroups

#### EU (GCP - Telefonica)
- **Job:** `RaD-Deployments/gcp-eu-tef/Weekly-Schedules_Trash-Cleaner`
- **URL:** https://jenkins.devotools.com/job/RaD-Deployments/job/gcp-eu-tef/job/Weekly-Schedules_Trash-Cleaner/
- **Description:** WRAPPER PIPELINE: EU GCP Datanode Trash-Amnesia Weekly Cleanup
- **Schedule:** `cron('H 6 * * 0')` - Every Sunday at 06:00 AM
- **Target:** GCP Telefonica datanodes

---

## Cleanup Strategies

### trash-amnesia-archive-365d

**Target:** Data older than 1 year (365 days)

**Directories:**
- `/var/logt/data/trash/`
- `/var/logt/data/trash-amnesia/`
- `/var/logt/data/archive/`

**Retention:** Files older than `CLEANUP_DAYS` parameter

---

## Scheduling

### Cron Syntax

```groovy
cron('H 6 * * 0')  // Every Sunday at 06:00 AM
```

**Key Points:**
- ✅ **`H` (Hash)** - Spreads load across Jenkins (prevents simultaneous execution)
- ✅ **Weekly** - Runs every Sunday
- ✅ **Regional** - Each region has independent schedule
- ✅ **Off-peak** - 06:00 AM on Sunday (low traffic)

---

## Verification Commands

### Disk Space Check (Before/After)

```bash
# VERIFY_DF_CMD - Check mount point health
df -hPT /var/logt/data
df -hPT /var/logt/data2
df -hPT /var/logt/data3
```

### Directory Size Check

```bash
# VERIFY_DU_CMD - Calculate trash size
du -sh /var/logt/data/trash
du -sh /var/logt/data/trash-amnesia
du -sh /var/logt/data/archive
```

**Purpose:** Safety verification
- **Before:** Understand disk utilization
- **After:** Verify space reclaimed

---

## Using the Automation

### Monitor Weekly Execution

```bash
# Load Jenkins helper
source ~/.jenkins/jenkins-helper.sh

# Check APAC weekly cleanup
jenkins_builds RaD-Deployments/aws-ap-pro/Weekly-Schedules_Trash-Cleaner 5

# Check US weekly cleanup
jenkins_builds RaD-Deployments/aws-us-pro/Weekly-Schedules_Trash-Cleaner 5

# Check EU weekly cleanup
jenkins_builds RaD-Deployments/aws-eu-pro/Weekly-Schedules_Trash-Cleaner 5

# Check GCP weekly cleanup
jenkins_builds RaD-Deployments/gcp-eu-tef/Weekly-Schedules_Trash-Cleaner 5
```

### Manual Trigger (Emergency)

If disk reaches critical threshold (>90%) before Sunday:

```bash
# Navigate to master job
jenkins_job_summary RaD-Deployments/datanode-trash-deletion-http

# Check recent parameters
jenkins_parameters RaD-Deployments/datanode-trash-deletion-http 366

# Trigger manual cleanup
jenkins_trigger RaD-Deployments/datanode-trash-deletion-http \
  ANSIBLE_HOST=datanode-shared \
  ANSIBLE_ENVIRONMENT=pro \
  ANSIBLE_REGION=eu \
  ANSIBLE_CLOUD=aws \
  CLEANUP_STRATEGY=trash-amnesia-archive-365d \
  CLEANUP_DAYS=0 \
  VERIFY_DF_CMD="df -hPT /var/logt/data /var/logt/data2 /var/logt/data3" \
  VERIFY_DU_CMD="du -sh /var/logt/data/trash /var/logt/data/trash-amnesia"
```

**Note:** `CLEANUP_DAYS=0` for immediate purge of all trash

### Check Console Output

```bash
# Get console output from recent build
jenkins_console RaD-Deployments/datanode-trash-deletion-http 366 100

# Full console output
jenkins_console_full RaD-Deployments/datanode-trash-deletion-http 366 > /tmp/trash-cleanup-366.log

# Search for errors
grep -i "error\|fail\|unreachable" /tmp/trash-cleanup-366.log

# Check disk space reclaimed
grep -i "freed\|reclaimed\|deleted" /tmp/trash-cleanup-366.log
```

---

## Troubleshooting

### Common Error Scenarios

#### 1. "UNREACHABLE!" in Ansible Logs

**Root Cause:** Datanode is down, SSH service stopped, or Security Group rules changed

**Actions:**
1. Check if node is alive in AWS/GCP Console
2. Verify SSH connectivity from Jenkins agent
3. Check Security Group rules

```bash
# SSH test from local machine
ssh datanode-1-pro-cloud-shared-aws-eu-west-1 "hostname"

# Check via Ansible
cd ~/Documents/Repository/automation
ansible datanode-1-pro-cloud-shared-aws-eu-west-1 \
  -i ansible/environments/aws/eu/pro/hosts \
  -m ping
```

#### 2. "Aborted due to timeout"

**Root Cause:** Cleanup taking longer than Jenkins timeout (millions of small files)

**Actions:**
1. Check disk I/O on node: `ssh <host> "iostat -x 5"`
2. Re-run with smaller `CLEANUP_DAYS` (e.g., 365 → 180 → 90)
3. Clear backlog in chunks

#### 3. "Permission Denied (publickey)"

**Root Cause:** Jenkins SSH key not authorized on target hostgroup

**Actions:**
1. Verify Jenkins public key in `/home/ubuntu/.ssh/authorized_keys` on datanode
2. Check SSH key permissions (600 for private, 644 for public)

#### 4. "df: /var/logt/... No such file"

**Root Cause:** Mount points in `VERIFY_DF_CMD` don't exist on target host

**Actions:**
1. Verify standard paths on target: `ssh <host> "ls -la /var/logt/"`
2. Update `VERIFY` commands in wrapper for non-standard paths

#### 5. "No space left on device"

**Root Cause:** Disk so full that cleanup script cannot initialize temporary files

**Actions:**
1. Manually delete small portion of logs via CLI
2. Bridge space to allow automation to run
3. Re-run automation

```bash
# Manual cleanup (emergency)
ssh <host> "sudo find /var/logt/data/trash -type f -mtime +30 -delete | head -1000"
```

### Handling Timeouts

If regional cleanup times out (Trash directory too large):

**Fix:** Manually trigger master job with progressive cleanup:

```bash
# Week 1: Clear >365 days
jenkins_trigger RaD-Deployments/datanode-trash-deletion-http CLEANUP_DAYS=365 ...

# Week 2: Clear >180 days
jenkins_trigger RaD-Deployments/datanode-trash-deletion-http CLEANUP_DAYS=180 ...

# Week 3: Clear >90 days
jenkins_trigger RaD-Deployments/datanode-trash-deletion-http CLEANUP_DAYS=90 ...

# Week 4: Back to normal weekly (7 days)
jenkins_trigger RaD-Deployments/datanode-trash-deletion-http CLEANUP_DAYS=7 ...
```

### Handling Unreachable Datanodes

Pipeline uses serial or parallel host processing. If one node unreachable:

1. Identify IP/Hostname from Jenkins console
2. Check Cloud Provider Console (AWS/GCP) - is instance running?
3. If permanently decommissioned, update Ansible inventory:

```bash
cd ~/Documents/Repository/automation
vim ansible/environments/aws/eu/pro/hosts
# Remove stale entry
git commit -m "Remove decommissioned datanode from inventory"
```

---

## Operations How-To Guide

### How to Add a New Region

1. **Create new Groovy file** in GitLab:
   ```
   jobs/trash_clean-up_schedules/job_trash_cleanup_<region>.groovy
   ```

2. **Copy existing wrapper** (e.g., US-PRO):
   ```groovy
   // Update these values
   ANSIBLE_REGION = 'ca'  // New region
   ANSIBLE_CLOUD = 'aws'
   ANSIBLE_HOST = 'datanode-shared:datanode-self'
   ```

3. **Update schedule** (optional):
   ```groovy
   cron('H 6 * * 0')  // Keep Sunday 06:00 or customize
   ```

4. **Create Jenkins Pipeline**:
   - Navigate to `RaD-Deployments/aws-<region>-pro/`
   - New Item → Pipeline
   - Name: `Weekly-Schedules_Trash-Cleaner`
   - Pipeline from SCM → Git
   - Repository: `git@gitlab.devotools.com:devops/jenkins/jenkinsfiles.git`
   - Script Path: `jobs/trash_clean-up_schedules/job_trash_cleanup_<region>.groovy`

5. **Test**:
   ```bash
   jenkins_trigger RaD-Deployments/aws-<region>-pro/Weekly-Schedules_Trash-Cleaner
   jenkins_console RaD-Deployments/aws-<region>-pro/Weekly-Schedules_Trash-Cleaner 1 50
   ```

### How to Modify Cleanup Strategy

1. **Update wrapper Groovy file** in GitLab
2. **Change parameters**:
   ```groovy
   CLEANUP_STRATEGY = 'trash-amnesia-archive-180d'  // New strategy
   CLEANUP_DAYS = '7'  // Retention window
   ```

3. **Commit and push**:
   ```bash
   git add jobs/trash_clean-up_schedules/job_trash_cleanup_*.groovy
   git commit -m "Update cleanup strategy to 180d retention"
   git push origin master
   ```

4. **Jenkins auto-reloads** on next scheduled run

---

## Escalation Matrix

If disk utilization remains >90% after successful pipeline run:

**Level 1:** Verify `CLEANUP_STRATEGY` matches directory structure
```bash
# SSH to datanode
ssh <host> "ls -la /var/logt/data/"
ssh <host> "du -sh /var/logt/data/{trash,trash-amnesia,archive}"
```

**Level 2:** Check `VERIFY_DU_CMD` output in logs
```bash
jenkins_console_full RaD-Deployments/datanode-trash-deletion-http 366 | \
  grep -A 10 "VERIFY_DU_CMD"
```

**Level 3:** Contact DevOps/Infrastructure team
- **Slack:** #team-infrastructure or #team-devops
- **Jira:** Create incident ticket with build URL and console output

---

## Monitoring Dashboard

### Quick Status Check

```bash
# Check all regional schedules
for region in aws-ap-pro aws-us-pro aws-eu-pro gcp-eu-tef; do
  echo "=== $region ==="
  jenkins_builds RaD-Deployments/$region/Weekly-Schedules_Trash-Cleaner 1
done

# Check master job
jenkins_builds RaD-Deployments/datanode-trash-deletion-http 5
```

### Success Criteria

After successful cleanup:
- ✅ Build status: SUCCESS
- ✅ Disk space reclaimed: >10GB per datanode
- ✅ No Ansible UNREACHABLE errors
- ✅ All verification commands passed

---

## Related Resources

**Confluence:**
- Main Documentation: https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/5553946635

**GitLab:**
- Master Groovy: https://gitlab.devotools.com/devops/jenkins/jenkinsfiles/-/blob/master/jobs/job_ops_datanode_trash_deletion_http.groovy
- Wrapper Schedules: https://gitlab.devotools.com/devops/jenkins/jenkinsfiles/-/tree/master/jobs/trash_clean-up_schedules
- Ansible Playbook: https://gitlab.com/devo_corp/platform/ansible/environments/automation/-/blob/master/ansible/playbooks/datanode-trash-cleanup.yml

**Jenkins:**
- Master Job: https://jenkins.devotools.com/job/RaD-Deployments/job/datanode-trash-deletion-http/
- APAC Schedule: https://jenkins.devotools.com/job/RaD-Deployments/job/aws-ap-pro/job/Weekly-Schedules_Trash-Cleaner/
- US Schedule: https://jenkins.devotools.com/job/RaD-Deployments/job/aws-us-pro/job/Weekly-Schedules_Trash-Cleaner/
- EU Schedule: https://jenkins.devotools.com/job/RaD-Deployments/job/aws-eu-pro/job/Weekly-Schedules_Trash-Cleaner/
- GCP Schedule: https://jenkins.devotools.com/job/RaD-Deployments/job/gcp-eu-tef/job/Weekly-Schedules_Trash-Cleaner/

---

**Last Updated:** 2026-03-22
**Status:** ✅ Production - Weekly automated cleanup across all regions
**Maintained By:** DevOps/Infrastructure Team
