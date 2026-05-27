# HMAC Logging Fix - Quick Reference Card

**CHG:** [To be created]
**Runbook:** `/tmp/hmac-logging-fix-runbook.md`

---

## Quick Execution Steps

### 1. Pre-Check (2 minutes)

```bash
# Check HMAC error count
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo -n "$node: "
  ssh $node "grep 'Invalid domain credentials' /var/log/serrea/serrea.log | grep '2026-03-01' | wc -l"
done

# Check cluster health
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq -r '.ok'
```

---

### 2. Backup (1 minute)

```bash
# Create backups
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo cp /etc/logtrust/serrea/log4j2.xml /etc/logtrust/serrea/log4j2.xml.backup.$(date +%Y%m%d_%H%M%S)"
done
```

---

### 3. Apply Configuration (3 minutes)

```bash
# Apply to all nodes
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "=== $node ==="
  ssh $node "sudo sed -i '/<\\/Loggers>/i\\    <!-- Suppress HMAC authentication failures -->\\n    <Logger name=\"com.devo.lugin.hmac.services.UserDomainHMACAccessService\" level=\"WARN\"/>\\n    <Logger name=\"com.devo.web.common.api.auth.HMAC\" level=\"WARN\"/>' /etc/logtrust/serrea/log4j2.xml"
  ssh $node "sudo grep -A 2 'Suppress HMAC' /etc/logtrust/serrea/log4j2.xml"
done
```

---

### 4. Rolling Restart (3 minutes)

```bash
# Serrea-3 (first)
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "systemctl is-active serrea"

# Serrea-2 (second)
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo systemctl restart serrea" && sleep 30
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "systemctl is-active serrea"

# Serrea-1 (last)
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "systemctl is-active serrea"
```

---

### 5. Verify (2 minutes)

```bash
# Check cluster health
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq .

# Check for new ERROR logs (should be none)
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "tail -100 /var/log/serrea/serrea.log | grep 'ERROR.*Invalid domain credentials'"
```

---

## Rollback Commands

```bash
# Restore backups
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo cp /etc/logtrust/serrea/log4j2.xml.backup.* /etc/logtrust/serrea/log4j2.xml"
done

# Restart services
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo systemctl restart serrea" && sleep 30
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
```

---

## Success Criteria

- ✅ All 3 nodes active
- ✅ Cluster health: all nodes "Up", unreachable=0
- ✅ No new ERROR logs for HMAC
- ✅ Log growth rate reduced

---

**Total Time:** ~10 minutes
**Downtime:** ~30 seconds per node (rolling restart)
