# my.synthesis Table Creation - Complete Workflow & Architecture

**Complete Knowledge Transfer Document**
**Date:** 2026-03-13
**Author:** Vikash Jaiswal
**Sources:** ISM-14892, Confluence KB, Lomana Documentation

---

## Table of Contents
1. [Overview](#overview)
2. [Architecture Components](#architecture-components)
3. [Complete Workflow](#complete-workflow)
4. [RabbitMQ Role & Queues](#rabbitmq-role--queues)
5. [Mason & Metadata Distribution](#mason--metadata-distribution)
6. [Troubleshooting](#troubleshooting)

---

## Overview

### What is my.synthesis?

**my.synthesis** is a custom table type in Devo that allows customers to create **aggregated/summarized tables** from existing data using LINQ queries. Think of it as a "materialized view" that runs periodically to aggregate data.

**Purpose:**
- Create pre-aggregated data for faster queries
- Build summary tables for dashboards
- Combine data from multiple sources
- Reduce query time on large datasets

**Example Use Case:**
```
Customer wants a table that shows hourly login statistics:
- Source: my.app.authentication.logs (raw login events)
- my.synthesis: my.synthesis.hourly_login_stats
- Query: Count logins per hour, by user type, by region
- Refresh: Every 1 hour
- Result: Fast dashboard queries on pre-computed stats
```

---

## Architecture Components

### 1. Webapp (Table Creation UI)

**Service:** webapp pods (2 replicas in devo-pro-san-core namespace)
**Purpose:** User interface for table creation
**Technology:** Web application (Java/Spring)

**Responsibilities:**
- Provide web UI for my.synthesis table definition
- Validate table name, query syntax
- Submit table creation requests to RabbitMQ
- Display table creation status to user

**User Actions:**
1. Customer logs into https://dataplatform.san.devo.com/
2. Navigates to "Active Modeler" or "Tables" section
3. Selects "Create my.synthesis table"
4. Defines:
   - Table name (e.g., `hourly_login_stats`)
   - Source query (LINQ query to aggregate data)
   - Refresh schedule (e.g., every 1 hour)
   - Key column (for deduplication)
5. Clicks "Create" button

---

### 2. RabbitMQ (Message Broker)

**Service:** rabbitmq pods (3 replicas in rabbitmq namespace)
**Purpose:** Asynchronous message queue for decoupling webapp from processing
**Technology:** RabbitMQ cluster with Raft storage
**DNS:** `rabbitmq.rabbitmq:5672`

**Why RabbitMQ is Needed:**

**Without RabbitMQ (Synchronous):**
```
User → Webapp → Lomana (direct call) → Wait 30s → Response
Problem: User waits, webapp blocks, no scalability
```

**With RabbitMQ (Asynchronous):**
```
User → Webapp → RabbitMQ (immediate) → Return "Request accepted"
                    ↓
                Lomana (processes in background)
                    ↓
                User gets notification when done
```

**Benefits:**
- **Decoupling:** Webapp doesn't wait for Lomana
- **Reliability:** Messages persist if Lomana is down
- **Scalability:** Multiple Lomana workers can process queue
- **Retry Logic:** Failed requests can be retried
- **Backpressure:** Queue prevents Lomana overload

---

### 3. RabbitMQ Queues & Exchanges

**Queue 1: Requests (from Webapp to Lomana)**
- **Name:** `mq_lomana_requests.lomana`
- **Purpose:** Webapp publishes table creation requests here
- **Buffer:** 1000 messages
- **Consumer:** Lomana service

**Exchange: Responses (from Lomana to Webapp)**
- **Name:** `mq_exchange_lomana_responses`
- **Routing Key:** `#` (all messages)
- **Purpose:** Lomana publishes processing results here
- **Consumer:** Webapp (to update UI status)

**Queue 2: Notifications (Mason/Lodge coordination)**
- **Name:** `mq_mason_lodge_notifications.lomana`
- **Purpose:** Mason/Lodge notify Lomana about metadata changes
- **Buffer:** 1000 messages
- **Use Case:** Trigger lookup updates when files change

**Message Flow:**
```
1. Webapp → mq_lomana_requests.lomana
   Message: { "action": "create", "tableName": "hourly_login_stats", "query": "...", "schedule": "1h" }

2. Lomana consumes request → Processes

3. Lomana → mq_exchange_lomana_responses
   Message: { "status": "success", "tableName": "hourly_login_stats", "message": "Table created" }

4. Webapp consumes response → Updates UI
```

---

### 4. Lomana (Lookup Manager)

**Service:** lomana-0 pod (StatefulSet in devo-pro-san-core namespace)
**Purpose:** Manages the ENTIRE lifecycle of lookups and my.synthesis tables
**Technology:** Scala/Akka service

**Full Name:** **LO**okup **MA**nager **NA**me (Lo-Ma-Na)

**Core Responsibilities:**

#### A. Table Creation
1. **Receives request** from RabbitMQ (`mq_lomana_requests.lomana`)
2. **Validates** table definition:
   - Table name unique?
   - Query syntax valid?
   - Refresh schedule reasonable?
3. **Registers** table in MySQL database (`logtrust.casper_concept`)
4. **Generates** table metadata file (`.mata` file)
5. **Creates initial data** by executing the source query
6. **Stores data** in S3 bucket (devo-lookups-prod-san)

#### B. Periodic Refresh
1. **Scheduler** triggers refresh based on table's schedule
2. **Executes source query** against Malote (query engine)
3. **Generates updated table data**
4. **Stores new version** in S3
5. **Notifies Mason** to distribute new version

#### C. Deployment to Datanodes
1. **Coordinates with Mason/Lodge** to deploy table files
2. **Ensures all datanodes** have the latest version
3. **Tracks deployment status** across cluster

#### D. Lifecycle Management
- **Update:** Modify table definition or query
- **Delete:** Remove table and clean up files
- **Enable/Disable:** Pause/resume table refresh
- **Version Control:** Track table versions over time

**Lomana Logs (Success):**
```
18:01:19.690 - lomana-0 - INFO - LomanaEventSink - pre_scib_process_monitoring.dynamic_loookup_ssmm - Sending lookup event
18:01:19.691 - lomana-0 - INFO - WebEnvelopeSink - pre_scib_process_monitoring.dynamic_loookup_ssmm - lomana.event.web.lookup.exec.sent
18:01:19.691 - lomana-0 - INFO - Proxy - Sending Store(...) to jobs.Actor(...)
18:01:19.757 - lomana-0 - INFO - LomanaEventSink - Lookup creation event published successfully
```

---

### 5. Mason-Agent & Lodge (Metadata Distribution)

**Mason-Agent:** Runs on each datanode
**Lodge:** Master service (coordinates Mason agents)
**Purpose:** Distribute metadata files (lookups, mafias, metas) to datanodes

**Relationship to my.synthesis:**
- my.synthesis tables are stored as **lookup files** on datanodes
- Mason-agent ensures all datanodes have the same version
- Lodge maintains the "desired state" of what files should exist

**Distribution Flow:**
```
1. Lomana creates lookup file → Uploads to S3
2. Lomana notifies Lodge: "New lookup available at s3://bucket/path"
3. Lodge updates desired state: "All datanodes should have this file"
4. Mason agents (on datanodes) poll Lodge periodically
5. Mason agents: "What files should I have?"
6. Lodge: "Here's the list, download from S3 if missing/outdated"
7. Mason agents download from S3 → Save to local disk (/var/logt/...)
8. Malote (query engine) can now use the lookup file
```

**Key Points:**
- Mason-agent does NOT create files (Lomana does)
- Mason-agent does NOT decide what to deploy (Lodge does)
- Mason-agent ONLY downloads and syncs files
- Replaced older rsync-based distribution

---

### 6. Malote (Query Engine)

**Service:** malote pods (runs on datanodes)
**Purpose:** Execute queries against stored data
**Technology:** Distributed query engine

**Role in my.synthesis:**
1. **Execution Engine:** Runs the source query to generate my.synthesis data
2. **Consumer:** Uses my.synthesis tables in customer queries
3. **Local Access:** Reads lookup files from local disk (synced by Mason)

**Query Execution:**
```
Customer runs:
  select * from my.synthesis.hourly_login_stats

Malote:
1. Finds lookup file: /var/logt/lookups/domain/hourly_login_stats.lookup
2. Reads data from file
3. Returns results to customer
```

---

### 7. S3 Bucket (File Storage)

**Bucket:** `devo-lookups-prod-san`
**Purpose:** Central storage for lookup/my.synthesis files

**Structure:**
```
s3://devo-lookups-prod-san/
├── domain1/
│   ├── hourly_login_stats_v1.lookup
│   ├── hourly_login_stats_v2.lookup
│   └── daily_summary_v1.lookup
├── domain2/
│   └── custom_table_v1.lookup
```

**Workflow:**
1. Lomana generates file → Uploads to S3
2. Lodge references S3 path in metadata
3. Mason-agents download from S3 to datanodes
4. Malote reads from local disk (not S3)

---

### 8. MySQL Database (Metadata Registry)

**Database:** `logtrust`
**Table:** `casper_concept`
**Purpose:** Track all my.synthesis tables and their metadata

**Schema (simplified):**
```sql
CREATE TABLE casper_concept (
  id INT PRIMARY KEY,
  domain_id INT,
  table_name VARCHAR(255),
  query_definition TEXT,
  refresh_schedule VARCHAR(50),
  status INT,  -- 0=active, 100+=deleted/error
  created_date TIMESTAMP,
  updated_date TIMESTAMP
);
```

**Queries:**
```sql
-- Check if table exists
SELECT * FROM casper_concept
WHERE table_name = 'hourly_login_stats'
  AND domain_id = (SELECT id FROM domain WHERE name = 'customer_domain')
  AND status < 100;

-- List all my.synthesis tables for a domain
SELECT table_name, refresh_schedule, status
FROM casper_concept
WHERE domain_id = (SELECT id FROM domain WHERE name = 'customer_domain')
  AND status = 0;
```

**Common Issues:**
- **Stuck record (status >= 100):** Old deleted table blocking new creation
- **Solution:** Delete the stuck record to allow re-creation

---

## Complete Workflow

### End-to-End Flow: Creating my.synthesis Table

```
┌──────────────────────────────────────────────────────────────────────┐
│                    CUSTOMER (Web Browser)                             │
│  Action: Define my.synthesis table in Active Modeler                 │
│  - Table name: hourly_login_stats                                    │
│  - Source query: from my.app.auth group every 1h by user_type        │
│  - Refresh schedule: Every 1 hour                                    │
│  - Click "Create"                                                    │
└──────────────────────────┬───────────────────────────────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │         1. WEBAPP (UI)              │
         │  Namespace: devo-pro-san-core       │
         │  Service: webapp (2 replicas)       │
         └─────────────────┬───────────────────┘
                           │
                           │ [HTTP POST /api/tables/create]
                           ▼
         ┌─────────────────────────────────────┐
         │  1a. Validate Table Definition      │
         │  - Check table name format           │
         │  - Validate LINQ query syntax        │
         │  - Check if table already exists     │
         └─────────────────┬───────────────────┘
                           │
                           │ [IF VALID]
                           ▼
         ┌─────────────────────────────────────┐
         │  1b. Build RabbitMQ Message         │
         │  {                                   │
         │    "action": "create_lookup",        │
         │    "domain": "customer_domain",      │
         │    "tableName": "hourly_login_stats",│
         │    "sourceQuery": "from my.app...",  │
         │    "refreshMillis": 3600000,         │
         │    "keyColumn": "user_type",         │
         │    "append": true                    │
         │  }                                   │
         └─────────────────┬───────────────────┘
                           │
                           │ [AMQP Protocol]
                           │ [URI: amqp://rabbitmq.rabbitmq:5672]
                           ▼
         ┌─────────────────────────────────────┐
         │     2. RABBITMQ (Message Broker)    │
         │  Namespace: rabbitmq                 │
         │  Service: rabbitmq (3-node cluster)  │
         │  Queue: mq_lomana_requests.lomana    │
         │  Buffer: 1000 messages               │
         └─────────────────┬───────────────────┘
                           │
                           │ [Message Persisted]
                           │ [Webapp returns 202 Accepted]
                           │
         ┌─────────────────┴───────────────────┐
         │  2a. Webapp Response to Customer     │
         │  HTTP 202 Accepted                   │
         │  {                                    │
         │    "status": "processing",           │
         │    "message": "Table creation        │
         │                 request accepted"     │
         │  }                                    │
         └─────────────────┬───────────────────┘
                           │
                           │ [Customer sees: "Table creation in progress..."]
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │     3. LOMANA (Lookup Manager)      │
         │  Namespace: devo-pro-san-core       │
         │  Service: lomana-0 (StatefulSet)    │
         │  Consumer: Reads from RabbitMQ      │
         └─────────────────┬───────────────────┘
                           │
                           │ [Consume message from queue]
                           ▼
         ┌─────────────────────────────────────┐
         │  3a. Process Table Creation         │
         │  Step 1: Register in MySQL DB       │
         │    INSERT INTO casper_concept       │
         │    (domain_id, table_name, query,   │
         │     refresh_schedule, status)        │
         │    VALUES (..., 0);                  │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  3b. Generate Metadata File         │
         │  Create: hourly_login_stats.mata    │
         │  Contains:                           │
         │    - Table structure                 │
         │    - Column definitions              │
         │    - Refresh rules                   │
         │    - Query definition                │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  3c. Execute Initial Data Query     │
         │  Connect to: Malote (query engine)  │
         │  Run: Source query to generate data │
         │  Example:                            │
         │    from my.app.authentication.logs   │
         │    where eventdate > now() - 24h     │
         │    group every 1h by user_type       │
         │    select count() as login_count     │
         └─────────────────┬───────────────────┘
                           │
                           │ [Query results returned]
                           ▼
         ┌─────────────────────────────────────┐
         │  3d. Generate Lookup File           │
         │  Create binary .lookup file:         │
         │    hourly_login_stats_v1.lookup     │
         │  Contains:                           │
         │    - Aggregated data                 │
         │    - Indexes for fast lookups        │
         │    - Compression for efficiency      │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  3e. Upload to S3                   │
         │  Bucket: devo-lookups-prod-san      │
         │  Path: /customer_domain/             │
         │         hourly_login_stats_v1.lookup│
         │  ACL: Private (only Devo services)  │
         └─────────────────┬───────────────────┘
                           │
                           │ [S3 upload complete]
                           ▼
         ┌─────────────────────────────────────┐
         │  3f. Notify Mason/Lodge             │
         │  Message to RabbitMQ:                │
         │  Queue: mq_mason_lodge_notifications │
         │  Content:                            │
         │  {                                   │
         │    "event": "lookup-created",        │
         │    "domain": "customer_domain",      │
         │    "lookup": "hourly_login_stats",   │
         │    "s3Path": "s3://bucket/...",      │
         │    "version": "v1"                   │
         │  }                                   │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │   4. LODGE (Distribution Coordinator)│
         │  Namespace: devo-pro-san-core       │
         │  Service: mason-mason-lodge-0       │
         │  Role: Maintains desired state      │
         └─────────────────┬───────────────────┘
                           │
                           │ [Consume notification]
                           ▼
         ┌─────────────────────────────────────┐
         │  4a. Update Desired State           │
         │  Registry:                           │
         │  {                                   │
         │    "file": "hourly_login_stats",    │
         │    "s3Path": "s3://...",             │
         │    "version": "v1",                  │
         │    "targetDatanodes": [all]          │
         │  }                                   │
         └─────────────────┬───────────────────┘
                           │
                           │ [Lodge now knows this file should be on ALL datanodes]
                           │
         ┌─────────────────┴───────────────────┐
         │  4b. Mason-Agents Poll Lodge        │
         │  Every datanode has a mason-agent    │
         │  that periodically asks:             │
         │  "What files should I have?"         │
         │                                      │
         │  Polling Frequency: Every 5-10 min   │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │   5. MASON-AGENT (on each Datanode) │
         │  Service: mason-agent.service       │
         │  Runs on: All datanodes              │
         │  (datanode-1, datanode-2, ...)       │
         └─────────────────┬───────────────────┘
                           │
                           │ [HTTP GET to Lodge API]
                           │ [Query: "What files for my datanode?"]
                           ▼
         ┌─────────────────────────────────────┐
         │  5a. Lodge Responds with File List  │
         │  Response:                           │
         │  {                                   │
         │    "files": [                        │
         │      {                               │
         │        "name": "hourly_login_stats", │
         │        "s3Path": "s3://...",         │
         │        "version": "v1",              │
         │        "localPath": "/var/logt/..."  │
         │      }                               │
         │    ]                                 │
         │  }                                   │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  5b. Mason-Agent Checks Local Disk  │
         │  Check: Does file exist locally?     │
         │  Path: /var/logt/lookups/customer/   │
         │        hourly_login_stats.lookup     │
         │                                      │
         │  IF NOT EXISTS or VERSION MISMATCH:  │
         │    → Download from S3                │
         │  ELSE:                               │
         │    → Skip (already have it)          │
         └─────────────────┬───────────────────┘
                           │
                           │ [File missing or outdated]
                           ▼
         ┌─────────────────────────────────────┐
         │  5c. Download from S3               │
         │  AWS SDK:                            │
         │    s3.getObject(                     │
         │      bucket: "devo-lookups-prod-san",│
         │      key: "customer_domain/..."      │
         │    )                                 │
         │  Download to temp location           │
         └─────────────────┬───────────────────┘
                           │
                           │ [Download complete]
                           ▼
         ┌─────────────────────────────────────┐
         │  5d. Save to Local Disk             │
         │  Move file to:                       │
         │  /var/logt/lookups/customer_domain/  │
         │    hourly_login_stats.lookup         │
         │  Set permissions: 644                │
         │  Verify integrity (checksum)         │
         └─────────────────┬───────────────────┘
                           │
                           │ [File saved successfully]
                           │
         ┌─────────────────┴───────────────────┐
         │  5e. Log Success                     │
         │  mason-agent.log:                    │
         │  "Successfully synced file:          │
         │   hourly_login_stats.lookup"         │
         └─────────────────┬───────────────────┘
                           │
                           │ [ALL DATANODES repeat steps 5a-5e]
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  6. DEPLOYMENT COMPLETE             │
         │  Status: Lookup deployed to all     │
         │          datanodes                   │
         │  Time: ~5-15 minutes from creation   │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  7. LOMANA sends Response to Webapp │
         │  Queue: mq_exchange_lomana_responses │
         │  Message:                            │
         │  {                                   │
         │    "status": "success",              │
         │    "tableName": "hourly_login_stats",│
         │    "message": "Table created and     │
         │                deployed successfully" │
         │  }                                   │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  8. WEBAPP updates UI                │
         │  Customer sees:                      │
         │  ✅ "Table hourly_login_stats        │
         │       successfully created"          │
         │  Status: Active                      │
         │  Refresh: Every 1 hour               │
         └─────────────────┬───────────────────┘
                           │
                           │ [TABLE IS NOW READY FOR USE]
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  9. CUSTOMER QUERIES TABLE          │
         │  Query in Devo UI:                   │
         │    from my.synthesis.`customer_domain│
         │         `.hourly_login_stats         │
         │    select *                          │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  10. MALOTE (Query Engine)          │
         │  Execute query:                      │
         │  1. Parse LINQ query                 │
         │  2. Identify table: my.synthesis.*   │
         │  3. Find local lookup file:          │
         │     /var/logt/lookups/.../           │
         │     hourly_login_stats.lookup        │
         │  4. Read data from file              │
         │  5. Return results to customer       │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  11. RESULTS DISPLAYED              │
         │  Customer sees aggregated data:      │
         │                                      │
         │  user_type  | login_count | hour    │
         │  ---------- | ----------- | ----    │
         │  admin      | 150         | 9:00    │
         │  user       | 3500        | 9:00    │
         │  admin      | 120         | 10:00   │
         │  ...                                 │
         └──────────────────────────────────────┘
```

---

### Periodic Refresh Flow (Every 1 Hour)

```
         ┌─────────────────────────────────────┐
         │  LOMANA SCHEDULER                   │
         │  Triggers: Every 1 hour (per table) │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  1. Execute Source Query            │
         │  Query Malote for new data          │
         │  (last 1 hour of authentication logs)│
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  2. Generate New Lookup File        │
         │  Create: hourly_login_stats_v2.lookup│
         │  (v2 because it's a new version)     │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  3. Upload to S3                    │
         │  Replace: hourly_login_stats_v1     │
         │  With: hourly_login_stats_v2        │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  4. Notify Mason/Lodge              │
         │  "New version available: v2"         │
         └─────────────────┬───────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────────┐
         │  5. Mason-Agents Update             │
         │  Download v2 → Replace v1 on disk   │
         │  Malote automatically picks up new   │
         │  version on next query              │
         └──────────────────────────────────────┘
```

---

## RabbitMQ Role & Queues

### Why RabbitMQ is Critical

**Problem Without RabbitMQ:**
```
Customer creates table → Webapp calls Lomana directly → Waits 30+ seconds
- Webapp thread blocked
- Customer sees loading spinner
- If Lomana crashes, request lost
- No scalability (1 request at a time)
```

**Solution With RabbitMQ:**
```
Customer creates table → Webapp sends message → Returns immediately (202 Accepted)
                              ↓
                         RabbitMQ persists message
                              ↓
                         Lomana processes when ready
                              ↓
                         Webapp gets notification via response queue
```

### Queue Configuration (from ISM-14892)

```json
{
  "amqpRPCConfig": {
    "amqpConfig": {
      "validation": "relaxed",
      "amqpUri": "amqp://rabbitmq.rabbitmq:5672",
      "parallelism": 10,
      "heartbeatPeriod": 10,
      "minBackoff": 3.0,
      "maxBackoff": 30.0,
      "randomFactor": 0.2,
      "maxRestarts": 20,
      "window": 300.0
    },
    "requests": {
      "name": "mq_lomana_requests.lomana",
      "buffer": 1000
    },
    "responses": {
      "name": "mq_exchange_lomana_responses",
      "routingKey": "#"
    }
  }
}
```

**Key Parameters:**
- **parallelism: 10** - Process 10 messages concurrently
- **heartbeatPeriod: 10** - Check connection every 10 seconds
- **minBackoff: 3s** - Wait 3s before reconnecting after failure
- **maxBackoff: 30s** - Max wait time between reconnection attempts
- **maxRestarts: 20** - Retry connection 20 times before giving up
- **window: 300s** - 5-minute window for restart counting

### What Happens if RabbitMQ is Down?

**Immediate Impact:**
- ❌ Customer cannot create new my.synthesis tables
- ❌ Webapp shows error: "Service unavailable"
- ❌ Lomana cannot receive new requests
- ❌ Existing tables still work (query existing my.synthesis)
- ❌ Scheduled refreshes fail (Lomana can't notify about completion)

**Recovery (from ISM-14892):**
1. Fix RabbitMQ (update image, restart pods)
2. Lomana auto-reconnects within 30s (maxBackoff)
3. Pending messages in queue (if RabbitMQ persisted them)
4. Lomana processes queued requests
5. Service restored

---

## Mason & Metadata Distribution

### Mason-Agent vs Lomana: Division of Responsibilities

| Task | Lomana | Mason-Agent |
|------|--------|-------------|
| **Create lookup file** | ✅ Yes | ❌ No |
| **Generate table data** | ✅ Yes | ❌ No |
| **Upload to S3** | ✅ Yes | ❌ No |
| **Decide what to deploy** | ❌ No (Lodge does) | ❌ No |
| **Download from S3** | ❌ No | ✅ Yes |
| **Sync files to datanodes** | ❌ No | ✅ Yes |
| **Check file versions** | ❌ No | ✅ Yes |
| **Manage file lifecycle** | ✅ Yes | ❌ No |

**Summary:**
- **Lomana:** Creates and manages the content
- **Lodge:** Decides where content should go
- **Mason-Agent:** Ensures content gets there
- **Malote:** Uses the content

### Mason-Agent Monitoring

**Health Check:**
```bash
# Check mason-agent service
systemctl status mason-agent

# Check recent sync activity
journalctl -u mason-agent --since '1 hour ago' | grep -i "synced\|downloaded\|failed"

# Check Lodge connectivity
grep "Lodge" /var/log/mason-agent/*.log | tail -20
```

**Common Issues:**
- **ImagePullBackOff:** RabbitMQ image unavailable (ISM-14892)
- **Lodge unreachable:** Network connectivity to Lodge service
- **S3 download failed:** Permissions or network issues
- **File placement errors:** Disk full or permission denied

---

## Troubleshooting

### Issue 1: my.synthesis Table Not Created

**Symptoms:**
- Customer clicks "Create" in UI
- Webapp shows "Processing..." but never completes
- Table never appears in table list

**Diagnosis Steps:**

**Step 1: Check Webapp Status**
```bash
source ~/.zshrc && kube get pods -n devo-pro-san-core | grep webapp
# Should be: 1/1 Running

source ~/.zshrc && kube logs -n devo-pro-san-core -l app=webapp --tail=50 | grep -i "error\|exception"
```

**Step 2: Check RabbitMQ Status**
```bash
source ~/.zshrc && kube get pods -n rabbitmq
# All should be: 1/1 Running

# Check for ImagePullBackOff or CrashLoopBackOff
```

**Step 3: Check Lomana Status**
```bash
source ~/.zshrc && kube get pods -n devo-pro-san-core | grep lomana
# Should be: 1/1 Running

source ~/.zshrc && kube logs lomana-0 -n devo-pro-san-core --tail=100 | grep -i "error\|failed"
```

**Step 4: Check RabbitMQ Connection**
```bash
source ~/.zshrc && kube logs lomana-0 -n devo-pro-san-core | grep -i "rabbitmq\|amqp"

# Looking for:
# ✅ "Successfully connected to amqp://rabbitmq.rabbitmq:5672"
# ❌ "Connection refused" or "Trying to connect"
```

**Common Root Causes:**
1. **RabbitMQ is down** → Fix RabbitMQ first (see ISM-14892)
2. **Lomana CrashLoopBackOff** → Check logs, often due to RabbitMQ
3. **Database connection lost** → Check MySQL RDS accessibility
4. **Reserved word in table name** → Use different name (not "client", "timestamp", etc.)
5. **Stuck record in database** → Query logtrust.casper_concept, delete if status >= 100

### Issue 2: Table Created But Not Visible in Queries

**Symptoms:**
- Table shows as "Created" in UI
- Query returns: "Table does not exist"

**Diagnosis:**

**Step 1: Check if Deployed to Datanodes**
```maqui
from system.delegated.internal.lookup
where lookup = "hourly_login_stats"
  and domain = "customer_domain"
group by instance(databaseinfo()) as datanode
```

**Expected:** All datanodes should have the lookup
**Problem:** Some datanodes missing → Mason-agent issue

**Step 2: Check Mason-Agent Logs**
```bash
# On affected datanode
ssh datanode-X
journalctl -u mason-agent --since '1 hour ago' | grep -i "hourly_login_stats\|error"
```

**Step 3: Check Lodge Registry**
```bash
# Check if Lodge knows about the file
source ~/.zshrc && kube logs mason-mason-lodge-0 -n devo-pro-san-core | grep "hourly_login_stats"
```

**Common Root Causes:**
1. **Mason-agent not running** → Check systemd service
2. **S3 download failed** → Check S3 permissions
3. **Lodge not notified** → Check RabbitMQ notifications queue
4. **File not in S3** → Check Lomana upload logs

### Issue 3: Table Not Refreshing

**Symptoms:**
- Table created successfully
- Data is outdated (not refreshing on schedule)

**Diagnosis:**

**Step 1: Check Lomana Scheduler**
```maqui
from siem.logtrust.lomana.free
where lookup = "hourly_login_stats"
  and msg -> "Lookup ready to use"
order by eventdate desc
limit 10
```

**Expected:** Recent entries (within refresh schedule)
**Problem:** No recent entries → Scheduler not running

**Step 2: Check for Execution Errors**
```maqui
from siem.logtrust.lomana.free
where lookup = "hourly_login_stats"
  and level = "ERROR"
order by eventdate desc
limit 10
```

**Common Root Causes:**
1. **Source query failing** → Check query syntax
2. **Malote connection issues** → Check Malote status
3. **S3 upload failing** → Check S3 permissions
4. **Lomana scheduler paused** → Check Lomana configuration

### Issue 4: RabbitMQ Connection Refused (ISM-14892)

**Root Cause:** Bitnami moved RabbitMQ images from Docker Hub to AWS ECR Public

**Symptoms:**
```
java.net.ConnectException: Connection refused (Connection refused)
  Trying to connect to: amqp://rabbitmq.rabbitmq:5672
```

**Quick Fix:**
```bash
# Update RabbitMQ StatefulSet image
source ~/.zshrc && kube patch statefulset rabbitmq -n rabbitmq \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "public.ecr.aws/bitnami/rabbitmq:3.12.13-debian-12-r2"}]'

# Force pod restart
source ~/.zshrc && kube delete pod rabbitmq-0 -n rabbitmq
source ~/.zshrc && kube delete pod rabbitmq-1 -n rabbitmq
source ~/.zshrc && kube delete pod rabbitmq-2 -n rabbitmq

# Verify all pods Running
source ~/.zshrc && kube get pods -n rabbitmq

# Lomana should auto-reconnect within 30s
source ~/.zshrc && kube logs lomana-0 -n devo-pro-san-core | grep -i "connected"
```

**Full Details:** See `/Users/vikash.jaiswal/.claude/skills/devo-infra/ISM-14892-santander-synthesis-rabbitmq-resolution.md`

---

## Key Takeaways

### 1. RabbitMQ is the Glue

RabbitMQ decouples all the services:
- **Webapp ↔ Lomana** - Asynchronous table creation
- **Lomana ↔ Mason/Lodge** - Deployment notifications
- **Scalability** - Multiple consumers can process queue
- **Reliability** - Messages persist even if services restart

### 2. Lomana is the Orchestrator

Lomana manages the entire lifecycle:
- **Creates** lookup files from queries
- **Schedules** periodic refreshes
- **Coordinates** deployment via Mason
- **Tracks** versions and status

### 3. Mason is the Distributor

Mason ensures consistency:
- **Lodge** maintains desired state
- **Mason-agents** sync files from S3
- **Replaces rsync** with modern API-based distribution
- **Resilient** to network failures

### 4. Without RabbitMQ, Nothing Works

If RabbitMQ is down:
- ❌ No new table creation
- ❌ No table updates
- ❌ No deployment notifications
- ✅ Existing tables still queryable

**Critical Single Point of Failure**

---

## References

**Jira:**
- ISM-14892: Santander my.synthesis issue (RabbitMQ fix)

**Confluence:**
- [KB] Troubleshooting: Investigating Causes of my.synthesis Table Not Created as Expected (5601202776)
- [KB] CSI Queries for Troubleshooting Lomana (5601204948)
- LOMANA & LOOKUPS API - Lookup Management (3556409355)

**Related Runbooks:**
- `/Users/vikash.jaiswal/.claude/skills/devo-infra/rabbitmq-troubleshooting-runbook.md`
- `/Users/vikash.jaiswal/.claude/skills/devo-infra/ISM-14892-santander-synthesis-rabbitmq-resolution.md`

---

**Document Version:** 1.0
**Last Updated:** 2026-03-13
**Author:** Vikash Jaiswal
