# DevOps Quick Reference - Devo Platform

**Status:** ✅ FINAL VERSION (v33) - Saved 2026-04-24

## Page Information

- **Confluence URL:** https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5762809869
- **Page ID:** 5762809869
- **Space:** RDT (R&D Teams)
- **Current Version:** 33
- **Title:** DevOps Quick Reference - Devo Platform
- **Content Size:** 201,527 characters (~197KB)
- **Total Entries:** ~270 pages indexed

## What This Page Is

A comprehensive DevOps documentation index covering the entire Devo platform. Created by scanning all Confluence spaces and organizing relevant operational documentation into 12 major categories.

### Categories

1. **Infrastructure** - Cloud Platforms (AWS, Azure, IBM, GovCloud), Datanodes, Kubernetes, Services
2. **Ingestion** - Cloud Collector, Batrasio, Relay
3. **Database** - Tools (Maqui), Services (MySQL, Aurora), Operations, Lookups
4. **Query & Data Processing** - Malote, Query Interface, Devo Query Tools
5. **Certificates Management** - Certificate System, Generation, Renewal, Administration
6. **Monitoring & Observability** - Core Monitoring, Grafana, Prometheus, Netdata, AlertManager
7. **Devo Alerts** - Alert System, Knowledge Base
8. **Security Products** - UEBA, SOAR
9. **Incident Management** - IRCA Reports, Systems OnCall, JIRA Operations
10. **Devo Platform** - Core Platform, Deployment
11. **Deployment** - Ansible, Terraform, Docker, Kubernetes, CI/CD, ArgoCD
12. **Strike48** - AI Platform, MCP, Matrix Studio

## Format

### Table Structure
- **3 Columns:** Title (15%) | Description (75%) | Link (10%)
- **Title:** 2-3 words describing the page
- **Description:** 10-15 words explaining what it covers
- **Link:** "View" link to actual Confluence page

### Header Format
```
Base URL: https://devoinc.atlassian.net/ (clickable link to Global Repository)
Status: Validated, Cleaned & Enhanced (~270 Pages)
By: Vikash Jaiswal
Generated: 2026-04-23
```

### Table of Contents
- Uses Confluence native `toc` macro for automatic navigation
- All section headers properly anchored for working links
- Auto-updates when page structure changes

## Files in This Directory

### Source Files
- **DEVO_DEVOPS_LINKS.md** - Markdown source with all 270 entries
- **FINAL_CONFLUENCE_PAGE_v33.html** - Final HTML storage format (saved 2026-04-24)
- **FINAL_PAGE_METADATA.json** - Page metadata (version, size, etc.)

### Conversion Scripts
- **restore_clean_version.py** - Clean conversion (no font overrides, plain Confluence markup)
- **restore_working_toc.py** - Previous version with various formatting attempts
- **toc_with_css_styling.py** - Attempted CSS styling (didn't work in Confluence)
- **fix_toc_hierarchy.py** - Manual TOC with hierarchy (links didn't work)

### Documentation
- **DEVOPS_QUICK_REFERENCE_README.md** - This file
- **README.md** - Main skill documentation (Jira/Confluence API usage)

## How to Update

### 1. Update Markdown Source

Edit `DEVO_DEVOPS_LINKS.md` with new entries:

```markdown
#### Category Name

| Title | Description | Link |
|-------|-------------|------|
| Short Title | 10-15 word description of what this page covers | [View](https://devoinc.atlassian.net/wiki/...) |
```

### 2. Convert and Upload

Use the clean conversion script:

```bash
cd /tmp
python3 /Users/vikash.jaiswal/.claude/skills/jira-platform/restore_clean_version.py
```

**Important:** The script at `/tmp/restore_clean_version.py` uses:
- NO layout wrappers (`<ac:layout>` tags)
- NO custom font sizing
- Plain Confluence markup for normal rendering
- Confluence native TOC macro for working navigation

### 3. Manual Formatting in Confluence

After upload, the user manually adjusts in Confluence editor:
- Table column widths
- Link alignment
- Any visual tweaks
- Font sizes (if needed)

**Note:** Font sizing must be done in Confluence editor, not via CSS or inline styles. The Confluence storage format doesn't support custom CSS properly.

## Data Collection Process

### Original Scan (2026-04-23)

Scanned ~1150+ Confluence pages across all spaces with these filters:

**Inclusion Criteria:**
- Operational documentation (procedures, runbooks, guides)
- Service documentation (architecture, deployment, troubleshooting)
- Tool documentation (usage, configuration, APIs)
- Page content > 300 characters

**Exclusion Criteria:**
- Meeting notes, personal pages
- Test/draft pages with no content
- Duplicate or redundant entries
- Pages with no operational value

**Categories Added:**
- Initial: Cloud Collector, UEBA, SOAR, Devo-Platform, Datanodes, K8s, Batrasio, Certificates, Malote, Grafana-Prometheus, Devo Alerts
- Added during scan: Infrastructure, Database, Monitoring, Incident Management, Deployment, Strike48

**Quality Filters:**
- Removed empty pages
- Removed deprecated docs where newer versions exist
- Kept foundational procedures regardless of age
- Enhanced descriptions to 10-15 words for clarity

## Version History

- **v1-19:** Development iterations (table format, TOC generation, metadata)
- **v20:** Clean version with 4-line metadata, working navigation
- **v21-22:** Title adjustments
- **v23:** Renamed to "DevOps Quick Reference - Devo Platform"
- **v24-26:** Font sizing attempts (CSS, inline styles) - didn't work
- **v27-28:** Removed layout wrappers to fix font size issues
- **v29-33:** Manual formatting by user (FINAL)

## Maintenance Notes

### What Works
✅ Confluence native TOC macro for navigation
✅ Plain Confluence markup (no layout wrappers)
✅ Bold table headers using `<strong>` tags
✅ Table column width control via `<colgroup>`
✅ Center-aligned Link column via style attribute
✅ Proper anchor IDs for section navigation

### What Doesn't Work
❌ Custom CSS for font sizing (Confluence ignores it)
❌ Inline font-size styles (reduced by layout wrapper)
❌ `<ac:layout>` wrapper (reduces all font sizes)
❌ Manual TOC with custom hierarchy (links break)

### Best Practices
1. Use plain Confluence markup without wrappers
2. Let Confluence handle font sizing naturally
3. Use native TOC macro for navigation
4. Keep table structure simple (3 columns, fixed widths)
5. Update markdown source first, then regenerate
6. Manual tweaks only after upload (in Confluence editor)

## Related Skills

- **/jira-platform** - Confluence API access (this skill)
- **/devo-platform** - Maqui queries for operational data
- **/devo-database** - Database access for infrastructure queries
- **/automation-resilience-infra** - Datanode automation and deployment
- **/malote** - Malote/Metamalote troubleshooting

## Contact

**Author:** Vikash Jaiswal (vikash.jaiswal@devo.com)
**Generated:** 2026-04-23
**Last Updated:** 2026-04-24 (v33 - Final format locked)

---

**Status:** 🎉 PRODUCTION READY - Final version saved and documented
