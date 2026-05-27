# CaixaBank Serrea - Memory Leak Fix Monitoring Schedule

## Deployment Details
- **Deployment Date:** 2026-04-14 08:10-08:45 UTC
- **Deployed By:** Vikash Jaiswal
- **Jira Ticket:** PLEN-8842
- **Related Incident:** ISM-16256

---

## Monitoring Checkpoints

### ✅ Checkpoint 1: 8.5 Hours Post-Deployment
**Date/Time:** 2026-04-14 16:45 UTC
**Status:** 🟢 EXCELLENT - All metrics healthy
**Report:** `STATUS_REPORT_20260414_8.5hours.md`

**Key Findings:**
- ✅ Zero OutOfMemoryError
- ✅ Zero connection leak warnings
- ✅ Zero connection pool exhaustion
- ✅ Memory stable (26-31 GB RSS)
- ✅ All 3 nodes healthy
- ✅ 100% success criteria met (6/6)

---

### ⏳ Checkpoint 2: 24 Hours Post-Deployment
**Scheduled:** 2026-04-15 08:10 UTC
**Status:** PENDING
**Commands to Run:**

```bash
# Run comprehensive health check
cd /Users/vikash.jaiswal/.claude/skills/devo-infra/serrea
./monitor_memory_leaks.sh serrea-2-pro-cloud-caixa-ibm-eu-de-3

# Or use the skill
/devo-infra check performance and status
```

**What to Check:**
- [ ] OutOfMemoryError count (should be 0)
- [ ] Connection leak warnings (should be 0)
- [ ] Heap usage trend (should be stable)
- [ ] Connection pool utilization (should be < 70%)
- [ ] All 3 nodes UP and stable
- [ ] GC patterns (look for Full GC frequency)

**Success Criteria:**
- No OutOfMemoryError in 24 hours
- Memory usage stable (no upward trend)
- Connection pools healthy
- No service restarts required

---

### ⏳ Checkpoint 3: 48 Hours Post-Deployment
**Scheduled:** 2026-04-16 08:10 UTC
**Status:** PENDING

**What to Check:**
- [ ] Verify 48-hour stability
- [ ] Compare heap dumps (if available)
- [ ] Check for any cache eviction issues
- [ ] Verify no performance degradation
- [ ] Customer feedback (any 504 errors reported?)

---

### ⏳ Checkpoint 4: 7 Days Post-Deployment
**Scheduled:** 2026-04-21 08:10 UTC
**Status:** PENDING

**What to Check:**
- [ ] One-week stability confirmed
- [ ] Heap usage trend analysis
- [ ] GC log analysis
- [ ] Connection leak warnings (should still be 0)
- [ ] Customer satisfaction
- [ ] Decision: Proceed with Phase 2 (code fixes)

---

## Escalation Criteria

### ⚠️ Yellow Alert - Investigate
- Heap usage > 80% sustained for > 1 hour
- Connection pool utilization > 70%
- 1-5 connection leak warnings
- Single OutOfMemoryError

### 🚨 Red Alert - Immediate Action
- Heap usage > 90% sustained
- Connection pool exhausted
- Multiple OutOfMemoryError events
- Service crashes/restarts
- API 504 errors returning

**Escalation Path:**
1. Review logs and metrics
2. Check for root cause
3. Consider rollback if critical
4. Update PLEN-8842 with findings
5. Contact Vikash Jaiswal if needed

---

## Monitoring Commands

### Quick Health Check
```bash
# Check cluster health
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 \
  'curl -sk http://localhost:8855/search/system/health | jq .'

# Check for errors
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "=== $node ==="
  ssh $node 'grep -c "OutOfMemoryError\|Connection leak" /var/log/serrea/serrea.log'
done
```

### Detailed Status Check
```bash
# Run the comprehensive check script
/tmp/check_serrea_status.sh

# Or detailed check
/tmp/detailed_check.sh
```

### Memory Analysis
```bash
# Check heap usage per node
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "=== $node ==="
  ssh $node 'PID=$(pgrep -f serrea | head -1); ps -p $PID -o rss= | awk "{print \$1/1024/1024 \" GB\"}"'
done
```

---

## Report Archive

| Date | Time Since Deploy | Status | Report File |
|------|-------------------|--------|-------------|
| 2026-04-14 16:45 UTC | 8.5 hours | 🟢 EXCELLENT | STATUS_REPORT_20260414_8.5hours.md |
| 2026-04-15 08:10 UTC | 24 hours | ⏳ PENDING | To be created |
| 2026-04-16 08:10 UTC | 48 hours | ⏳ PENDING | To be created |
| 2026-04-21 08:10 UTC | 7 days | ⏳ PENDING | To be created |

---

## Next Actions

### Tomorrow (2026-04-15)
- [ ] Run 24-hour status check
- [ ] Create STATUS_REPORT_20260415_24hours.md
- [ ] Update PLEN-8842 with 24-hour results
- [ ] Verify all success criteria still met

### This Week
- [ ] Monitor daily for any issues
- [ ] Collect trend data
- [ ] Prepare Phase 2 planning (code fixes)

### Next Month
- [ ] Deploy permanent Java code fixes
- [ ] Final validation
- [ ] Close PLEN-8842
- [ ] Document lessons learned

---

**Last Updated:** 2026-04-14 16:50 UTC
**Next Check:** 2026-04-15 08:10 UTC (Tomorrow)
**Contact:** vikash.jaiswal@devo.com
