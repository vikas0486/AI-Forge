# 🤖 Claude AI at Devo — KT Report

**Author:** Vikash Jaiswal &nbsp;|&nbsp; **Updated:** 2026-05-15 &nbsp;|&nbsp; **Talk time:** ~35 min
**Full doc:** `~/Documents/Repository/CLAUDE-AI-KT.md` &nbsp;|&nbsp; **Publish to:** Confluence → `03NOC` or `DevOps`

---

## 🧠 What Is This? (2 min)

Claude Code is Anthropic's AI CLI tool — think of it as a terminal assistant that can read files, run commands, call APIs, and remember context across sessions.

I set it up as a **fully integrated DevOps copilot** for Devo infrastructure. Not a chatbot — it actually runs Maqui queries, SSHes into datanodes, runs Ansible, and investigates incidents end-to-end.

---

## 🏗️ How It's Set Up (5 min)

Everything lives in three places:

```
~/.claude/          → Claude's brain (config, skills, memory)
~/.devo/            → Devo credentials + wrapper scripts
~/Documents/Repository/  → Our code (where Claude works)
```

**The key insight:** Claude Code runs in a non-interactive shell — your `.zshrc` aliases don't exist. So everything runs through **wrapper scripts** that are pre-approved (no permission prompts).

```
You type /devo-query
    → Claude loads the skill context
    → Runs: ~/Documents/Scripts/maqui-wrapper.sh eu "from siem.logtrust..."
    → Gets results, analyzes, responds
```

---

## ⚡ What It Actually Does (5 min)

| Before Claude | With Claude |
|--------------|-------------|
| Manually remember Maqui syntax | `/devo-query` — 97 ready functions, 9 regions |
| SSH → grep logs → SSH somewhere else | Jira → Maqui → Analysis in one flow |
| Look up Ansible playbook args | `/automation-resilience-infra` with full context |
| Hunt for Vault tokens in docs | `/devo-security` has the full topology |
| Re-explain context every session | Memory files persist across restarts |

**Biggest wins:** incident investigation speed, no context loss between sessions, Maqui queries that actually run fast.

---

## 🔧 Skills — The Core Concept (5 min)

A **skill** is a folder under `~/.claude/skills/skill-name/` with a `SKILL.md` file. When you type `/skill-name`, Claude loads that file as context — like giving it a cheat sheet for that domain.

**Currently: 22 skills.** They grew organically. Some overlap. That's why we're restructuring.

| Category | Skills |
|----------|--------|
| 🔍 Query | `/devo-query`, `/devo-database`, `/devo-platform` |
| 🖥️ Infrastructure | `/automation-resilience-infra`, `/devo-infra`, `/k8-multi-account` |
| 🔧 Platform services | `/malote`, `/devo-platform`, `/devo-infra`, `/devo-platform`, `/devo-infra` |
| 🚨 Alerting | `/devo-alert`, `/devo-devtool` |
| 🔐 Security | `/devo-security` |
| 🤖 Automation | `/automation-offboarding`, `/automation-tabularasa`, `/automation-resilience-infra` |
| 🛠️ DevTools | `/devo-devtool`, `/devo-devtool` |
| 📋 Ticketing | `/jira-platform` (Jira + Confluence, **READ ONLY**) |

---

## 🔐 Credentials & Safety (5 min)

**How secrets are stored:**
- Devo creds → `~/.devo/credentials.<region>` (chmod 600, never in shell history)
- AWS → SSO only, 4 accounts via `~/.aws/config` (no static keys except Bedrock IAM)
- Vault/OpenBao → accessed via `~/Documents/Scripts/vault-wrapper.sh`

**Safety rules enforced at config level** — these commands are **blocked** and always need your explicit "yes" first:

```
rm / rm -rf / find -delete / find -exec rm    ← file deletion
ssh host "... rm ..."                          ← remote deletion
git push / git merge                           ← repo writes
glab mr create / glab mr merge                ← MR operations
```

> This was added after an incident where aggregation data was deleted from a datanode without confirmation (2026-05-15).

**Jira is strictly READ ONLY** — Claude can search and read tickets, never comment or update.

---

## ⚡ Maqui Query Optimization (3 min)

Default queries scan weeks of data → slow. Smart filters cut that to seconds.

| Table | Add This Filter | Speed |
|-------|----------------|-------|
| `siem.logtrust.*` | `where client = 'self'` | 45s → **3s** |
| `syslog.alcohol.stats` | `where client = 'self'` ← mandatory | 30s+ → **3s** |
| `box.*` (metrics) | `where machine ~ 'pattern'` | 20s → **3s** |
| `system.delegated.*` | `pragma delegation.reaction.failed.connection.for: 0s` | eliminates timeouts |

Rule: **always add a time filter** (`now()-5m < eventdate < now()`) to every query. Adjust the window to your need — never leave it unbounded.

---

## 🔄 Two Claude Versions (2 min)

Both run via **AWS Bedrock** — no direct Anthropic billing, uses your existing AWS account.

```bash
claude45    # Sonnet 4.5 — extended thinking, 128k tokens, Bedrock debug mode
claude46    # Sonnet 4.6 — daily ops, faster, current default
```

Switch by running the alias. Claude Code needs a restart to pick it up.

---

## 🗺️ Restructuring Plan — 22 → 9 Skills (5 min)

The 22 skills overlap, share context, and are hard to maintain. The plan: collapse into 9 focused skills under a `/devo` master, each with one large well-organized `SKILL.md`.

```
TODAY (22 fragmented)          TARGET by 2026-05-28 (9 consolidated)
──────────────────             ──────────────────────────────────────
/devo-query    ─┐              /devo          ← master entry + routing
/devo-database  ├─▶            /devo-query    ← all query execution
/devo-platform ─┘              /devo-infra    ← datanodes + K8s + metamalote
                               /devo-tool     ← malote + asilo + soar + parsers
/automation-resilience-infra ─┐        /devo-devtool  ← jenkins + gitlab + terraform
/devo-infra     ├─▶      /devo-alert    ← alerts + monitoring + grafana
/k8-multi-account    ─┘        /devo-security ← vault (keep, enrich)
                               /devo-automation ← offboarding + tabularasa + resilience
/malote ─┐                     /jira-platform ← keep, enrich
/soar    ├─▶ /devo-tool
/asilo  ─┘
...etc
```

**Week 1:** `/devo-query`, `/devo-infra`, `/devo-alert`
**Week 2:** `/devo-tool`, `/devo-devtool`, `/devo-automation`, `/devo` master, cleanup

---

## 📍 Key File Paths (reference)

| What | Where |
|------|-------|
| Global rules | `~/.claude/CLAUDE.md` |
| Active config | `~/.claude/settings.json` |
| All skills | `~/.claude/skills/` |
| Session memory | `~/.claude/projects/.../memory/` |
| Devo wrappers + creds | `~/.devo/` |
| AWS SSO config | `~/.aws/config` |
| Model switcher | `~/.claude/switch-model.sh` |
| This full KT doc | `~/Documents/Repository/CLAUDE-AI-KT.md` |

---

## 📣 To Publish This to Confluence

```bash
source ~/.zshrc && conf spaces   # find the right space (03NOC or DevOps)
# Create page: "Claude AI Setup — ISM DevOps KT"
```

> ⚠️ Before publishing: remove any token/credential values from the content. Check `reference_openbao_prod.md` references.

---

*Questions? Everything is documented in the full KT doc. Skills are living files — add learnings directly back to the relevant `SKILL.md` after each incident.*
