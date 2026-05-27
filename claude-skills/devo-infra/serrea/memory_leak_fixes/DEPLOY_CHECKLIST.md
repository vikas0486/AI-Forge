# Serrea Memory Leak Fix - Deployment Checklist

**Target:** Caixabank Serrea Cluster
**Issue:** ISM-16256
**Date:** 2026-04-14

---

## Pre-Deployment

- [ ] Review ISM-16256 in Jira
- [ ] Create CHG ticket in Jira
- [ ] Notify CaixaBank of maintenance window
- [ ] Verify SSH access to all 3 servers:
  ```bash
  ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 echo OK
  ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 echo OK
  ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 echo OK
  ```
- [ ] Review README.md thoroughly
- [ ] Test scripts locally (dry run)

---

## Deployment Phase

### Server 1: serrea-2 (the failing server - deploy first)

- [ ] Backup configuration
- [ ] Deploy configuration files
- [ ] Deploy ehcache.xml
- [ ] Restart Serrea service
- [ ] Wait 30 seconds for startup
- [ ] Verify health endpoint
- [ ] Monitor for 30 minutes
- [ ] Check for leak warnings

**Commands:**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation/serrea_memory_leak_fixes
./deploy_memory_leak_fixes.sh
# Select: serrea-2-pro-cloud-caixa-ibm-eu-de-3

./monitor_memory_leaks.sh serrea-2-pro-cloud-caixa-ibm-eu-de-3 10 180
```

### Server 2: serrea-1

- [ ] Deploy configuration files
- [ ] Restart Serrea service
- [ ] Verify health endpoint
- [ ] Monitor for 15 minutes

### Server 3: serrea-3

- [ ] Deploy configuration files
- [ ] Restart Serrea service
- [ ] Verify health endpoint
- [ ] Monitor for 15 minutes

---

## Post-Deployment Validation

- [ ] All 3 servers responding
- [ ] Cluster health check passes
- [ ] No 504 errors in application
- [ ] Connection pool stats look healthy
- [ ] Old Gen heap < 80%
- [ ] No immediate OOM errors

**Validation Commands:**
```bash
# Check cluster health
for server in serrea-{1,2,3}-pro-cloud-caixa-ibm-eu-de-{2,3,2}; do
    echo "=== $server ==="
    ssh $server 'curl -k -s https://localhost/search/system/health | jq .ok'
done

# Check connection pools
for server in serrea-{1,2,3}-pro-cloud-caixa-ibm-eu-de-{2,3,2}; do
    echo "=== $server ==="
    ssh $server 'curl -k -s https://localhost/search/system/health | jq .results.mysql'
done
```

---

## Monitoring (First 24 Hours)

### Hour 1
- [ ] Monitor heap usage continuously
- [ ] Check for connection leak warnings
- [ ] Verify no 504 errors

### Hour 2-4
- [ ] Check heap usage every 30 minutes
- [ ] Monitor application logs for errors

### Hour 5-24
- [ ] Check heap usage every 2 hours
- [ ] Verify Old Gen heap stays < 70%
- [ ] Confirm no OOM errors

**Monitoring Commands:**
```bash
# Continuous monitoring
./monitor_memory_leaks.sh serrea-2-pro-cloud-caixa-ibm-eu-de-3 30 120

# Check leak warnings
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 \
  'grep "Connection leak detection" /var/log/serrea/serrea.log | tail -20'

# Check OOM errors
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 \
  'grep -i "OutOfMemoryError" /var/log/serrea/serrea.log'
```

---

## Documentation

- [ ] Update ISM-16256 with deployment results
- [ ] Add comment in ISM-16256 with monitoring stats
- [ ] Update CHG ticket with completion
- [ ] Document any issues encountered
- [ ] Share success metrics with team

**Template for ISM-16256 Update:**
```
DEPLOYMENT COMPLETE

Deployed configuration fixes to all 3 Serrea servers:
- serrea-1-pro-cloud-caixa-ibm-eu-de-2 ✅
- serrea-2-pro-cloud-caixa-ibm-eu-de-3 ✅
- serrea-3-pro-cloud-caixa-ibm-eu-de-2 ✅

Fixes Applied:
✅ HikariCP leak detection (60s threshold)
✅ Bounded caches (max 10,000 entries)
✅ Connection pool optimization
✅ EHCache configuration

Results (after 2 hours):
- Old Gen heap: 65% (was 90%)
- Connection errors: 0 (was frequent)
- OOM errors: 0
- API 504 errors: 0

Monitoring ongoing for 24 hours.

Next: Apply permanent code fixes (Phase 3)
```

---

## Rollback Plan (If Needed)

If issues occur, rollback immediately:

```bash
# For each server
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 \
  'sudo -u logtrust cp /tmp/serrea_backup_before_fix/logtrust.properties.backup_* \
   /opt/logtrust/serrea/conf/logtrust.properties'

# Restart
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 'sudo systemctl restart serrea'

# Verify
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 \
  'curl -k -s https://localhost/search/system/health | jq .ok'
```

**Rollback Checklist:**
- [ ] Restore configuration from backup
- [ ] Remove ehcache.xml
- [ ] Restart service
- [ ] Verify service healthy
- [ ] Document rollback reason
- [ ] Update ISM-16256

---

## Success Criteria

✅ **Immediate (within 1 hour)**
- All servers restarted successfully
- Health endpoints responding
- No 504 errors

✅ **Short-term (within 24 hours)**
- Old Gen heap < 70%
- No OOM errors
- Connection leak warnings visible (if leaks exist)

✅ **Long-term (within 1 week)**
- Heap usage stable
- No service restarts needed
- 504 errors eliminated
- Application performance improved

---

## Next Steps

After successful deployment:

1. **Week 1:** Monitor daily, collect metrics
2. **Week 2:** Analyze leak warnings, identify code locations
3. **Week 3:** Get Serrea source code access
4. **Week 4:** Apply Java code fixes (Phase 3)
5. **Week 5:** Deploy permanent code fixes to production

---

**Deployment Lead:** Vikash Jaiswal
**Date:** 2026-04-14
**Status:** Ready for Execution
