# CHG: Suppress HMAC Authentication Error Logging - CaixaBank Serrea

**Date:** 2026-03-01
**CHG ID:** [To be assigned]
**Related Incident:** ISM-15453
**Root Cause:** CaixaBank Go client using invalid/expired API credentials (IP: 213.229.173.244)

---

## Executive Summary

**Problem:** 22,767 HMAC authentication errors per day flooding Serrea logs across 3 nodes
**Impact:** Log file growth, reduced visibility of actual issues
**Solution:** Suppress HMAC authentication failures from ERROR to WARN in log4j2.xml
**Duration:** 10 minutes | **Downtime:** ~30 seconds per node (rolling restart)

---

## Manager Decision Required

### Option 1: Suppress HMAC Logs (ERROR → WARN) ⭐ RECOMMENDED

**What:** Change log4j2.xml on 3 Serrea nodes to reduce HMAC errors to WARN level
**Pros:** Immediate log relief, reduces growth, low risk, reversible
**Cons:** Requires restart (~90s rolling), masks symptom temporarily
**Effort:** 10 min | **Risk:** Low

### Option 2: Modify Prometheus Alert Rule

**What:** Adjust alert to exclude known HMAC errors, keep ERROR logs
**Pros:** No restart, preserves logs, filters by IP
**Cons:** Logs continue growing (22,767/day), disk space concern
**Effort:** 5 min | **Risk:** Very Low

### Recommendation: Option 1

**Rationale:** Customer escalated, log growth immediate concern, minimal restart impact

### Decision

- [x] **Option 1:** Suppress to WARN (proceed with CHG)
- [ ] **Option 2:** Modify alert rule
- [ ] **Both:** Suppress + modify alert
- [ ] **Neither:** Wait for customer fix

**Approved by:** ________________ **Date:** ________________

---

## Change Request Details

### Affected Systems

| Node | Hostname | IP | Role |
|------|----------|-----|------|
| Serrea-1 | serrea-1-pro-cloud-caixa-ibm-eu-de-2 | 10.9.64.20 | Akka node |
| Serrea-2 | serrea-2-pro-cloud-caixa-ibm-eu-de-3 | 10.9.128.20 | Akka node |
| Serrea-3 | serrea-3-pro-cloud-caixa-ibm-eu-de-2 | 10.9.128.21 | Akka node |

### Configuration Change

**File:** `/etc/logtrust/serrea/log4j2.xml`

**Configuration to add:**
```xml
<!-- Suppress HMAC authentication failures -->
<Logger name="com.devo.lugin.hmac.services.UserDomainHMACAccessService" level="WARN"/>
<Logger name="com.devo.web.common.api.auth.HMAC" level="WARN"/>
```

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Service restart fails | Low | High | Rolling restart + immediate rollback |
| Configuration error | Low | Medium | Backup + verification before restart |
| Cluster unavailability | Very Low | High | 30s restart per node, cluster available |

### Success Criteria

- ✅ All 3 Serrea services active
- ✅ Akka cluster: all nodes "Up", unreachable=0
- ✅ No new ERROR logs for HMAC failures
- ✅ API health checks pass
- ✅ Configuration persists after restart

---

## Implementation Runbook

### Pre-Execution Checklist

- [ ] Manager approval obtained
- [ ] CHG ticket created and approved
- [ ] Maintenance window scheduled (or approved for production)
- [ ] All 3 Serrea nodes accessible
- [ ] Sudo access confirmed

---

### Step 1: Pre-Change Verification (2 minutes)

#### 1.1 Check current HMAC error rate
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo -n "$node: "; ssh $node "grep 'Invalid domain credentials' /var/log/serrea/serrea.log | grep '2026-03-01' | wc -l"
done
```
**Expected:** ~7,600 errors per node

#### 1.2 Verify Serrea services active
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo -n "$node: "; ssh $node "systemctl is-active serrea"
done
```
**Expected:** All show `active`

#### 1.3 Check Akka cluster health
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq -r '.ok, .details.unreachable | length'
```
**Expected:** `true` and `0` (all nodes Up, none unreachable)

---

### Step 2: Backup Configuration (1 minute)

#### 2.1 Create backups on all nodes
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo cp /etc/logtrust/serrea/log4j2.xml /etc/logtrust/serrea/log4j2.xml.backup.$(date +%Y%m%d_%H%M%S)"
done
```

#### 2.2 Verify backups created
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "=== $node ==="; ssh $node "ls -lh /etc/logtrust/serrea/log4j2.xml.backup.*"
done
```

---

### Step 3: Apply Configuration Changes (3 minutes)

#### 3.1 Check if already configured
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo -n "$node: "; ssh $node "sudo grep -q 'UserDomainHMACAccessService' /etc/logtrust/serrea/log4j2.xml && echo 'Already configured' || echo 'Not configured'"
done
```

#### 3.2 Apply configuration to Serrea-1
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo sed -i '/<\\/Loggers>/i\\    <!-- Suppress HMAC authentication failures -->\\n    <Logger name=\"com.devo.lugin.hmac.services.UserDomainHMACAccessService\" level=\"WARN\"/>\\n    <Logger name=\"com.devo.web.common.api.auth.HMAC\" level=\"WARN\"/>' /etc/logtrust/serrea/log4j2.xml"
```

#### 3.3 Verify Serrea-1 configuration
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo grep -A 2 'Suppress HMAC' /etc/logtrust/serrea/log4j2.xml"
```
**Expected:** Shows 3 lines (comment + 2 Logger entries)

#### 3.4 Apply configuration to Serrea-2
```bash
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo sed -i '/<\\/Loggers>/i\\    <!-- Suppress HMAC authentication failures -->\\n    <Logger name=\"com.devo.lugin.hmac.services.UserDomainHMACAccessService\" level=\"WARN\"/>\\n    <Logger name=\"com.devo.web.common.api.auth.HMAC\" level=\"WARN\"/>' /etc/logtrust/serrea/log4j2.xml"
```

#### 3.5 Verify Serrea-2 configuration
```bash
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo grep -A 2 'Suppress HMAC' /etc/logtrust/serrea/log4j2.xml"
```

#### 3.6 Apply configuration to Serrea-3
```bash
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo sed -i '/<\\/Loggers>/i\\    <!-- Suppress HMAC authentication failures -->\\n    <Logger name=\"com.devo.lugin.hmac.services.UserDomainHMACAccessService\" level=\"WARN\"/>\\n    <Logger name=\"com.devo.web.common.api.auth.HMAC\" level=\"WARN\"/>' /etc/logtrust/serrea/log4j2.xml"
```

#### 3.7 Verify Serrea-3 configuration
```bash
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo grep -A 2 'Suppress HMAC' /etc/logtrust/serrea/log4j2.xml"
```

---

### Step 4: Rolling Restart (3 minutes)

⚠️ **IMPORTANT:** Restart one node at a time, verify health before proceeding to next

#### 4.1 Restart Serrea-3 (first)
```bash
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea"
sleep 30
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "systemctl is-active serrea"
```
**Expected:** `active`

#### 4.2 Verify Serrea-3 rejoined cluster
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq '.details.nodes[] | select(.address | contains("10.9.64.21"))'
```
**Expected:** `"status": "Up"`

#### 4.3 Restart Serrea-2 (second)
```bash
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo systemctl restart serrea"
sleep 30
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "systemctl is-active serrea"
```

#### 4.4 Verify Serrea-2 rejoined cluster
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq '.details.unreachable | length'
```
**Expected:** `0` (no unreachable nodes)

#### 4.5 Restart Serrea-1 (last)
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea"
sleep 30
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "systemctl is-active serrea"
```

#### 4.6 Final cluster health check
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq .
```
**Expected:** All 3 nodes "Up", unreachable=0

---

### Step 5: Post-Change Verification (2 minutes)

#### 5.1 Verify all services running
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo -n "$node: "; ssh $node "systemctl is-active serrea"
done
```

#### 5.2 Check for new ERROR logs (should be none)
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "tail -100 /var/log/serrea/serrea.log | grep 'ERROR.*Invalid domain credentials'"
```
**Expected:** No results (or only old errors before restart)

#### 5.3 Verify configuration persisted
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "=== $node ==="; ssh $node "sudo grep 'UserDomainHMACAccessService' /etc/logtrust/serrea/log4j2.xml"
done
```

#### 5.4 Test API functionality
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo -n "$node: "; ssh $node "curl -sk http://localhost:8855/search/system/health" | jq -r '.ok'
done
```
**Expected:** All return `true`

---

### Step 6: Monitor (1 hour)

#### 6.1 Monitor for new HMAC errors
```bash
# Wait 5 minutes for new errors to potentially appear
sleep 300
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "tail -100 /var/log/serrea/serrea.log | grep -i hmac"
```
**Expected:** No ERROR logs, only WARN or no logs

#### 6.2 Check log growth rate
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "=== $node ==="; ssh $node "du -h /var/log/serrea/serrea.log"
done
```

#### 6.3 Monitor cluster stability
```bash
# Check every 15 minutes for 1 hour
for i in {1..4}; do
  echo "=== Check $i/4 ==="
  ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq -r '.ok, .details.unreachable | length'
  sleep 900
done
```

---

## Rollback Procedure

**If issues occur, execute rollback immediately:**

### Rollback Step 1: Restore backups
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo cp /etc/logtrust/serrea/log4j2.xml.backup.* /etc/logtrust/serrea/log4j2.xml"
done
```

### Rollback Step 2: Rolling restart
```bash
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo systemctl restart serrea" && sleep 30
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
```

### Rollback Step 3: Verify cluster health
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq .
```

**Rollback Duration:** 5 minutes

---

## Post-Implementation

### Communication

**After successful completion:**
- [ ] Update ISM-15453: "CHG-XXXXX completed - HMAC errors suppressed to WARN"
- [ ] Update CHG ticket: "Successfully completed, all nodes healthy"
- [ ] Notify: Manager/Team lead

**If rollback required:**
- [ ] Update ISM-15453: "CHG-XXXXX rolled back - [reason]"
- [ ] Update CHG ticket: "Rolled back due to [issue]"
- [ ] Escalate: Manager + NOC team

### Monitoring

**Next 24 hours:**
- Monitor log file sizes (should grow slower)
- Check cluster stability (no new issues)
- Watch for customer credential update (then revert to ERROR)

---

## Execution Record

**Executed by:** ________________
**Start time:** ________________
**End time:** ________________
**CHG Status:** ________________

**Issues encountered:**
```
[None expected - document any issues here]
```

**Final cluster health:**
```
[Paste final health check output]
```

**Success criteria met:**
- [ ] All 3 services active
- [ ] Cluster healthy (all nodes Up)
- [ ] No new HMAC ERROR logs
- [ ] Configuration persisted
- [ ] No new issues introduced

---

## Quick Command Summary

```bash
# PRE-CHECK
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo -n "$node: "; ssh $node "systemctl is-active serrea"
done

# BACKUP
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo cp /etc/logtrust/serrea/log4j2.xml /etc/logtrust/serrea/log4j2.xml.backup.$(date +%Y%m%d_%H%M%S)"
done

# APPLY CONFIG (all 3 nodes)
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo sed -i '/<\\/Loggers>/i\\    <!-- Suppress HMAC authentication failures -->\\n    <Logger name=\"com.devo.lugin.hmac.services.UserDomainHMACAccessService\" level=\"WARN\"/>\\n    <Logger name=\"com.devo.web.common.api.auth.HMAC\" level=\"WARN\"/>' /etc/logtrust/serrea/log4j2.xml"
  ssh $node "sudo grep -A 2 'Suppress HMAC' /etc/logtrust/serrea/log4j2.xml"
done

# ROLLING RESTART
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo systemctl restart serrea" && sleep 30
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30

# VERIFY
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq .
```

---

**Document Version:** 1.0 (Consolidated)
**Created:** 2026-03-01
**Status:** Ready for execution
**Estimated Duration:** 10 minutes
**Estimated Downtime:** 30 seconds per node (rolling)
