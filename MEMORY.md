# Project Memory: AI Forge

## Mission
To empower Devo Platform Engineers with an AI-orchestrated operational layer that provides instant expertise, unified multi-region control, and a high-security, low-friction workflow.

## Core Objective
Consolidate fragmented platform knowledge into 11 executable domain skills, abstracting away infrastructure complexity through a unified wrapper and alias layer.

## Architecture Summary
AI Forge follows a "Crescent" architecture:
*   **Skill Layer:** Domain-specific knowledge packs (`claude-skills/`).
*   **Wrapper Layer:** Unified shell scripts (`~/Documents/Scripts/`) that handle auth and regional logic.
*   **Execution Layer:** Native platform binaries (Maqui, MySQL, Kubectl, Adolfo).
*   **Security Layer:** Centralized credentials (`~/.devo/credentials`) and model switching logic.
*   **Memory Layer:** Persistent cross-session context stored in `memory/`.

## Key Components
*   **switch-model.sh:** Centrally manages AI model profiles and environment variables.
*   **Maqui Wrappers:** Standardized aliases (`maquieu`, `maquius`, etc.) for 7 regions.
*   **Adolfo/SQL Wrappers:** Direct DB access with region auto-resolution.
*   **Vault/OpenBao Wrappers:** Automated token injection for 5 regional Vaults.
*   **Jenkins/Jira/Git Wrappers:** Secure API interactions with token-based auth.

## Important Decisions
*   **Centralized in eu-west-1:** Core automation hubs (Lambda, API GW) are consolidated in Ireland for management simplicity.
*   **Skills as Modules:** Domain knowledge is decoupled from core configuration to minimize context bloat.
*   **Wrapper-First Execution:** Direct binary calls are discouraged in favor of wrappers that enforce safety and auth.
*   **IST Timezone Primary:** All human interactions and Maqui results are in IST; internal logs are UTC.
*   **Read-Only Integration:** Jira and Confluence are strictly read-only for the AI agent to prevent unauthorized documentation changes.

## AWS Dependencies
*   **Bedrock:** Primary AI execution engine (Sonnet 4.6/4.5).
*   **EKS:** Hosting for Pilot, Tapu, and other platform microservices.
*   **RDS:** Multi-region storage for `logtrust` and `pilot` schemas.
*   **Secrets Manager:** Storage for high-value root tokens.
*   **SSM:** Primary method for remote shell access to EC2 datanodes.

## Known Constraints
*   **Interactive Shell:** The AI agent's shell is non-interactive; all aliases must be prefixed with `source ~/.zshrc &&`.
*   **Maqui Timeouts:** Unfiltered queries on large tables (e.g., `siem.logtrust.flow.out`) will timeout after 60s.
*   **Vault Cooldown:** Regional Vaults may have rate-limiting on token creation.
*   **Git Protected Branches:** Pushing directly to `master` or `main` is blocked by server-side hooks.

## Security Rules
*   **Zero Secret Commitment:** Never commit files from `~/.devo/` or `~/.aws/` to git.
*   **Deny-List Enforcement:** `rm -rf`, `reboot`, and `shutdown` are globally blocked in `settings.json`.
*   **HMAC Signature:** Mandatory for all SNS/API Gateway interactions.
*   **chmod 600:** Enforced on all credential files.

## Operational Knowledge
*   **Metric Intervals:** Maqui metrics are typically 1-minute; Lodge polling is 10-60 minutes.
*   **Log Locations:** `/var/log/metamalote/`, `/var/log/health-check/`, and `/var/log/myapp-loader.log` are primary targets.
*   **Table Patterns:** `my.app.*` and `my.synthesis.*` require `client = "<domain>"` for performance.

## Common Failure Scenarios
*   **Lomana/Lodge Desync:** Metadata files not reaching datanodes (check Mason Agent logs).
*   **Jenkins Disk Full:** Builds stuck due to `/var/lib/jenkins` exhaustion (check build retention).
*   **Vault Token Expiry:** 403 errors on Vault operations (renew via `switch-model.sh`).

## Troubleshooting Knowledge
*   **CANCELED Queries:** Often indicative of Pilot heap leaks or Malote overload.
*   **401 Errors in Probio:** Misleading; usually signifies a signature mismatch, not just bad auth.
*   **Blank Lookups:** Check Mason Agent S3 connectivity and `udlu/` directory permissions.

## Future Work
*   **NOC Skill:** Dedicated real-time triage and alert correlation.
*   **Ansible GenAI:** Drafting playbooks from natural language requests.
*   **Cross-Region Aggregator:** Single skill to query all 7 regions simultaneously.

## AI Agent Notes
*   **SOP:** Always `source ~/.zshrc &&` before executing any alias.
*   **Assumption Guard:** Do not assume a region; always specify or derive from context.
*   **Verification:** Confirm success of a command by checking logs or status aliases, not just the exit code.
*   **Identity:** When prompted for identity in git, use `Vikash Jaiswal <vikash.jaiswal@devo.com>`.
