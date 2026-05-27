# Devo SOAR - Platform & Integration Management

Complete documentation for Devo's SOAR (Security Orchestration, Automation, and Response) platform, internal repositories, team contacts, and integration troubleshooting.

---

## Overview

**Devo SOAR** is powered by **LogicHub**, providing security orchestration and automation capabilities. This skill covers:
- Internal repositories and team structure
- Native Devo integration in LogicHub
- External SOAR platform integrations (Cortex XSOAR)
- Common integration issues and troubleshooting

---

## Devo SOAR (LogicHub) Platform

### What is Devo SOAR?

Devo's native SOAR platform built on **LogicHub** technology. It provides:
- Security automation and orchestration
- Native integration with Devo platform
- Playbook creation and management
- Alert ingestion and case management

**Key Advantage**: Direct integration with Devo's alert API without external dependencies.

---

## Internal Repositories

### GitLab Organization

**Main Group**: `devo_corp/engineering/soar`
- **Web URL**: https://gitlab.com/groups/devo_corp/engineering/soar

### Key Repositories

| Repository | Purpose | URL |
|------------|---------|-----|
| **soar/app** | LogicHub UI application | https://gitlab.com/devo_corp/engineering/soar/app |
| **soar/helm-charts/soar-app** | Helm deployment charts | https://gitlab.com/devo_corp/engineering/soar/helm-charts/soar-app |
| **soar/applications/devo-soar-app** | Devo SOAR integration app | https://gitlab.com/devo_corp/engineering/soar/applications/devo-soar-app |
| **soar/applications/soar-devo-sso** | SSO integration | https://gitlab.com/devo_corp/engineering/soar/applications/soar-devo-sso |
| **observability/soar-observability** | SOAR monitoring/observability | https://gitlab.com/devo_corp/engineering/observability/soar-observability |

### Deployment Repositories

**Terraform Environments**:
- `platform/terraform/environments/logichub-prod-us`
- `platform/terraform/environments/logichub-prod-eu`
- `platform/terraform/environments/logichub-prod-apac`
- `platform/terraform/environments/logichub-prod-us3`
- `platform/terraform/environments/logichub-prod-ncscbh`
- `platform/terraform/environments/logichub-stage`
- `platform/terraform/environments/logichub-int`
- `platform/terraform/environments/logichub-poc-us`

**Argo CD Configuration**:
- Hydra: `platform/argo/hydra/soar/`
- Cerberus: `platform/argo/cerberus/soar/`

---

## Team SOAR

### Team Members

| Name | GitLab Username | Role |
|------|----------------|------|
| Aman Tiwari | @aman.tiwari1 | Team member |
| Ashish Jha | @ashish.jha7311514 | Team member |
| Sharad Mehrotra | @sharad.mehrotra | Team member |
| Utkarsh Priyam | @utkarsh.priyam1 | Team member |
| Sumit Yadav | @sumit.yadav6 | Team member |
| Amardeep Kumar | @amardeep.kumar1 | Team member |
| Raghav Sekhri | @raghav.sekhri | Team member |
| Saurabh Kumar | @saurabh.kumar23 | Team member |
| Siddhartha Yadav | @siddhartha.yadav | Team member |
| Kamran Hussain | @kamran.hussain2 | Team member |

### Contact

**Slack**: Search for "SOAR team" or individual team members
**Email**: `{firstname.lastname}@devo.com`
**GitLab**: Tag `@devo_corp/engineering/soar` in issues/MRs

---

## Devo Native Integration (LogicHub)

### Documentation

**Official Docs**: https://help.logichub.com/docs/devo
**Integration List**: https://help.logichub.com/docs/integrations

### Configuration

**API Endpoints**:
- US Region: `https://apiv2-us.devo.com`
- EU Region: `https://apiv2-eu.devo.com`

**Authentication**:
- API Token (OAuth or API key/secret)
- SSL verification (optional)
- Remote Agent support

### Available Actions

#### 1. Alert Management
- **List Triggered Alerts**: Fetch alerts with filtering
- **Get Alert Details**: Retrieve specific alert information
- **Update Alert Status**: Change alert state (open/closed)
- **Manage Annotations**: Add/update alert annotations
- **Get Alert Raw Query**: Retrieve original query

#### 2. Query Execution
- **Run Query**: Execute LINQ queries against Devo
- **Time Range**: UTC timestamps or relative (5m, 1h, 1d)
- **Pagination**: Limit (max 50,000), offset, nextPageToken

#### 3. Event Management
- **Send Events**: Push events to Devo

#### 4. Lookup Management
- **Create/Update/Delete Lookups**: Manage lookup tables

### Timestamp Handling

**Format**: UTC timestamps with millisecond precision
**Supported**:
- Absolute: `2024-03-10T02:00:00.123Z`
- Relative: `5m` (5 minutes), `1h` (1 hour), `1d` (1 day)
- Range: Start/end time parameters

**Key Feature**: ✅ **Preserves millisecond precision** - No truncation issues

### Pagination

```
limit: 500 (default), max 50,000
offset: For pagination
nextPageToken: Response includes token for next page
```

---

## External SOAR Integrations

### Cortex XSOAR (Palo Alto Networks)

**Platform**: Third-party SOAR by Palo Alto Networks
**Integration Repository**: https://github.com/demisto/content
**Maintainer**: Community/Palo Alto Networks

#### Integration File

**Location**: `Packs/Devo/Integrations/Devo_v2/Devo_v2.py`
**File**: https://github.com/demisto/content/blob/master/Packs/Devo/Integrations/Devo_v2/Devo_v2.py

#### Known Issue: Timestamp Truncation Bug

**Issue**: Duplicate alerts fetched from Devo

**Root Cause**: Line 98-100 in `Devo_v2.py`
```python
def timestamp_to_date(timestamp):
    datetime_obj = datetime.fromtimestamp(timestamp)
    return datetime_obj.strftime("%Y-%m-%d %H:%M:%S")  # ← TRUNCATES MILLISECONDS!
```

**Impact**:
1. Devo stores: `2026-02-03 00:00:06.311` (milliseconds)
2. XSOAR saves: `2026-02-03 00:00:06` (truncated)
3. Next fetch: `eventdate >= "2026-02-03 00:00:06"`
4. Result: Re-fetches ALL alerts from `.000` to `.999`

**Example Case**:
- Jira Ticket: ISM-15655
- Customer: Curo Group
- Symptom: Duplicate alerts at specific times (e.g., 2:00 AM)

#### Fix Options

**Option 1: Preserve Milliseconds** (Recommended)
```python
def timestamp_to_date(timestamp):
    datetime_obj = datetime.fromtimestamp(timestamp)
    return datetime_obj.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]  # Include milliseconds
```

**Option 2: Use `>` Instead of `>=`**
Modify query to exclude already-fetched alerts (not recommended - doesn't fix root cause)

**Option 3: Add 1 Millisecond**
```python
new_last_run["from_time"] = (max(event[event_date] for event in final_events) / 1000) + 0.001
```

#### Submitting Fix

**Steps**:
1. Fork: https://github.com/demisto/content
2. Modify: `Packs/Devo/Integrations/Devo_v2/Devo_v2.py`
3. Test: Run integration tests
4. Submit PR: To `demisto/content` repository

**OR**

Contact Team SOAR for internal patch/workaround.

---

## Architecture & Flow

### Devo SOAR (LogicHub) Architecture

```
┌─────────────────────────────────────────────────┐
│         Devo SOAR (LogicHub Platform)           │
│                                                 │
│  ┌─────────────┐       ┌──────────────────┐   │
│  │  LogicHub   │       │  Playbook Engine │   │
│  │     UI      │◄─────►│   (Automation)   │   │
│  └─────────────┘       └──────────────────┘   │
│         │                        │             │
│         └────────┬───────────────┘             │
│                  │                             │
└──────────────────┼─────────────────────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Native Devo         │
        │  Integration         │
        │  (API v2)            │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │   Devo Platform      │
        │                      │
        │  - Alert API         │
        │  - Query API         │
        │  - Event API         │
        │  - Lookup API        │
        └──────────────────────┘
```

**Key Points**:
- ✅ Direct API access (no external dependencies)
- ✅ Millisecond precision preserved
- ✅ Officially supported by Devo
- ✅ Team SOAR maintains integration

### Cortex XSOAR Architecture (External)

```
┌─────────────────────────────────────────────────┐
│      Cortex XSOAR (Palo Alto Networks)          │
│                                                 │
│  ┌─────────────┐       ┌──────────────────┐   │
│  │   XSOAR     │       │    Playbook      │   │
│  │     UI      │◄─────►│     Engine       │   │
│  └─────────────┘       └──────────────────┘   │
│         │                        │             │
│         └────────┬───────────────┘             │
│                  │                             │
└──────────────────┼─────────────────────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Devo_v2 Integration │ ← Community maintained
        │  (demisto/content)   │ ← ⚠️ Timestamp bug here!
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │   Devo Platform      │
        │   (API v2)           │
        └──────────────────────┘
```

**Key Points**:
- ❌ External/community integration
- ❌ Timestamp truncation bug
- ⚠️ Not officially supported by Devo
- ⚠️ Fix requires PR to external repo

---

## Troubleshooting

### Common Issue: Duplicate Alerts in Cortex XSOAR

**Symptoms**:
- Same alert appears multiple times
- Occurs at specific times (e.g., 2:00 AM)
- Alert IDs are different but content is identical

**Diagnosis**:

1. **Check Alert Timestamps**:
```maqui
from siem.logtrust.alert.info
where domain -> "customer_name"
where context -> "alert_context"
where now() - 24h < eventdate < now()
select eventdate, alertId, context
```

2. **Look for Millisecond Patterns**:
```
2026-02-03 05:30:06.311 - Alert 600397309
2026-02-03 05:30:06.623 - Alert 600397311
```
If multiple alerts within same second → timestamp truncation issue

3. **Verify Integration**:
- Check if customer uses Cortex XSOAR
- Confirm they're using `Devo_v2` integration from GitHub

**Resolution**:

**Short-term**:
1. Apply patch to `Devo_v2.py` (preserve milliseconds)
2. Redeploy integration in customer's XSOAR instance

**Long-term**:
1. Migrate customer to **Devo SOAR (LogicHub)**
2. Use native Devo integration (no timestamp issues)

### Alert Fetch Verification (Devo SOAR)

```maqui
from siem.logtrust.alert.info
where domain -> "customer_domain"
where now() - 1h < eventdate < now()
group by alertId
select count() as occurrences
where occurrences > 1
```

Should return 0 results if no duplicates.

### XSOAR Integration Debug

**Check XSOAR last_run**:
```python
# In XSOAR debug console
demisto.getLastRun()
# Should show: {"from_time": 1707801606.311}
```

**Check timestamp conversion**:
```python
from datetime import datetime
timestamp = 1707801606.311
datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d %H:%M:%S")
# Returns: "2026-02-03 00:00:06" (milliseconds lost!)
```

---

## Migration Guide

### Moving from Cortex XSOAR to Devo SOAR

**Why Migrate?**
- ✅ Native Devo integration (no bugs)
- ✅ Official support from Team SOAR
- ✅ Better performance (direct API)
- ✅ Millisecond precision preserved
- ✅ Unified Devo platform experience

**Steps**:

1. **Assessment**:
   - Inventory existing XSOAR playbooks
   - Identify alert sources and workflows
   - Review custom integrations

2. **Contact Team SOAR**:
   - Reach out to Team SOAR members
   - Request migration consultation
   - Get Devo SOAR instance provisioned

3. **Configuration**:
   - Set up Devo integration in LogicHub
   - Configure API credentials (OAuth/API key)
   - Test alert fetching

4. **Playbook Migration**:
   - Recreate playbooks in LogicHub
   - Test automation workflows
   - Validate alert handling

5. **Cutover**:
   - Run parallel for testing
   - Switch primary SOAR to Devo SOAR
   - Decommission Cortex XSOAR

---

## Key Queries

### Find Customer's SOAR Platform

```sql
-- Check if using Devo SOAR (LogicHub)
SELECT domain, integration_type, config
FROM integrations
WHERE integration_type = 'logichub';
```

### Alert Deduplication Check

```maqui
from siem.logtrust.alert.info
where domain -> "customer_name"
where now() - 7d < eventdate < now()
group by context, severity, msg
select count() as alert_count
where alert_count > 1
order by alert_count desc
```

### XSOAR Integration Activity

```maqui
from my.app.customer.xsoar.logs
where now() - 24h < eventdate < now()
where msg -> "fetch_incidents"
select eventdate, msg
```

---

## Related Resources

### Internal Documentation
- **LogicHub UI Repo**: https://gitlab.com/devo_corp/engineering/soar/app
- **SOAR Helm Charts**: https://gitlab.com/devo_corp/engineering/soar/helm-charts/soar-app
- **Observability**: https://gitlab.com/devo_corp/engineering/observability/soar-observability

### External Documentation
- **Devo Integration Docs**: https://help.logichub.com/docs/devo
- **LogicHub Integrations**: https://help.logichub.com/docs/integrations
- **Cortex XSOAR Content**: https://github.com/demisto/content

### Support Channels
- **Team SOAR**: Slack or GitLab `@devo_corp/engineering/soar`
- **Customer Success**: For migration discussions
- **Platform Team**: For API/integration issues

---

## Recent Issues & Tickets

### ISM-15655: Duplicate Alerts with XSOAR Integration

**Customer**: Curo Group
**Issue**: Duplicate alerts appearing in Cortex XSOAR
**Root Cause**: Timestamp truncation in `Devo_v2.py` integration
**Status**: Under investigation
**Resolution**:
- Short-term: Patch external integration
- Long-term: Migrate to Devo SOAR

**Evidence**:
```
Alert ID: 600397309 - Created: 2026-02-03 00:00:06.311
Alert ID: 600397311 - Created: 2026-02-03 00:00:06.623
Both have alertNumber "13" (duplicates)
```

**Slack Discussion**:
- Manuel: "Alert in Devo web app has no issues"
- Manu: "Might be XSOAR integration issue"
- Team consensus: XSOAR managed by SOAR team

---

## Quick Reference

### Check SOAR Platform Type

**For Devo SOAR (LogicHub)**:
```bash
# Check if LogicHub is deployed
kubectl get pods -n devo-soar | grep logichub
```

**For Cortex XSOAR**:
```bash
# Check external integration
curl -s customer_xsoar_url/health
```

### Contact Team SOAR

**GitLab**:
```bash
# Tag team in issue
@devo_corp/engineering/soar
```

**Email**:
```
sharad.mehrotra@devo.com
aman.tiwari@devo.com
utkarsh.priyam@devo.com
```

### Fix Timestamp Bug (Cortex XSOAR)

```python
# File: Packs/Devo/Integrations/Devo_v2/Devo_v2.py
# Line: 98-100

# BEFORE (buggy):
def timestamp_to_date(timestamp):
    datetime_obj = datetime.fromtimestamp(timestamp)
    return datetime_obj.strftime("%Y-%m-%d %H:%M:%S")

# AFTER (fixed):
def timestamp_to_date(timestamp):
    datetime_obj = datetime.fromtimestamp(timestamp)
    return datetime_obj.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]  # Preserve milliseconds
```

---

## Summary

- **Devo SOAR (LogicHub)** = Native, officially supported SOAR platform
- **Team SOAR** = Internal team managing LogicHub and integrations
- **Cortex XSOAR** = External SOAR with community integration (has bugs)
- **Key Issue** = Timestamp truncation in external XSOAR integration
- **Recommendation** = Use Devo SOAR for all customers

---

**Last Updated**: 2026-04-13
**Author**: Vikash Jaiswal (vikash.jaiswal@devo.com)
**Session**: ISM-15655 Investigation & SOAR Platform Analysis
