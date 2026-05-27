# Maqui Query Optimization Guide

**Problem:** Maqui queries timing out or taking too long

**Solution:** 10-100x faster queries with these optimization strategies

---

## 🚀 Top 10 Optimization Rules

### 1. ✅ **ALWAYS Use Time Filters** (Most Critical!)

```maqui
# REQUIRED for fast queries
where now() - 1h < eventdate < now()
```

### 2. ✅ **Use Narrow Time Windows**

- ✅ **15 minutes** for quick checks (fastest)
- ✅ **1 hour** for health monitoring (balanced)
- ⚠️ **24 hours** only if necessary (slow)

### 3. ✅ **Filter by Specific Client**

```maqui
where client = "exact_domain@customer"  # Exact match = fastest!
```

### 4. ✅ **Filter Early, Aggregate Late**

```maqui
# CORRECT order:
where <time_filter>      # 1. Time first
where <client_filter>    # 2. Client second
where <field_filters>    # 3. Other filters
group by ...             # 4. Then aggregate
```

### 5. ✅ **Limit Result Sets**

```maqui
limit 100  # Always add limit!
```

### 6. ✅ **Use Performance Pragmas**

```maqui
pragma query.timeout: 0  # No timeout - let query finish
```

### 7. ✅ **Avoid Complex Regex**

```maqui
# SLOW: select re('.*pattern(.*)') as match
# FAST: where message -> "pattern"
```

### 8. ✅ **Use Specific Tables**

```maqui
from siem.logtrust.malote.gc    # GC events only
from box.unix                   # System metrics only
```

### 9. ✅ **Run Parallel Queries**

```bash
# Query multiple datanodes simultaneously
maqui -q "..." &
maqui -q "..." &
wait
```

### 10. ✅ **Use Optimized Helper Functions**

```bash
source ~/.devo/maqui-helper-optimized.sh
maqui_health_quick eu "client@domain"  # Pre-optimized!
```

---

## Available Regions

All global Devo regions supported:

| Region | Alias | Metamalote Host |
|--------|-------|-----------------|
| Europe | `eu` | metamalote-eu.devo.com:10100 |
| USA | `us` | metamalote-us.devo.com:10100 |
| USA 3 | `us3` | metamalote-us3.devo.com:10100 |
| Asia Pacific | `apac` | metamalote-ap.devo.com:10100 |
| Canada | `canada` | metamalote-canada.devo.com:10100 |
| Santander | `santander` | metamalote-santander.devo.com:10100 |
| GCP Telefonica EU | `gcpeu` | metamalote-sasr.devo.com:10100 |
| GCP US | `gcpus` | metamalote-gcpus.devo.com:10100 |
| ME/NCSC Bahrain | `me` | metamalote-ncscbh.devo.com:10100 |

---

## Optimized Helper Functions

**Location:** `~/.devo/maqui-helper-optimized.sh`

**Auto-loaded:** Added to `~/.zshrc` (sources on shell start)

### Quick Reference

```bash
# Show all regions
maqui_regions

# Fast query (no timeout)
maqui_fast <region> '<query>'

# Quick health check (15 min)
maqui_health_quick [region] <client>

# GC activity check (1 hour)
maqui_gc_check [region] <datanode>

# Connection pool check
maqui_connections [region] <datanode>

# Malote errors check
maqui_malote_errors [region] <datanode>

# Parallel checks for multiple datanodes
maqui_parallel_check <region> <dn1> <dn2> <dn3>
```

### Usage Examples

```bash
# Quick health check (EU region, 15 min window)
maqui_health_quick eu "gournay@factum"

# GC check for specific datanode (US region)
maqui_gc_check us "datanode-2-pro-cloud-shared-aws-us-east-1"

# Parallel GC checks for multiple datanodes
maqui_parallel_check eu \
  "datanode-2-pro-cloud-shared-aws-eu-west-1" \
  "datanode-7-pro-cloud-shared-aws-eu-west-1" \
  "datanode-8-pro-cloud-shared-aws-eu-west-1"

# Custom optimized query
maqui_fast apac "from siem.logtrust.malote.free where client = \"tokopedia\" where now() - 15m < eventdate < now() where errorMessage -> \"timeout\" group by client select count() limit 100 pragma query.timeout: 0"
```

**Region Parameter:** If not specified, defaults to `eu`

---

## Performance Comparison

### Before Optimization (5+ minutes):

```maqui
from siem.logtrust.malote.free
where client -> "factum"
where now() - 24h < eventdate < now()
where errorMessage -> "timeout" or message -> "timeout" or errorClass -> "timeout"
select re('.*failed=\\[agent:(.*)\\],.*') as Filter
select subs(msg, Filter, template("\\1"), msg) as Datanode
group by client, errorMessage, errorClass, message
select count() as errors
```

**Problems:**
- ❌ 24h time range (billions of events)
- ❌ Multiple OR conditions
- ❌ Complex regex extraction
- ❌ Too many group by fields
- ❌ No result limit
- ❌ No timeout pragma

### After Optimization (10 seconds):

```maqui
from siem.logtrust.malote.free
where client = "gournay@factum"         # Exact client
where now() - 1h < eventdate < now()    # 1h not 24h
where errorMessage -> "timeout"         # Single condition
group by client                         # Minimal grouping
select count() as errors
limit 100                               # Limit results
pragma query.timeout: 0                 # No timeout
```

**Improvements:**
- ✅ 1h time range (manageable)
- ✅ Exact client match
- ✅ Single filter condition
- ✅ Minimal grouping
- ✅ Result limit
- ✅ No timeout pragma

---

## Query Template (Copy-Paste Ready)

```maqui
from <table>
where client = "<exact_client>"               # 1. Exact client
where now() - 1h < eventdate < now()          # 2. 1h window
where <field> -> "simple_match"               # 3. Simple filter
group by <minimal_fields>                     # 4. Minimal grouping
select count() as count                       # 5. Simple aggregate
limit 100                                     # 6. Limit results
pragma query.timeout: 0                       # 7. No timeout
```

---

## Timeout Handling

### ❌ Wrong Approach:

```bash
# This cuts off Maqui mid-query!
timeout 60 maqui -q "..."
```

**Problem:** Bash `timeout` kills Maqui before query finishes

### ✅ Correct Approaches:

**Option 1: No timeout (let query finish)**
```bash
maqui -q "from ... pragma query.timeout: 0"
```

**Option 2: Optimize query instead**
```bash
# Narrow time window + filters = fast query
maqui -q "from ... where now() - 15m < eventdate < now() where client = 'x' limit 100"
```

**Option 3: Use helpers (pre-optimized)**
```bash
source ~/.devo/maqui-helper-optimized.sh
maqui_health_quick eu "client"  # Already optimized!
```

---

## Performance Metrics

| Query Type | Time Range | Result Size | Speed |
|------------|------------|-------------|-------|
| Unoptimized | 24h | Unlimited | 5+ min ⏳ |
| Basic optimization | 1h | Unlimited | 1-2 min ⏱️ |
| **Optimized** | 1h | Limited (100) | **10 sec** ⚡ |
| **Quick check** | 15m | Limited (100) | **3-5 sec** 🚀 |

---

## Troubleshooting

### Issue: Query still slow

**Checklist:**
1. ✅ Time filter present? (`now() - 1h < eventdate < now()`)
2. ✅ Client filter exact? (`client = "exact"` not `client -> "partial"`)
3. ✅ Time window narrow? (1h max, 15m best)
4. ✅ Result limit added? (`limit 100`)
5. ✅ Pragma added? (`pragma query.timeout: 0`)
6. ✅ VPN connected? (required for internal metamalote)

### Issue: "No query" error

**Fix:** Check query syntax
```bash
# WRONG - heredoc without quotes
maqui -q 'from ...' < file.txt

# CORRECT
maqui -q "from ... where ..."
```

### Issue: Connection timeout

**Fix:** Ensure VPN connected
```bash
# Test connectivity
nc -zv metamalote-eu.devo.com 10100

# Should show: Connection succeeded!
```

### Issue: Functions not available

**Fix:** Source the helper script
```bash
source ~/.devo/maqui-helper-optimized.sh
```

Or add to `~/.zshrc` (already done):
```bash
echo "source ~/.devo/maqui-helper-optimized.sh 2>/dev/null" >> ~/.zshrc
```

---

## Key Takeaways

1. 🚀 **Always use time filters** - #1 most important optimization
2. ⏰ **15-60 min windows** - Sweet spot for performance
3. 🎯 **Exact client match** - Faster than partial match (`=` vs `->`)
4. 🔢 **Always add limits** - Prevent huge result sets
5. ⏳ **No bash timeouts** - Let Maqui finish or optimize query
6. 🛠️ **Use helper functions** - Pre-optimized and ready to use
7. 🌍 **All regions supported** - EU, US, APAC, Canada, ME, GCP

---

## Related Documentation

- **Query Examples:** See main README.md in this skill
- **Database Access:** `/devo-database` skill (Adolfo, MySQL)
- **Jira Integration:** `/devo-jira` skill
- **Malote Troubleshooting:** `/malote` skill

---

**Created:** 2026-04-14  
**Author:** Vikash Jaiswal  
**Performance:** 10-100x faster queries
**Status:** ✅ Production Ready - All 9 regions supported
