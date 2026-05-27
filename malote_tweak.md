# EU Shared Datanode-2 — Malote Calibration Plan of Action

**Node:** `datanode-2-pro-cloud-shared-aws-eu-west-1`  
**Instances in Scope:** `malote@i2`, `malote@i5`  
**Prepared by:** Vikash Jaiswal  
**Date:** 2026-05-20  
**Review Window:** 7 days post-implementation

---

## Problem Statement

Instances `i2` and `i5` on EU Shared Datanode-2 are experiencing sustained memory pressure and GC instability:

- Live heap usage on `i2` observed at **44–47 GB** — exceeding the current `-Xmx31G` default, triggering OOM and to-space exhausted GC events
- Live heap usage on `i5` observed at **40–45 GB** — same condition
- Default G1GC `IHOP=45%` causes concurrent marking to start too late; heap fills faster than collection can reclaim
- Accumulated `meta.info` / `licor.idx` index bloat from expired tenants adding unnecessary heap pressure

---

## Proposed Changes

### 1. JVM Heap Expansion + G1GC Tuning

**Files to modify:**

```
/etc/logtrust/systemd/malote/datanode-2-pro-cloud-shared-aws-eu-west-1/i2.conf
/etc/logtrust/systemd/malote/datanode-2-pro-cloud-shared-aws-eu-west-1/i5.conf
```

**Proposed `JAVA_OPTIONS` (both instances):**

```ini
JAVA_OPTIONS=-Xms55G -Xmx55G -XX:G1HeapRegionSize=32m -XX:G1ReservePercent=15 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1MixedGCCountTarget=16 -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=16 -XX:ConcGCThreads=4
```

**Flag rationale:**

| Flag | Proposed Value | Reason |
|------|---------------|--------|
| `-Xms55G -Xmx55G` | Fixed 55G | Eliminates heap resize overhead; 8G headroom above peak live data |
| `G1HeapRegionSize` | 32m | Larger regions reduce fragmentation caused by large object tenants |
| `G1ReservePercent` | 15 | Reserves 15% heap as GC emergency buffer — prevents to-space exhaustion |
| `InitiatingHeapOccupancyPercent` | 35 | Starts concurrent marking at 35% instead of default 45% — GC runs ahead of fill |
| `G1MixedGCCountTarget` | 16 | More mixed GC cycles per round — reclaims old-gen more aggressively |
| `MaxGCPauseMillis` | 200 | Soft pause target; prevents runaway STW pauses |
| `ParallelGCThreads` | 16 | Matches available vCPU for parallel GC phases |
| `ConcGCThreads` | 4 | Dedicated concurrent marking threads without starving application threads |

> **Important:** Per-instance `malote.javaoptions` files are **not read** by the malote startup script. The `JAVA_OPTIONS` environment variable in the instance `.conf` file is the only supported mechanism.

---

### 2. Tenant Licor Index Cleanup

Expired tenant `meta.info` and `licor.idx` directories to be removed from trunk 5 (and trunk 2 where applicable). These directories are index caches — they regenerate automatically on the next query. All customer data files remain untouched.

**Tenants to clean:**

| Tenant | Years to Delete | Trunk |
|--------|----------------|-------|
| `signalit` (all sub-tenants) | 2023, 2024 (full) | 5 |
| `deutschebank_f_soc@eucsfc_hcltech` | 2023, 2024 (full) | 5 |
| `cginfra_fi@icd_eu` | 2023, 2024 (full) | 2 |
| `catawiki` | 2023, 2024, 2025 (full), 2026 Jan–Apr | 5 |
| `*hcltech*` (all hcltech tenants) | 2023, 2024 (full) | all |
| `*@getd*` (all getd tenants incl. `globalexchange@getd`) | 2023, 2024 (full) | all |
| `mdr15@coretocloud` | 2023, 2024 (full) | 5 |
| `*icd_eu*` (all icd_eu tenants incl. `cginfra_fr@icd_eu`, `icd_de@icd_eu`) | 2023, 2024 (full) | all |
| `*coretocloud*` (all coretocloud tenants incl. `mdr11@coretocloud`) | 2023, 2024 (full) | all |

---

### 3. Kernel Transparent Hugepage Configuration

Tuning kernel THP settings to reduce GC pause variance for large JVM heaps:

```bash
echo always        > /sys/kernel/mm/transparent_hugepage/enabled
echo defer+madvise > /sys/kernel/mm/transparent_hugepage/defrag
```

**Expected state post-change:**

```
/sys/kernel/mm/transparent_hugepage/enabled  → [always]
/sys/kernel/mm/transparent_hugepage/defrag   → [defer+madvise]
```

> **Note:** These are runtime settings — not persistent across reboots. Persistence via the Ansible `sysctl` role should be addressed as a follow-up.

---

## Implementation Steps

| Step | Action | Command |
|------|--------|---------|
| 1 | Backup current `.conf` files | `cp i2.conf i2.conf.bak.$(date +%Y%m%d)` |
| 2 | Edit `i2.conf` — update `JAVA_OPTIONS` | As per Section 1 above |
| 3 | Edit `i5.conf` — update `JAVA_OPTIONS` | As per Section 1 above |
| 4 | Set THP kernel parameters | As per Section 3 above |
| 5 | Delete expired tenant licor indexes | As per Section 2 above |
| 6 | Reload systemd and restart instances | `systemctl daemon-reload && systemctl restart malote@i2 malote@i5` |
| 7 | Validate JVM flags loaded | `cat /proc/$(systemctl show malote@i2 --property=MainPID --value)/cmdline \| tr '\0' '\n' \| grep -E 'Xmx\|G1Heap\|IHOP\|GCThreads'` |
| 8 | Confirm instances running with new heap | `systemctl status malote@i2 malote@i5` |
| 9 | Baseline GC pause average | `grep 'Pause Young' /var/log/malote/malote2.gc.log \| tail -20 \| awk -F' ' '{print $NF}' \| sed 's/ms//' \| awk '{sum+=$1;n++} END{printf "avg: %.1fms\n",sum/n}'` |

---

## Success Criteria

| Metric | Target |
|--------|--------|
| OOM / to-space exhausted events | 0 during 7-day review window |
| RSS per instance | ≤ 65 GB |
| Average GC Pause Young | ≤ 250ms |
| Instance uptime | Continuous — no restarts triggered by GC |

---

## Rollback Plan

If instability is observed post-change:

1. Restore backup `.conf` files
2. `systemctl daemon-reload && systemctl restart malote@i2 malote@i5`
3. Verify instances return to previous heap (`-Xmx31G`) via `/proc/<pid>/cmdline`

---

## Follow-up Actions

| # | Action | Priority |
|---|--------|----------|
| 1 | Persist THP settings via Ansible `sysctl` role | Medium |
| 2 | Codify `JAVA_OPTIONS` changes in Ansible `group_vars` for `datanode-shared` so next deploy does not overwrite | High |
| 3 | Review GC logs after 7-day soak — confirm no OOM regression | High |
| 4 | Assess applying same G1GC profile to EU Shared DN1, DN3+ if load profile is similar | Low |
| 5 | Schedule periodic `meta.info` cleanup for expired tenants via cron or dailytasks role | Medium |
