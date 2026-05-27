# Manager Decision Required: HMAC Error Resolution

**Issue:** ISM-15453 - HMAC authentication errors flooding Serrea logs (22,767 errors/day)
**Root Cause:** CaixaBank Go client using invalid/expired API credentials
**Customer Action:** Escalated - awaiting credential update

---

## Two Resolution Options

### Option 1: Suppress HMAC Logs (ERROR → WARN)

**What it does:**
- Changes log4j2.xml configuration on 3 Serrea nodes
- Reduces HMAC authentication failures from ERROR to WARN level
- Prevents log flooding while customer fixes credentials

**Pros:**
- ✅ Immediate relief from log noise
- ✅ Reduces log file growth
- ✅ Low risk (only logging change)
- ✅ Reversible (simple rollback)

**Cons:**
- ⚠️ Masks symptom (doesn't fix root cause)
- ⚠️ Requires service restart (rolling restart, ~90 seconds)
- ⚠️ May hide future HMAC issues from same source

**Effort:** 10 minutes
**Risk:** Low
**CHG Required:** Yes

---

### Option 2: Modify Prometheus Alert Rule

**What it does:**
- Adjusts alert threshold or filters to exclude known HMAC errors
- Keeps ERROR logs but prevents false positive alerts
- No service restart required

**Pros:**
- ✅ No service restart needed
- ✅ Preserves ERROR logs for troubleshooting
- ✅ Can filter by specific IP (213.229.173.244)
- ✅ Maintains visibility of other HMAC issues

**Cons:**
- ⚠️ Logs continue to grow (22,767 errors/day)
- ⚠️ Disk space concern if customer delays fix
- ⚠️ Alert may need adjustment as customer fixes issue

**Effort:** 5 minutes
**Risk:** Very Low
**CHG Required:** Yes (alert modification)

---

## Recommendation

**Recommended:** **Option 1 (Suppress to WARN)** + Customer escalation

**Rationale:**
1. Customer already escalated - fix expected within days
2. Log growth is immediate concern (22,767 errors/day × 3 nodes)
3. Rolling restart has minimal impact (~30 sec per node)
4. ERROR logs are noise (authentication expected to fail with invalid credentials)
5. Can revert to ERROR once customer fixes credentials

---

## Decision Required

**Please select:**

- [ ] **Option 1:** Suppress HMAC logs to WARN (proceed with CHG)
- [ ] **Option 2:** Modify Prometheus alert rule (proceed with CHG)
- [ ] **Both:** Suppress logs AND modify alert
- [ ] **Neither:** Wait for customer fix (no change)

---

**Manager Approval:**

Name: ________________
Date: ________________
Choice: ________________

---

**Next Steps (if Option 1 approved):**
1. Create CHG ticket
2. Schedule maintenance window (or proceed in production)
3. Execute runbook: `/tmp/hmac-logging-fix-runbook.md`
4. Verify success
5. Monitor for 1 hour
6. Update ISM-15453
