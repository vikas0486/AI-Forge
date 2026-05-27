#!/bin/bash
set -euo pipefail

# Test MISP Lookup Generation
# Manually triggers lookup generation job and monitors progress

NAMESPACE="misp-prod"
JOB_NAME="manual-test-$(date +%s)"

echo "=========================================="
echo "MISP Lookup Generation Test"
echo "=========================================="
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found"
    exit 1
fi

# Create job from cronjob
echo "Creating manual test job: ${JOB_NAME}"
kubectl create job --from=cronjob/misp-lookup-generator "${JOB_NAME}" -n ${NAMESPACE}

# Wait for pod to be created
echo "Waiting for pod to be created..."
sleep 5

# Get pod name
POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l job-name="${JOB_NAME}" --no-headers -o custom-columns=":metadata.name")

if [ -z "${POD_NAME}" ]; then
    echo "❌ Pod not found"
    exit 1
fi

echo "Pod: ${POD_NAME}"
echo ""

# Follow logs
echo "Following logs (Ctrl+C to stop):"
echo "=========================================="
kubectl logs -f "${POD_NAME}" -n ${NAMESPACE}

# Check job status
echo ""
echo "=========================================="
echo "Job Status:"
kubectl get job "${JOB_NAME}" -n ${NAMESPACE}

# Check if successful
if kubectl get job "${JOB_NAME}" -n ${NAMESPACE} -o jsonpath='{.status.succeeded}' | grep -q "1"; then
    echo ""
    echo "✅ Lookup generation completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Verify lookup in Devo:"
    echo "     from lookup.mispIndicator"
    echo "     group"
    echo "     select count() as total_indicators"
    echo ""
    echo "  2. Check lookup update timestamp:"
    echo "     from lookup.mispIndicator"
    echo "     select max(eventdate) as last_update"
else
    echo ""
    echo "❌ Lookup generation failed or still running"
    echo ""
    echo "Debug commands:"
    echo "  kubectl logs ${POD_NAME} -n ${NAMESPACE}"
    echo "  kubectl describe pod ${POD_NAME} -n ${NAMESPACE}"
    echo "  kubectl describe job ${JOB_NAME} -n ${NAMESPACE}"
fi

# Cleanup prompt
echo ""
read -p "Delete test job? (yes/no): " -r
if [[ $REPLY =~ ^[Yy]es$ ]]; then
    kubectl delete job "${JOB_NAME}" -n ${NAMESPACE}
    echo "✅ Job deleted"
fi
