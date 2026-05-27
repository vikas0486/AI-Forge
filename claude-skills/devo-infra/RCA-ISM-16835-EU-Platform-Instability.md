# RCA — EU Platform Instability
**Ticket:** ISM-16835  
**Date:** 2026-05-20  
**Author:** Vikash Jaiswal  

---

## 1. Summary

EU platform degradation since January 2026 was caused by a combination of long-standing infrastructure under-resourcing and a series of delayed or cancelled fixes. The visible crisis in May 2026 was the convergence of three independent failure chains — not a single event or action.

---

## 2. Timeline

| Date | Event |
|---|---|
| Pre-Jan 2026 | EU shared datanodes experiencing fullGC / heap exhaustion — malote instances crashing and being restarted by automation every 20-30 minutes |
| 2026-01-29 | ISM-14287 opened — "weeks" of prior EU shared DN performance issues. EU memory-limit 5GB vs US 10GB. |
| 2026-02-27 | Daniel identified pilot-server query leak: 1.4M unclosed queries holding ~28GB heap. **Never fixed.** |
| 2026-03-11 | Aman documented EU/US config gap: EU memory-limit 5GB vs US 10GB, threads 8 vs 16 |
| 2026-04-15 | CHG-10502 approved — memory-limit fix ready to deploy |
| 2026-04-16 | **CHG-10502 cancelled** 30 min before execution — decision to isolate Catawiki on dedicated infra instead |
| April 2026 | Catawiki migrated to dedicated datanodes (dn-1: 172.17.42.67, dn-2: 172.17.60.77). **`asilo.jks` not deployed** to new dedicated DNs → Asilo cannot delete aggr files on catawiki cluster → all casparables with catawiki data enter `FailedDeletion` loop |
| 2026-04-27 | Catawiki migration completed — performance did NOT recover (shared DN heap issue unresolved) |
| 2026-05-07 | CHG-10502 finally re-run (3 weeks late) — memory-limit 5G→12G. Partial relief only. |
| 2026-05-11 10:38 UTC | Vikash unregistered `required:siem.lt.scoja.domain.counter` (investigating stuck state), restarted Asilo engine with `--read-state-from 2026-04-01`. Asilo engine restart broadcast `global-state: false,0,0,-` for all casparables — **this is normal restart behavior, not a bulk deregister**. Only `domain.counter` was unregistered. |
| 2026-05-12 00:33 UTC | Victor batch-unregistered `collector.counter`, `domain.counter`, `me.counter` casparables |
| 2026-05-12 | Victor initiated PLEN-9169 — mass recalculation of ~305 EU casparables from 2022-04-01 → ~5,000 concurrent JDBC streams → ~120,000 connections → all 10 EU metamalote nodes saturated |
| 2026-05-15 | Signalit ingestion spike: 0.5TB/day → 3.7TB/day — compounded metamalote load |
| 2026-05-18 | Martin deployed `asilo.jks` to catawiki dedicated DNs (delayed fix — weeks after migration) |
| 2026-05-18 | CHG-10643: EU metamalote heap -Xmx31G → -Xmx80G, x2gd.xlarge → x2gd.2xlarge upgrade, nvme2n1 lookup disk fix |
| 2026-05-19 | Vikash resumed all required:* grains, deleted blocking catawiki 2026 aggr files |
| 2026-05-19 21:00 UTC | Victor restarted Asilo engine — applied US executor-strategy to EU, added `delegation.allow.delegates: {"self"}` |
| 2026-05-20 | All 5 required:* casparables RunningJob — platform stabilizing |

---

## 3. Root Cause Chain

### Primary — EU Shared Datanode Capacity Reduction + Heap Configuration Gap (ISM-14287)

EU shared datanode cluster was reduced from 9 nodes to 5 nodes between 2022–2023 as dedicated customers (Panda, Newscorp) completed their migrations to dedicated infrastructure (CHG-2928, CHG-2950, MR!5890). The remaining 5 shared nodes absorbed the full consolidated shared customer query load — a 44% reduction in capacity with no corresponding adjustment to malote JVM memory limits.

EU shared datanodes were running with `memory_limit: 5GB` (vs US `10GB`) — a configuration sized for the original larger cluster. Combined with an unresolved pilot-server JDBC connection accumulation (~1.4M unclosed query handles holding ~28GB heap across shared DNs), malote instances began hitting fullGC under the increased per-node load, with the automation resilience agent (CHG-10288) performing graceful restarts to maintain availability. This condition was formally tracked in ISM-14287 (opened 2026-01-29).

The memory configuration alignment fix (CHG-10502, memory-limit 5GB→12GB) was raised in March 2026 and executed in May 2026.

### Secondary — Catawiki Migration Without `asilo.jks` (April 2026)
When Catawiki was migrated to dedicated datanodes in April 2026, `asilo.jks` was not deployed to the new cluster. Asilo's mm0 SSL handshake to catawiki dedicated DNs failed, causing `not-deleted: N` on every deletion attempt. All casparables that had catawiki aggregation data entered a `FailedDeletion` / `DeletingJob` loop — including all 5 `required:*` platform-critical casparables. This is why the required:* grains are stuck at **July 2024** — that is the date range Asilo was trying to sanitize when deletion first started failing.

### Compounding — PLEN-9169 Mass Recalculation (May 12, 2026)
Victor's mass recalculation of ~305 EU casparables from 2022-04-01 started on May 12, generating ~5,000 concurrent JDBC streams and ~120,000 connections across 10 EU metamalote nodes. EU nodes (x2gd.xlarge: 4-core/31GB) were underpowered vs US (x2gd.2xlarge: 8-core/80GB), causing GC pause storms. The NLB idle timeout (~350s) killed long-running `lastEventdate` JDBC scans mid-query. This flooded an already-stressed system and made the degradation visible to all customers.

---

## 4. Clarification — Vikash's May 11 Action

On May 11 at 10:38 UTC, Vikash unregistered `required:siem.lt.scoja.domain.counter` as a troubleshooting step to release it from `FailedDeletion` state, then restarted Asilo engine with `--read-state-from 2026-04-01`.

**Evidence from `siem.logtrust.asilo.response`:**
- At 10:38 UTC: `domain.counter` aggr-state reset to `false,0,0,-` — single casparable unregister
- At 10:44 UTC: all 3 grains of `domain.counter` returned as `RunningJob` starting from `1775001600000` (2026-04-01) — matching the `--read-state-from` value
- The `global-state: false,0,0,-` broadcast seen at this time for ALL casparables is **normal Asilo engine restart behavior** — when the engine restarts it re-broadcasts current state for all registered casparables. This was misread as a bulk deregister. It was not.

**Unregister ≠ delete.** Unregistering a casparable releases it from a stuck deletion state so it can be re-registered and resume computation. No aggregation data is lost. This is standard operational procedure for recovering from `FailedDeletion`.

**Victor's bulk unregister of 3 casparables at 2026-05-12 00:33 UTC** — one day later — was the larger action, and likewise was a recovery step, not a destructive one.

---

## 5. Ongoing Issue — EU Shared Datanode FullGC

EU shared datanodes continue to experience malote port failures every 20-30 minutes due to heap exhaustion. The automation resilience infrastructure (health-check-agent, deployed Feb 2026 via CHG-10288) detects unresponsive malote ports and performs a graceful service restart within **<10 seconds** — preventing dropped datanode events that would affect customer queries.

This automation has kept the EU platform from experiencing datanode drops for the past 2 months despite the ongoing instability.

### Validated Fix — DN2 JVM Tuning (May 1-11, 2026)

A configuration change was trail-tested on `datanode-2-pro-cloud-shared-aws-eu-west-1` malote@i2 and @i5 from May 1-11, 2026.

**Configuration applied:**
```
Heap:  -Xms55G -Xmx55G  (from default 31G)
-XX:G1HeapRegionSize=32m
-XX:G1ReservePercent=15
-XX:InitiatingHeapOccupancyPercent=35
-XX:G1MixedGCCountTarget=16
-XX:MaxGCPauseMillis=200
-XX:ParallelGCThreads=16
-XX:ConcGCThreads=4
Transparent hugepages: always / defer+madvise
```

**Maqui Full GC validation (`siem.logtrust.malote.gc`, instance=malote@i2 and @i5):**

| Period | malote@i2 Full GC/day | malote@i5 Full GC/day |
|---|---|---|
| Apr 28 – May 5 (before tuning) | 8,000 – 12,000 | 8,000 – 12,000 |
| May 6 – May 12 (tuning active) | **0** | **0** |
| May 13 – May 19 (Ansible overwrote i5 config) | 0 (i2 still tuned) | 3,428 – 7,144 (signalit spike + config reverted) |

**Result:** Zero fullGC events during the tuning period. malote@i2 remained stable and was NOT being restarted by automation during those days. malote@i5 degraded again only after Ansible deployment reverted its config coinciding with the signalit ingestion spike.

### Plan of Action (Ready to Implement)

Apply validated JVM tuning to all EU shared datanode malote instances as a permanent configuration change via Ansible.

---

## 6. Resolution Steps Taken

| Action | Owner | Date |
|---|---|---|
| Deployed `asilo.jks` to catawiki dedicated DNs | Martin | 2026-05-18 |
| Deleted blocking catawiki 2026 aggr files (Jan-May) on both catawiki DNs | Vikash | 2026-05-19 |
| Resumed all 5 required:* casparables | Vikash | 2026-05-19 |
| EU metamalote heap -Xmx31G → -Xmx80G, x2gd.xlarge → x2gd.2xlarge (CHG-10643) | Vikash | 2026-05-19 |
| Applied US executor-strategy to EU Asilo, added `delegation.allow.delegates: {"self"}` | Victor | 2026-05-19 |
| All 5 required:* casparables RunningJob | — | 2026-05-20 |

---

## 7. Preventive Actions

| Action | Priority |
|---|---|
| Apply DN2 JVM tuning to all EU shared datanode malote instances | HIGH — ready to implement |
| Fix pilot-server query leak (Daniel, Feb 27 finding — 1.4M unclosed queries) | HIGH |
| Raise NLB idle timeout `private-metamalote-prod-eu` from ~350s to 3600s+ | HIGH |
| Raise EU Asilo JAVA_OPTS heap from 16g to 31g (match US) | MEDIUM |
| Add `asilo.jks` deployment to dedicated datanode provisioning runbook | MEDIUM — prevent recurrence |
| Stagger PLEN-9169 recalculation in batches of ~50 (stop `cc_*` first) | MEDIUM |
| Align EU/US Asilo executor-strategy — completed May 19 | DONE ✅ |

---

## 8. Key Finding (Benson, VP Engineering)

> *"We talked ourselves out of the fix that was available."*

CHG-10502 (memory-limit fix) was approved April 15, cancelled April 16, not re-run until May 7 — **3 weeks of unnecessary degradation**. The Catawiki hypothesis was reasonable to test, but once it did not hold up the original fix should have been restored immediately.

---

*RCA authored by Vikash Jaiswal — ISM-16835 — 2026-05-20*
