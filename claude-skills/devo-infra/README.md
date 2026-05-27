# Infrastructure Deployment - Datanode Operations

General infrastructure deployment and configuration management for datanodes, metamalotes, and batrasios.

> **Note:** This README covers Ansible reference material. Full operational details (Kubernetes, Malote JVM tuning, MISP, Serrea, SOAR, alcohol restart procedures) are in `SKILL.md`.

---

## Key Paths

**Local:**
- Automation repo: `/Users/vikash.jaiswal/Documents/Repository/automation`
- Roles: `/Users/vikash.jaiswal/Documents/Repository/Roles/`
- Ansible config: `/Users/vikash.jaiswal/Documents/Repository/automation/ansible.cfg`

**GitLab:**
- Automation: `git@gitlab.com:devo_corp/platform/ansible/environments/automation.git`
- Roles: https://gitlab.com/devo_corp/platform/ansible/roles
- ansible-dn-dailytasks: https://gitlab.com/devo_corp/platform/ansible/roles/ansible-dn-dailytasks

---

## Node Naming Patterns

- **Datanodes:** `datanode[1-9]-<account>-cloud-<env>-<cloud>-<region>`
- **Metamalotes:** `metamalote-[1-9]-<env>-cloud-<env>-<cloud>-<region>`
- **Batrasios:** `batrasio-[1-9]-<env>-cloud-<env>-<cloud>-<region>`

**Examples:**
```
datanode1-santander-cloud-shared-aws-eu-west-1   (172.27.30.47)
datanode2-santander-cloud-shared-aws-eu-west-1   (172.27.28.41)
datanode-1-pro-cloud-shared-aws-eu-west-1
datanode-1-pro-cloud-shared-aws-ap-southeast-1
```

---

## Inventory Structure

**Location:** `automation/ansible/environments/`

```
environments/
├── aws/
│   ├── eu/
│   │   ├── pro/hosts          # EU production
│   │   ├── santander/hosts    # Santander
│   │   └── tef/hosts          # Telefonica
│   ├── ap/
│   │   └── pro/hosts          # APAC production
│   └── us/
│       └── pro/hosts          # US production
└── gcp/
    └── tef/hosts              # GCP Telefonica
```

**Example inventory entry (Santander):**
```ini
[datanode-santander]
datanode1-santander-cloud-shared-aws-eu-west-1 ansible_host=172.27.30.47
datanode2-santander-cloud-shared-aws-eu-west-1 ansible_host=172.27.28.41

[datanode-santander:vars]
ansible_user=ubuntu
ansible_become=yes
```

---

## Requirements Files

**Location:** `automation/ansible/`

| File | Environment |
|---|---|
| `requirements-aws-eu-pro.yml` | EU production |
| `requirements-aws-eu-santander.yml` | Santander |
| `requirements-aws-ap-pro.yml` | APAC production |
| `requirements-aws-us-pro.yml` | US production |

**Example (Santander):**
```yaml
- src: git@gitlab.com:devo_corp/platform/ansible/roles/ansible-dn-dailytasks.git
  name: devoinc.datanode_dailytasks
  version: v1.12.5
  scm: git
```

**Install roles:**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation
ansible-galaxy install -r ansible/requirements-aws-eu-santander.yml --force
```

---

## Common Ansible Commands

```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation

# List inventory
ansible-inventory -i ansible/environments/aws/eu/santander/hosts --list

# Test connectivity
ansible all -i ansible/environments/aws/eu/santander/hosts -m ping

# Run shell command
ansible datanode-santander -i ansible/environments/aws/eu/santander/hosts \
  -m shell -a "df -h /var/logt/backup"

# Gather facts
ansible <hostname> -i ansible/environments/<path>/hosts -m setup

# Dry-run a playbook
ansible-playbook playbook.yml -i ansible/environments/<path>/hosts --check --diff
```

---

## Common Roles

| Role | Purpose | Latest |
|---|---|---|
| `ansible-dn-dailytasks` | Daily maintenance scripts (compression, move, delete, backup cleanup) | v1.12.5 |
| `ansible-dn-backup` | Backup configuration and management | — |
| `ansible-dn-monitoring` | Monitoring agents and configuration | — |

**Dailytasks key scripts:** `daily_move.sh`, `daily_compress.sh`, `daily_tasks.sh`, `daily_del.sh`, `rsync_tier1_to_tier2.sh`

**Required fact file** (must exist or backup cleanup is skipped):
```bash
# /etc/ansible/facts.d/devo_infra.fact
{"backup": true, "volumes": []}
```

---

## Common Playbook Patterns

```yaml
- name: Deploy dailytasks to datanodes
  hosts: datanode-santander
  become: yes
  gather_facts: yes
  serial: 1  # One node at a time

  vars:
    dailytasks_user: "logtrust"
    dailytasks_bucket_num: 2
    dailytasks_age: "3"
    dailytasks_tier_names:
      trunk: "ebs"
      t00: "yng"
      t01: "old"

  tasks:
    - name: Create devo_infra.fact
      copy:
        content: '{"backup": true, "volumes": []}'
        dest: /etc/ansible/facts.d/devo_infra.fact
        mode: '0644'

    - name: Deploy scripts from role templates
      template:
        src: /tmp/ansible-dn-dailytasks/templates/{{ item }}
        dest: /usr/local/bin/{{ item }}
        owner: "{{ dailytasks_user }}"
        mode: '0755'
        backup: yes
      loop:
        - daily_move.sh
        - daily_compress.sh
        - daily_tasks.sh
```

---

## Deployment Best Practices

- Always run `--check --diff` dry-run before applying
- Use `serial: 1` for critical infrastructure (never all nodes simultaneously)
- Use `backup: yes` when modifying existing files
- Verify each node before proceeding to the next
- Never restart alcohol services without setting datanode READONLY first (see SKILL.md)
- Never restart both alcohol services simultaneously

---

## Troubleshooting

### Deployment Failures

**Ansible cannot connect:**
```bash
ssh <hostname> "hostname"
grep ansible_user ansible/environments/<path>/hosts
```

**Template rendering fails / role not found:**
```bash
ansible-galaxy list | grep datanode_dailytasks
ansible-galaxy install -r ansible/requirements-<region>.yml --force
```

**Facts not available:**
```bash
ansible <hostname> -i ansible/environments/<path>/hosts -m setup
ssh <hostname> "ls -la /etc/ansible/facts.d/"
```

### Post-Deployment Issues

**Scripts not executing:**
```bash
ssh <hostname> "ls -l /usr/local/bin/daily_*.sh"
ssh <hostname> "bash -n /usr/local/bin/daily_move.sh"
```

**Backup cleanup not working:**
```bash
ssh <hostname> "cat /etc/ansible/facts.d/devo_infra.fact"
ssh <hostname> "grep 'deleting backup' /usr/local/bin/daily_move.sh"
ssh <hostname> "grep 'daily_move' /var/log/syslog | tail -20"
```

**Service status:**
```bash
ansible <group> -i ansible/environments/<path>/hosts \
  -m shell -a "systemctl status alcohol.target"
```

---

## Related Skills

- **`/devo-infra`** (`SKILL.md`) — Full operational guide: Kubernetes EKS, Malote JVM tuning, Serrea, SOAR, alcohol restart procedures
- **`/automation-resilience-infra`** — Health-check agent and auto-healing deployment
- **`/automation-offboarding`** — Customer domain off-boarding procedure
- **`/devo-database`** — MySQL/Adolfo access for datanode queries
- **`/devo-query`** — Maqui queries for ingestion and data verification
