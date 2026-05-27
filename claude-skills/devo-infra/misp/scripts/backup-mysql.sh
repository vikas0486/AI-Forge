#!/bin/bash
set -euo pipefail

# Backup MISP MySQL Database
# Creates mysqldump backup and uploads to S3

NAMESPACE="misp-prod"
BACKUP_DIR="/tmp/misp-backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="misp-backup-${TIMESTAMP}.sql.gz"
S3_BUCKET="${MISP_BACKUP_S3_BUCKET:-s3://devo-misp-backups}"

echo "=========================================="
echo "MISP MySQL Backup"
echo "=========================================="
echo ""

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Get MySQL root password from secret
echo "Retrieving MySQL credentials..."
MYSQL_ROOT_PASSWORD=$(kubectl get secret misp-mysql-secret -n ${NAMESPACE} -o jsonpath='{.data.root-password}' | base64 -d)

# Run mysqldump
echo "Creating database backup..."
kubectl exec -n ${NAMESPACE} mysql-0 -- bash -c \
    "mysqldump -u root -p'${MYSQL_ROOT_PASSWORD}' --single-transaction --quick --lock-tables=false misp" \
    | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

# Check backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
echo "✅ Backup created: ${BACKUP_FILE} (${BACKUP_SIZE})"

# Upload to S3 (if aws cli available)
if command -v aws &> /dev/null; then
    echo ""
    echo "Uploading to S3: ${S3_BUCKET}/${BACKUP_FILE}"
    aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" "${S3_BUCKET}/${BACKUP_FILE}"
    echo "✅ Backup uploaded to S3"
else
    echo ""
    echo "⚠️  AWS CLI not found - backup saved locally only"
fi

# Cleanup old local backups (keep last 3)
echo ""
echo "Cleaning up old local backups..."
cd "${BACKUP_DIR}"
ls -t misp-backup-*.sql.gz | tail -n +4 | xargs -r rm
echo "✅ Cleanup complete"

echo ""
echo "=========================================="
echo "Backup Summary:"
echo "  File: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "  Size: ${BACKUP_SIZE}"
echo "  S3: ${S3_BUCKET}/${BACKUP_FILE}"
echo "=========================================="
echo ""
echo "To restore this backup:"
echo "  ./restore-mysql.sh ${BACKUP_FILE}"
echo ""
