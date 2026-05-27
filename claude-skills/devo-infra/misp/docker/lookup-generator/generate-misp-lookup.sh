#!/bin/bash
set -euo pipefail

# MISP Lookup Generator Script
# Fetches MISP events and generates mispIndicator lookup for Devo

echo "=========================================="
echo "MISP Lookup Generator v1.0"
echo "Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "=========================================="

# Environment variables (from Kubernetes secrets)
MISP_URL="${MISP_URL:-https://misp.internal.devo.com}"
MISP_API_KEY="${MISP_API_KEY:?Error: MISP_API_KEY not set}"
DEVO_API_KEY="${DEVO_API_KEY:?Error: DEVO_API_KEY not set}"
DEVO_API_SECRET="${DEVO_API_SECRET:?Error: DEVO_API_SECRET not set}"
DEVO_API_URL="${DEVO_API_URL:-https://apiv2-us.devo.com}"
LOOKUP_NAME="${LOOKUP_NAME:-mispIndicator}"
LAST_DAYS="${LAST_DAYS:-30}"  # Download events from last N days

# Temp files
MISP_JSON="/tmp/misp-events-$(date +%s).json"
LOOKUP_CSV="/tmp/mispIndicator-$(date +%s).csv"

# Step 1: Download MISP events
echo ""
echo "[1/4] Downloading MISP events from last ${LAST_DAYS} days..."
python3 /app/create-lookups.py \
    --last "${LAST_DAYS}d" \
    --output "$MISP_JSON"

if [ ! -f "$MISP_JSON" ]; then
    echo "ERROR: Failed to download MISP events"
    exit 1
fi

EVENT_COUNT=$(jq '.response | length' "$MISP_JSON" 2>/dev/null || echo "0")
echo "✓ Downloaded $EVENT_COUNT MISP events"

# Step 2: Convert MISP JSON to CSV lookup
echo ""
echo "[2/4] Converting MISP events to CSV lookup format..."
python3 /app/json2lookups.py "$MISP_JSON"

if [ ! -f "Threat-Malware-by-IP.csv" ]; then
    echo "ERROR: Failed to generate lookup CSV"
    exit 1
fi

# Merge all generated lookups into one mispIndicator lookup
echo "ip,threat,category,type" > "$LOOKUP_CSV"
cat Threat-Malware-by-IP.csv | tail -n +2 >> "$LOOKUP_CSV" 2>/dev/null || true
cat Threat-Fraud-by-IP.csv | tail -n +2 >> "$LOOKUP_CSV" 2>/dev/null || true
cat Threat-Malware-by-Domain.csv | tail -n +2 | awk -F, '{print $1",,"$2",domain"}' >> "$LOOKUP_CSV" 2>/dev/null || true
cat isTorNode.csv | tail -n +2 | awk -F, '{print $1",,tor,"$2}' >> "$LOOKUP_CSV" 2>/dev/null || true

INDICATOR_COUNT=$(wc -l < "$LOOKUP_CSV")
INDICATOR_COUNT=$((INDICATOR_COUNT - 1))  # Subtract header
echo "✓ Generated $INDICATOR_COUNT threat indicators"

# Step 3: Upload to Devo
echo ""
echo "[3/4] Uploading lookup to Devo..."

# Create misp_config.py for Devo upload
cat > /tmp/misp_config.py <<EOF
misp_url = "$MISP_URL"
misp_key = "$MISP_API_KEY"
devo_api_url = "$DEVO_API_URL"
devo_api_key = "$DEVO_API_KEY"
devo_api_secret = "$DEVO_API_SECRET"
EOF

# Upload using Devo SDK (Python script)
python3 <<PYTHON_SCRIPT
import sys
from devo.api import Client
from devo.common import Configuration

# Read CSV
with open("$LOOKUP_CSV", "r") as f:
    csv_data = f.read()

# Configure Devo client
config = Configuration()
config.set("api", {
    "address": "$DEVO_API_URL",
    "credentials": {
        "key": "$DEVO_API_KEY",
        "secret": "$DEVO_API_SECRET"
    }
})

# Upload lookup
client = Client(config=config)
response = client.lookup.upload(
    name="$LOOKUP_NAME",
    data=csv_data,
    description="MISP Threat Intelligence Indicators - Generated $(date -u +"%Y-%m-%d %H:%M:%S UTC")",
    action="full"  # Replace entire lookup
)

print(f"✓ Lookup uploaded successfully")
print(f"  Lookup: $LOOKUP_NAME")
print(f"  Indicators: $INDICATOR_COUNT")
print(f"  Response: {response}")
PYTHON_SCRIPT

# Step 4: Cleanup
echo ""
echo "[4/4] Cleaning up temporary files..."
rm -f "$MISP_JSON" "$LOOKUP_CSV" Threat-*.csv isTorNode.csv /tmp/misp_config.py

echo ""
echo "=========================================="
echo "✓ MISP Lookup Generation Complete"
echo "  Lookup: $LOOKUP_NAME"
echo "  Indicators: $INDICATOR_COUNT"
echo "  Time: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "=========================================="

# Success
exit 0
