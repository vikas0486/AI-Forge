# SOAR Skill - Quick Start Guide

Quick reference for common SOAR-related tasks and troubleshooting.

---

## When to Use This Skill

Use `/devo-infra` when dealing with:
- ✅ Devo SOAR (LogicHub) platform issues
- ✅ Customer using Cortex XSOAR with Devo
- ✅ Duplicate alert issues
- ✅ SOAR integration problems
- ✅ Team SOAR contact information
- ✅ Alert fetch timestamp issues

---

## Common Commands

### Contact Team SOAR

```bash
# Email
sharad.mehrotra@devo.com
aman.tiwari@devo.com
utkarsh.priyam@devo.com

# GitLab
@devo_corp/engineering/soar

# Slack
Search "Team SOAR" or individual names
```

### Check Customer's SOAR Platform

**If using Devo SOAR (LogicHub)**:
```bash
# Check deployment
kubectl config use-context prod-us
kubectl get pods -n devo-soar | grep logichub

# Check LogicHub version
kubectl get deployment -n devo-soar -o yaml | grep image:
```

**If using Cortex XSOAR (External)**:
- Customer manages their own XSOAR instance
- Uses integration from: https://github.com/demisto/content
- File: `Packs/Devo/Integrations/Devo_v2/Devo_v2.py`

### Verify Alert Duplication

```maqui
from siem.logtrust.alert.info
where domain -> "customer_domain"
where now() - 24h < eventdate < now()
group by alertId, eventdate
select count() as occurrences
where occurrences > 1
```

---

## Troubleshooting Duplicate Alerts

### Step 1: Identify Pattern

```maqui
from siem.logtrust.alert.info
where domain -> "customer_domain"
where context -> "alert_context"
where now() - 7d < eventdate < now()
select eventdate, alertId, context, severity
```

**Look for**:
- Multiple alerts within same second with different milliseconds
- Example: `2026-02-03 00:00:06.311` and `2026-02-03 00:00:06.623`

### Step 2: Check SOAR Platform

**Question**: What SOAR platform is the customer using?

- **Devo SOAR (LogicHub)** → No timestamp issues (works correctly)
- **Cortex XSOAR** → Potential timestamp truncation bug

### Step 3: Verify Integration

**For Cortex XSOAR**:
1. Check integration version in customer's XSOAR
2. Confirm they use `Devo_v2` integration
3. Check if `timestamp_to_date()` preserves milliseconds

### Step 4: Apply Fix

**Short-term**: Patch customer's XSOAR integration
**Long-term**: Migrate to Devo SOAR (LogicHub)

---

## Repository Quick Access

### Clone SOAR App

```bash
cd ~/Documents/Repository
git clone git@gitlab.com:devo_corp/engineering/soar/app.git soar-app
cd soar-app
```

### Clone Helm Charts

```bash
git clone git@gitlab.com:devo_corp/engineering/soar/helm-charts/soar-app.git soar-helm
```

### Browse on GitLab

- **Main Group**: https://gitlab.com/groups/devo_corp/engineering/soar
- **LogicHub UI**: https://gitlab.com/devo_corp/engineering/soar/app
- **Observability**: https://gitlab.com/devo_corp/engineering/observability/soar-observability

---

## Documentation Links

### Devo SOAR (LogicHub)
- **Integration Docs**: https://help.logichub.com/docs/devo
- **All Integrations**: https://help.logichub.com/docs/integrations

### Cortex XSOAR
- **Content Repo**: https://github.com/demisto/content
- **Devo Integration**: https://github.com/demisto/content/tree/master/Packs/Devo/Integrations/Devo_v2

---

## Common Jira Queries

### Find SOAR-related Tickets

```bash
source ~/.zshrc && jira search 'text ~ "SOAR" OR text ~ "LogicHub" OR text ~ "XSOAR"' 10
```

### Find Duplicate Alert Issues

```bash
source ~/.zshrc && jira search 'text ~ "duplicate alert" OR text ~ "duplicate alerts"' 10
```

---

## Quick Fixes

### Fix Timestamp Truncation (Cortex XSOAR)

**File**: `Packs/Devo/Integrations/Devo_v2/Devo_v2.py`
**Line**: 98-100

```python
# BEFORE (buggy):
def timestamp_to_date(timestamp):
    datetime_obj = datetime.fromtimestamp(timestamp)
    return datetime_obj.strftime("%Y-%m-%d %H:%M:%S")

# AFTER (fixed):
def timestamp_to_date(timestamp):
    datetime_obj = datetime.fromtimestamp(timestamp)
    return datetime_obj.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]  # Keep milliseconds
```

### Create Patch File

```bash
cd /tmp
git clone https://github.com/demisto/content.git
cd content
git checkout -b fix-devo-timestamp-truncation

# Edit file
vim Packs/Devo/Integrations/Devo_v2/Devo_v2.py
# Make the change above

# Create patch
git diff > devo_timestamp_fix.patch

# Share with customer or submit PR
```

---

## Escalation Path

1. **Team SOAR** - For integration issues, LogicHub problems
2. **Customer Success** - For migration discussions
3. **Platform Team** - For Devo API issues
4. **External** - Palo Alto/Demisto for Cortex XSOAR bugs

---

## Migration Checklist

### From Cortex XSOAR to Devo SOAR

- [ ] Contact Team SOAR for consultation
- [ ] Inventory existing XSOAR playbooks
- [ ] Get Devo SOAR instance provisioned
- [ ] Configure Devo integration in LogicHub
- [ ] Migrate/recreate playbooks
- [ ] Test alert fetching (check for duplicates)
- [ ] Run parallel for validation period
- [ ] Cutover to Devo SOAR
- [ ] Decommission Cortex XSOAR

---

## Regional Deployments

### LogicHub Environments

| Environment | Region | Purpose |
|-------------|--------|---------|
| logichub-prod-us | US East | Production US |
| logichub-prod-eu | EU West | Production EU |
| logichub-prod-apac | APAC | Production Asia Pacific |
| logichub-prod-us3 | US East 2 | Production US3 |
| logichub-prod-ncscbh | ME South | Production NCSC Bahrain |
| logichub-stage | - | Staging environment |
| logichub-int | - | Integration testing |
| logichub-poc-us | US | POC/Demo |

### Access

```bash
# List all SOAR deployments
glab api "/projects?search=logichub&per_page=50" | \
  jq -r '.[] | select(.path_with_namespace | contains("devo_corp")) | .path_with_namespace'
```

---

## Key Takeaways

1. **Devo SOAR = LogicHub** (native platform)
2. **Team SOAR** manages LogicHub and integrations
3. **Cortex XSOAR** = External platform with known bugs
4. **Always recommend Devo SOAR** to customers
5. **Timestamp truncation** = Root cause of duplicate alerts in XSOAR

---

**Skill Location**: `~/.claude/skills/soar/`
**Main Documentation**: `README.md`
**Quick Start**: `QUICK_START.md` (this file)
