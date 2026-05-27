# Serrea Memory Leak Fixes - Reference

**Jira:** ISM-16256, PLEN-8842, CHG-10511
**Status:** Deployed 2026-04-14, 6 days stable as of 2026-04-20

All operational content — deployed config, deployment steps, monitoring commands, rollback procedure,
post-deployment results — is in the parent document:

**See `~/.claude/skills/devo-infra/serrea/README.md` → "Memory Leak Fixes" section.**

## Fix Files (in this directory)

```
01_hikaricp_leak_detection.properties   # HikariCP config (leakDetectionThreshold=60000, pool-size=20)
02_bounded_cache_config.properties      # Cache limits (10k/5k/2k entries)
03_ehcache.xml                          # EHCache XML (LRU, TTL 3600s)
04_java_code_fixes.md                   # Phase 3 code patterns (try-with-resources, Guava CacheBuilder)
deploy_memory_leak_fixes.sh             # Automated deployment script
monitor_memory_leaks.sh                 # Real-time monitoring script
```

## Phase 3 Code Fixes (Future — requires source access)

Three patterns documented in `04_java_code_fixes.md`:
- Try-with-resources for JDBC connection management
- Hibernate session cleanup in `finally` blocks
- `CacheBuilder.newBuilder().maximumSize(5000).expireAfterWrite(30, MINUTES)` replacing raw `HashMap`
