# Devo Parser Deployment System

**Complete guide to Devo matasmafias parser deployment, troubleshooting, and service management.**

## What This Skill Does

Understand and manage Devo's parser deployment system (matasmafias) - from GitLab merge to production metamalote servers. Includes complete deployment architecture, service restart procedures, and troubleshooting for parser-related query failures.

**Use this skill for:**
- Understanding parser deployment architecture
- Troubleshooting "Unknown identifier" or "Unknown table" errors
- Verifying parser deployments across regions
- Restarting metamalote services after parser updates
- Investigating parser version mismatches between regions

---

## What Are Parsers?

**Parsers (matasmafias)** define how Devo ingests and structures data:

- **`.mata` files** - Table schema definitions (field names, types)
- **`.mafia` files** - Parsing logic (how to extract fields from raw events)

**Repository:** https://gitlab.com/devo_corp/data-ingestion/integrations/parsers/matasmafias

**Example Tables:**
- `cef0.paloAltoNetworks.panOs` - Palo Alto firewall logs
- `cloud.gsuite.reports.takeout` - Google Workspace takeout events
- `firewall.sonicwall.general` - SonicWall firewall logs

---

## Deployment Architecture

### Full Deployment Flow

```
1. GitLab MR → release-next branch
   ↓
2. Merge release-next → master branch
   ↓
3. GitLab CI Pipeline (2-5 minutes)
   - check_duplicates
   - gradlew_build
   - publish → Nexus Repository
   ↓
4. Jenkins: Config2/matas/master
   - Downloads from Nexus
   - Packages by region (awseu.tgz, awsus.tgz, etc.)
   - Uploads to S3: s3://lt-jenkins/matasmafias/master/
   ↓
5. Jenkins Regional Jobs (manual trigger)
   - deploy-matasmafias-aws-eu-pro
   - deploy-matasmafias-aws-us-pro
   - deploy-matasmafias-aws-apac-pro
   - deploy-matasmafias-aws-us3-pro
   - deploy-matasmafias-aws-ca-pro
   - deploy-matasmafias-gcp-telefonica-eu-pro
   - deploy-matasmafias-gcp-caixabank-eu-pro
   - deploy-matasmafias-aws-santander-eu-pro
   ↓
6. Ansible Playbook: matasmafias-v2.yml
   - Downloads from S3
   - Extracts to /var/tmp/matasmafias/
   - Syncs to /etc/logtrust/malote/defs/
   - Touches /etc/logtrust/malote/ (trigger reload)
   ↓
7. ⚠️ CRITICAL: Services DO NOT auto-reload!
   - Must manually restart metamalote services
   - Otherwise parsers sit on disk unused
```

### Regional Infrastructure

**Each region has:**

**A) Metamalote Servers** (query coordinators)
- EU: metamalote-1 through metamalote-10 (172.17.43.85:10100)
- US: metamalote-1 through metamalote-10 (172.25.62.129:10100)
- APAC: Similar structure
- Functions: Query parsing, routing, coordination

**B) Datanodes** (data storage & query execution)
- Shared datanodes: datanode-{1-8}-pro-cloud-shared-aws-eu-west-1
- Customer-dedicated: datanode-1-pro-cloud-{deloitte,gitlab,panda,etc}
- Functions: Store data, execute queries, run parsers on data

**Query Flow:**
```
User → Metamalote (coordinator) → Datanode (execution) → Data Files
```

**⚠️ BOTH need parsers and BOTH need service restarts!**

---

## File Locations

### On Metamalote/Datanode Servers

```bash
# Parser definitions
/etc/logtrust/malote/defs/
├── cef0/
│   ├── cef0-paloAltoNetworks-panOs.mata
│   ├── cef0-paloAltoNetworks-panOs.mafia
│   └── ...
├── cloud/
│   ├── cloud-gsuite-reports-takeout.mata
│   ├── cloud-gsuite-reports-takeout.mafia
│   └── ...
├── firewall/
├── my-app/
└── ... (307 subdirectories)

# Control directories
/etc/logtrust/malote/.db/      # Database files
/etc/logtrust/malote/.ks/      # Keystore files

# Temporary deployment location
/var/tmp/matasmafias/          # Ansible extraction directory
```

### In S3

```bash
# Check latest parser packages
aws s3 ls s3://lt-jenkins/matasmafias/master/ --profile production-limited

# Files by region
s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz       # EU
s3://lt-jenkins/matasmafias/master/matasmafias-awsus.tgz       # US
s3://lt-jenkins/matasmafias/master/matasmafias-awsapac.tgz     # APAC
s3://lt-jenkins/matasmafias/master/matasmafias-awsus3.tgz      # US3
s3://lt-jenkins/matasmafias/master/matasmafias-awsca.tgz       # Canada
s3://lt-jenkins/matasmafias/master/matasmafias-awseutef.tgz    # Telefónica
s3://lt-jenkins/matasmafias/master/matasmafias-awseucai.tgz    # Caixabank
```

---

## Service Architecture

### Services on Each Server

**1. metamalote (backend query engine)**
- Service: `metamalote.service`
- Process: Java process on port 10100
- Function: Executes queries, applies parsers to data
- **MUST restart after parser deployment**

**2. malote-controller (query coordinator)**
- Service: `malote-controller.service`
- Process: Java controller process
- Function: Routes queries, monitors metamalote health
- **MUST restart after parser deployment**

### Service Commands

```bash
# Check service status
sudo systemctl status metamalote
sudo systemctl status malote-controller

# Restart services (BOTH required for parser reload)
sudo systemctl restart metamalote
sudo systemctl restart malote-controller

# Check if metamalote is running
ps aux | grep -i 'java.*malote' | grep -v grep

# Check port 10100 listener
sudo ss -tlnp | grep :10100
```

---

## Deployment Verification

### 1. Check S3 Upload Timestamp

```bash
# Authenticate
aws sso login --profile production-limited

# Check latest upload
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz --profile production-limited

# Get detailed metadata
aws s3api head-object --bucket lt-jenkins --key matasmafias/master/matasmafias-awseu.tgz --profile production-limited
```

### 2. Verify Files on Server

```bash
# SSH to metamalote/datanode
ssh metamalote-1-pro-cloud-general-aws-eu-west-1

# Check parser file exists
sudo ls -lh /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata

# Check file timestamp (should match recent deployment)
sudo stat /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata | grep Modify

# Verify specific field exists in parser
sudo grep -n 'action_raw_event' /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata

# Check parsing function exists
sudo grep -n 'parseRawEventInDetail' /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mafia
```

### 3. Test with Maqui Query

```bash
# Test new field
maquieu 'from cef0.paloAltoNetworks.panOs where today()-1d <= eventdate < today() select action_raw_event limit 1'

# Test new table
maquieu 'from cloud.gsuite.reports.takeout where today()-7d <= eventdate < today() select * limit 1'

# Success: Returns data or "Rows processed: 0"
# Failure: "Unknown identifier" or "Unknown table"
```

### 4. Download & Inspect S3 Package

```bash
# Download parser package
mkdir -p /tmp/parser-check
cd /tmp/parser-check
aws s3 cp s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz . --profile production-limited

# List files in package
tar -tzf matasmafias-awseu.tgz | grep -E "paloAlto|gsuite"

# Extract and verify content
tar -xzf matasmafias-awseu.tgz cef0/cef0-paloAltoNetworks-panOs.mata
grep 'action_raw_event' cef0/cef0-paloAltoNetworks-panOs.mata
```

---

## Service Restart Procedures

### Restart EU Region (Complete)

**All 10 Metamalote Servers:**
```bash
# Restart metamalote backend (primary service)
for i in {1..10}; do 
    echo "=== metamalote-$i ==="; 
    ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && echo 'Restarted'"; 
done

# Restart malote-controller
for i in {1..10}; do 
    echo "=== metamalote-$i ==="; 
    ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart malote-controller && echo 'Restarted'"; 
done
```

**Shared Datanodes (most critical):**
```bash
for host in datanode-1-pro-cloud-shared-aws-eu-west-1 \
            datanode-2-pro-cloud-shared-aws-eu-west-1 \
            datanode-3-pro-cloud-shared-aws-eu-west-1 \
            datanode-7-pro-cloud-shared-aws-eu-west-1 \
            datanode-8-pro-cloud-shared-aws-eu-west-1; do 
    echo "=== $host ==="; 
    ssh $host "sudo systemctl restart metamalote && echo 'Restarted'" & 
done
wait
```

**Customer-Dedicated Datanodes:**
```bash
# Deloitte
ssh datanode-1-pro-cloud-deloitte-aws-eu-west-1 "sudo systemctl restart metamalote"

# GitLab (17 datanodes)
for i in {1..17}; do
    ssh datanode-$i-pro-cloud-gitlab-aws-eu-west-1 "sudo systemctl restart metamalote" &
done
wait

# Bitdefender (8 datanodes)
for i in {1..8}; do
    ssh datanode-$i-pro-cloud-bitdefender-aws-eu-west-1 "sudo systemctl restart metamalote" &
done
wait

# Panda (3 datanodes)
for i in {1..3}; do
    ssh datanode-$i-pro-cloud-panda-aws-eu-west-1 "sudo systemctl restart metamalote" &
done
wait
```

### Restart Other Regions

**US Region:**
```bash
for i in {1..10}; do 
    ssh metamalote-$i-pro-cloud-general-aws-us-east-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"; 
done
```

**APAC Region:**
```bash
for i in {1..10}; do 
    ssh metamalote-$i-pro-cloud-general-aws-ap-southeast-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"; 
done
```

---

## Troubleshooting Guide

### Issue 1: "Unknown identifier `field_name`"

**Symptoms:**
```
ERROR: Unknown identifier `action_raw_event`
Code: 1101001, Kind: QUERY_PARSING_ERROR
```

**Diagnosis:**
- Schema metadata knows about field (shown in Columns list)
- But actual data files don't have it
- Parser not loaded into running metamalote service

**Resolution:**
1. Verify parser file exists on server
2. Verify field exists in .mata file
3. **Restart metamalote service**
4. Wait 30 seconds for reload
5. Test query again

**Commands:**
```bash
# Check file
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo grep 'field_name' /etc/logtrust/malote/defs/path/to/parser.mata"

# Restart service
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote"

# Wait and test
sleep 30
maquieu 'from table.name where today()-1d <= eventdate < today() select field_name limit 1'
```

### Issue 2: "Unknown table `table.name`"

**Symptoms:**
```
ERROR: Unknown table `cloud.gsuite.reports.takeout`
Code: 2086000, Kind: MISSING_RESOURCE
```

**Diagnosis:**
- Parser files don't exist on server
- Or metamalote service hasn't loaded them

**Resolution:**
1. Check if parser files exist
2. If missing, re-run Jenkins deployment
3. If present, restart metamalote service

**Commands:**
```bash
# Check if parser exists
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo find /etc/logtrust/malote/defs -name '*gsuite-reports-takeout*'"

# If missing: re-run Jenkins job
# https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-eu-pro/

# If present: restart service
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote"
```

### Issue 3: Query Routes to Old Datanode

**Symptoms:**
```
ERROR: Unknown identifier `field_name`
Chain: [{/172.17.43.85:10100, message: } -> {/172.17.36.160:10100, message: }]
```

**Diagnosis:**
- Query hits metamalote-1 (172.17.43.85) ✅
- Routes to datanode (172.17.36.160) ❌ (old parser)
- Metamalote restarted but datanode not restarted

**Resolution:**
1. Identify the datanode IP from error
2. Find hostname: `grep "IP_ADDRESS" /etc/hosts`
3. Restart that datanode's metamalote service

**Commands:**
```bash
# Find datanode hostname
grep "172.17.36.160" /etc/hosts
# Output: 172.17.36.160 datanode-1-pro-cloud-deloitte-aws-eu-west-1

# Restart that datanode
ssh datanode-1-pro-cloud-deloitte-aws-eu-west-1 "sudo systemctl restart metamalote"

# Wait and test
sleep 30
maquieu 'from table.name where today()-1d <= eventdate < today() select field_name limit 1'
```

### Issue 4: Parser Deployed But Still Fails

**Symptoms:**
- Files exist on disk with correct content
- File timestamp matches recent deployment
- Query still fails with "Unknown identifier"

**Diagnosis:**
- Metamalote service running for days/weeks
- Service has old parsers cached in memory
- Ansible "touch" trigger doesn't work reliably

**Resolution:**
- **ALWAYS restart services after parser deployment**
- Don't rely on automatic reload

**Root Cause:**
```
Ansible playbook touches /etc/logtrust/malote/ directory
 ↓
Expected: Metamalote watches directory and reloads
 ↓
Reality: Metamalote doesn't detect change reliably
 ↓
Result: Parsers sit on disk unused for hours/days
```

**Solution:**
```bash
# Manual service restart is required
sudo systemctl restart metamalote
sudo systemctl restart malote-controller
```

### Issue 5: Works in US But Not EU

**Symptoms:**
- Same query works in US: `maquius 'from table select field'` ✅
- Same query fails in EU: `maquieu 'from table select field'` ❌

**Diagnosis:**
- Parser deployed to US but not EU
- Or Jenkins job failed for EU
- Or EU services not restarted

**Resolution:**
1. Check S3 timestamp for both regions
2. Verify Jenkins job ran for EU
3. Verify files exist on EU servers
4. Restart EU metamalote services

**Commands:**
```bash
# Compare S3 timestamps
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awsus.tgz --profile production-limited
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz --profile production-limited

# Check Jenkins build history
# https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-eu-pro/
# https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-us-pro/

# Restart EU services (see "Restart EU Region" section above)
```

---

## Common Deployment Issues

### Race Condition: Jenkins Started Too Early

**Problem:**
```
13:13:58 - GitLab merges release-next → master
13:14:53 - Jenkins EU deployment starts (55 seconds later!)
13:18:31 - GitLab CI finishes publishing to S3 (4 minutes after merge)
```

**Result:** Jenkins downloaded OLD parsers from S3 (before new publish completed)

**Solution:**
- Wait 5-10 minutes after master merge before triggering regional Jenkins jobs
- Or check GitLab CI pipeline status before starting Jenkins deployment

**Verification:**
```bash
# Check GitLab CI pipeline
# https://gitlab.com/devo_corp/data-ingestion/integrations/parsers/matasmafias/-/pipelines

# Wait for "publish" stage to complete (green checkmark)
# Then trigger Jenkins regional jobs
```

### Missing Service Restart in Ansible

**Problem:**
- Ansible playbook does NOT restart services
- Only touches directory (unreliable)

**Current Ansible Flow:**
```yaml
- name: Synchronize parsers to /etc/logtrust/malote/defs/
  synchronize: ...

- name: Touch over destination directory
  file:
    path: /etc/logtrust/malote
    state: touch
  # ⚠️ This doesn't reliably trigger reload!
```

**Recommended Fix:**
Add service restart to Ansible playbook:
```yaml
- name: Restart metamalote to load new parsers
  systemd:
    name: metamalote
    state: restarted

- name: Restart malote-controller
  systemd:
    name: malote-controller
    state: restarted

- name: Wait for services to start
  pause:
    seconds: 30
```

---

## Jenkins Jobs Reference

### Production Deployment Jobs

| Job | Region | URL |
|-----|--------|-----|
| **deploy-matasmafias-aws-eu-pro** | EU General | https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-eu-pro/ |
| **deploy-matasmafias-aws-us-pro** | US General | https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-us-pro/ |
| **deploy-matasmafias-aws-apac-pro** | APAC | https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-apac-pro/ |
| **deploy-matasmafias-aws-us3-pro** | US3 | https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-us3-pro/ |
| **deploy-matasmafias-aws-ca-pro** | Canada | https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-ca-pro/ |
| **deploy-matasmafias-gcp-telefonica-eu-pro** | Telefónica EU | https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-gcp-telefonica-eu-pro/ |
| **deploy-matasmafias-gcp-caixabank-eu-pro** | Caixabank EU | https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-gcp-caixabank-eu-pro/ |
| **deploy-matasmafias-aws-santander-eu-pro** | Santander | https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-santander-eu-pro/ |

### Master Build Job

**Config2/matas/master** - Packages and uploads to S3
- URL: https://jenkins.devotools.com/job/Config2/job/matas/job/master/
- Triggered: Automatically on master branch merge
- Duration: 2-5 minutes
- Output: Uploads .tgz files to S3

---

## Regional Server Lists

### EU Region Servers

**Metamalote Coordinators:**
```
metamalote-1-pro-cloud-general-aws-eu-west-1  (172.17.43.85)
metamalote-2-pro-cloud-general-aws-eu-west-1
metamalote-3-pro-cloud-general-aws-eu-west-1
metamalote-4-pro-cloud-general-aws-eu-west-1
metamalote-5-pro-cloud-general-aws-eu-west-1
metamalote-6-pro-cloud-general-aws-eu-west-1
metamalote-7-pro-cloud-general-aws-eu-west-1
metamalote-8-pro-cloud-general-aws-eu-west-1
metamalote-9-pro-cloud-general-aws-eu-west-1
metamalote-10-pro-cloud-general-aws-eu-west-1
```

**Shared Datanodes:**
```
datanode-1-pro-cloud-shared-aws-eu-west-1
datanode-2-pro-cloud-shared-aws-eu-west-1
datanode-3-pro-cloud-shared-aws-eu-west-1
datanode-7-pro-cloud-shared-aws-eu-west-1
datanode-8-pro-cloud-shared-aws-eu-west-1
```

**Customer-Dedicated Datanodes:**
```
# Deloitte
datanode-1-pro-cloud-deloitte-aws-eu-west-1

# GitLab (1-17)
datanode-{1..17}-pro-cloud-gitlab-aws-eu-west-1

# Bitdefender (1-8)
datanode-{1..8}-pro-cloud-bitdefender-aws-eu-west-1

# Panda (1-3)
datanode-{1..3}-pro-cloud-panda-aws-eu-west-1

# Trustwave
datanode-1-pro-cloud-trustwave-use2-aws-eu-west-1
datanode-2-pro-cloud-trustwave-use2-aws-eu-west-1
datanode-dr-1-pro-cloud-trustwave-use2-aws-eu-west-1
datanode-dr-2-pro-cloud-trustwave-use2-aws-eu-west-1

# NCSC Bahrain
datanode-1-prod-ncscbh-cloud-ncscbh-aws-eu-west-1
datanode-2-prod-ncscbh-cloud-ncscbh-aws-eu-west-1
datanode-1-prod-ncscbh-cloud-self-aws-eu-west-1
datanode-2-prod-ncscbh-cloud-self-aws-eu-west-1

# Self/Internal
datanode-{1..5}-pro-cloud-self-aws-eu-west-1
```

**Total EU Servers Requiring Parser Updates:** ~60 servers

---

## Deployment Checklist

### For Parser Team

**Before Deployment:**
- [ ] Merge MR to `release-next` branch
- [ ] Merge `release-next` to `master` branch
- [ ] Wait for GitLab CI pipeline to complete (check "publish" stage)
- [ ] Wait 5 minutes for S3 upload to finish

**Deployment:**
- [ ] Trigger Jenkins regional jobs
- [ ] Wait for Ansible playbook to complete
- [ ] **Restart metamalote services on all servers**
- [ ] **Restart malote-controller services on all servers**

**Verification:**
- [ ] Test queries in each region
- [ ] Check for "Unknown identifier" errors
- [ ] Verify new tables exist
- [ ] Test new fields are accessible

**Rollback (if needed):**
- [ ] Re-deploy previous S3 package
- [ ] Restart services again
- [ ] Verify queries work with old parsers

### For Operations Team

**When Queries Fail After Deployment:**
- [ ] Check if files exist on server
- [ ] Check file timestamps match deployment
- [ ] Verify field/table in parser definition
- [ ] **Restart metamalote service**
- [ ] **Restart malote-controller service**
- [ ] Wait 30 seconds
- [ ] Test query again
- [ ] Check query routing (which datanode?)
- [ ] Restart datanode if needed

---

## Real-World Case Study: CHG-10577

**Issue:** Parsers deployed April 30, but queries still failing May 1

**Investigation:**
1. Verified S3 had new parsers (uploaded May 1 02:26 UTC) ✅
2. Verified files on metamalote servers (timestamp Apr 30 13:12) ✅
3. Verified fields exist in .mata files ✅
4. Queries still failing ❌

**Root Cause Discovery:**
```
Query error showed: Chain: [{/172.17.43.85:10100} -> {/172.17.36.160:10100}]
```
- 172.17.43.85 = metamalote-1 (coordinator)
- 172.17.36.160 = datanode-1-pro-cloud-deloitte (executor)

**Diagnosis:**
- Parsers deployed to disk ✅
- Ansible touched directory ✅
- Services NEVER restarted ❌
- Services running since April 4 (27 days!)
- Old parsers cached in memory

**Solution:**
```bash
# Restarted 10 metamalote servers (both services)
for i in {1..10}; do 
    ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"; 
done

# Restarted shared datanodes
for host in datanode-{1,2,3,7,8}-pro-cloud-shared-aws-eu-west-1; do 
    ssh $host "sudo systemctl restart metamalote"; 
done

# Restarted Deloitte datanode (where query failed)
ssh datanode-1-pro-cloud-deloitte-aws-eu-west-1 "sudo systemctl restart metamalote"
```

**Result:** All queries working ✅

**Lesson Learned:**
- Ansible "touch" trigger is unreliable
- ALWAYS restart services after parser deployment
- Both metamalote AND datanodes need restart
- Services can run for weeks without reloading parsers

---

## Quick Reference Commands

### Check Parser Deployment Status

```bash
# S3 timestamp
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz --profile production-limited

# Server file timestamp
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo stat /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata"

# Service uptime (how long since restart?)
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo systemctl status metamalote | grep 'Active:'"

# Test query
maquieu 'from cef0.paloAltoNetworks.panOs where today()-1d <= eventdate < today() select * limit 1'
```

### Restart Services

```bash
# Single server
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"

# All EU metamalote servers
for i in {1..10}; do ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"; done

# Shared datanodes
for i in 1 2 3 7 8; do ssh datanode-$i-pro-cloud-shared-aws-eu-west-1 "sudo systemctl restart metamalote"; done
```

### Troubleshoot Failed Query

```bash
# 1. Identify which datanode the query hit
maquieu 'from table where condition select *'
# Look for: Chain: [{/172.17.43.85:10100} -> {/172.17.36.160:10100}]

# 2. Find datanode hostname
grep "172.17.36.160" /etc/hosts

# 3. Check if parser exists on that datanode
ssh datanode-1-pro-cloud-deloitte-aws-eu-west-1 "sudo ls /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.*"

# 4. Restart that datanode
ssh datanode-1-pro-cloud-deloitte-aws-eu-west-1 "sudo systemctl restart metamalote"

# 5. Test again
sleep 30
maquieu 'from table where condition select *'
```

---

## Related Resources

- **GitLab Repository:** https://gitlab.com/devo_corp/data-ingestion/integrations/parsers/matasmafias
- **Jenkins Deployment Jobs:** https://jenkins.devotools.com/job/deploy-matasmafias/
- **Confluence - Parser Deployment:** https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3643146268/Deployment+of+matasmafias+to+Production
- **Confluence - Telefónica/Caixabank:** https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/5394595844/Production+Deployment+Process+for+Telefonica+and+Caixabank

## Related Skills

- `/devo-query` - Query system with 98 helper functions
- `/devo-jira` - Track parser deployment tickets (CHG-*)
- `/automation-resilience-infra` - Ansible automation for infrastructure

---

**Last Updated:** 2026-05-01
**Status:** ✅ Production Ready (Based on CHG-10577 resolution)
**Maintainer:** Platform Operations Team
