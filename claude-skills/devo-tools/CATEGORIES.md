# Devo Platform - Query Categories Overview

**Organization:** Queries are organized by functional purpose for easier navigation.

## Query Categories

### 1. Infrastructure Monitoring (30+ queries)

**Purpose:** Monitor Devo platform services themselves

**Services Covered:**
- **Mason Agent** (Metadata Synchronization) - 6 queries
  - Distributes metadata files (lookups, metas, mafias) from S3 to datanodes
  - Monitors: Agent failures, S3 download errors, Lodge connectivity, legacy detection
  - Works with Lodge (master) to maintain desired metadata state
- **Lomana** (Lookup Lifecycle Manager) - 4 queries
  - Creates and manages lookup files (receives requests via RabbitMQ)
  - Uses Mason-agent as distribution backend
  - Monitors: Error logs, lookup processing, availability, casperables status
- **Malote** (Query Engine) - 10 queries
  - Executes queries on datanode data
  - Monitors: Restarts, GC events, versions, memory limits, open files, permissions
- **Metamalote** (Query Coordinator) - 7 queries
  - Coordinates distributed queries across Malote instances
  - Monitors: Connections, delegate health, clock drift, reinjections
- **Batrasio** (Load Balancer) - 5 queries
  - Distributes queries to healthy datanodes
  - Monitors: No usable targets, stalled instances, connection failures
- **Barcenas** (Data Manager) - 1 query
  - Manages data lifecycle (removal, archival)
  - Monitors: REMOVE operations
- **Flow/Pilot** (Ingestion Pipeline) - 1 query
  - Ingestion flow control
  - Monitors: Pilot errors

**Key Tables:**
- `siem.logtrust.mason.free`
- `siem.logtrust.malote.free`
- `siem.logtrust.metamalote.free`
- `siem.logtrust.batrasio.free`
- `siem.logtrust.lomana.free`
- `siem.logtrust.barcenas.activity`
- `siem.logtrust.flow.out`
- `system.delegated.internal.*`
- `box.unix` / `box.win`

**Key Architecture: Mason Agent + Lomana**

Understanding the relationship between Mason and Lomana is crucial for troubleshooting metadata/lookup issues:

```
Lomana (Lookup Lifecycle)        Mason (Metadata Distribution)
       │                                    │
       │ Creates/Manages Lookups            │ Synchronizes Files
       │ via RabbitMQ requests              │ from S3 to Datanodes
       │                                    │
       ├─────────────┐                     │
       │             │                     │
       ▼             ▼                     ▼
   Generate      Deploy via            Lodge (Master)
   Lookup        Mason-agent              │
   Files         Backend                  │ Maintains desired state
                                          │
                                          ▼
                                    Mason Agents
                                    (on datanodes)
                                          │
                                          ▼
                                    Download from S3
                                          │
                                          ▼
                                    Local Storage
                                    (lookups, metas, mafias)
```

**Key Differences:**

| Aspect | Mason Agent | Lomana |
|--------|-------------|--------|
| **Creates lookups?** | ❌ No | ✅ Yes |
| **Distributes files?** | ✅ Yes | ❌ No (uses Mason) |
| **File source** | S3 (downloads) | Generated locally |
| **Triggered by** | Periodic Lodge checks | RabbitMQ requests |
| **Replaces** | rsync (old method) | N/A |

**When to check Mason:** File synchronization issues, S3 download errors, Lodge connectivity
**When to check Lomana:** Lookup creation failures, deployment issues, RabbitMQ problems

---

### 2. Data Ingestion Monitoring (5+ queries)

**Purpose:** Track data flowing INTO the platform (ingestion pipeline)

**What's Monitored:**
- Ingestion volume by domain/customer
- Ingestion by technology/subkind
- Table ingestion byte counts
- Ingestion rate over time
- Parameters and metadata

**Key Tables:**
- `syslog.alcohol.stats` - Main ingestion statistics
- `siem.logtrust.collector.counter` - Table-level byte counters

**Example Use Cases:**
- "How much data did customer X ingest today?"
- "Which technology/source is sending the most data?"
- "Is data flowing to this table?"
- "Track ingestion trends over 7 days"

---

### 3. Data Storage & Retrieval (10+ queries)

**Purpose:** Query actual CUSTOMER DATA stored in tables

**What You Can Do:**
- Query customer application logs (`my.app.*`)
- Query customer synthesis data (`my.synthesis.*`)
- Query Windows event logs (`box.win_nxlog.*`)
- Check which datanodes have a table deployed
- Search for specific messages/events
- Filter by log levels, errors, patterns

**Key Table Patterns:**
- `my.app.<domain>.*` - Customer application data
- `my.synthesis.<domain>.*` - Processed customer data
- `box.win_nxlog.*` - Windows events
- `system.delegated.internal.table` - Table deployment info

**Example Use Cases:**
- "Show me ERROR logs from customer X's application"
- "Which datanodes have the GitLab table?"
- "Search for authentication failures in Windows logs"
- "Query specific customer's IDCS logs"
- "Find messages containing specific text"

**Key Difference from Ingestion:**
- **Ingestion** = monitoring the pipeline (how much data came in)
- **Storage & Retrieval** = querying the actual data content

---

### 4. Performance & System Monitoring (5+ queries)

**Purpose:** Monitor system resources and performance

**What's Monitored:**
- CPU usage (user, system, interrupts)
- Memory usage
- GC pause times
- Corrupted indexes
- Command history
- Delegate delays

**Key Tables:**
- `box.stat.unix.dstatLt1` - Detailed CPU/memory stats
- `siem.logtrust.malote.gc` - GC events
- `system.delegated.internal.indexing.licor.stat` - Index status
- `box.unix` - Command history

---

### 5. Affinity & Domain Management (10+ queries - MySQL)

**Purpose:** Manage which domains can access which storage trunks

**What's Managed:**
- Domain-to-trunk affinity
- Count domains per trunk
- Alert on low affinity (≤2 trunks)
- Alert on no affinity (0 trunks)
- Add/remove trunk affinity
- Identify trunk IDs

**Database:** MySQL (not Maqui)
- `database-eu.devo.com`
- `database-apac.devo.com`
- `database-us.devo.com`

**Key Tables:**
- `affinity` - Domain-trunk relationships
- `domain` - Customer domains
- `trunk` - Storage trunks (EBS volumes)
- `installation` - Datanode installations

---

### 6. Advanced Data Management (5+ queries)

**Purpose:** Authenticated data deletion (requires signer/keystore)

**⚠️ WARNING:** Use with extreme caution - these delete data!

**Operations:**
- Dry run (list files to delete)
- Close and delete files
- Delete by domain/date range
- Offboarding data deletion

**Requirements:**
- Keystore authentication
- Signer tool
- Execute from metamalote host
- Proper pragmas for safety

---

## Navigation Tips

### By Use Case

**"I need to troubleshoot a service issue"**
→ **Infrastructure Monitoring** (Mason, Malote, Metamalote, Batrasio)

**"I need to check if data is flowing"**
→ **Data Ingestion Monitoring** (Alcohol stats, Collector counters)

**"I need to query actual customer data"**
→ **Data Storage & Retrieval** (my.app.*, my.synthesis.*, Windows logs)

**"I need to check system performance"**
→ **Performance & System Monitoring** (CPU, GC, indexes)

**"I need to manage domain access"**
→ **Affinity & Domain Management** (MySQL queries)

### By Table Type

**Infrastructure Tables** (siem.logtrust.*, system.delegated.*)
→ Infrastructure Monitoring + Performance

**Ingestion Tables** (syslog.alcohol.stats, collector.counter)
→ Data Ingestion Monitoring

**Customer Data Tables** (my.app.*, my.synthesis.*, box.*)
→ Data Storage & Retrieval

**MySQL Tables** (affinity, domain, trunk, installation)
→ Affinity & Domain Management

---

## Quick Access

**Full Documentation:**
```bash
cat ~/.claude/skills/devo-tools/README.md
```

**Quick Reference:**
```bash
cat ~/.claude/skills/devo-tools/QUERY-REFERENCE.md
```

**This Categories Guide:**
```bash
cat ~/.claude/skills/devo-tools/CATEGORIES.md
```

**Invoke Skill:**
```bash
/devo-tools
```
