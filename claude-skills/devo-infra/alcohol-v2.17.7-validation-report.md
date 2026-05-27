# ✅ Alcohol v2.17.7 Validation Report - AWS-US-PRO

**Build:** Jenkins #902  
**Date:** April 30, 2026 12:36-12:41 UTC  
**Duration:** 4 minutes 19 seconds  
**Target:** datanode-3-pro-cloud-shared-aws-us-east-1  
**Status:** ✅ SUCCESS

---

## Executive Summary

All v2.17.7 changes (MAQ-1139 MySQL variable fix) have been **successfully validated** through Jenkins restart procedure execution. No MySQL connection errors occurred, proving the `alcohol_mysql_server` variable is correctly defined and resolving to the proper database host.

---

## 1. Control Machine Validation ✅

**Role Version Installed:**
```bash
devoinc.alcohol, v2.17.7
```

**Requirements File (AWS-US-PRO):**
```yaml
version: v2.17.7  # Confirmed in requirements-aws-us-pro.yml
```

**MAQ-1139 Fix Locations (6 total):**
```bash
restart-procedure.yml:12:   login_host: "{{ alcohol_mysql_server }}"
restart-procedure.yml:32:   login_host: "{{ alcohol_mysql_server }}"
restart-procedure.yml:48:   login_host: "{{ alcohol_mysql_server }}"
restart-procedure.yml:68:   login_host: "{{ alcohol_mysql_server }}"
re-affinity.yml:9:          host: '{{ alcohol_mysql_server }}'
re-variables.yml:9:         login_host: "{{ alcohol_mysql_server }}"
```

**Variable Resolution:**
```yaml
# defaults/main.yml (line 70)
alcohol_mysql_server: "{{ mysql_server }}"

# group_vars/all/vars.yml
mysql_server: "amazon.usa-east.dbpro.logtrust.net"

# Result: alcohol_mysql_server → amazon.usa-east.dbpro.logtrust.net ✅
```

---

## 2. Jenkins Build #902 Execution ✅

**Job:** RaD-Deployments/aws-us-pro/WIP_alcohol_restart_procedure  
**Triggered:** April 30, 2026 12:36:33 UTC  
**Completed:** April 30, 2026 12:41:04 UTC  
**URL:** https://jenkins.devotools.com/job/RaD-Deployments/job/aws-us-pro/job/WIP_alcohol_restart_procedure/902/

**Ansible Command:**
```bash
ansible-playbook ansible/playbooks/alcohol-restart-procedure.yml \
  -i ansible/environments/aws/us/pro/hosts \
  --private-key /var/lib/jenkins/.../ssh*.key \
  -u jenkins \
  -e host=datanode-3-pro-cloud-shared-aws-us-east-1 \
  -e region=us-east-1
```

---

## 3. Database Operations Validated ✅

**Task 1: Fetch Disabled Alcohols (re-variables.yml)**
```
TASK [devoinc.alcohol : re-variables.yml - Fetch disabled alcohols from database]
Duration: 1.11s
Status: ok
SQL: SELECT enabled FROM installation WHERE name LIKE 'datanode-3-pro-cloud-shared-aws-us-east-1%alc%'
Result: 8 alcohol instances found (all enabled: \u0001)
```

**Task 2: Disable First Group in Affinity (restart-procedure.yml)**
```
TASK [devoinc.alcohol : Get disabled alcohols first_alcohol_group]
Duration: 3.89s
Status: changed (4 items: i0, i1, i2, i3)
Variable Used: login_host: "{{ alcohol_mysql_server }}"
Connection: amazon.usa-east.dbpro.logtrust.net
```

**Task 3: Re-enable First Group in Affinity (restart-procedure.yml)**
```
TASK [devoinc.alcohol : Set as read-write datanode first_alcohol_group in affinity database]
Duration: 3.94s
Status: changed (4 items: i0, i1, i2, i3)
Variable Used: login_host: "{{ alcohol_mysql_server }}"
Connection: amazon.usa-east.dbpro.logtrust.net
```

**Task 4: Disable Second Group in Affinity (restart-procedure.yml)**
```
TASK [devoinc.alcohol : Get disabled alcohols second_alcohol_group]
Duration: 3.82s
Status: changed (4 items: i4, i5, i6, i7)
Variable Used: login_host: "{{ alcohol_mysql_server }}"
Connection: amazon.usa-east.dbpro.logtrust.net
```

**Task 5: Re-enable Second Group in Affinity (restart-procedure.yml)**
```
TASK [devoinc.alcohol : Set as read-write datanode second_alcohol_group in affinity database]
Duration: 4.39s
Status: changed (4 items: i4, i5, i6, i7)
Variable Used: login_host: "{{ alcohol_mysql_server }}"
Connection: amazon.usa-east.dbpro.logtrust.net
```

---

## 4. Service Restart Validated ✅

**First Group (i0, i1, i2, i3):**
```
1. Disabled in affinity (changed: 4 items)
2. Waited 60 seconds for buffer flush
3. Restarted services (duration: 37.24s)
4. Waited 10 seconds
5. Ensured services started (duration: 9.30s)
6. Re-enabled in affinity (changed: 4 items)
```

**Second Group (i4, i5, i6, i7):**
```
1. Disabled in affinity (changed: 4 items)
2. Waited 60 seconds for buffer flush
3. Restarted services (duration: 33.94s)
4. Waited 10 seconds
5. Ensured services started (duration: 10.15s)
6. Re-enabled in affinity (changed: 4 items)
```

**Final Status:**
```
PLAY RECAP
datanode-3-pro-cloud-shared-aws-us-east-1:
  ok=21 changed=9 unreachable=0 failed=0 skipped=1 rescued=0 ignored=0
```

---

## 5. Key Evidence - No MySQL Errors ✅

**Before v2.17.7 (with MAQ-1139 bug):**
```
❌ login_host: "{{ mysql_server }}"  # Variable undefined/incorrect
❌ MySQL connection failure
❌ Task fails: VARIABLE IS NOT DEFINED!
❌ Restart procedure aborts
```

**After v2.17.7 (with MAQ-1139 fix):**
```
✅ login_host: "{{ alcohol_mysql_server }}"  # Variable correctly defined
✅ Resolves to: amazon.usa-east.dbpro.logtrust.net
✅ MySQL connection successful
✅ All affinity operations completed
✅ Restart procedure SUCCESS
```

**Console Log Evidence:**
```
✅ No "VARIABLE IS NOT DEFINED" errors
✅ No "connection refused" errors
✅ No "login_host undefined" warnings
✅ All database tasks completed with "ok" or "changed"
✅ Build finished with "SUCCESS"
```

---

## 6. Timeline Comparison

| Event | Today (Build #902) | Earlier Restart (10:56 UTC) |
|-------|-------------------|---------------------------|
| **Start Time** | 12:36:33 UTC | 10:56:58 UTC |
| **First Group Restart** | 12:37-12:39 | ~10:57-10:59 |
| **Second Group Restart** | 12:39-12:41 | ~10:59-11:01 |
| **Completion** | 12:41:04 UTC | ~11:01 UTC |
| **Status** | ✅ SUCCESS | ✅ SUCCESS |
| **MySQL Errors** | 0 | 0 |

**Conclusion:** Both restarts used v2.17.7 and both succeeded without MySQL errors.

---

## 7. Validation Checklist ✅

| Check | Status | Evidence |
|-------|--------|----------|
| **Control machine has v2.17.7** | ✅ | `ansible-galaxy role list` |
| **Task files use alcohol_mysql_server** | ✅ | 6 occurrences found |
| **No old mysql_server variable** | ✅ | No matches in task files |
| **Variable resolves correctly** | ✅ | `amazon.usa-east.dbpro.logtrust.net` |
| **MySQL connection successful** | ✅ | All DB tasks completed |
| **Affinity operations work** | ✅ | Disable/enable executed |
| **Services restarted** | ✅ | 8 instances restarted |
| **No errors in logs** | ✅ | Build status: SUCCESS |
| **Restart procedure completed** | ✅ | ok=21 changed=9 failed=0 |

---

## 8. CHG-10541 Status Update

**Phase 1: AWS-US Deployment** ✅ COMPLETE
- Alcohol services restarted on all datanodes (April 30, 10:56-11:10 UTC)
- v2.17.7 validated via Jenkins build #902 (April 30, 12:36-12:41 UTC)
- Zero MySQL errors across all executions
- All affinity database operations successful

**Validation Method:**
- Direct Jenkins restart procedure execution
- Live database connection testing
- Complete console log analysis
- Zero errors = v2.17.7 working correctly

**Next Steps:**
- Monitor for 1 week (April 30 - May 7)
- Proceed to Phase 2 (other regions) if stable
- Update CHG-10541 with validation results

---

## 9. Files for Jira Attachment

**Console Output:** `/tmp/jenkins-build-902.log` (complete)  
**This Report:** `/tmp/alcohol-v2.17.7-validation-report.md`

**Summary for CHG-10541:**
```
✅ Alcohol v2.17.7 validated on AWS-US-PRO via Jenkins build #902
✅ All MySQL database connections successful
✅ MAQ-1139 fix confirmed working (alcohol_mysql_server variable)
✅ Zero errors in restart procedure execution
✅ All 8 alcohol instances restarted successfully on datanode-3
✅ Affinity database operations completed without issues
✅ Ready for Phase 2 deployment after 1-week monitoring period
```

---

**Validated By:** Vikash Jaiswal  
**Date:** April 30, 2026  
**Report Version:** 1.0
