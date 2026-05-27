# Devo Parser Deployment System

Complete operational knowledge for Devo's matasmafias parser deployment system.

## Quick Start

```bash
# Load the skill
/parsers

# Or reference it in conversation:
"Check the /devo-tools skill for how to restart metamalote services"
```

## What's Inside

- **Deployment Architecture** - GitLab → Jenkins → Ansible → Metamalote flow
- **Service Management** - How to restart metamalote and malote-controller
- **Troubleshooting** - Common errors and their solutions
- **Regional Infrastructure** - Metamalote vs datanode architecture
- **Verification Procedures** - How to verify parser deployments
- **Real Case Study** - CHG-10577 resolution details

## Key Learnings

1. **Services don't auto-reload parsers** - Manual restart required after deployment
2. **Both metamalote AND datanodes need restart** - Not just coordinators
3. **Ansible "touch" is unreliable** - Don't rely on automatic reload
4. **Query routing matters** - Check which datanode the query hits

## Files

- `SKILL.md` - Complete skill documentation (loaded with `/devo-tools`)
- `claude-skills.json` - Skill manifest
- `README.md` - This file

## Created

Based on CHG-10577 investigation and resolution (May 1, 2026).

## Related Skills

- `/devo-query` - Maqui query system
- `/devo-jira` - Jira ticket tracking
- `/automation-resilience-infra` - Ansible infrastructure automation
