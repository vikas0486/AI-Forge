<div align="center">

# 🌙 &nbsp; C &nbsp; R &nbsp; E &nbsp; S &nbsp; C &nbsp; E &nbsp; N &nbsp; T &nbsp; : &nbsp; AI &nbsp; F &nbsp; O &nbsp; R &nbsp; G &nbsp; E
### ·  Knowledge Transfer

</div>

> **Author:** Vikash Jaiswal | **Updated:** 2026-05-18 (v6)  
> *Team-facing overview — AI FORGE architecture, setup rationale, and operational benefits*

---

## Overview

```
╔══════════════════════════════════════════════════════════════════════════════╗
║         C R E S C E N T  :  AI-FORGE  ECOSYSTEM  @  DEVO  ENGINEERING        ║
╠══════════════════════════════════════════════════════════════════════════════╣
║   🧠  INSTANT EXPERTISE        Zero ramp-up · Domain-ready · Always-on       ║
║   ⚡️  ONE COMMAND POWER        11 skills · 7 regions · 10 wrappers           ║
║   🔐  VAULT-GRADE SECURITY     Single credential source · No secrets leak    ║
║   🛡  BLAST-PROOF SAFETY       Deny-list enforced · Destructive ops blocked  ║
║   🗃  PERSISTENT MEMORY        Cross-session context · Zero re-explaining    ║
║   🔄  DUAL-MODEL AGILITY       Sonnet 4.6 daily · Sonnet 4.5 deep analysis   ║
║   🌍  MULTI-REGION NATIVE      EU · US · US3 · APAC · NCSC · Santander       ║
║   🤖  FULL AUTOMATION          Offboard · Resilience · Affinity — one agent  ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## 1. Model Configuration

*AI FORGE runs two model profiles — switch in one command. Credentials centralized, permissions always preserved.*

```
┌──────────────────────────────────────────────────────────────────────┐
│                  AI FORGE — MODEL PROFILES                           │
├───────────────┬────────────────────────┬─────────────────────────────┤
│  Alias        │  Model                 │  Best For                   │
├───────────────┼────────────────────────┼─────────────────────────────┤
│  claude46     │  Sonnet 4.6 (default)  │  Daily ops, queries, fast   │
│  claude45     │  Sonnet 4.5            │  Deep analysis, reasoning   │
└───────────────┴────────────────────────┴─────────────────────────────┘

Both route via:
  AWS Bedrock  →  us-east-1
  (no direct Anthropic API — all traffic stays within AWS)
```

### Model Switch Flow

```
  User runs:  claude46  (or claude45)
                   │
                   ▼
  ~/Documents/Scripts/switch-model.sh 4.6
                   │
                   ├─ source ~/.devo/credentials
                   │         reads BEDROCK_46_* vars
                   │
                   ├─ builds env block (keys + model ID)
                   │
                   └─→ writes env only → ~/.claude/settings.json
                                          ┌─────────────────────┐
                                          │  env   ← REPLACED   │
                                          │  permissions ← KEPT │
                                          │  hooks       ← KEPT │
                                          │  model       ← KEPT │
                                          └─────────────────────┘
                   ▼
        Restart Claude Code → AI FORGE runs on new model
```


---

## 2. Directory Structure

*Single well-known root. Everything in `~/.claude/` — no scattered config files.*

```
~/.claude/
│
├── CLAUDE.md                    ← 🧠 Global brain — rules always loaded
├── settings.json                ← ⚙️  Active model + permissions + env vars
├── settings.local.json          ← 🔧 Local overrides (non-shared)
├── welcome.sh                   ← 🎨 Session startup banner
│
├── skills/                      ← 📦 11 domain skill packs
│   ├── devo-query/
│   ├── devo-tools/
│   ├── devo-database/
│   ├── devo-alert/
│   ├── devo-security/
│   ├── devo-infra/
│   ├── devo-devtool/
│   ├── devo-jira/
│   ├── automation-offboarding/
│   ├── automation-resilience-infra/
│   └── automation-tabularasa/
│       │
│       └── Each skill contains:
│           ├── SKILL.md              ← Full knowledge loaded on invoke
│           └── claude-skills.json    ← Registration + trigger prompts
│
└── projects/
    └── -Users-vikash-jaiswal-Documents-Repository/
        └── memory/               ← 🗃️  Persistent cross-session memory
            ├── MEMORY.md         ← Index (auto-loaded every session)
            └── *.md              ← Typed memory files

~/.devo/
├── credentials                   ← 🔐 ALL secrets (platform + Bedrock keys)
├── settings.sonnet-4.5.json      ← 💾 Sonnet 4.5 profile backup
└── settings.sonnet-4.6.json      ← 💾 Sonnet 4.6 profile backup

~/.adolfo.yaml                    ← 🗄️  MySQL credentials (adolfo native)
~/.aws/config                     ← ☁️  4 SSO profiles
~/Documents/Scripts/              ← 🛠️  All wrapper scripts + switch-model.sh
```

### Why this structure?

| Design Choice | Benefit |
|--------------|---------|
| All config under `~/.claude/` | One place to back up / migrate / audit |
| [`CLAUDE.md`](../../.claude/CLAUDE.md) as global brain | Rules + constraints always loaded — no re-stating |
| Skills as separate directories | Load only what's needed — no context bloat |
| Single credentials file | One rotation point, one permission to audit |
| Wrapper scripts separate from config | Scripts are versioned in git; config stays local |
| Memory under project path | Auto-scoped — different projects get different memory |

---

## 3. Skills Architecture

*Domain knowledge pre-packaged. Invoke once → full expert context loaded.*

```
                        ┌─────────────────────┐
                        │   /skill-name       │
                        │   (slash command)   │
                        └──────────┬──────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │        SKILL.md              │
                    │  Full domain knowledge       │
                    │  Commands · Patterns · Rules │
                    └──────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                              11 SKILLS — DOMAIN MAP                                      │
├────────────────┬──────────────────────────┬──────────────────────────────────────────────┤
│  PLATFORM      │  /devo-query             │  Maqui LINQ · 7 regions · 97 funcs           │
│                │                          │  When: query logs, investigate customer data │
│                ├──────────────────────────┼──────────────────────────────────────────────┤
│                │  /devo-tools             │  Mason · Lomana · Asilo · Parsers            │
│                │                          │  When: Asilo jobs, my.synthesis, table mgmt  │
│                ├──────────────────────────┼──────────────────────────────────────────────┤
│                │  /devo-database          │  Adolfo ORM + MySQL direct access            │
│                │                          │  When: DB queries, alert context, affinity   │
├────────────────┼──────────────────────────┼──────────────────────────────────────────────┤
│  OPERATIONS    │  /devo-infra             │  EKS (19 clusters) + Ansible                 │
│                │                          │  When: K8s ops, Ansible playbooks, datanodes │
│                ├──────────────────────────┼──────────────────────────────────────────────┤
│                │  /devo-devtool           │  Jenkins · GitLab · Grafana/Prometheus       │
│                │                          │  When: CI/CD, SSH ops, monitoring, disk mgmt │
│                ├──────────────────────────┼──────────────────────────────────────────────┤
│                │  /devo-alert             │  Flow · Pilot · Cockpit · XSOAR              │
│                │                          │  When: alert lifecycle, staggering, TAPU     │
├────────────────┼──────────────────────────┼──────────────────────────────────────────────┤
│  SECURITY      │  /devo-security          │  Vault/OpenBao — 5 regions                   │
│                │                          │  When: secrets, tokens, Vault CRUD ops       │
│                ├──────────────────────────┼──────────────────────────────────────────────┤
│                │  /devo-jira              │  Jira JQL + Confluence CQL (READ ONLY)       │
│                │                          │  When: ticket lookup, runbook, doc search    │
├────────────────┼──────────────────────────┼──────────────────────────────────────────────┤
│  AUTOMATION    │  /automation-offboarding │  Customer decommission via Probio API        │
│                │                          │  When: domain removal, multi-region cleanup  │
│                ├──────────────────────────┼──────────────────────────────────────────────┤
│                │  /automation-resilience  │  Health-check agents on datanodes/metamalotes│
│                │                          │  When: deploy/update resilience infra        │
│                ├──────────────────────────┼──────────────────────────────────────────────┤
│                │  /automation-tabularasa  │  Domain affinity SQL rebalancing + rollback  │
│                │                          │  When: affinity rebalance, tabula rasa ops   │
└────────────────┴──────────────────────────┴──────────────────────────────────────────────┘
```

### Skill Interaction Map

```
  /devo-infra ──────────→ references  /devo-devtool  (SSH + Ansible ops)
  /devo-query ──────────→ feeds into  /devo-tools    (Asilo job status)
  /devo-alert ──────────→ feeds into  /devo-database (alert context DB)
  /automation-* ────────→ uses        /devo-infra    (Ansible playbooks)
  /devo-security ───────→ needed by   /devo-infra    (Vault creds for K8s)
```

### Skill Benefits

| # | Feature | Without Skills | With Skills |
|---|---------|---------------|------------|
| 1 | Domain context | Re-explain every session | Auto-loaded on invoke |
| 2 | Command accuracy | Guesses syntax | Exact wrapper/alias used |
| 3 | Region awareness | Must specify each time | Baked into skill |
| 4 | Safety rules | Forgotten | Enforced in skill |
| 5 | Onboarding | Hours of explanation | One `/skill-name` |

---

## 4. Wrapper & Alias Layer

*Every platform tool wrapped — auth, region, error handling abstracted. Same aliases for human and AI FORGE — zero dual maintenance.*

> ⚠️ Bash tool is non-interactive — always prefix `source ~/.zshrc &&` before any alias.

```
  Workflow of Wrapper Script
  ──────────────────────────────────────────────────────────────

  AI FORGE USER
       │
       │  source ~/.zshrc && <alias> <args>
       │
       ▼
  ┌─────────────────────────────────────────────────┐
  │              <tool>-wrapper.sh                  │
  │                                                 │
  │  • source ~/.devo/credentials  → token injected │
  │  • resolve region endpoint     → no raw IPs     │
  │  • validate auth               → clean errors   │
  └─────────────────────┬───────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────┐
  │           Platform API / Service                │
  │                                                 │
  │   Maqui · MySQL · Vault · K8s · Git             │
  │   Jira  · Confluence · Jenkins · SSO            │
  └─────────────────────────────────────────────────┘
```

| Alias | Wrapper | Covers | Details | Benefit |
|-------|---------|--------|---------|---------|
| `maquieu` | [`maqui-wrapper.sh`](../../Documents/Scripts/maqui-wrapper.sh) | Maqui LINQ | EU region, token injected | No raw IPs, region auto-set |
| `maquius` `maquius3` | [`maqui-wrapper.sh`](../../Documents/Scripts/maqui-wrapper.sh) | Maqui LINQ | US / US3 regions | Multi-region, one wrapper |
| `maquiapac` `maquisant` | [`maqui-wrapper.sh`](../../Documents/Scripts/maqui-wrapper.sh) | Maqui LINQ | APAC / Santander regions | 7 regions total covered |
| `maquigcp` `maquincsc` | [`maqui-wrapper.sh`](../../Documents/Scripts/maqui-wrapper.sh) | Maqui LINQ | GCP / NCSC regions | Single alias per region |
| `sql` | [`mysql-wrapper.sh`](../../Documents/Scripts/mysql-wrapper.sh) | MySQL direct | eu_pro / usa_pro / ap_pro / us3_pro / santander_eu | Multi-region, one command |
| `vault` | [`vault-wrapper.sh`](../../Documents/Scripts/vault-wrapper.sh) | OpenBao / Vault | 5 regions (EU/US/US3/APAC/NCSC) | Token auto-loaded |
| `kube` | [`kubectl-wrapper.sh`](../../Documents/Scripts/kubectl-wrapper.sh) | Kubernetes EKS | 4 AWS accounts, 19 clusters | Auto-detects account |
| `vault-repo` | [`ansible-vault-wrapper.sh`](../../Documents/Scripts/ansible-vault-wrapper.sh) | Ansible Vault | default / aws_us_pro | Secret decryption abstracted |
| `git` | [`git-wrapper.sh`](../../Documents/Scripts/git-wrapper.sh) | GitLab | HTTPS + `GITLAB_TOKEN` | No PAT exposure |
| `jira` | [`jira-wrapper.sh`](../../Documents/Scripts/jira-wrapper.sh) | Jira REST API | issue / search / my / status | Token injected, read-only safe |
| `conf` | [`confluence-wrapper.sh`](../../Documents/Scripts/confluence-wrapper.sh) | Confluence API | page / search / cql / update | Unified doc access |
| `jenkins` | [`jenkins-wrapper.sh`](../../Documents/Scripts/jenkins-wrapper.sh) | Jenkins API | jobs / build / console / trigger | CI/CD from CLI |
| `awssso` | [`aws-wrapper.sh`](../../Documents/Scripts/aws-wrapper.sh) | AWS SSO | login / use / profiles / status | Session-based, no static keys |
| `claude46` | [`switch-model.sh`](../../Documents/Scripts/switch-model.sh) | AI FORGE | Sonnet 4.6 — daily ops | Reads `BEDROCK_46_*` from creds |
| `claude45` | [`switch-model.sh`](../../Documents/Scripts/switch-model.sh) | AI FORGE | Sonnet 4.5 — deep analysis | Reads `BEDROCK_45_*` from creds |

---

## 5. Security & Credentials Architecture

*Zero secrets in config. Zero secrets in Claude context. One encrypted file.*

### Bedrock Model Credential Flow (AI FORGE)

```
  ~/.devo/credentials
        │
        ├── BEDROCK_46_*    ← Sonnet 4.6 — keys + model config
        └── BEDROCK_45_*    ← Sonnet 4.5 — keys + model config + inference profile

  [~/Documents/Scripts/switch-model.sh](../../Documents/Scripts/switch-model.sh)
        │  source [~/.devo/credentials](../../.devo/credentials)
        │  reads BEDROCK_4x_* vars
        └─→ writes env block only → [~/.claude/settings.json](../../.claude/settings.json)
                                       (permissions / hooks always untouched)
```

| Command | Flow | Effect |
|---------|------|--------|
| `claude46` | `switch-model.sh 4.6` → `BEDROCK_46_*` → `settings.json` env | Activate Sonnet 4.6 |
| `claude45` | `switch-model.sh 4.5` → `BEDROCK_45_*` → `settings.json` env | Activate Sonnet 4.5 |
| Key rotation | Update `~/.devo/credentials` only | One file, instant effect |

### Credentials Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CREDENTIALS FLOW                                 │
│                                                                     │
│   ~/.devo/credentials  (chmod 600 — single source)                  │
│         │                                                           │
│          ├──→  maqui-wrapper.sh     (sourced at runtime)            │
│          ├──→  mysql-wrapper.sh     (sourced at runtime)            │
│          ├──→  vault-wrapper.sh     (sourced at runtime)            │
│          ├──→  git-wrapper.sh       (GITLAB_TOKEN injected)         │
│          ├──→  jenkins-wrapper.sh   (API token injected)            │
│          └──→  jira/conf wrappers   (API tokens injected)           │
│                                                                     │
│   ~/.adolfo.yaml   (MySQL only — read natively by adolfo binary)    │
│   ~/.aws/config    (SSO profiles — no static keys stored)           │
└─────────────────────────────────────────────────────────────────────┘
```

### Credential Categories

| Category | Storage | Access Method |
|----------|---------|--------------|
| Platform APIs (7 regions) | [`~/.devo/credentials`](../../.devo/credentials) | Wrapper scripts |
| Vault / OpenBao (5 regions) | [`~/.devo/credentials`](../../.devo/credentials) | `vault` alias |
| GitLab | [`~/.devo/credentials`](../../.devo/credentials) | `git` wrapper |
| Jira / Confluence | [`~/.devo/credentials`](../../.devo/credentials) | `jira` / `conf` alias |
| Jenkins | [`~/.devo/credentials`](../../.devo/credentials) | `jenkins` alias |
| **Bedrock** | [`~/.devo/credentials`](../../.devo/credentials) | [`switch-model.sh`](../../Documents/Scripts/switch-model.sh) |
| MySQL | [`~/.adolfo.yaml`](../../.adolfo.yaml) | adolfo binary (native) |
| AWS | [`~/.aws/config`](../../.aws/config) | `awssso` alias |

### Security Benefits

| Feature | Benefit |
|---------|---------|
| Single credentials file | One audit surface, one rotation event |
| No secrets in [`~/.claude/settings.json`](../../.claude/settings.json) | Claude config can be shared safely |
| No secrets in commits | git-wrapper injects token at runtime |
| chmod 600 | OS-level protection |
| SSO (no static AWS keys) | Session tokens — expire automatically |

---

## 6. Permission & Safety Architecture

*Claude cannot self-authorize destructive operations — enforced at [`settings.json`](../../.claude/settings.json) config level.*

```
                 PERMISSION DECISION FLOW
                 ─────────────────────────
                 Claude wants to run command
                          │
                ┌─────────▼─────────┐
                │  Check deny list  │
                │  (settings.json)  │
                └─────────┬─────────┘
                   Match? │
             ┌────────────┴───────────┐
            YES                       NO
       ❌ BLOCKED                     │
            │                 ┌───────▼────────┐
         Show command         │  Check allow   │
         Wait for "yes"       │  list          │
                              └───────┬────────┘
                                Match?│
                           ┌──────────┴──────────┐
                         YES                     NO
                           │                     │
                    ✅ AUTO-RUN            🔔 PROMPT USER
```

### Protected Operation Categories

| Category | Examples | Behavior |
|----------|---------|---------|
| File deletion | `rm`, `find -delete` | Blocked — show + confirm |
| Service ops | `systemctl restart/stop` | Blocked — show + confirm |
| Server reboot | `reboot`, `shutdown` | Blocked — show + confirm |
| K8s restarts | `kubectl rollout restart` | Blocked — show + confirm |
| Process kill | `kill`, `pkill` | Blocked — show + confirm |
| Git push | `push origin master/main` | Blocked — show + confirm |
| MR operations | `pr create`, `mr merge` | Blocked — show + confirm |
| Asilo wipe | `stop-delete-unregister` | Blocked — show + confirm |

### Why This Matters

| Risk Without This | Protection |
|------------------|-----------|
| Accidental file wipe | Deletion requires explicit "yes" |
| Service disruption | Restart/stop always confirmed |
| Prod data loss | Asilo wipe is last-resort only |
| Unauthorized pushes | Git to master/main always blocked |

---

## 7. Persistent Memory System

*Session-to-session context — no re-explaining the same things twice.*

```
  Session 1                Session 2                Session N
  ─────────                ─────────                ─────────
  Learn something   ──→   Memory file written  ──→  Auto-loaded in MEMORY.md
  Vikash corrects   ──→   Feedback saved       ──→  Behavior adapts
  Incident context  ──→   Project file         ──→  Available next session
```

```
  MEMORY TYPES
  ─────────────────────────────────────────────────────
  📋 feedback    Behavioral rules — dos/don'ts
  📁 project     Active incident / project context
  🔗 reference   Pointers to external systems
  👤 user        User preferences and expertise
```

### Memory File Structure

**Path:** `~/.claude/projects/-Users-vikash-jaiswal-Documents-Repository/memory/`  
**Index:** [`MEMORY.md`](../../.claude/projects/-Users-vikash-jaiswal-Documents-Repository/memory/MEMORY.md)

```
memory/
├── MEMORY.md                  ← Index — auto-loaded every session
├── feedback_*.md              ← Behavioral corrections
├── project_*.md               ← Active project context
└── reference_*.md             ← External system pointers
```

### Memory Benefits

| Without Memory | With Memory |
|---------------|------------|
| Re-explain platform context each session | Loaded automatically |
| Repeat behavioral corrections | Saved as feedback — permanent |
| Re-share infrastructure details | Stored as reference |
| Incident context lost between sessions | Persisted in project files |
| Generic responses | Tailored to Devo platform specifics |

---

## 8. Operational Rules

### Timezone Handling

```
  ┌──────────────────────────────────────────────────────────┐
  │  TIMEZONE MAP                                            │
  ├─────────────────────────┬────────────┬───────────────────┤
  │  Component              │  Timezone  │  Offset from IST  │
  ├─────────────────────────┼────────────┼───────────────────┤
  │  User machine           │  IST       │  —                │
  │  Maqui query results    │  IST       │  —                │
  │  MySQL / Adolfo         │  UTC       │  -5:30            │
  │  K8s pods / Jenkins     │  UTC       │  -5:30            │
  │  Server logs            │  UTC       │  -5:30            │
  │  Datanode timestamps    │  UTC       │  -5:30            │
  └─────────────────────────┴────────────┴───────────────────┘
  Always convert before comparing.  UTC → IST: +5:30
```

### Git Workflow (Enforced)

```
  ✅ CORRECT                          ❌ BLOCKED
  ───────────────────────────────     ────────────────────────
  git checkout -b feature/<name>      git push origin master
  git push origin feature/<name>      git push origin main
  Open MR → user merges               git push --force
                                      git merge (shared branch)
                                      Co-Authored-By: Claude
```

### Maqui Learning & Query Safety Rules

*AI FORGE has learned Maqui LINQ syntax, table structures, and safe query patterns across all 7 regions — no hand-holding needed.*

| Table | Mandatory Filter |
|-------|-----------------|
| `siem.logtrust.*` | `where client = 'self'` |
| `syslog.alcohol.stats` | `where client = 'self'` |
| `system.delegated.*` | `pragma delegation.reaction.failed.connection.for: 0s` |
| `my.app.*` / `my.synthesis.*` | `where client = 'customer-domain'` |

*Unfiltered queries on large tables → timeout 30–60s. Filters are enforced in skill.*

---

## 9. Benefits Summary

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    WHAT THIS SETUP ACHIEVES                             │
├────────────────────────┬────────────────────────────────────────────────┤
│  Challenge             │  How Addressed                                 │
├────────────────────────┼────────────────────────────────────────────────┤
│  Context ramp-up       │  Memory auto-loaded — zero re-explaining       │
│  Platform complexity   │  11 domain skills — instant expert knowledge   │
│  Auth sprawl           │  Single credentials file, wrapper abstraction  │
│  Destructive accidents │  Permission deny-list + confirm protocol       │
│  Multi-region ops      │  All wrappers region-aware                     │
│  Slow investigations   │  Query patterns pre-baked in skills            │
│  Onboarding time       │  New team member: invoke skill = instant KT    │
│  Security risk         │  No secrets in Claude config or commits        │
│  Model flexibility     │  Switch model in one command, perms preserved  │
│  Timezone confusion    │  Rules enforced in Claude configuration with TZ│
└────────────────────────┴────────────────────────────────────────────────┘
```

---

## 10. Future Scope

- **Automation expansion** — more runbook-style skills for common incidents (datanode full disk, metamalote overload)
- **NOC Agent** — dedicated skill for real-time NOC monitoring queries and alert triage
- **AI FORGE** — Claude AI studio platform formalization (Strike48 · Prospects Studio · AI Agent · Crescent Forge)
- **Skill auto-suggestions** — Claude proactively suggests skill based on task without user invoking
- **Cross-region incident correlation** — single skill that queries all 7 regions simultaneously
- **Ansible playbook generation** — skill that drafts playbooks from natural language ops requests
- **RAG Evolution** — see Section 11 for the full token-optimized retrieval implementation plan

---

## 11. RAG Architecture: Minimum Token Consumption

*The biggest cost in an LLM agent is what goes into the prompt, not what the model generates. This section defines AI FORGE's strategy to minimize input tokens while maximizing retrieval quality.*

### Why Token Efficiency Matters

Current "Primitive RAG" loads full `SKILL.md` files — 2,000–4,000 tokens before any task begins. At scale (many queries, many sessions), this drives API cost and latency directly. Target: retrieve only the relevant chunks, cache the static, discard what's already known.

### Current Token Budget (Baseline)

```
┌──────────────────────────────────────────────────────────────────┐
│              TOKEN COST — CURRENT STATE (per turn)               │
├───────────────────────────────┬──────────────────────────────────┤
│  Component                    │  Tokens                          │
├───────────────────────────────┼──────────────────────────────────┤
│  CLAUDE.md (global brain)     │  ~700  (re-sent every turn)      │
│  MEMORY.md index              │  ~400                            │
│  Active SKILL.md (1 skill)    │  ~2,000 (full file load)         │
│  Referenced memory files      │  ~500 each (loaded on mention)   │
├───────────────────────────────┼──────────────────────────────────┤
│  Baseline before task input   │  ~3,600 tokens                   │
└──────────────────────────────────────────────────────────────────┘
```

### Target Token Budget (Optimized RAG)

```
┌──────────────────────────────────────────────────────────────────┐
│              TOKEN COST — TARGET STATE (per turn)                │
├───────────────────────────────┬──────────────────────────────────┤
│  Component                    │  Tokens                          │
├───────────────────────────────┼──────────────────────────────────┤
│  CLAUDE.md (Bedrock cached)   │  ~0  (prompt cache hit)          │
│  MEMORY.md index (trimmed)    │  ~200                            │
│  Skill context (3–5 chunks)   │  ~400 (semantic retrieval)       │
│  Memory files                 │  ~0  (fetch on demand only)      │
├───────────────────────────────┼──────────────────────────────────┤
│  Baseline before task input   │  ~600 tokens  (~83% reduction)   │
└──────────────────────────────────────────────────────────────────┘
```

### RAG Flow: Token-Optimized Retrieval

```
  USER QUERY
       │
       ▼
  ┌──────────────────────────────────────┐
  │  1. Prompt Cache Check               │
  │     CLAUDE.md cached in Bedrock?     │──YES──→ 0 tokens (skip)
  └──────────────────┬───────────────────┘
                     │ NO → include once, mark for caching
                     ▼
  ┌──────────────────────────────────────┐
  │  2. Intent Embedding                 │
  │     Embed user query (local model)   │
  └──────────────────┬───────────────────┘
                     │
                     ▼
  ┌──────────────────────────────────────┐
  │  3. Metadata Pre-filter              │
  │     {region, domain, command_type}   │──→ Shrinks search space
  └──────────────────┬───────────────────┘
                     │
                     ▼
  ┌──────────────────────────────────────┐
  │  4. Semantic Chunk Retrieval         │
  │     Top 3–5 chunks from index        │──→ ~400 tokens injected
  │     (ChromaDB embedded / Qdrant EKS) │
  └──────────────────┬───────────────────┘
                     │
                     ▼
  ┌──────────────────────────────────────┐
  │  5. Dedup Check                      │
  │     Strip context already present    │
  │     in CLAUDE.md or prior turns      │
  └──────────────────┬───────────────────┘
                     │
                     ▼
  Claude Response (grounded, minimal context overhead)
```

### Chunking Strategy for SKILL.md Files

| Chunk Type | Target Size | Content | Example |
|---|---|---|---|
| **Header chunk** | ~50 tokens | Skill name + trigger conditions + region scope | `devo-query: Maqui LINQ · EU/US/APAC · 7 regions` |
| **Command chunk** | ~150–200 tokens | 1 command pattern with args + safety filter | `maquieu "select … where client='self'"` |
| **Rule chunk** | ~100 tokens | Mandatory filter or safety constraint | `siem.logtrust.*: always where client = 'self'` |
| **Reference chunk** | ~100 tokens | Cross-skill pointer | `For K8s after query → /devo-infra` |

Each `SKILL.md` (~2,000 tokens) → ~10–15 semantic chunks → retrieve top 3–5 → **~400 tokens delivered**.
All 11 skills combined at chunk level = ~22,000 tokens indexed; only ~400 retrieved per query.

### Phase 1 Quick Win: SKILL-COMPACT.md (Zero Infrastructure)

Fastest path to token reduction with no vector DB required:

```
claude-skills/
├── devo-query/
│   ├── SKILL.md              ← Full knowledge (load on deep-dive only)
│   ├── SKILL-COMPACT.md      ← ≤200 token summary (loaded by default)
│   └── claude-skills.json
```

`SKILL-COMPACT.md` format template (< 200 tokens per skill):

```
SKILL: devo-query
TRIGGER: Maqui LINQ queries, log investigation, customer data analysis
REGIONS: EU(maquieu) US(maquius) US3(maquius3) APAC(maquiapac) SANT(maquisant) GCP(maquigcp) NCSC(maquincsc)
SAFETY: siem.logtrust.* → where client='self' | my.app.* → where client='<domain>'
LOAD_FULL: invoke /devo-query when writing complex queries or needing 97 function signatures
```

All 11 skills in compact format = ~2,200 tokens total vs. ~22,000 for all full `SKILL.md` files — **a 10x reduction** available today with no new tooling.

### Bedrock Prompt Caching Opportunity

Bedrock supports prompt caching with a 5-minute TTL. Apply `cache_control` to the static blocks in settings:

| Block | Cache-able? | Tokens Saved/turn |
|---|---|---|
| CLAUDE.md preamble | Yes | ~700 |
| Safety rules + deny-list | Yes | ~200 |
| Wrapper alias table | Yes | ~300 |
| **Total saved** | | **~1,200 tokens/turn** |

At 50 turns/day → **60,000 tokens/day saved** → ~90% cost reduction on cached sections.

### Implementation Phases

| Phase | Action | Token Reduction | Infrastructure | Effort |
|---|---|---|---|---|
| **1 (Now)** | Add `SKILL-COMPACT.md` per skill; load compact by default | ~40% | None | Low |
| **2 (Short)** | ChromaDB embedded; chunk + index all skills; `search-skill` tool | ~80% | Local Python | Medium |
| **3 (Medium)** | Qdrant on EKS `eu-west-1`; BM25 + dense hybrid search | ~85% | EKS StatefulSet | High |
| **4 (Long)** | Ingest Confluence/Jira; autonomous agentic retrieval | ~85% + quality | EKS + Bedrock | High |

---

*Last updated: 2026-06-27 (v8 — RAG token optimization added)*
