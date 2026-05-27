# Jira & Confluence - Atlassian API Access

**Instance:** https://devoinc.atlassian.net  
**Credentials:** `~/.devo/credentials` (JIRA_EMAIL + JIRA_API_TOKEN / CONFLUENCE_EMAIL + CONFLUENCE_API_TOKEN)

## Quick Start

```bash
# Jira
source ~/.zshrc && jira issue ISM-14287
source ~/.zshrc && jira search "project=PLEN AND status=Open"
source ~/.zshrc && jira my
source ~/.zshrc && jira comments ISM-14287
source ~/.zshrc && jira status

# Confluence — read
source ~/.zshrc && conf page 5586812931
source ~/.zshrc && conf search "mason agent" 10
source ~/.zshrc && conf cql 'space=03NOC AND text~"mason"' 10
source ~/.zshrc && conf spaces
source ~/.zshrc && conf status

# Confluence — update page
# Step 1: write body to HTML file (Confluence storage format)
# Step 2: check current version with: conf page PAGE-ID
# Step 3: push (version = current + 1)
source ~/.zshrc && conf update 5586812931 3 "Page Title" /tmp/body.html
```

---

## JQL Examples

```bash
# Urgent open work
source ~/.zshrc && jira search "assignee=currentUser() AND priority IN (High, Critical) AND status!='Done'"

# Recent updates
source ~/.zshrc && jira search "project=PLEN AND updated >= -1d ORDER BY updated DESC" 50

# Text search
source ~/.zshrc && jira search "text ~ 'datanode' AND created >= -30d" 50

# Production bugs
source ~/.zshrc && jira search "type=Bug AND labels=production AND status IN (Open, 'In Progress')"
```

---

## CQL Examples

```bash
# Space + text
source ~/.zshrc && conf cql 'space=03NOC AND type=page AND title~healthcheck' 50

# Recent updates
source ~/.zshrc && conf cql 'space=03NOC AND lastModified>=now("-7d") order by lastModified desc' 25

# By label
source ~/.zshrc && conf cql 'space=03NOC AND label=production' 50
```

---

## ISM Board Patterns

Always query all three project keys together: `project in (ISM, ISM2, NISM)`

```jql
# Currently in tribe escalation
project in (ISM,ISM2,NISM) AND status = "escalate to tribes"

# Passed through tribe status (last 30d)
project in (ISM,ISM2,NISM) AND status changed to "escalate to tribes" AFTER -30d
```

**Pagination:** `/rest/api/3/search/jql` uses token-based pagination. `total` returns `null`. Use `nextPageToken` + `isLast`. `jira search` caps at 100 results.

---

## On-Call Report

**Script:** `~/Documents/Scripts/jira-platform/oncall-report-generator.sh`  
**Input:** `/Users/vikash.jaiswal/Downloads/finalAlertData.csv`  
**Output:** `~/Documents/Repository/oncall_report.md`

```bash
bash ~/Documents/Scripts/jira-platform/oncall-report-generator.sh
```

---

## Confluence Key IDs

| Space | Key | Space ID |
|-------|-----|----------|
| Cloud Operations | CO | 650117258 |
| Monitoring Operations | 03NOC | 1294467123 |

Known page IDs (CO space): Incident Trends parent `3794796706`, 2024 ISM Trends `3962339329`

**DevOps Reference Guide:** https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5763891386
