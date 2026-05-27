# Creating Test my.synthesis Tables - Practical Guide

**Purpose:** Test the my.synthesis table creation workflow
**Date:** 2026-03-13
**Author:** Vikash Jaiswal

---

## Table of Contents

1. [Methods Available](#methods-available)
2. [Method 1: Web UI (Recommended for Testing)](#method-1-web-ui-recommended-for-testing)
3. [Method 2: Devo Lookups API](#method-2-devo-lookups-api)
4. [Method 3: Direct RabbitMQ Message (Advanced)](#method-3-direct-rabbitmq-message-advanced)
5. [Verification Steps](#verification-steps)
6. [Cleanup](#cleanup)

---

## Methods Available

There are three ways to create a test my.synthesis table:

| Method | Difficulty | Use Case | Prerequisites |
|--------|------------|----------|---------------|
| **Web UI** | Easy | Quick manual test | Browser access to Devo |
| **Lookups API** | Medium | Automated testing | API credentials |
| **Direct RabbitMQ** | Hard | Deep testing | kubectl access, RabbitMQ CLI |

---

## Method 1: Web UI (Recommended for Testing)

### Step 1: Access Devo Web Interface

**Santander (San region):**
```
URL: https://dataplatform.san.devo.com/
Login: Use your Devo credentials
```

**EU region:**
```
URL: https://eu.devo.com/
Login: Use your Devo credentials
```

### Step 2: Navigate to Active Modeler

```
1. Click on "Data" menu (top navigation)
2. Select "Active Modeler" or "Lookups"
3. Click "Create new lookup" button
```

### Step 3: Create Test my.synthesis Table

**Test Table Configuration:**

```yaml
Table Type: my.synthesis
Domain: self (or your test domain)
Table Name: test_hourly_stats
Description: Test table for workflow validation

Source Query (LINQ):
  from siem.logtrust.malote.free
  where now() - 24h < eventdate < now()
  group every 1h
  select count() as event_count

Key Column: eventdate
Refresh Schedule: Every 1 hour
Mode: Append (or Replace)
```

**Example Source Query Options:**

**Option A: Simple Count (Fast):**
```maqui
from siem.logtrust.malote.free
where now() - 24h < eventdate < now()
group every 1h
select count() as events
```

**Option B: Service Stats (More Realistic):**
```maqui
from siem.logtrust.lomana.free
where now() - 7d < eventdate < now()
where level in ("INFO", "ERROR", "WARN")
group every 1h by level
select count() as count
```

**Option C: Minimal Test:**
```maqui
from siem.logtrust.mason.free
where now() - 1d < eventdate < now()
group every 1h by hostname
select count() as sync_count
```

### Step 4: Submit and Monitor

**After clicking "Create":**

1. **Immediate Response:**
   - Web UI shows: "Table creation in progress..."
   - Status: Processing
   - Expected: Returns within 1-2 seconds

2. **Check Status:**
   - Refresh the page
   - Table should appear in list
   - Status should change to "Active" within 5-10 minutes

3. **Expected Timeline:**
   - **T+0s:** Request accepted (202)
   - **T+5s:** Lomana processes request
   - **T+30s:** Initial data generated
   - **T+1min:** File uploaded to S3
   - **T+5-10min:** Deployed to all datanodes
   - **T+10-15min:** Ready for queries

---

## Method 2: Devo Lookups API

### Prerequisites

**API Access:**
- API Token (from Devo Web UI → Settings → API Tokens)
- Base URL: `https://api.devo.com/` (or region-specific)

### Step 1: Get API Credentials

**Create API Token (if not exists):**
```
1. Login to Devo Web UI
2. Navigate to: Administration → API Tokens
3. Click "Create Token"
4. Name: test-lookup-creation
5. Permissions: Lookup management
6. Copy token (only shown once!)
```

### Step 2: Create Lookup via API

**Endpoint:**
```
POST https://api.devo.com/v1/lookups
```

**Headers:**
```bash
Content-Type: application/json
X-Logtrust-ApiKey: <YOUR_API_KEY>
X-Logtrust-ApiSecret: <YOUR_API_SECRET>
```

**Request Body (JSON):**
```json
{
  "name": "test_hourly_stats",
  "domain": "self",
  "type": "my.synthesis",
  "description": "Test table for workflow validation",
  "query": "from siem.logtrust.malote.free where now() - 24h < eventdate < now() group every 1h select count() as events",
  "keyColumn": "eventdate",
  "refreshInterval": 3600000,
  "mode": "append"
}
```

**Complete curl Example:**

```bash
#!/bin/bash

# Configuration
API_KEY="your_api_key_here"
API_SECRET="your_api_secret_here"
REGION="eu"  # or "us", "apac", "san", etc.
BASE_URL="https://api-${REGION}.devo.com"

# Lookup definition
LOOKUP_NAME="test_hourly_stats_$(date +%s)"
DOMAIN="self"

# Create lookup
curl -X POST "${BASE_URL}/v1/lookups" \
  -H "Content-Type: application/json" \
  -H "X-Logtrust-ApiKey: ${API_KEY}" \
  -H "X-Logtrust-ApiSecret: ${API_SECRET}" \
  -d '{
    "name": "'"${LOOKUP_NAME}"'",
    "domain": "'"${DOMAIN}"'",
    "type": "my.synthesis",
    "description": "Test table created via API",
    "query": "from siem.logtrust.malote.free where now() - 24h < eventdate < now() group every 1h select count() as events",
    "keyColumn": "eventdate",
    "refreshInterval": 3600000,
    "mode": "append"
  }'
```

**Response (Success):**
```json
{
  "status": "success",
  "lookupId": "12345",
  "name": "test_hourly_stats",
  "message": "Lookup creation request accepted"
}
```

**Response (Error):**
```json
{
  "status": "error",
  "code": "LOOKUP_ALREADY_EXISTS",
  "message": "A lookup with this name already exists"
}
```

### Step 3: Check API Status

**Get Lookup Status:**
```bash
curl -X GET "${BASE_URL}/v1/lookups/${LOOKUP_NAME}" \
  -H "X-Logtrust-ApiKey: ${API_KEY}" \
  -H "X-Logtrust-ApiSecret: ${API_SECRET}"
```

**Response:**
```json
{
  "name": "test_hourly_stats",
  "status": "active",
  "lastUpdated": "2026-03-13T10:30:00Z",
  "version": "v1",
  "deployedDatanodes": 5,
  "totalDatanodes": 5
}
```

---

## Method 3: Direct RabbitMQ Message (Advanced)

**⚠️ WARNING:** This method bypasses the Web UI and sends messages directly to RabbitMQ. Use ONLY for deep troubleshooting or testing.

### Prerequisites

- `kubectl` access to the cluster
- RabbitMQ management plugin enabled
- Understanding of RabbitMQ message format

### Step 1: Port-Forward to RabbitMQ

```bash
# Port-forward RabbitMQ management UI
source ~/.zshrc && kube port-forward -n rabbitmq rabbitmq-0 15672:15672 &

# Port-forward AMQP port
source ~/.zshrc && kube port-forward -n rabbitmq rabbitmq-0 5672:5672 &
```

### Step 2: Access RabbitMQ Management UI

```
URL: http://localhost:15672
Username: admin (check kubectl secret)
Password: <from secret>
```

**Get RabbitMQ credentials:**
```bash
source ~/.zshrc && kube get secret -n rabbitmq rabbitmq -o jsonpath='{.data.rabbitmq-password}' | base64 -d
```

### Step 3: Publish Message to Queue

**Using RabbitMQ Management UI:**
```
1. Navigate to: Queues → mq_lomana_requests.lomana
2. Click "Publish message"
3. Paste message (see below)
4. Click "Publish message"
```

**Message Payload (JSON):**
```json
{
  "action": "create_lookup",
  "domain": "self",
  "lookup": "test_hourly_stats_manual",
  "definition": {
    "type": "my.synthesis",
    "query": "from siem.logtrust.malote.free where now() - 24h < eventdate < now() group every 1h select count() as events",
    "keyColumn": "eventdate",
    "refreshMillis": 3600000,
    "mode": "append"
  }
}
```

**Using Python (pika library):**

```python
#!/usr/bin/env python3
import pika
import json

# RabbitMQ connection
connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host='localhost',
        port=5672,
        credentials=pika.PlainCredentials('admin', 'password')
    )
)
channel = connection.channel()

# Message payload
message = {
    "action": "create_lookup",
    "domain": "self",
    "lookup": "test_hourly_stats_python",
    "definition": {
        "type": "my.synthesis",
        "query": "from siem.logtrust.malote.free where now() - 24h < eventdate < now() group every 1h select count() as events",
        "keyColumn": "eventdate",
        "refreshMillis": 3600000,
        "mode": "append"
    }
}

# Publish to queue
channel.basic_publish(
    exchange='',
    routing_key='mq_lomana_requests.lomana',
    body=json.dumps(message),
    properties=pika.BasicProperties(
        delivery_mode=2,  # make message persistent
        content_type='application/json'
    )
)

print(f"Message published: {message['lookup']}")
connection.close()
```

**Using curl to RabbitMQ API:**

```bash
#!/bin/bash

# RabbitMQ credentials
RABBITMQ_USER="admin"
RABBITMQ_PASS="password"
RABBITMQ_HOST="localhost"
RABBITMQ_PORT="15672"
QUEUE="mq_lomana_requests.lomana"
VHOST="%2F"  # URL-encoded "/"

# Message payload
MESSAGE=$(cat <<'EOF'
{
  "action": "create_lookup",
  "domain": "self",
  "lookup": "test_hourly_stats_curl",
  "definition": {
    "type": "my.synthesis",
    "query": "from siem.logtrust.malote.free where now() - 24h < eventdate < now() group every 1h select count() as events",
    "keyColumn": "eventdate",
    "refreshMillis": 3600000,
    "mode": "append"
  }
}
EOF
)

# Publish message
curl -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
  -H "Content-Type: application/json" \
  -X POST \
  "http://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/exchanges/${VHOST}/amq.default/publish" \
  -d '{
    "properties": {
      "delivery_mode": 2,
      "content_type": "application/json"
    },
    "routing_key": "'"${QUEUE}"'",
    "payload": "'"$(echo "$MESSAGE" | base64)"'",
    "payload_encoding": "base64"
  }'
```

---

## Verification Steps

### Step 1: Check Lomana Logs

**Watch Lomana processing:**
```bash
source ~/.zshrc && kube logs -f lomana-0 -n devo-pro-san-core | grep -i "test_hourly_stats"
```

**Expected logs:**
```
INFO - LomanaEventSink - test_hourly_stats - Sending lookup event
INFO - WebEnvelopeSink - test_hourly_stats - lomana.event.web.lookup.exec.sent
INFO - Proxy - Sending Store(...) to jobs.Actor(...)
INFO - LomanaEventSink - Lookup creation event published successfully
```

### Step 2: Check RabbitMQ Queues

**Check message consumption:**
```bash
# Via kubectl
source ~/.zshrc && kube exec -n rabbitmq rabbitmq-0 -- rabbitmqctl list_queues name messages

# Expected: mq_lomana_requests.lomana should have 0 messages (consumed)
```

### Step 3: Check Database Registration

**Query MySQL to verify table registered:**
```sql
-- Connect to logtrust database
mysql -h database-san.devo.com -u admin -p

-- Check if table exists
USE logtrust;
SELECT * FROM casper_concept
WHERE table_name = 'test_hourly_stats'
  AND domain_id = (SELECT id FROM domain WHERE name = 'self')
  AND status = 0;
```

**Expected output:**
```
+----+-----------+--------------------+---------+
| id | domain_id | table_name         | status  |
+----+-----------+--------------------+---------+
| 123| 5         | test_hourly_stats  | 0       |
+----+-----------+--------------------+---------+
```

### Step 4: Check S3 Upload

**Verify file in S3:**
```bash
# Using AWS CLI
aws s3 ls s3://devo-lookups-prod-san/self/ | grep test_hourly_stats

# Expected:
# 2026-03-13 10:30:00   1234567 test_hourly_stats_v1.lookup
```

### Step 5: Check Datanode Deployment

**Query Malote to check deployment:**
```maqui
from system.delegated.internal.lookup
where lookup = "test_hourly_stats"
  and domain = "self"
group by instance(databaseinfo()) as datanode
select datanode, filesize, entries, creation
```

**Expected result:**
- All datanodes should have the lookup
- Same filesize and creation date across all nodes
- entries > 0 (has data)

### Step 6: Query the Table

**Test querying the my.synthesis table:**
```maqui
from my.synthesis.`self`.test_hourly_stats
select *
limit 10
```

**Expected result:**
```
eventdate           | events
--------------------|-------
2026-03-13 09:00:00 | 1523
2026-03-13 10:00:00 | 1789
2026-03-13 11:00:00 | 2043
```

---

## Cleanup

### Method 1: Via Web UI

```
1. Navigate to: Data → Lookups
2. Find: test_hourly_stats
3. Click: ⋮ (menu)
4. Select: "Delete"
5. Confirm deletion
```

### Method 2: Via API

```bash
#!/bin/bash

API_KEY="your_api_key"
API_SECRET="your_api_secret"
REGION="san"
BASE_URL="https://api-${REGION}.devo.com"
LOOKUP_NAME="test_hourly_stats"

# Delete lookup
curl -X DELETE "${BASE_URL}/v1/lookups/${LOOKUP_NAME}" \
  -H "X-Logtrust-ApiKey: ${API_KEY}" \
  -H "X-Logtrust-ApiSecret: ${API_SECRET}"
```

### Method 3: Database Cleanup (Emergency)

**⚠️ Use ONLY if API/UI methods fail:**

```sql
-- Connect to database
mysql -h database-san.devo.com -u admin -p logtrust

-- Mark as deleted (status >= 100)
UPDATE casper_concept
SET status = 100, updated_date = NOW()
WHERE table_name = 'test_hourly_stats'
  AND domain_id = (SELECT id FROM domain WHERE name = 'self');

-- Verify
SELECT * FROM casper_concept
WHERE table_name = 'test_hourly_stats'
  AND domain_id = (SELECT id FROM domain WHERE name = 'self');
```

**Note:** This only marks as deleted in database. Files may still exist on datanodes until cleanup runs.

---

## Monitoring the Full Workflow

**Complete monitoring script:**

```bash
#!/bin/bash

LOOKUP_NAME="test_hourly_stats"
NAMESPACE="devo-pro-san-core"

echo "=== Monitoring my.synthesis Table Creation ==="
echo ""

echo "1. Check RabbitMQ queue:"
source ~/.zshrc && kube exec -n rabbitmq rabbitmq-0 -- rabbitmqctl list_queues name messages | grep lomana
echo ""

echo "2. Watch Lomana logs:"
source ~/.zshrc && kube logs -n ${NAMESPACE} lomana-0 --tail=20 | grep -i "${LOOKUP_NAME}"
echo ""

echo "3. Check RabbitMQ pods:"
source ~/.zshrc && kube get pods -n rabbitmq
echo ""

echo "4. Check Lomana pod:"
source ~/.zshrc && kube get pods -n ${NAMESPACE} | grep lomana
echo ""

echo "5. Check Mason/Lodge:"
source ~/.zshrc && kube get pods -n ${NAMESPACE} | grep mason
echo ""

echo "6. Query table deployment:"
# Run Maqui query via Web UI or API
echo "Run this query in Devo:"
echo "from system.delegated.internal.lookup"
echo "where lookup = \"${LOOKUP_NAME}\""
echo "group by instance(databaseinfo())"
echo ""

echo "=== End of Monitoring ==="
```

---

## Troubleshooting

### Issue: Table Creation Hangs

**Symptoms:** Web UI shows "Processing..." indefinitely

**Check:**
```bash
# 1. RabbitMQ status
source ~/.zshrc && kube get pods -n rabbitmq

# 2. Lomana status
source ~/.zshrc && kube get pods -n devo-pro-san-core | grep lomana

# 3. Lomana logs
source ~/.zshrc && kube logs lomana-0 -n devo-pro-san-core --tail=50 | grep -i "error\|failed"

# 4. RabbitMQ connection
source ~/.zshrc && kube logs lomana-0 -n devo-pro-san-core | grep -i "rabbitmq\|connection"
```

**Solution:** See ISM-14892 resolution if RabbitMQ is down.

### Issue: Table Created But Not Queryable

**Check deployment:**
```maqui
from system.delegated.internal.lookup
where lookup = "test_hourly_stats"
group by instance(databaseinfo())
```

**If missing on some datanodes:**
```bash
# Check Mason-agent logs on affected datanode
ssh datanode-X
journalctl -u mason-agent --since '1 hour ago' | grep test_hourly_stats
```

### Issue: Query Syntax Error

**Common mistakes:**
- Using reserved words (client, timestamp, etc.)
- Invalid LINQ syntax
- Missing backticks in domain name

**Valid query format:**
```maqui
from my.synthesis.`domain_name`.table_name
select *
```

---

## Summary

**Best Method for Testing:**
- **Quick test:** Use Web UI (Method 1)
- **Automated testing:** Use Lookups API (Method 2)
- **Deep troubleshooting:** Use Direct RabbitMQ (Method 3)

**Key Points:**
- Table creation is asynchronous (via RabbitMQ)
- Full deployment takes 5-15 minutes
- Monitor Lomana logs for progress
- Verify deployment on all datanodes before querying

**Related Documents:**
- Complete workflow: `my-synthesis-table-creation-workflow.md`
- RabbitMQ troubleshooting: `rabbitmq-troubleshooting-runbook.md`
- ISM-14892 resolution: `ISM-14892-santander-synthesis-rabbitmq-resolution.md`

---

**Document Version:** 1.0
**Last Updated:** 2026-03-13
**Author:** Vikash Jaiswal
