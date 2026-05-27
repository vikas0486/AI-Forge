---
name: automation-resilience-infra
description: Deploy auto-healing health-check agents to datanodes, metamalotes, and batrasios via Ansible. Smart port mapping, counter reset, Slack alerts. Replaces /datanode-deployment.
argument-hint: "[host-type] [region]"
tags: [ansible, health-check, datanode, resilience, malote]
---

# Automation Resilience Infrastructure

> Replaces `/datanode-deployment` (merged May 2026). Use this skill for all resilience deployment work.

---

## Key Paths

**Local:**
- Role: `/Users/vikash.jaiswal/Documents/Repository/Roles/ansible-resilient-infra`
- Automation: `/Users/vikash.jaiswal/Documents/Repository/automation`
- Playbook: `ansible/playbooks/deploy-datanode-resilience.yml`
- Role-mode script: `/Users/vikash.jaiswal/Documents/Scripts/role-mode-switcher.sh`

**GitLab:**
- Role: https://gitlab.com/devo_corp/platform/ansible/roles/ansible-resilient-infra
- Automation: https://gitlab.com/devo_corp/platform/ansible/environments/automation
- Latest release: v1.1.0 — https://gitlab.com/devo_corp/platform/ansible/roles/ansible-resilient-infra/-/tags/v1.1.0
- Latest MR: https://gitlab.com/devo_corp/platform/ansible/roles/ansible-resilient-infra/-/merge_requests/4 (merged)
- Branch: `master` (merge commit: `accb02c`)

**Ansible Inventory:**
```
automation/ansible/environments/
├── aws/eu/pro/hosts        # EU production datanodes + metamalotes + batrasios
├── aws/eu/santander/hosts  # Santander
├── aws/ap/pro/hosts        # APAC (Singapore, Sydney, Jakarta)
└── aws/us/pro/hosts        # US datanodes
```

---

## Deployment Workflow

### Step 1 — Switch to local role mode (MUST DO before every deployment)

```bash
source /Users/vikash.jaiswal/Documents/Scripts/role-mode-switcher.sh
role-local        # Use local development version
role-status       # Verify: must show LOCAL MODE
role-pub          # Switch back to published version when done
```

### Step 2 — Syntax check

```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml --syntax-check
```

### Step 3 — Deploy by region and node type

```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation

# EU datanodes
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/eu/pro/hosts \
  -e target_hosts=datanode

# EU metamalotes
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/eu/pro/hosts \
  -e target_hosts=metamalote

# EU batrasios
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/eu/pro/hosts \
  -e target_hosts=batrasio

# APAC datanodes
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/ap/pro/hosts \
  -e target_hosts=datanode

# APAC metamalotes
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/ap/pro/hosts \
  -e target_hosts=metamalote

# APAC batrasios
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/ap/pro/hosts \
  -e target_hosts=batrasio

# US datanodes
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/us/pro/hosts \
  -e target_hosts=datanode

# Santander (all node types)
ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml \
  -i ansible/environments/aws/eu/santander/hosts \
  -e target_hosts=datanode:metamalote:batrasio
```

---

## Production Status

**v1.1.0 — 162 hosts deployed — 100% COMPLETE (March 17, 2026)**

| Region | Datanodes | Metamalotes | Batrasios | Total |
|--------|-----------|-------------|-----------|-------|
| EU (incl. Santander) | 17 | 2 | 2 | **21** |
| APAC (SG/SYD/JKT) | 12 | 3 | 6 | **21** |
| US | 120 | 0 | 0 | **120** |
| **TOTAL** | **149** | **5** | **8** | **162** |

**Slack Integration:**
- Webhook: `REDACTED - stored in Vault`
- Channel: `#infra_health_monitor`
- Alerts: service down, restart failure, max restarts exceeded

---

## Monitored Services by Node Type

| Node Type | Services Monitored | Malote Tests |
|-----------|-------------------|--------------|
| **Datanode** | alcohol@i0-i7, malote@i0-i7, malotepre@i0, batrasio, licor, metamalote, devo-monitor, mason-agent, netdata (22–23 services) | 33 ports |
| **Metamalote** | metamalote, malote-controller, devo-monitor, mason-agent, netdata (5 services) | 1 port |
| **Batrasio** | batrasio, devo-monitor, mason-agent, netdata (3–4 services) | Skipped |

**Monitoring cycle:** 60s check interval · 600s heartbeat + malote tests · 3 max restarts · 300s cooldown

**Port-to-instance mapping (datanodes):**
- 10101–10102, 10901 → `malote@i0`
- 10103–10104, 10902 → `malote@i1`
- 10105–10106, 10903 → `malote@i2`
- 10107–10108, 10904 → `malote@i3`
- (pattern continues for i4–i9)

Only the affected instance is restarted — never all 10.

**Counter reset logic:** When a service recovers after hitting the 3/3 restart limit, the agent automatically deletes its `.count` and `.cooldown` files, resetting the counter to 0. No manual intervention needed for transient failures.

**Batrasio skip logic:** `run_malote_test()` checks `$NODE_TYPE == batrasio` at entry and returns 0 immediately. Batrasios do not run malote services so tests are skipped entirely.

**Batrasio restart warning:** Batrasio requires ALB deregistration before restart. For planned restarts use the dedicated playbook: `ansible/playbooks/batrasio_service_restart.yml`. The health-check-agent does NOT do ALB deregistration — it will restart batrasio directly (acceptable for crash recovery, but use the playbook for planned maintenance).

**Malote port config location (on datanodes):** `/etc/logtrust/systemd/malote/$(hostname)/i?.conf` — each file contains `PORT=<number>`. The test_malotes.sh script reads these to know which ports to test.

---

## Verification

```bash
# Check agent active status (ansible bulk)
ansible datanode -i ansible/environments/aws/ap/pro/hosts \
  -m shell -a "systemctl is-active health-check-agent" 2>/dev/null

# Check watchdog disabled (should show WatchdogUSec=0)
ssh <hostname> "systemctl show metamalote.service batrasio.service | grep WatchdogUSec"

# Check what services are being monitored
ssh <hostname> "grep 'Monitoring:' /var/log/health-check/agent.log | tail -1"

# Check malote test results (datanode/metamalote only)
ssh <hostname> "grep 'MALOTE_TEST RESULT' /var/log/health-check/agent.log | tail -1"

# Check counter resets (confirm auto-recovery working)
ssh <hostname> "grep 'recovered.*resetting' /var/log/health-check/agent.log"

# Check escalation events
ssh <hostname> "grep 'exceeded max restarts' /var/log/health-check/agent.log | tail -5"

# Check Slack delivery
ssh <hostname> "grep '📤 Slack alert' /var/log/health-check/agent.log | tail -5"

# Tail live logs
ssh <hostname> "tail -50 /var/log/health-check/agent.log"
```

---

## Common Issues & Fixes

### Services stuck at 3/3 restart limit

Counter reset logic handles this automatically since v1.1.0. If needed manually:
```bash
sudo rm -f /var/lib/health-check/*.count
sudo rm -f /var/lib/health-check/*.cooldown
```

### Malote ports failing but services show active

```bash
# Test specific ports
for port in 10105 10106 10905 10906; do
  echo -n "Port $port: "
  timeout 3 bash -c "</dev/tcp/localhost/$port" && echo 'OK' || echo 'FAIL'
done

# Check for OOM errors
sudo grep -i "OutOfMemory" /var/log/malote/malote.out.i*.log

# Restart affected instances directly
sudo systemctl restart malote@i2 malote@i4 malote@i5
sudo journalctl -u malote@i2 --since '10 minutes ago'
```

### Malote test lock conflict

`[ERROR]: Could not acquire lock` — normal behavior, prevents concurrent tests, no action needed.

### Deploying old version

Run `role-local` before deploying. `role-status` must show LOCAL MODE.

---

## Log Locations

```
/var/log/health-check/agent.log         # All agent activity (main log)
/opt/health-check/health_check_agent.sh # Deployed agent script
/usr/local/bin/test_malotes.sh          # Malote test script
/var/lib/health-check/*.count           # Restart counters (delete to reset)
/var/lib/health-check/*.cooldown        # Cooldown state files
```

---

## Deployment History

### Phase 1 — CHG-10288 (2026-02-18)
Initial deployment of health-check agents to EU datanodes.
- **Jira:** CHG-10288
- **MR:** automation repo [MR #77](https://gitlab.com/devo_corp/platform/ansible/environments/automation/-/merge_requests/77)
- **Branch:** `ansible/Auto-ResilienceInfrastructure-Phase#1` → master
- **Pipeline:** Success (44s)

### v1.1.0 Full Rollout — 162 hosts (2026-03-17)
See Production Status table above — EU + APAC + US + Santander complete.

---

## Related Skills

- **`/devo-infra`** — General datanode infrastructure, Kubernetes, Ansible deployments
- **`/devo-database`** — Database access for datanode queries
- **`/devo-query`** — Maqui queries for platform data investigation
