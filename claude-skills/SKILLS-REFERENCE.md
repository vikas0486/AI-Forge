# Claude Code Skills Reference

**Last Updated:** 2026-03-01

## Available Skills

### 1. devo-tools
**Purpose:** Query and monitor Devo platform using Maqui (LINQ) query language

**Capabilities:**
- Infrastructure monitoring (Mason, Malote, Metamalote, Batrasio, Lomana)
- Ingestion tracking
- Performance analysis
- Affinity management
- Multi-region support (EU, APAC, US, US3, Telefonica, San, NCSC-Bahrain)

**Usage:** `/devo-tools`

---

### 2. jira-platform
**Purpose:** Query and manage Jira and Confluence using Atlassian REST APIs

**Capabilities:**
- **Jira:** Search issues via JQL, manage issues/comments/projects
- **Confluence:** Browse spaces, search pages with CQL, get page content, track documentation updates
- Shared API token authentication

**Usage:** `/devo-jira`

---

### 3. devo-database
**Purpose:** Direct database access to Devo infrastructure

**Capabilities:**
- Adolfo (DB orchestrator) queries
- Maqui CLI (metamalote queries)
- MySQL (logtrust database) access
- Fastest method for datanode management
- Domain affinity queries
- Operational queries
- Multi-region credentials (EU, USA, APAC, Canada, US3, ME, GCP Telefonica)

**Usage:** `/devo-database`

---

### 4. datanode-deployment
**Purpose:** Deploy resilience infrastructure and automation to datanodes using Ansible

**Capabilities:**
- Auto-healing deployment
- Monitoring infrastructure deployment
- Infrastructure automation to datanode environments

**Usage:** `/automation-resilience-infra`

---

### 5. malote
**Purpose:** Malote/Metamalote service troubleshooting

**Capabilities:**
- Connection pool analysis
- Heap exhaustion diagnostics
- OOM issue debugging
- Connection explosion troubleshooting
- Performance problem analysis

**Usage:** `/malote`

---

### 6. serrea_cluster ⭐ NEW
**Purpose:** Serrea cluster operations for CaixaBank environment

**Capabilities:**
- HMAC error suppression
- log4j configuration management
- Rolling restart procedures
- Production troubleshooting
- Complete CHG runbook with step-by-step instructions

**Usage:** `/devo-infra`

**Status:** Created 2026-03-01 (requires Claude Code restart to activate)

---

## Skill Locations

All skills stored in: `~/.claude/skills/`

```
~/.claude/skills/
├── devo-tools/
├── jira-platform/
├── devo-database/
├── datanode-deployment/
├── malote/
└── serrea_cluster/      ⭐ NEW
```

---

## Quick Reference

| Skill | Use Case | Primary Tool |
|-------|----------|--------------|
|  devo-tools | Platform monitoring, Maqui queries | Maqui/LINQ |
| jira-platform | Issue/doc management | Jira/Confluence API |
| devo-database | Direct DB queries | Adolfo/MySQL |
| datanode-deployment | Infrastructure automation | Ansible |
| malote | Service troubleshooting | Diagnostics |
| serrea_cluster | Cluster operations | Runbooks |

---

## Notes

- Use `/` prefix to invoke skills (e.g., `/devo-tools`)
- Skills are context-aware and provide specialized prompts
- New skills require Claude Code restart to appear in system reminders
- Skills can be edited in `~/.claude/skills/[skill-name]/SKILL.md`
