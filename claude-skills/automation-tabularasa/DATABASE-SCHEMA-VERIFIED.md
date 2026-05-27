# Database Schema - Verified from Production (APAC)

**Verification Date:** 2026-04-23
**Region:** APAC (ap_pro)
**Database:** logtrust

---

## Key Tables for Tabula Rasa

### 1. `affinity` Table
**Purpose:** Domain-to-trunk affinity assignments

**Structure:**
```sql
Field            Type          Null   Key     Default             Extra
--------------------------------------------------------------------------------
id               int           NO     PRI     NULL                auto_increment
domain_id        varchar(50)   NO     MUL     NULL
trunk_id         int           NO     MUL     NULL
creation_date    timestamp     NO     MUL     CURRENT_TIMESTAMP   DEFAULT_GENERATED
expiration_date  timestamp     YES    MUL     NULL
```

**Row Count:** 9,302 (APAC)

**Key Notes:**
- Primary key: `id`
- Foreign keys: `domain_id` → domain.id, `trunk_id` → trunk.id
- Indexed on: domain_id, trunk_id, creation_date, expiration_date

---

### 2. `domain` Table
**Purpose:** Domain information and metadata

**Structure:**
```sql
Field                Type           Null   Key     Default   Extra
--------------------------------------------------------------------------------
id                   varchar(50)    NO     PRI     NULL
name                 varchar(100)   YES    UNI     NULL
default_port         int            YES            NULL
type                 int            NO             NULL
status               int            NO     MUL     NULL
update_date          datetime       NO             NULL
creation_date        datetime       NO             NULL
subscribed           int            NO             0
price_plan_id        int            YES            NULL
days_left            int            YES            NULL
show_landing         tinyint(1)     NO             0
reseller_id          bigint         YES    MUL     NULL
urlAlias             varchar(200)   YES    UNI     NULL
group_id             int            YES    MUL     NULL
alerts_last_reseted  datetime       YES            NULL
auth_restrictions    tinyint        NO             0
data_retrieval       tinyint        NO             0
```

**Row Count:** 638 (APAC)

**Key Notes:**
- Primary key: `id` (varchar, not auto-increment)
- Unique index: `name`, `urlAlias`
- Foreign key: `group_id` → domain_group.id

---

### 3. `machine` Table
**Purpose:** Datanode/machine information

**Structure:**
```sql
Field            Type          Null   Key     Default   Extra
--------------------------------------------------------------------------------
id               int           NO     PRI     NULL      auto_increment
name             varchar(100)  NO     UNI     NULL
ip_management    varchar(15)   YES    UNI     NULL
```

**Row Count:** 12 (APAC)

**Key Notes:**
- Primary key: `id`
- Unique index: `name`, `ip_management`
- Example: `datanode-1-pro-cloud-shared-aws-ap-southeast-1`

---

### 4. `trunk` Table
**Purpose:** Trunk information (shards on datanodes)

**Structure:**
```sql
Field        Type          Null   Key     Default   Extra
--------------------------------------------------------------------------------
id           int           NO     PRI     NULL      auto_increment
name         varchar(100)  NO     UNI     NULL
machine_id   int           NO     MUL     NULL
```

**Row Count:** (Not queried)

**Key Notes:**
- Primary key: `id`
- Foreign key: `machine_id` → machine.id
- Unique index: `name`

---

## Related Tables

### `machine_group` Table
**Purpose:** Machine group definitions (shared, self, public, etc.)

**Usage:** Filter machines by group for tabula rasa execution

---

### `domain_group` Table
**Purpose:** Domain group definitions

**Usage:** Group domains for affinity management

---

## Typical Joins for Tabula Rasa

### Get Complete Affinity Information:
```sql
SELECT 
    d.name as domain,
    m.name as datanode,
    t.name as trunk,
    a.creation_date,
    a.expiration_date
FROM affinity a
JOIN domain d ON a.domain_id = d.id
JOIN trunk t ON a.trunk_id = t.id
JOIN machine m ON t.machine_id = m.id
WHERE a.expiration_date IS NULL OR a.expiration_date > NOW()
ORDER BY m.name, d.name;
```

### Count Domains per Datanode:
```sql
SELECT 
    m.name as datanode,
    COUNT(DISTINCT a.domain_id) as domain_count
FROM affinity a
JOIN trunk t ON a.trunk_id = t.id
JOIN machine m ON t.machine_id = m.id
WHERE a.expiration_date IS NULL
GROUP BY m.name
ORDER BY domain_count DESC;
```

### Find Domain Affinity:
```sql
SELECT 
    d.name as domain,
    m.name as datanode,
    t.name as trunk
FROM affinity a
JOIN domain d ON a.domain_id = d.id
JOIN trunk t ON a.trunk_id = t.id
JOIN machine m ON t.machine_id = m.id
WHERE d.name = 'example.com'
  AND (a.expiration_date IS NULL OR a.expiration_date > NOW());
```

---

## Permissions Required for Tabula Rasa

### Read Permissions (Source Data):
```sql
GRANT SELECT ON logtrust.domain TO 'tabularasa_automation'@'%';
GRANT SELECT ON logtrust.machine TO 'tabularasa_automation'@'%';
GRANT SELECT ON logtrust.trunk TO 'tabularasa_automation'@'%';
GRANT SELECT ON logtrust.affinity TO 'tabularasa_automation'@'%';
GRANT SELECT ON logtrust.machine_group TO 'tabularasa_automation'@'%';
GRANT SELECT ON logtrust.domain_group TO 'tabularasa_automation'@'%';
```

### Write Permissions (Affinity Only):
```sql
GRANT INSERT ON logtrust.affinity TO 'tabularasa_automation'@'%';
GRANT UPDATE ON logtrust.affinity TO 'tabularasa_automation'@'%';
```

### Denied Operations (Security):
```sql
-- ❌ NO DELETE permission
-- ❌ NO DROP permission
-- ❌ NO TRUNCATE permission
-- ❌ NO ALTER permission
-- ❌ NO CREATE permission
```

---

## Tabula Rasa SQL Output Format

**Generated SQL Structure:**
```sql
SET @change_date := '2026-04-23 17:00';

-- Insert new affinity assignments
INSERT INTO affinity (domain_id, trunk_id, creation_date)
VALUES
  ('domain-id-1', 1, @change_date),
  ('domain-id-2', 2, @change_date),
  ('domain-id-3', 3, @change_date);

-- Update expiration date for old assignments (if applicable)
UPDATE affinity 
SET expiration_date = @change_date
WHERE domain_id IN ('domain-id-1', 'domain-id-2', 'domain-id-3')
  AND expiration_date IS NULL;
```

---

## Verification Queries

### Check Recent Affinity Changes:
```sql
SELECT 
    COUNT(*) as new_assignments,
    MIN(creation_date) as first_created,
    MAX(creation_date) as last_created
FROM affinity
WHERE creation_date > NOW() - INTERVAL 1 HOUR;
```

### Validate Affinity Integrity:
```sql
-- Check for orphaned affinity (no valid domain/trunk)
SELECT COUNT(*) as orphaned
FROM affinity a
LEFT JOIN domain d ON a.domain_id = d.id
LEFT JOIN trunk t ON a.trunk_id = t.id
WHERE d.id IS NULL OR t.id IS NULL;
```

### Check Datanode Balance:
```sql
SELECT 
    m.name,
    COUNT(DISTINCT a.domain_id) as domains,
    ROUND(COUNT(DISTINCT a.domain_id) * 100.0 / SUM(COUNT(DISTINCT a.domain_id)) OVER(), 2) as percentage
FROM affinity a
JOIN trunk t ON a.trunk_id = t.id
JOIN machine m ON t.machine_id = m.id
WHERE a.expiration_date IS NULL
GROUP BY m.name
ORDER BY domains DESC;
```

---

## Important Notes

1. **Domain ID Format:** varchar(50), not auto-increment (likely UUID or domain name)
2. **Affinity Expiration:** NULL = active, timestamp = expired/superseded
3. **Creation Date:** Auto-populated on INSERT (DEFAULT CURRENT_TIMESTAMP)
4. **Multi-region:** Each region (ap, us, eu) has identical schema but separate data
5. **Backup Strategy:** Export affinity table before changes (mysqldump)

---

## Next Steps

1. ✅ Schema verified from production (APAC)
2. ⏳ Create limited-access user `tabularasa_automation`
3. ⏳ Test permissions (read/write/denied operations)
4. ⏳ Update Groovy pipeline with correct table names
5. ⏳ Test end-to-end flow (generate SQL → execute → verify)

---

**Verified By:** Vikash Jaiswal (vikash.jaiswal@devo.com)
**Date:** 2026-04-23
**Region:** APAC Production (ap_pro)
**Tool:** `/devo-database` skill via MySQL wrapper
