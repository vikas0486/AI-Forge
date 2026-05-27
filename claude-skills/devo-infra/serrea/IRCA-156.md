# RCA: CaixaBank Serrea Cluster Outage - MySQL Host Blocking

**RCA ID:** IRCA-156
**Date:** 2026-04-01
**Author:** Vikash Jaiswal
**Related Tickets:** ISM-16096, ISM-16088
**Severity:** High
**Customer:** CaixaBank
**Service:** Serrea (Query API)

---

## Incident Summary

**What happened:**
2 of 3 Serrea nodes (Serrea-1 and Serrea-3) were unable to connect to MySQL RDS for 18 hours, reducing cluster capacity to 33% and causing severe query performance degradation for CaixaBank customers.

**When:**
- Start: March 31, 2026 16:30 UTC
- Detection: April 1, 2026 07:45 UTC (15+ hour delay)
- Resolution: April 1, 2026 10:45 UTC
- Duration: 18 hours total

**Impact:**
- Services affected: Serrea cluster (2 of 3 nodes down)
- Customer impact: Severe query slowness, reduced capacity to 33%
- Data loss: None
- Availability: 33% capacity for 18 hours

---

## Timeline

| Time (UTC) | Event |
|------------|-------|
| **March 31, 16:30** | OutOfMemoryError on all 3 Serrea nodes during large query execution (JVM heap: 20GB) |
| **16:30 - 08:00** | Repeated service restart attempts generate 100+ connection errors to MySQL RDS |
| **~20:00** | MySQL RDS blocks Serrea-1 (10.9.64.20) and Serrea-3 (10.9.64.21) IPs due to Error 1129 (exceeded max_connect_errors=100) |
| **April 1, 07:45** | Manager escalation: Customer reports severe slowness |
| **08:01** | Serrea-2 restarted successfully (before being blocked) - cluster at 33% capacity |
| **09:48** | Serrea-1 and Serrea-3 restarted but fail to connect (already blocked at MySQL level) |
| **10:00 - 10:30** | Deep troubleshooting: heap analysis, GC logs, MySQL RDS state analysis |
| **10:30** | Root cause discovered: MySQL handshake test reveals Error 1129 host blocking |
| **10:45** | Fix applied: `FLUSH HOSTS;` executed on MySQL RDS using root credentials |
| **10:46** | Services restarted - all nodes operational, cluster 100% healthy |

---

## Root Cause

**Primary Cause:**
MySQL RDS blocked Serrea-1 and Serrea-3 IP addresses at the protocol level due to exceeding `max_connect_errors` threshold (default: 100 errors).

**Contributing Factors:**

1. **Initial Trigger:** OutOfMemoryError on March 31 caused service crashes
   - JVM heap: 20GB insufficient for large query
   - Services crashed and attempted repeated reconnections

2. **Connection Error Accumulation:** Each failed restart attempt incremented MySQL error counter
   - After 100+ errors per host, MySQL blocked the IPs
   - Error 1129: "Host blocked because of many connection errors; unblock with 'mysqladmin flush-hosts'"

3. **Timing Factor:** Serrea-2 restarted early (08:01 UTC) before being blocked
   - Serrea-1/3 restarted later (09:48 UTC) when already blocked
   - Resulted in 2 of 3 nodes unable to connect

4. **Detection Gap:** 15+ hour delay before alert fired
   - Cluster appeared "up" (services running) but 67% degraded
   - No health checks for MySQL connectivity

5. **Diagnostic Difficulty:** Log configuration suppressed stack traces
   - `log4j2.xml` ThresholdFilter only logs ERROR level
   - Connection pool initialization errors not captured
   - Made root cause analysis extremely difficult

**Why it wasn't caught earlier:**
- Akka cluster health checks passed (services running, but not functional)
- No synthetic query health checks
- No MySQL connection monitoring at application level
- Alert thresholds not tuned for partial cluster degradation

---

## Resolution

**Immediate Fix:**

1. Used devo-database skill to access MySQL RDS with root credentials
2. Executed `FLUSH HOSTS;` to clear MySQL host error cache
3. Restarted Serrea-1 and Serrea-3 services
4. Verified all nodes connected to MySQL RDS successfully
5. Confirmed Akka cluster health: 100% operational

**Verification:**
```
MySQL Connections:
- Serrea-1: 10 sessions
- Serrea-2: 11 sessions
- Serrea-3: 10 sessions

Akka Cluster: OK (0 unreachable nodes)
```

---

## Action Items

### Immediate (Priority: Critical)

| Action | Owner | ETA | Status |
|--------|-------|-----|--------|
| Increase `max_connect_errors` to 10,000 in RDS parameter group | DBA Team | 2026-04-02 | Pending |
| Document FLUSH HOSTS runbook with root access procedure | Platform Team | 2026-04-02 | Pending |
| Add MySQL connection error monitoring and alerting | NOC Team | 2026-04-03 | Pending |

### Short-term (Priority: High)

| Action | Owner | ETA | Status |
|--------|-------|-----|--------|
| Increase JVM heap from 20GB to 28GB on all Serrea nodes | Platform Team | 2026-04-05 | Pending |
| Enable DEBUG logging for Hibernate/DBCP2 connection pool | Platform Team | 2026-04-05 | Pending |
| Implement synthetic query health checks (every 5 minutes) | NOC Team | 2026-04-10 | Pending |
| Add alerting on MySQL `Aborted_connects` metric | NOC Team | 2026-04-10 | Pending |

### Long-term (Priority: Medium)

| Action | Owner | ETA | Status |
|--------|-------|-----|--------|
| Review and adjust log4j2.xml ThresholdFilter configuration | Dev Team | 2026-04-15 | Pending |
| Implement connection pool metrics dashboard | Platform Team | 2026-04-20 | Pending |
| Add query resource limits and cost estimation | Dev Team | 2026-04-30 | Pending |
| Conduct post-mortem meeting with stakeholders | Platform Team | 2026-04-05 | Pending |

---

## Lessons Learned

**What went well:**
- Systematic troubleshooting approach identified root cause in 90 minutes
- Direct MySQL protocol testing revealed blocking issue
- devo-database skill provided necessary admin access
- Quick resolution (5 minutes) once root cause identified

**What could be improved:**
- Detection time: 15+ hours unacceptable - need 5-10 minute SLA
- Log visibility: ThresholdFilter too aggressive, suppressed critical diagnostics
- Heap capacity: 20GB insufficient for production workload
- Runbook gap: First encounter with MySQL Error 1129, no documented procedure
- Health checks: Need MySQL connectivity checks, not just service status

**Key insights:**
- MySQL `max_connect_errors` can silently block entire services
- Timing matters: Restart sequence determined which nodes survived
- Application logs alone insufficient - protocol-level testing critical
- Root/admin access essential for MySQL host cache management

---

## Preventive Measures Summary

**Configuration Changes:**
1. Increase MySQL `max_connect_errors`: 100 → 10,000
2. Increase JVM heap: 20GB → 28GB
3. Enable connection pool DEBUG logging

**Monitoring Improvements:**
1. Synthetic query health checks (5-min interval)
2. MySQL connection error alerting
3. Connection pool metrics dashboard
4. Alert tuning for partial cluster degradation

**Process Improvements:**
1. Document FLUSH HOSTS runbook
2. Post-mortem with development and DBA teams
3. Review query resource limits and timeouts

---

## Technical Details

**Environment:**
- Cluster: serrea-caixa (3 nodes)
- Nodes: serrea-1-pro-cloud-caixa-ibm-eu-de-2 (10.9.64.20), serrea-2-pro-cloud-caixa-ibm-eu-de-3 (10.9.128.20), serrea-3-pro-cloud-caixa-ibm-eu-de-2 (10.9.64.21)
- MySQL RDS: logtrustdb-production.c70tbv6xtaqr.eu-west-1.rds.amazonaws.com
- JVM: 20GB heap (Xms20G -Xmx20G)

**Root Cause Validation:**
```python
# Direct MySQL handshake test revealed blocking
import socket, struct
sock = socket.socket()
sock.connect(('mysql-rds-host', 3306))
data = sock.recv(4096)
# Response: Error packet (0xFF)
# Error 1129: Host '10.9.64.20' is blocked because of many connection errors
```

**Resolution Command:**
```sql
FLUSH HOSTS;  -- Executed with root credentials
```

---

**RCA Status:** Draft
**Review Required:** Platform Team Lead, DBA Team Lead
**Approval Required:** VP Engineering

**Next Steps:**
1. Review and approve RCA
2. Assign action item owners
3. Track implementation of preventive measures
4. Schedule post-mortem meeting
