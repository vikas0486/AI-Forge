# Project Skill Guide: AI Forge

## Domain Knowledge
AI Forge operates in the **DevOps and Platform Engineering** domain, specifically tailored for the **Devo Data Analytics Platform**. It encompasses:
*   **Data Ingestion:** Parsers, matasmafias, and myapp-loader.
*   **Storage & Metadata:** Datanode architecture, Mason, Lodge, and Lomana.
*   **Query Operations:** Maqui LINQ, Malote query engine, and multi-region routing.
*   **Security & Auth:** Vault, OpenBao, TAPU tokens, and HMAC signing.
*   **Infrastructure:** Kubernetes (EKS), Ansible, and AWS service management.

## Technical Stack
*   **Languages:** Python, Bash, Groovy (Jenkins), SQL, Maqui LINQ.
*   **Orchestration:** Ansible, Kubernetes (kubectl), Terraform/Terragrunt.
*   **Automation:** Jenkins (CI/CD), GitLab Pipelines.
*   **Infrastructure:** AWS (EC2, EKS, RDS, S3, Lambda, API Gateway).
*   **Monitoring:** Grafana, Prometheus, Alertmanager, Dynatrace.

## Architecture Knowledge
*   **Centralized Hub (eu-west-1):** All Lambdas and API Gateways for automation are hosted here.
*   **Regional Datanodes:** Storage and query execution occur in the datanode's native region.
*   **Crescent Pattern:** AI-assisted logic surrounds native platform tools via a wrapper layer.
*   **Metadata Propagation:** Lomana -> S3 -> Mason Agent -> Malote.

## AWS Knowledge Required
*   **EKS:** Navigating namespaces (`vault`, `robusta`, `pilotserver-alerts`) and StatefulSets.
*   **RDS:** Managing `logtrust` and `pilot` schemas across regions.
*   **IAM & SSO:** Role-based access via `aws sso login` and regional profiles.
*   **Secrets Manager:** Automated retrieval of root Vault tokens.
*   **Bedrock:** Selecting and switching between Sonnet 4.6 and 4.5 models.

## Development Workflow
1.  **Skill Development:** Create or update `SKILL.md` in `claude-skills/<name>/`.
2.  **Wrapper Logic:** Modify or add scripts in `~/Documents/Scripts/`.
3.  **Local Testing:** Use `role-local` mode for Ansible deployments.
4.  **Deployment:** Push to GitLab and trigger Jenkins regional jobs.
5.  **Validation:** Verify via Maqui metrics or regional `systemctl` status checks.

## Debugging Workflow
1.  **CloudWatch Logs:** For automation hubs (Lambda/API GW) in `eu-west-1`.
2.  **Pod Logs:** Use `kube logs` for `pilotserver`, `tapu`, or `asilo` issues.
3.  **Service Logs:** SSH/SSM to datanodes for `metamalote`, `mason-agent`, or `health-check-agent`.
4.  **Maqui Queries:** Use `siem.logtrust.flow.out` or `siem.logtrust.malote.query` for platform-wide issues.

## Security Knowledge
*   **Signature Calculation:** Knowledge of HMAC SHA256 for Devo API and Probio interactions.
*   **Credential Masking:** Ensuring tokens are passed via environment variables, never string interpolation.
*   **Vault Namespaces:** Understanding the difference between `vault` and `openbao-prod` namespaces.

## Common Tasks

### Add a New Skill
*   Create `claude-skills/<new-skill>/SKILL.md`.
*   Register trigger prompts in `claude-skills.json`.
*   Update the master `README.md` skills map.

### Deploy Resilience Agent
*   `source /Users/vikash.jaiswal/Documents/Scripts/role-mode-switcher.sh && role-local`.
*   `ansible-playbook ansible/playbooks/deploy-datanode-resilience.yml -i <inventory> -e target_hosts=<group>`.

### Troubleshoot Missing Lookups
*   Check Lomana activity via Maqui.
*   Verify Mason Agent status on the datanode.
*   Check `udlu/` directory content and Malote logs.

## Coding Standards
*   **Safe Queries:** Always use `where client = 'self'` or `<domain>` and `limit`.
*   **Error Handling:** Wrappers must catch non-zero exits and provide domain-relevant hints.
*   **Documentation:** All new features must be reflected in `SKILL.md` and the project `MEMORY.md`.

## Repository Conventions
*   **Commit Messages:** Follow the `Release: vX.Y.Z` pattern for pipeline compatibility.
*   **Branching:** Always use `feature/<name>` and open an MR; do not push to master.
*   **Timezones:** Display Maqui results in IST; interpret platform logs as UTC.

## Operational Procedures
1.  **Model Switching:** Use `claude46` or `claude45` aliases to rotate Bedrock profiles.
2.  **Vault Rotation:** Retrieve new tokens from AWS Secrets Manager and update `~/.devo/credentials`.
3.  **Jenkins Cleanup:** Manually prune builds if executors are stuck due to disk space.

## AI Assistant Instructions
If asked to perform a task:
1.  **Identify Domain:** Determine which of the 11 skills is most relevant.
2.  **Check Memory:** Review `MEMORY.md` for previous feedback or constraints.
3.  **Source Wrappers:** Always `source ~/.zshrc` before running any alias.
4.  **Confirm Destruction:** Never execute `rm`, `reboot`, or `stop` without explicit user "yes".

## Knowledge Checklist
- [ ] Do you know how to switch to Sonnet 4.5 for deep analysis?
- [ ] Can you identify the 7 Devo regions?
- [ ] Do you understand the difference between `logtrust` and `pilot` DB schemas?
- [ ] Are you comfortable running `ansible-playbook` via the wrapper layer?
- [ ] Do you know where to find the `myapp-loader` logs?
