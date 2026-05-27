---
name: devo-jira
description: Jira and Confluence access — search issues via JQL, get issue details, browse Confluence spaces and pages via CQL. READ ONLY (never write/comment). On-call report generation from CSV alert data.
argument-hint: "[issue-key|JQL|search-term]"
tags: [jira, confluence, atlassian, tickets, documentation]
---

## Skill Boundaries

| What | Skill |
|------|-------|
| Jira issue search, details, project tracking | **this skill** |
| Confluence space/page search, content retrieval | **this skill** |
| On-call report generation | **this skill** |
| Any Devo platform queries | **`/devo-query`** |

**CRITICAL: READ ONLY** — Never add comments, never update tickets. User manages all Jira writes manually.

---

## Quick Start

**Instance:** https://devoinc.atlassian.net  
**Credentials:** `~/.devo/credentials` (JIRA_EMAIL + JIRA_API_TOKEN / CONFLUENCE_EMAIL + CONFLUENCE_API_TOKEN)

### Jira

```bash
# Get issue details
source ~/.zshrc && jira issue ISM-14287

# Search issues
source ~/.zshrc && jira search "project=PLEN AND status=Open"

# My open issues
source ~/.zshrc && jira my

# All comments on issue
source ~/.zshrc && jira comments ISM-14287

# Test connection
source ~/.zshrc && jira status
```

### Confluence

```bash
# Get page by ID
source ~/.zshrc && conf page 5586812931

# Full-text search
source ~/.zshrc && conf search "mason agent" 10

# CQL search
source ~/.zshrc && conf cql 'space=03NOC AND text~"mason"' 10

# List spaces
source ~/.zshrc && conf spaces

# Test connection
source ~/.zshrc && conf status
```

---

## Aliases

| Alias | Wrapper | Subcommands |
|-------|---------|-------------|
| `jira` | `~/Documents/Scripts/jira-wrapper.sh` | `issue` `search` `my` `comments` `status` |
| `conf` | `~/Documents/Scripts/confluence-wrapper.sh` | `page` `search` `cql` `spaces` `status` `update` |

Helper functions: `~/Documents/Scripts/jira-platform/jira-helper.sh` and `confluence-helper.sh`  
(Sourced automatically by the wrapper scripts)

### Updating a Confluence Page

```bash
# 1. Write body to a temp HTML file
# 2. Get current version number
source ~/.zshrc && conf page PAGE-ID   # check Version field

# 3. Push update (version = current + 1)
source ~/.zshrc && conf update PAGE-ID VERSION "Page Title" /tmp/body.html
```

**Example:**
```bash
source ~/.zshrc && conf update 5586812931 3 "Automation : Resilience_Infrastructure" /tmp/body.html
```

The body file must be Confluence storage-format HTML. Use `<ac:structured-macro ac:name="code">` blocks for code sections.

---

## Common JQL Patterns

```bash
# Open issues in project
source ~/.zshrc && jira search "project=PLEN AND status!=Done ORDER BY created DESC"

# Issues assigned to me
source ~/.zshrc && jira search "assignee=currentUser() AND status in (Open, 'In Progress')"

# Recent incidents
source ~/.zshrc && jira search "project=ISM AND created>=-7d ORDER BY created DESC"

# Search by text
source ~/.zshrc && jira search 'project=PLEN AND text~"myapp-loader"'

# High priority open
source ~/.zshrc && jira search "priority in (Critical, Blocker) AND status=Open"
```

---

## Common CQL Patterns

```bash
# Search by space and text
source ~/.zshrc && conf cql 'space=03NOC AND text~"mason agent"' 10

# Recently updated in space
source ~/.zshrc && conf cql 'space=DevOps AND lastModified>=-7d ORDER BY lastModified DESC'

# Pages by label
source ~/.zshrc && conf cql 'label="runbook" AND space=03NOC'

# Pages matching title
source ~/.zshrc && conf cql 'title~"datanode" AND type=page'
```

---

## On-Call Report

**Script:** `~/Documents/Scripts/jira-platform/oncall-report-generator.sh`  
**Input:** CSV export from alert tool  
**Output:** Formatted report with P1/P2/False Positive categorization, durations

```bash
bash ~/Documents/Scripts/jira-platform/oncall-report-generator.sh
```

Full details: `~/.claude/skills/devo-jira/ONCALL-REPORT.md`

---

## Related Skills

- `/devo-query` — Maqui queries and platform data
- `/devo-tools` — Platform architecture docs
- `/devo-alert` — Alert management (Flow/Pilot/Cockpit)
- `/devo-devtool` — Jenkins, GitLab, monitoring
