# CHG-10577 Resolution Summary

**Issue:** Parser deployment completed but queries failing in EU region  
**Date:** 2026-05-01  
**Status:** ✅ RESOLVED

---

## Timeline

### April 30, 2026

**08:20 UTC** - MR 761 merged (GSuite Takeout parser)  
**08:29 UTC** - MR 754 merged (Palo Alto action_raw_event field)  
**13:13 UTC** - MRs merged from release-next → master  
**13:14 UTC** - Jenkins EU deployment #557 started (55 seconds after merge!)  
**13:18 UTC** - GitLab CI finished publishing to S3

**Problem:** Jenkins downloaded OLD parsers (S3 publish still in progress)

### May 1, 2026

**02:26 UTC** - Config2/matas/master build #945 uploaded NEW parsers to S3  
**02:50 UTC** - Investigation begins - queries still failing  
**03:20 UTC** - Root cause identified: Services not restarted  
**03:25 UTC** - Restarted all 10 EU metamalote servers (24 services total)  
**03:30 UTC** - ✅ All queries working

---

## Affected Tables

| Table | Issue | Fixed |
|-------|-------|-------|
| `cef0.paloAltoNetworks.panOs` | Unknown identifier `action_raw_event` | ✅ |
| `cloud.gsuite.reports.takeout` | Unknown table | ✅ |
| `cloud.gsuite.reports.classroom` | Unknown table | ✅ |
| `firewall.sonicwall.general` | Unknown identifier `precise_timestamp` | ✅ |
| `firewall.sonicwall.genv58` | Unknown identifier `precise_timestamp` | ✅ |
| `adn.barracuda.adc.access` | Unknown table | ✅ |

---

## Root Cause

**Parsers deployed to disk but services never reloaded them.**

### What Went Wrong

1. **Jenkins deployment #557 ran too early**
   - Started 55 seconds after master merge
   - GitLab CI still publishing to S3 (takes 4+ minutes)
   - Downloaded OLD parsers from S3

2. **Ansible playbook doesn't restart services**
   - Deploys files to `/etc/logtrust/malote/defs/` ✅
   - Touches `/etc/logtrust/malote/` directory ✅
   - **Does NOT restart services** ❌

3. **Services cached old parsers in memory**
   - metamalote services running since April 4 (27 days!)
   - Parsers loaded at startup, never reloaded
   - "Touch" trigger doesn't work reliably

4. **Query routing through datanodes**
   - Query hits metamalote-1 (coordinator) ✅
   - Routes to datanode-1-pro-cloud-deloitte ❌
   - Datanode had old parser in memory

---

## Services Restarted

**EU Region - 24 services across 14 servers:**

### Metamalote Coordinators (10 servers)
```
metamalote-1 through metamalote-10
  - metamalote.service (backend)
  - malote-controller.service (coordinator)
Total: 20 services
```

### Datanodes (4 servers)
```
datanode-1-pro-cloud-shared-aws-eu-west-1
datanode-2-pro-cloud-shared-aws-eu-west-1
datanode-3-pro-cloud-shared-aws-eu-west-1
datanode-1-pro-cloud-deloitte-aws-eu-west-1
  - metamalote.service only
Total: 4 services
```

---

## Verification Results

### Before Fix
```bash
maquieu 'from cef0.paloAltoNetworks.panOs select action_raw_event limit 1'
# ERROR: Unknown identifier `action_raw_event`
```

### After Fix
```bash
maquieu 'from cef0.paloAltoNetworks.panOs select action_raw_event limit 1'
# null USERID /10.161.8.207
# Rows processed: 1
# ✅ SUCCESS
```

All 6 affected tables verified working.

---

## Lessons Learned

### Critical Findings

1. **Jenkins must wait for GitLab CI publish stage**
   - Wait 5-10 minutes after master merge
   - Check pipeline status before triggering regional jobs

2. **Services MUST be restarted after parser deployment**
   - Ansible "touch" is unreliable
   - Manual service restart required
   - Both metamalote AND datanodes need restart

3. **Services can run for weeks without reloading**
   - metamalote processes don't auto-reload parsers
   - Long-running services have stale parsers cached
   - Service restart is the ONLY reliable way to reload

4. **Query routing matters**
   - Queries route through datanodes
   - Datanode services also need restart
   - Check error chain to identify which datanode

### Recommended Changes

**For Parser Team:**
1. Add 5-minute delay between master merge and Jenkins trigger
2. Verify GitLab CI "publish" stage completes before deployment
3. Add service restart confirmation to deployment checklist

**For Ansible Playbook:**
```yaml
# Add to matasmafias-v2.yml after file sync:
- name: Restart metamalote to load new parsers
  systemd:
    name: metamalote
    state: restarted

- name: Restart malote-controller
  systemd:
    name: malote-controller
    state: restarted

- name: Wait for services to stabilize
  pause:
    seconds: 30
```

**For Operations:**
1. Create automated restart script for all regions
2. Add post-deployment verification queries
3. Document service restart as REQUIRED step
4. Create monitoring for "service uptime vs parser version"

---

## Commands Used

### Investigation
```bash
# Check S3 timestamp
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz --profile production-limited

# Check file on server
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo stat /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata"

# Verify parser content
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo grep 'action_raw_event' /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata"

# Check service status
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo systemctl status metamalote | grep Active"
```

### Resolution
```bash
# Restart all EU metamalote servers
for i in {1..10}; do 
    ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"; 
done

# Restart shared datanodes
for host in datanode-{1,2,3}-pro-cloud-shared-aws-eu-west-1; do 
    ssh $host "sudo systemctl restart metamalote"; 
done

# Restart specific customer datanode
ssh datanode-1-pro-cloud-deloitte-aws-eu-west-1 "sudo systemctl restart metamalote"

# Wait for reload
sleep 30

# Verify fix
maquieu 'from cef0.paloAltoNetworks.panOs where today()-1d <= eventdate < today() select action_raw_event, name limit 1'
```

---

## Impact Assessment

### Duration
- **Total Downtime:** 14 hours (April 30 13:00 - May 1 03:30 UTC)
- **Resolution Time:** 30 minutes (investigation + restart)
- **Affected Regions:** EU only (US working due to infrastructure overlap)

### Affected Customers
- Any customer querying the 6 affected tables in EU region
- Queries returned "Unknown identifier" or "Unknown table" errors
- No data loss - only query failures

### Cost
- 14 hours of broken queries for affected tables
- Parser team investigation time
- Operations team response time
- No customer-visible incidents reported (likely low query volume)

---

## Prevention Strategy

### Immediate (Already Done)
- ✅ Restarted all EU services
- ✅ Verified all tables working
- ✅ Documented root cause and solution

### Short-term (Next Week)
- [ ] Update Ansible playbook to restart services
- [ ] Create automated restart script for all regions
- [ ] Add post-deployment verification queries to Jenkins
- [ ] Document service restart requirement in Confluence

### Long-term (Next Month)
- [ ] Add monitoring for "parser version vs service uptime"
- [ ] Create alert for "service running >7 days without restart"
- [ ] Implement automated parser version checks
- [ ] Add parser reload endpoint to metamalote API (if feasible)

---

## Related Tickets

- **CHG-10577** - Matasmafias deployment for 30-04-2026
- **CHG-9855** - Parent: Deployment of MatasMafias to Telefónica & Caixabank
- **MR 754** - [INT-4730] Parsed action in raw event in cef0.paloaltoNetworks.panOs
- **MR 761** - [INT-4775] Added parser cloud.gsuite.reports.takeout
- **MR 762** - [PAR-29302] [Caixabank] Fix my.app.filemon_pr**** tables
- **MR 763** - [CHG-10577] Matasmafias deployment for 30-04-2026
- **MR 764** - [CHG-10577] Matasmafias deployment for 30-04-2026 for Caixabank

---

## Key Takeaway

**Parser deployment is a 2-step process:**

1. Deploy files via Ansible ✅
2. **Restart services manually** ⚠️ (REQUIRED!)

Without step 2, parsers sit on disk unused indefinitely.

---

**Resolution Date:** 2026-05-01 03:30 UTC  
**Resolved By:** Platform Operations (with Claude Code assistance)  
**Status:** ✅ Complete - All services operational
