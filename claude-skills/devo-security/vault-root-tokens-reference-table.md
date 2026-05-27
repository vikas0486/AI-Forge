# Vault Root Tokens - Quick Reference Table

**Last Updated:** May 6, 2026

## Complete Token Locations

| Vault Environment | Vault URL | Vault Region | AWS Secret Name | AWS Secret Region | AWS Console Link |
|-------------------|-----------|--------------|-----------------|-------------------|------------------|
| **US Production** | vault-us.devo.com | us-east-1 | `vault-us-token` | us-east-1 | [Open](https://us-east-1.console.aws.amazon.com/secretsmanager/secret?name=vault-us-token&region=us-east-1) |
| **US3 Production** | vault-us3.devo.com | us-east-2 | `devo-vault-init-token-pro-us3` | us-east-2 | [Open](https://us-east-2.console.aws.amazon.com/secretsmanager/secret?name=devo-vault-init-token-pro-us3&region=us-east-2) |
| **EU Production** | vault-eu.devo.com | eu-west-1 | `devo-vault-init-token` | eu-west-1 | [Open](https://eu-west-1.console.aws.amazon.com/secretsmanager/secret?name=devo-vault-init-token&region=eu-west-1) |
| **APAC Production** | vault-apac.devo.com | ap-southeast-1 | `devo-vault-init-token-prod-apac` | ap-southeast-1 | [Open](https://ap-southeast-1.console.aws.amazon.com/secretsmanager/secret?name=devo-vault-init-token-prod-apac&region=ap-southeast-1) |
| **NCSC Bahrain** | vault.hawk.ncsc.gov.bh | me-south-1 | `prod-ncscbh-eu-vault-init-definite-hare` | eu-west-1 ⚠️ | [Open](https://eu-west-1.console.aws.amazon.com/secretsmanager/secret?name=prod-ncscbh-eu-vault-init-definite-hare&region=eu-west-1) |
| **DevTools (OpenBao)** | openbao-prod.devo.com | eu-west-1 | `openbao_root_token` | eu-west-1 | Account 281139278838 |

⚠️ **Note:** NCSC Bahrain vault runs in `me-south-1` but root token stored in `eu-west-1` (cross-region secret management).

⚠️ **DevTools Note:** `vault.devotools.com` is **decommissioned** (dead). Replaced by OpenBao at `openbao-prod.devo.com`. The `vault-init-token-devotools` secret is the old dead token — use `openbao_root_token` instead. AWS profile `devotools-limited` lacks secretsmanager access; retrieve from AWS Console.

## AWS CLI Quick Commands

### Retrieve Individual Tokens

```bash
# US Production
aws secretsmanager get-secret-value \
  --secret-id vault-us-token \
  --region us-east-1 --query SecretString --output text

# US3 Production
aws secretsmanager get-secret-value \
  --secret-id devo-vault-init-token-pro-us3 \
  --region us-east-2 --query SecretString --output text

# EU Production
aws secretsmanager get-secret-value \
  --secret-id devo-vault-init-token \
  --region eu-west-1 --query SecretString --output text

# APAC Production
aws secretsmanager get-secret-value \
  --secret-id devo-vault-init-token-prod-apac \
  --region ap-southeast-1 --query SecretString --output text

# NCSC Bahrain
aws secretsmanager get-secret-value \
  --secret-id prod-ncscbh-eu-vault-init-definite-hare \
  --region eu-west-1 --query SecretString --output text
```

### One-Liner for Each Environment

```bash
# Set environment variable with token
export VAULT_TOKEN_US=$(aws secretsmanager get-secret-value --secret-id vault-us-token --region us-east-1 --query SecretString --output text)

export VAULT_TOKEN_US3=$(aws secretsmanager get-secret-value --secret-id devo-vault-init-token-pro-us3 --region us-east-2 --query SecretString --output text)

export VAULT_TOKEN_EU=$(aws secretsmanager get-secret-value --secret-id devo-vault-init-token --region eu-west-1 --query SecretString --output text)

export VAULT_TOKEN_APAC=$(aws secretsmanager get-secret-value --secret-id devo-vault-init-token-prod-apac --region ap-southeast-1 --query SecretString --output text)

export VAULT_TOKEN_NCSC=$(aws secretsmanager get-secret-value --secret-id prod-ncscbh-eu-vault-init-definite-hare --region eu-west-1 --query SecretString --output text)
```

## Update Local Vault Credentials

### Manual Update

```bash
vim ~/.devo/credentials

# Update each environment's token field:
us_prod:
  token: '<token from vault-us-token>'

us3_prod:
  token: '<token from devo-vault-init-token-pro-us3>'

eu_prod:
  token: '<token from devo-vault-init-token>'

apac_prod:
  token: '<token from devo-vault-init-token-prod-apac>'

ncsc_bahrain:
  token: '<token from prod-ncscbh-eu-vault-init-definite-hare>'
```

### Automated Update Script

```bash
#!/bin/bash
# update-vault-tokens.sh - Retrieve all tokens from AWS Secrets Manager

CREDS_FILE="$HOME/.vault-credentials.yaml"
BACKUP_FILE="$HOME/.vault-credentials.yaml.backup.$(date +%Y%m%d_%H%M%S)"

# Backup existing file
cp "$CREDS_FILE" "$BACKUP_FILE"
echo "Backed up to: $BACKUP_FILE"

# Retrieve tokens
US_TOKEN=$(aws secretsmanager get-secret-value --secret-id vault-us-token --region us-east-1 --query SecretString --output text 2>/dev/null)
US3_TOKEN=$(aws secretsmanager get-secret-value --secret-id devo-vault-init-token-pro-us3 --region us-east-2 --query SecretString --output text 2>/dev/null)
EU_TOKEN=$(aws secretsmanager get-secret-value --secret-id devo-vault-init-token --region eu-west-1 --query SecretString --output text 2>/dev/null)
APAC_TOKEN=$(aws secretsmanager get-secret-value --secret-id devo-vault-init-token-prod-apac --region ap-southeast-1 --query SecretString --output text 2>/dev/null)
NCSC_TOKEN=$(aws secretsmanager get-secret-value --secret-id prod-ncscbh-eu-vault-init-definite-hare --region eu-west-1 --query SecretString --output text 2>/dev/null)

# Update credentials file (using yq or sed)
if command -v yq &> /dev/null; then
  yq eval ".us_prod.token = \"$US_TOKEN\"" -i "$CREDS_FILE"
  yq eval ".us3_prod.token = \"$US3_TOKEN\"" -i "$CREDS_FILE"
  yq eval ".eu_prod.token = \"$EU_TOKEN\"" -i "$CREDS_FILE"
  yq eval ".apac_prod.token = \"$APAC_TOKEN\"" -i "$CREDS_FILE"
  yq eval ".ncsc_bahrain.token = \"$NCSC_TOKEN\"" -i "$CREDS_FILE"
  echo "✓ Updated all tokens using yq"
else
  # Fallback: manual sed replacements
  echo "⚠️  yq not found. Manual update recommended."
  echo "US Token: $US_TOKEN"
  echo "US3 Token: $US3_TOKEN"
  echo "EU Token: $EU_TOKEN"
  echo "APAC Token: $APAC_TOKEN"
  echo "NCSC Token: $NCSC_TOKEN"
fi

# Verify permissions
chmod 600 "$CREDS_FILE"
echo "✓ Set secure permissions on $CREDS_FILE"
```

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:*:secret:vault-us-token-*",
        "arn:aws:secretsmanager:us-east-2:*:secret:devo-vault-init-token-pro-us3-*",
        "arn:aws:secretsmanager:eu-west-1:*:secret:devo-vault-init-token-*",
        "arn:aws:secretsmanager:eu-west-1:*:secret:prod-ncscbh-eu-vault-init-definite-hare-*",
        "arn:aws:secretsmanager:ap-southeast-1:*:secret:devo-vault-init-token-prod-apac-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": [
            "secretsmanager.us-east-1.amazonaws.com",
            "secretsmanager.us-east-2.amazonaws.com",
            "secretsmanager.eu-west-1.amazonaws.com",
            "secretsmanager.ap-southeast-1.amazonaws.com"
          ]
        }
      }
    }
  ]
}
```

## Secret Naming Analysis

| Environment | Secret Name Pattern | Notes |
|-------------|---------------------|-------|
| **US** | `vault-us-token` | Simple naming (oldest deployment?) |
| **US3** | `devo-vault-init-token-pro-us3` | Standard pattern with environment |
| **EU** | `devo-vault-init-token` | Generic name (shared/primary?) |
| **APAC** | `devo-vault-init-token-prod-apac` | Standard pattern with region |
| **NCSC** | `prod-ncscbh-eu-vault-init-definite-hare` | Complex name with random suffix |

**Observation:** Inconsistent naming suggests secrets created at different times or by different automation. Recommendation: Standardize naming for future deployments.

## Verification Checklist

After retrieving tokens:

- [ ] Verify all 5 tokens retrieved successfully
- [ ] Update `~/.devo/credentials` with new tokens
- [ ] Test vault access: `~/Documents/Scripts/vault-wrapper.sh us_prod login`
- [ ] Verify permissions: `ls -la ~/.devo/credentials` (should be 600)
- [ ] Backup credentials file
- [ ] Document token retrieval date in change log
- [ ] Set calendar reminder for next rotation (90 days)

## Troubleshooting

### Issue: Access Denied

```bash
# Check your AWS credentials
aws sts get-caller-identity

# Check IAM permissions
aws iam get-user-policy --user-name $(aws sts get-caller-identity --query Arn --output text | cut -d'/' -f2) --policy-name VaultSecretsAccess
```

### Issue: Secret Not Found

```bash
# List all secrets (verify exact name)
aws secretsmanager list-secrets --region us-east-1 | grep -i vault

# Check secret exists
aws secretsmanager describe-secret --secret-id vault-us-token --region us-east-1
```

### Issue: KMS Decryption Failed

```bash
# Check KMS key access
aws kms list-grants --key-id alias/aws/secretsmanager --region us-east-1

# Verify KMS permissions
aws kms describe-key --key-id alias/aws/secretsmanager --region us-east-1
```

## Security Notes

1. **Cross-Region Secret Storage:** NCSC Bahrain vault runs in `me-south-1` but secret stored in `eu-west-1`. This is intentional for centralized secret management.

2. **Token Rotation:** All tokens should be rotated every 90 days. Set up automated rotation via AWS Lambda.

3. **Access Logging:** All `GetSecretValue` operations logged in CloudTrail. Enable alerts for suspicious access patterns.

4. **Backup:** Secrets Manager maintains automatic version history. Previous tokens accessible via version ID.

---

**Created:** 2026-05-01  
**All Secrets Confirmed:** ✅ 5/5  
**IAM Policy:** Included above  
**Next Review:** 2026-08-01 (90 days)
