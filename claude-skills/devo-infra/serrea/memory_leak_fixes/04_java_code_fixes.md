# Serrea Memory Leak - Java Code Fixes

**Related:** ISM-16256, ISM-16096, CHG-10470
**Date:** 2026-04-14
**Author:** Vikash Jaiswal

## Overview

This document provides the exact Java code changes needed to fix three types of memory leaks in Serrea:

1. **Connection Leaks** - Database connections not properly closed
2. **Hibernate Session Leaks** - Hibernate sessions not properly closed
3. **Unbounded Caches** - HashMap/cache objects growing indefinitely

---

## Fix 1: Connection Leaks - Use try-with-resources

### Problem

```java
// BAD: Connection not closed on exception
Connection conn = dataSource.getConnection();
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery("SELECT ...");

// If exception occurs here, connection never closed!
processResults(rs);

// Manual close (may not execute)
conn.close();
```

### Solution

```java
// GOOD: Auto-closes even on exception
try (Connection conn = dataSource.getConnection();
     Statement stmt = conn.createStatement();
     ResultSet rs = stmt.executeQuery("SELECT ...")) {

    processResults(rs);

} // Automatically closed even if exception occurs
```

### Finding Files to Fix

Search for connection usage patterns:

```bash
# On Serrea server
cd /opt/logtrust/serrea
unzip -q lib/serrea-4.4.0-SNAPSHOT.jar -d /tmp/serrea_src

# Find potential connection leaks
grep -r "getConnection()" /tmp/serrea_src --include="*.class" | grep -v "try-with-resources"
```

### Example Fixes Needed

**File: `com/devo/serrea/dao/SomeDAO.java` (hypothetical)**

```java
// BEFORE - Leak Risk
public List<Data> fetchData() throws SQLException {
    Connection conn = dataSource.getConnection();
    PreparedStatement ps = conn.prepareStatement("SELECT * FROM data");
    ResultSet rs = ps.executeQuery();

    List<Data> results = new ArrayList<>();
    while (rs.next()) {
        results.add(mapRow(rs));
    }

    rs.close();
    ps.close();
    conn.close();  // Won't execute if exception thrown above
    return results;
}

// AFTER - Fixed
public List<Data> fetchData() throws SQLException {
    try (Connection conn = dataSource.getConnection();
         PreparedStatement ps = conn.prepareStatement("SELECT * FROM data");
         ResultSet rs = ps.executeQuery()) {

        List<Data> results = new ArrayList<>();
        while (rs.next()) {
            results.add(mapRow(rs));
        }
        return results;

    } // All resources auto-closed
}
```

---

## Fix 2: Hibernate Session Leaks - Proper Session Management

### Problem

```java
// BAD: Session not closed on exception
Session session = sessionFactory.openSession();
Transaction tx = session.beginTransaction();

// Do work
User user = session.get(User.class, userId);
tx.commit();

// Forgot to close session!
// Or exception prevents reaching session.close()
```

### Solution A: Try-finally (Traditional)

```java
// GOOD: Use try-finally
Session session = sessionFactory.openSession();
try {
    Transaction tx = session.beginTransaction();
    try {
        // Do work
        User user = session.get(User.class, userId);
        tx.commit();
    } catch (Exception e) {
        tx.rollback();
        throw e;
    }
} finally {
    session.close();  // Always executed
}
```

### Solution B: Try-with-resources (Java 7+)

```java
// BEST: Use try-with-resources
try (Session session = sessionFactory.openSession()) {
    Transaction tx = session.beginTransaction();
    try {
        // Do work
        User user = session.get(User.class, userId);
        tx.commit();
    } catch (Exception e) {
        tx.rollback();
        throw e;
    }
} // Session auto-closed
```

### Example Fixes Needed

**File: `com/devo/serrea/service/UserService.java` (hypothetical)**

```java
// BEFORE - Leak Risk
public User findUser(String userId) {
    Session session = sessionFactory.openSession();
    try {
        return session.get(User.class, userId);
    } catch (Exception e) {
        logger.error("Error finding user", e);
        return null;
    }
    // Session never closed!
}

// AFTER - Fixed
public User findUser(String userId) {
    try (Session session = sessionFactory.openSession()) {
        return session.get(User.class, userId);
    } catch (Exception e) {
        logger.error("Error finding user", e);
        return null;
    } // Session auto-closed
}
```

---

## Fix 3: Unbounded Caches - Use Guava Cache with Size Limits

### Problem

```java
// BAD: Cache grows indefinitely - MEMORY LEAK!
private final Map<String, QueryResult> queryCache = new HashMap<>();

public QueryResult executeQuery(String query) {
    if (queryCache.containsKey(query)) {
        return queryCache.get(query);
    }

    QueryResult result = doExpensiveQuery(query);
    queryCache.put(query, result);  // NEVER EVICTS OLD ENTRIES!
    return result;
}
```

**Why this is bad:**
- Cache grows forever
- No expiration policy
- No size limit
- Eventually causes OutOfMemoryError

### Solution: Use Guava Cache

```java
import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;
import java.util.concurrent.TimeUnit;

// GOOD: Bounded cache with expiration
private final Cache<String, QueryResult> queryCache = CacheBuilder.newBuilder()
    .maximumSize(5000)                              // Max 5000 entries
    .expireAfterWrite(30, TimeUnit.MINUTES)         // Expire after 30 min
    .recordStats()                                  // Enable monitoring
    .build();

public QueryResult executeQuery(String query) {
    try {
        return queryCache.get(query, () -> doExpensiveQuery(query));
    } catch (Exception e) {
        logger.error("Query execution failed", e);
        throw new RuntimeException(e);
    }
}

// Optionally: Monitor cache stats
public void logCacheStats() {
    CacheStats stats = queryCache.stats();
    logger.info("Query cache - Hits: {}, Misses: {}, Evictions: {}",
        stats.hitCount(), stats.missCount(), stats.evictionCount());
}
```

### Common Cache Patterns to Fix

#### Pattern 1: Static HashMap Cache

```java
// BEFORE - Unbounded
private static final Map<String, User> USER_CACHE = new HashMap<>();

public User getUser(String id) {
    if (!USER_CACHE.containsKey(id)) {
        USER_CACHE.put(id, loadUserFromDB(id));
    }
    return USER_CACHE.get(id);
}

// AFTER - Bounded
private static final Cache<String, User> USER_CACHE = CacheBuilder.newBuilder()
    .maximumSize(1000)
    .expireAfterAccess(1, TimeUnit.HOURS)
    .build();

public User getUser(String id) {
    try {
        return USER_CACHE.get(id, () -> loadUserFromDB(id));
    } catch (Exception e) {
        throw new RuntimeException("Failed to load user", e);
    }
}
```

#### Pattern 2: Session Cache

```java
// BEFORE - Unbounded
private final Map<String, Session> sessionCache = new ConcurrentHashMap<>();

public void storeSession(String sessionId, Session session) {
    sessionCache.put(sessionId, session);  // LEAK!
}

// AFTER - Bounded with expiration
private final Cache<String, Session> sessionCache = CacheBuilder.newBuilder()
    .maximumSize(2000)
    .expireAfterWrite(2, TimeUnit.HOURS)  // Sessions expire
    .removalListener(notification -> {
        // Cleanup when session removed
        Session session = (Session) notification.getValue();
        session.invalidate();
    })
    .build();

public void storeSession(String sessionId, Session session) {
    sessionCache.put(sessionId, session);
}

public Session getSession(String sessionId) {
    return sessionCache.getIfPresent(sessionId);
}
```

#### Pattern 3: Domain/Lookup Cache

```java
// BEFORE - Unbounded
private final Map<String, Domain> domainCache = new HashMap<>();

public Domain getDomain(String domainId) {
    return domainCache.computeIfAbsent(domainId, this::loadDomain);  // LEAK!
}

// AFTER - Bounded
private final Cache<String, Domain> domainCache = CacheBuilder.newBuilder()
    .maximumSize(500)
    .expireAfterWrite(1, TimeUnit.HOURS)
    .build();

public Domain getDomain(String domainId) {
    try {
        return domainCache.get(domainId, () -> loadDomain(domainId));
    } catch (Exception e) {
        logger.error("Failed to load domain: " + domainId, e);
        throw new RuntimeException(e);
    }
}
```

---

## Fix 4: Using Caffeine Cache (Modern Alternative)

If Serrea can be upgraded, Caffeine is a modern replacement for Guava Cache:

```java
import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;

// Caffeine Cache (better performance than Guava)
private final Cache<String, QueryResult> queryCache = Caffeine.newBuilder()
    .maximumSize(5000)
    .expireAfterWrite(Duration.ofMinutes(30))
    .recordStats()
    .build();

public QueryResult executeQuery(String query) {
    return queryCache.get(query, k -> doExpensiveQuery(k));
}
```

---

## Files to Check in Serrea

Based on common patterns, check these locations:

```bash
# On Serrea server or in source code
# Look for unbounded caches in these packages:

1. Query/Result Caching
   - com/devo/serrea/query/**/*.java
   - Look for: Map<String, QueryResult>

2. Session Management
   - com/devo/serrea/session/**/*.java
   - Look for: Map<String, Session>

3. User/Domain Caching
   - com/devo/serrea/domain/**/*.java
   - com/devo/serrea/user/**/*.java
   - Look for: Map<String, User>, Map<String, Domain>

4. Alert Configuration
   - com/devo/serrea/alert/**/*.java
   - Look for: Map<String, AlertConfig>

5. Database Access Layer
   - com/devo/serrea/dao/**/*.java
   - com/devo/serrea/dbaccess/**/*.java
   - Look for: Connection, Session usage

6. Service Layer
   - com/devo/serrea/service/**/*.java
   - Look for: All cache patterns
```

---

## Heap Dump Analysis

If you have the heap dump (`java_pid2356.hprof`), analyze it with Eclipse MAT:

### Download Eclipse MAT
- https://www.eclipse.org/mat/downloads.php

### Analysis Steps

1. **Open heap dump** in Eclipse MAT
2. **Run "Leak Suspects Report"**
3. **Look for these patterns:**

   **Connection Leaks:**
   - Search for: `java.sql.Connection`
   - Check retained size
   - Find dominator tree

   **Session Leaks:**
   - Search for: `org.hibernate.Session`
   - Check if sessions are held by thread locals
   - Find GC roots

   **Unbounded Caches:**
   - Search for: `java.util.HashMap`, `java.util.ConcurrentHashMap`
   - Filter by size > 10,000 entries
   - Check retained heap size
   - Find what holds the reference

### MAT Query Examples

```sql
-- Find large HashMaps
SELECT * FROM java.util.HashMap WHERE size > 10000

-- Find Connection objects
SELECT * FROM java.sql.Connection

-- Find Hibernate Sessions
SELECT * FROM org.hibernate.internal.SessionImpl

-- Find thread locals (common leak source)
SELECT * FROM java.lang.ThreadLocal
```

---

## Testing the Fixes

### 1. Unit Tests

```java
@Test
public void testCacheEviction() {
    Cache<String, String> cache = CacheBuilder.newBuilder()
        .maximumSize(2)
        .build();

    cache.put("key1", "value1");
    cache.put("key2", "value2");
    cache.put("key3", "value3");  // Should evict key1

    assertNull(cache.getIfPresent("key1"));  // Evicted
    assertNotNull(cache.getIfPresent("key3"));
}

@Test
public void testCacheExpiration() throws Exception {
    Cache<String, String> cache = CacheBuilder.newBuilder()
        .expireAfterWrite(1, TimeUnit.SECONDS)
        .build();

    cache.put("key", "value");
    assertEquals("value", cache.getIfPresent("key"));

    Thread.sleep(1100);  // Wait for expiration
    assertNull(cache.getIfPresent("key"));  // Expired
}
```

### 2. Integration Tests

```java
@Test
public void testConnectionNotLeaked() throws Exception {
    int activeConnectionsBefore = getActiveConnections();

    try (Connection conn = dataSource.getConnection()) {
        // Simulate exception
        throw new RuntimeException("Test exception");
    } catch (RuntimeException e) {
        // Expected
    }

    // Connection should be closed despite exception
    assertEquals(activeConnectionsBefore, getActiveConnections());
}
```

### 3. Load Testing

Monitor memory during load test:

```bash
# Start load test
./gradlew loadTest

# Monitor heap in separate terminal
watch -n 5 'jstat -gcutil $(pgrep -f serrea) | tail -1'

# Check for leaks
grep "Connection leak detection" /var/log/serrea/serrea.log
```

---

## Deployment Checklist

- [ ] Backup Serrea source code
- [ ] Apply connection leak fixes (try-with-resources)
- [ ] Apply Hibernate session leak fixes (try-finally/try-with-resources)
- [ ] Replace unbounded caches with Guava Cache
- [ ] Add unit tests for cache eviction
- [ ] Add integration tests for resource cleanup
- [ ] Update configuration (hikaricp leak detection)
- [ ] Deploy to staging environment
- [ ] Run load tests
- [ ] Monitor for leak warnings
- [ ] Analyze heap dumps (before/after)
- [ ] Deploy to production
- [ ] Monitor production metrics

---

## Monitoring After Deployment

### 1. Connection Leak Detection

```bash
# Check for leak warnings
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 \
  'grep "Connection leak detection" /var/log/serrea/serrea.log | tail -20'
```

### 2. Heap Usage Monitoring

```bash
# Monitor heap every 5 seconds
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 \
  'jstat -gcutil $(pgrep -f serrea) 5000'
```

### 3. Cache Statistics

If you added cache monitoring, check cache stats:

```bash
# Check cache hit rates (in application logs)
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 \
  'grep "Cache stats" /var/log/serrea/serrea.log | tail -20'
```

### 4. Connection Pool Statistics

```bash
# Check health endpoint
curl -k https://serrea-2-pro-cloud-caixa-ibm-eu-de-3/search/system/health | jq '.results.mysql'
```

---

## Expected Results

### Before Fixes
- Heap grows continuously
- Old Gen stays > 80%
- Frequent Full GC
- Connection errors
- OutOfMemoryError

### After Fixes
- Heap stabilizes
- Old Gen < 70%
- Rare Full GC
- No connection errors
- No OOM errors

---

## References

- **Guava Cache:** https://github.com/google/guava/wiki/CachesExplained
- **HikariCP:** https://github.com/brettwooldridge/HikariCP
- **Hibernate Session Management:** https://docs.jboss.org/hibernate/orm/5.6/userguide/html_single/Hibernate_User_Guide.html
- **Eclipse MAT:** https://www.eclipse.org/mat/
- **Java try-with-resources:** https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html

---

**Next Steps:**
1. Apply configuration fixes (already done in deployment script)
2. Get access to Serrea source code repository
3. Apply Java code fixes from this document
4. Test in staging environment
5. Deploy to production

**Related Issues:**
- ISM-16256: [Caixabank] API 504 errors
- ISM-16096: Previous similar incident
- CHG-10470: Related change
