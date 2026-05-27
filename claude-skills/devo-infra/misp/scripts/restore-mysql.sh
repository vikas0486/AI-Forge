#!/bin/bash
set -euo pipefail

# Restore MISP MySQL Database
# Restores database from backup file

NAMESPACE="misp-prod"
BACKUP_DIR="/tmp/misp-backups"
BACKUP_FILE="${1:-}"

if [ -z "${BACKUP_FILE}" ]; then
    echo "Usage: $0 <backup-file>"
    echo ""
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/misp-backup-*.sql.gz 2>/dev/null || echo "  No backups found"
    exit 1
fi

# Check if backup file exists
if [ ! -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    # Try downloading from S3
    S3_BUCKET="${MISP_BACKUP_S3_BUCKET:-s3://devo-misp-backups}"
    echo "Backup not found locally, attempting download from S3..."
    if command -v aws &> /dev/null; then
        aws s3 cp "${S3_BUCKET}/${BACKUP_FILE}" "${BACKUP_DIR}/${BACKUP_FILE}"
    else
        echo "❌ Backup file not found: ${BACKUP_DIR}/${BACKUP_FILE}"
        exit 1
    fi
fi

echo "=========================================="
echo "MISP MySQL Restore"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will REPLACE the current database!"
echo ""
echo "Backup file: ${BACKUP_FILE}"
echo "Namespace: ${NAMESPACE}"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Get MySQL root password
echo ""
echo "Retrieving MySQL credentials..."
MYSQL_ROOT_PASSWORD=$(kubectl get secret misp-mysql-secret -n ${NAMESPACE} -o jsonpath='{.data.root-password}' | base64 -d)

# Stop MISP pods to prevent writes during restore
echo ""
echo "Scaling down MISP deployment..."
kubectl scale deployment misp-server --replicas=0 -n ${NAMESPACE}

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
kubectl wait --for=delete pod -l app=misp-server -n ${NAMESPACE} --timeout=60s || true

# Restore database
echo ""
echo "Restoring database..."
gunzip < "${BACKUP_DIR}/${BACKUP_FILE}" | \
    kubectl exec -i -n ${NAMESPACE} mysql-0 -- bash -c \
    "mysql -u root -p'${MYSQL_ROOT_PASSWORD}' misp"

echo "✅ Database restored"

# Restart MISP pods
echo ""
echo "Scaling up MISP deployment..."
kubectl scale deployment misp-server --replicas=2 -n ${NAMESPACE}

# Wait for pods to be ready
echo "Waiting for MISP pods to be ready..."
kubectl wait --for=condition=ready pod -l app=misp-server -n ${NAMESPACE} --timeout=300s

echo ""
echo "=========================================="
echo "✅ Restore Complete!"
echo "=========================================="
echo ""
echo "MISP server is back online."
echo "Verify functionality:"
echo "  1. Access https://misp.internal.devo.com"
echo "  2. Check events and attributes"
echo "  3. Test lookup generation"
echo ""
