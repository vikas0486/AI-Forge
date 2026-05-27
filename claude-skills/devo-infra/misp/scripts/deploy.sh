#!/bin/bash
set -euo pipefail

# MISP Deployment Script
# Deploys complete MISP stack to Kubernetes cluster

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s-manifests"
NAMESPACE="misp-prod"

echo "=========================================="
echo "MISP Kubernetes Deployment"
echo "=========================================="
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Check your kubeconfig."
    exit 1
fi

echo "✅ Connected to cluster: $(kubectl config current-context)"
echo ""

# Confirm deployment
read -p "Deploy MISP to namespace '${NAMESPACE}'? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Step 1: Create namespace
echo ""
echo "[1/9] Creating namespace..."
kubectl apply -f "${K8S_DIR}/namespace.yaml"

# Step 2: Create secrets (must be created manually first)
echo ""
echo "[2/9] Checking secrets..."
if ! kubectl get secret misp-mysql-secret -n ${NAMESPACE} &> /dev/null; then
    echo "❌ Secret 'misp-mysql-secret' not found!"
    echo "   Create secrets first using k8s-manifests/secrets.yaml.template"
    exit 1
fi
if ! kubectl get secret devo-api-secret -n ${NAMESPACE} &> /dev/null; then
    echo "❌ Secret 'devo-api-secret' not found!"
    echo "   Create secrets first using k8s-manifests/secrets.yaml.template"
    exit 1
fi
echo "✅ All secrets exist"

# Step 3: Create ConfigMaps
echo ""
echo "[3/9] Creating ConfigMaps..."
kubectl apply -f "${K8S_DIR}/configmap.yaml"

# Step 4: Create Storage
echo ""
echo "[4/9] Creating Persistent Volume Claims..."
kubectl apply -f "${K8S_DIR}/storage.yaml"

# Wait for PVCs to be bound
echo "Waiting for PVCs to be bound..."
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/mysql-data-pvc -n ${NAMESPACE} --timeout=120s
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/redis-data-pvc -n ${NAMESPACE} --timeout=120s
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/misp-files-pvc -n ${NAMESPACE} --timeout=120s
echo "✅ All PVCs bound"

# Step 5: Deploy MySQL
echo ""
echo "[5/9] Deploying MySQL StatefulSet..."
kubectl apply -f "${K8S_DIR}/mysql-statefulset.yaml"

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready (may take 3-5 minutes)..."
kubectl wait --for=condition=ready pod/mysql-0 -n ${NAMESPACE} --timeout=300s
echo "✅ MySQL is ready"

# Step 6: Deploy Redis
echo ""
echo "[6/9] Deploying Redis StatefulSet..."
kubectl apply -f "${K8S_DIR}/redis-statefulset.yaml"

# Wait for Redis to be ready
echo "Waiting for Redis to be ready..."
kubectl wait --for=condition=ready pod/redis-0 -n ${NAMESPACE} --timeout=180s
echo "✅ Redis is ready"

# Step 7: Deploy MISP Server
echo ""
echo "[7/9] Deploying MISP Server..."
kubectl apply -f "${K8S_DIR}/misp-deployment.yaml"

# Wait for MISP to be ready (may take 5-10 minutes on first start)
echo "Waiting for MISP server to be ready (may take 5-10 minutes on first start)..."
kubectl wait --for=condition=ready pod -l app=misp-server -n ${NAMESPACE} --timeout=600s
echo "✅ MISP server is ready"

# Step 8: Create Services and Ingress
echo ""
echo "[8/9] Creating Services and Ingress..."
kubectl apply -f "${K8S_DIR}/services.yaml"
kubectl apply -f "${K8S_DIR}/ingress.yaml"

# Step 9: Deploy Lookup Generator CronJob
echo ""
echo "[9/9] Deploying Lookup Generator CronJob..."
kubectl apply -f "${K8S_DIR}/lookup-cronjob.yaml"

# Deploy monitoring (optional)
if [ -d "${K8S_DIR}/monitoring" ]; then
    echo ""
    echo "[OPTIONAL] Deploying monitoring stack..."
    kubectl apply -f "${K8S_DIR}/monitoring/"
fi

# Summary
echo ""
echo "=========================================="
echo "✅ MISP Deployment Complete!"
echo "=========================================="
echo ""
echo "MISP Server:"
echo "  - Pods: $(kubectl get pods -n ${NAMESPACE} -l app=misp-server --no-headers | wc -l) running"
echo "  - Service: misp-server (LoadBalancer)"
echo "  - URL: https://misp.internal.devo.com"
echo ""
echo "MySQL:"
echo "  - Pod: mysql-0"
echo "  - Service: mysql-service"
echo "  - Storage: 100Gi"
echo ""
echo "Redis:"
echo "  - Pod: redis-0"
echo "  - Service: redis-service"
echo "  - Storage: 20Gi"
echo ""
echo "Lookup Generator:"
echo "  - CronJob: misp-lookup-generator"
echo "  - Schedule: Daily at 00:00 UTC"
echo ""
echo "Next Steps:"
echo "  1. Get LoadBalancer IP: kubectl get svc misp-server -n ${NAMESPACE}"
echo "  2. Update DNS: misp.internal.devo.com → LoadBalancer IP"
echo "  3. Access MISP: https://misp.internal.devo.com"
echo "  4. Login with admin credentials (from misp-admin-secret)"
echo "  5. Configure MISP feeds and API keys"
echo "  6. Test lookup generation:"
echo "     kubectl create job --from=cronjob/misp-lookup-generator manual-test-\$(date +%s) -n ${NAMESPACE}"
echo ""
echo "View logs:"
echo "  kubectl logs -f deployment/misp-server -n ${NAMESPACE}"
echo "  kubectl logs -f statefulset/mysql -n ${NAMESPACE}"
echo "  kubectl logs -f statefulset/redis -n ${NAMESPACE}"
echo ""
