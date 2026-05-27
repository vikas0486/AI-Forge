---
name: devo-security
description: HashiCorp/OpenBao Vault — credentials access, KV secret paths, region endpoints (EU/US/US3/APAC/NCSC), Kubernetes contexts for Vault operations.
argument-hint: "[region] [secret-path]"
tags: [vault, openbao, secrets, security, credentials]
---

# CRITICAL: vault-wrapper.sh Environment Names

| Environment | Region | Correct Name | Wrong (never use) |
|---|---|---|---|
| EU Production | eu-west-1 | `eu_prod` | eu, eu_pro, eu-prod |
| US Production | us-east-1 | `us_prod` | us, us_pro, us-prod |
| US3 Production | us-east-2 | `us3_prod` | us3, us3_pro |
| APAC Production | ap-southeast-1 | `apac_prod` | apac, apac_pro, ap_prod |
| NCSC Bahrain | eu-west-1 | `ncsc_bahrain` | ncsc, ncsc_prod, ncsc_pro |

---

## Vault Instances (All Regions)

| Env | URL | AWS Region | AWS Account | Secret Name (Secrets Manager) |
|---|---|---|---|---|
| `eu_prod` | https://vault-eu.devo.com | eu-west-1 | 175688291360 | `devo-vault-init-token` |
| `us_prod` | https://vault-us.devo.com | us-east-1 | 175688291360 | `vault-us-token` |
| `us3_prod` | https://vault-us3.devo.com | us-east-2 | 175688291360 | `devo-vault-init-token-pro-us3` |
| `apac_prod` | https://vault-apac.devo.com | ap-southeast-1 | 175688291360 | `devo-vault-init-token-prod-apac` |
| `ncsc_bahrain` | https://vault.hawk.ncsc.gov.bh | eu-west-1 | 018108407576 | `prod-ncscbh-eu-vault-init-definite-hare` |
| DevTools (OpenBao) | https://openbao-prod.devo.com | eu-west-1 | 281139278838 | `openbao_root_token` |

> **DevTools:** `vault.devotools.com` (HashiCorp Vault) is permanently decommissioned. All DevTools secrets now live in OpenBao at `openbao-prod.devo.com`. The `vault-init-token-devotools` secret in Secrets Manager is the **old dead token** — do not use it.

### EKS Cluster Names (kubectl contexts)

| Region | Cluster Context | Vault Namespace |
|---|---|---|
| EU | `prod-eu` | `vault` |
| US | `prod-us` | `vault` |
| US3 | `prod-us3` | `vault` |
| APAC | `prod-apac` | `vault` |
| NCSC | `prod-ncscbh-eu` | `vault` |
| LogicHub EU | `logichub-prod-eu` | `vault` |
| Observability | `observability` | `vault` |
| UEBA EU | `ueba-prod-eu` | `vault` |
| DevTools (OpenBao) | `devtools` | `openbao-prod` |

---

## Authentication

### Retrieve Root Tokens (AWS Secrets Manager)

```bash
# EU
aws secretsmanager get-secret-value --secret-id devo-vault-init-token --region eu-west-1 --query SecretString --output text --profile production-limited

# US
aws secretsmanager get-secret-value --secret-id vault-us-token --region us-east-1 --query SecretString --output text --profile production-limited

# US3
aws secretsmanager get-secret-value --secret-id devo-vault-init-token-pro-us3 --region us-east-2 --query SecretString --output text --profile production-limited

# APAC
aws secretsmanager get-secret-value --secret-id devo-vault-init-token-prod-apac --region ap-southeast-1 --query SecretString --output text --profile production-limited

# NCSC Bahrain (account 018108407576)
aws secretsmanager get-secret-value --secret-id prod-ncscbh-eu-vault-init-definite-hare --region eu-west-1 --query SecretString --output text --profile production-limited

# DevTools OpenBao (account 281139278838 — devotools-limited lacks secretsmanager; use AWS Console)
# Secret name: openbao_root_token  Region: eu-west-1
aws secretsmanager get-secret-value --secret-id openbao_root_token --region eu-west-1 --query SecretString --output text --profile devotools-limited
```

### SSO Login

```bash
aws sso login --profile production-limited   # EU/US/US3/APAC
aws sso login --profile bahrain-access        # NCSC Bahrain
aws sts get-caller-identity --profile production-limited
```

### AWS Profiles (~/.aws/config)

```ini
[profile production-limited]
sso_session = production
sso_account_id = 175688291360
sso_role_name = LimitedAdmin
region = eu-west-1

[profile bahrain-access]
sso_session = production
sso_account_id = 175688291360
sso_role_name = BahrainAccess
region = eu-west-1

[profile bahrain]
source_profile = bahrain-access
role_arn = arn:aws:iam::018108407576:role/BH-Bahrain
region = eu-west-1
role_session_name = ncsc-bahrain-access
```

### Local Credentials File

**Location:** `~/.devo/credentials` (permissions: 600)

```yaml
eu_prod:
  url: 'https://vault-eu.devo.com'
  token: '<token-from-aws-secrets-manager>'
  namespace: ''
  region: 'eu-west-1'

us_prod:
  url: 'https://vault-us.devo.com'
  token: '<token>'
  namespace: ''
  region: 'us-east-1'

us3_prod:
  url: 'https://vault-us3.devo.com'
  token: '<token>'
  namespace: ''
  region: 'us-east-2'

apac_prod:
  url: 'https://vault-apac.devo.com'
  token: '<token>'
  namespace: ''
  region: 'ap-southeast-1'

ncsc_bahrain:
  url: 'https://vault.hawk.ncsc.gov.bh'
  token: '<token>'
  namespace: ''
  region: 'me-south-1'
```

---

## Common Operations (KV read/write/list)

```bash
# Status check
source ~/.zshrc && vault eu_prod status
source ~/.zshrc && vault us_prod status

# List secrets
source ~/.zshrc && vault eu_prod list secret/
source ~/.zshrc && vault eu_prod kv-list devo/

# Read secret
source ~/.zshrc && vault eu_prod read secret/path
source ~/.zshrc && vault eu_prod kv-get devo/secret

# Write secret
source ~/.zshrc && vault eu_prod kv-put devo/test key=value

# Token lookup
source ~/.zshrc && vault eu_prod token-lookup

# Raw API
source ~/.zshrc && vault eu_prod raw sys/storage/raft/configuration

# Health check all regions
for env in eu_prod us_prod us3_prod apac_prod ncsc_bahrain; do
  echo "=== $env ==="
  source ~/.zshrc && vault $env status | grep -E "Sealed|HA Mode|Version"
done
```

### Secrets Inventory (Key Paths)

| Path | Contents |
|---|---|
| `AWS/` | AWS service credentials (access keys, secrets) |
| `database/` | MySQL, MongoDB, PostgreSQL, Redis, OrientDB passwords |
| `devo/` | Devo Platform API keys and secrets |
| `grafana/` | Grafana API tokens |
| `dynatrace/` | APM monitoring tokens |
| `slack/` | Webhook URLs |
| `certificates/` | SSL/TLS certificates |
| `pki/` | Certificate authority and signing keys |
| `keys/` | Encryption keys (amnesia, lomana, lookups, webapp) |
| `devoapps/` | Application-specific secrets |
| `gitlab/` | OAuth tokens, API keys |
| `soar/` | SOAR integration credentials |
| `nass/` | Authentication secrets |
| `tapu/`, `mason/`, `malote/` | Data pipeline secrets |

**Estimated total:** ~100-150 secrets across 38+ paths

---

## Kubernetes Access for Vault Operations

```bash
# Switch context and check pods
source ~/.zshrc && kube config use-context prod-eu && kube get pods -n vault -o wide
source ~/.zshrc && kube config use-context prod-us && kube get pods -n vault -o wide
source ~/.zshrc && kube config use-context prod-us3 && kube get pods -n vault -o wide
source ~/.zshrc && kube config use-context prod-apac && kube get pods -n vault -o wide

# NCSC: private EKS endpoints — use AWS Console CloudShell (eu-west-1)
aws eks update-kubeconfig --name prod-ncscbh-eu --region eu-west-1
kubectl get pods -n vault -o wide

# Check Raft cluster health
source ~/.zshrc && vault us_prod raw sys/storage/raft/configuration | jq '.data.config.servers[] | {id, address, leader, voter}'
```

### Troubleshooting

```bash
# Vault sealed — KMS auto-unseal should handle it; check KMS access if stuck
aws kms describe-key --key-id alias/vault-auto-unseal --region us-east-1 --profile production-limited

# Pod crash
source ~/.zshrc && kube config use-context prod-us
source ~/.zshrc && kube logs vault-0 -n vault --tail=100
source ~/.zshrc && kube describe pod vault-0 -n vault

# Re-enable US backup (suspended since Aug 2024)
source ~/.zshrc && kube config use-context prod-us
source ~/.zshrc && kube patch cronjob vault-snapshots -n vault-snapshots -p '{"spec":{"suspend":false}}'
```

---

## OpenBao Production (DevTools Cluster)

**URL:** https://openbao-prod.devo.com  
**AWS Account:** 281139278838 (DevTools/Hydra)  
**EKS Cluster:** `devtools` (eu-west-1)  
**Namespace:** `openbao-prod`  
**Status:** Production since Feb 23, 2026

```bash
# Via vault wrapper (recommended)
source ~/.zshrc && vault openbao_prod status
source ~/.zshrc && vault openbao_prod kv-list devo/
source ~/.zshrc && vault openbao_prod kv-get devo/gitlab

# Direct (credentials from ~/.devo/credentials)
source ~/.devo/credentials
export VAULT_ADDR="$OPENBAO_URL"
export VAULT_TOKEN="$OPENBAO_ROOT_TOKEN"
curl -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/health
```

### Secret Engines & Paths

| Engine | Type | Path | Key Secrets |
|---|---|---|---|
| `devo/` | KV v2 | `devo/gitlab` | `devo_automation`, `rds-password`, `smtp-password` (placeholder) |
| `devo/` | KV v2 | `devo/gitlab-runner/cache` | Managed by terraform (gitlab-s3.tf) |
| `devo/` | KV v2 | `devo/gitlab-dot-com` | `runnerRegistrationToken` |
| `devo/` | KV v2 | `devo/gitlab-dot-com-runner/cache` | `accesskey`, `secretkey`, `bucket_name`, `bucket_region` |
| `DevoTools/` | KV v1 | `DevoTools/argocd` | `clientID`, `clientSecret`, `slack-token`, `argocd_reader_devtools`, `argocd-reader-2025-10-03_helms` (exp 2026-10-08), `cerberus_password` |

### CI Token (Devtools Terraform Pipeline — GitLab project 71295288)

**Policy:** `terraform-ci` (full access to `devo/*`, `DevoTools/*`, `sys/*`, `auth/*`)  
**Expires:** ~2026-06-06 (90d, renewable)  
**Token:** `~/.devo/credentials` → `OPENBAO_CI_TOKEN` | Set as `VAULT_TOKEN` CI/CD variable in GitLab project 71295288

### Known Issue: smtp-password Placeholder

`devo/gitlab` → `smtp-password` is a placeholder. Fix requires `AdministratorAccess` in account 281139278838 (LimitedAdmin has explicit deny). IAM user: `ses-smtp-user`, key `AKIAUC5JU6P3CFC7XA5M`.

---

## Infrastructure Notes

- **Vault version:** 1.16.1 (all clusters)
- **Deployment:** EKS StatefulSet, 3 replicas per cluster, 1 pod per AZ
- **Storage:** Integrated Raft (no Consul/DynamoDB), KMS-encrypted PVCs
- **Auto-unseal:** AWS KMS (pods auto-unseal after restart)
- **US backup:** CronJob in `vault-snapshots` ns → S3 `vault-snapshots-us` — SUSPENDED since Aug 2024
- **EU/US3/APAC/NCSC:** No automated backups configured
- **APAC audit PVCs:** Using unencrypted `gp2` (compliance gap)
- **NCSC:** Private EKS endpoints; access via AWS Console CloudShell only

---

## Related Skills

- `/devo-infra` — Kubernetes EKS contexts, cluster access, kubectl operations
- `/devo-devtool` — DevTools cluster (devtools EKS), GitLab, ArgoCD, Terraform pipelines
- `/devo-tools` — Platform services that consume Vault secrets
