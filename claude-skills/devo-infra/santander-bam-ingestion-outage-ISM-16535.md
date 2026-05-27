# Santander BAM Ingestion Outage - ISM-16535

**Date:** April 2, 2026 (detected) / May 7, 2026 (partial fix) / May 22, 2026 (fully resolved)  
**Ticket:** ISM-16535  
**Customer:** Santander (dedicated cluster, eu-west-1)  
**Affected domains:** `cert_gtb_bam` → writes to `oem.scib.bam.*` tables  
**Symptom:** No data in `oem.scib.bam.*` tables since April 1, 2026 at ~11:30 CEST

---

## Root Cause (Full Chain)

### Primary — NLB AZ Mismatch (resolved 2026-05-22)

Customer hardcoded `54.216.125.87` (eu-west-1a NLB node) in `kafka-devo.json`.  
`batrasio-santander-443-tcp` TG (TCP:443) only had batrasio-3 (`eu-west-1b`) registered.  
With cross-zone load balancing disabled, traffic hitting eu-west-1a had no target → connections dropped silently.

**Fix:** Added batrasio-2 (`i-035dcd19503f48a87`, eu-west-1a) to `batrasio-santander-443-tcp` TG on 2026-05-22.  
Ingestion ramped from ~477 → 12,000+ events/15min within minutes of fix.

See: [santander-nlb-batrasio-ISM-16535.md](santander-nlb-batrasio-ISM-16535.md)

### Secondary — TLS Intermediate CA Change (resolved 2026-05-07)

Devo rotated `wildcard.devo.io.crt` on April 1, 2026. The **intermediate CA changed**:

| | Intermediate CA | Root CA |
|-|----------------|---------|
| **Before (up to Apr 1)** | `DigiCert TLS RSA SHA256 2020 CA1` | DigiCert Global Root G2 |
| **After (Apr 1 onwards)** | `DigiCert Global G2 TLS RSA SHA256 2020 CA1` | DigiCert Global Root G2 |

Customer's BAM sender had a restricted trust store → TLS handshake failures on their side.

### Tertiary (also fixed 2026-05-07)
- `cert_gtb_bam` affinity entries missing from MySQL since Feb 7, 2026. Fixed via `adolfo affinity update -e santander_eu -d cert_gtb_bam --exec`.
- Cloudflare `santander_whitelist` missing BAM source IPs (`193.127.189.15`, `180.44.44.0/25`, `180.44.44.128/25`). Added May 7, 2026.

---

## How to Detect

```bash
# Check cert_gtb_bam daily traffic — should be 100k-300k events/day
source ~/.zshrc && maquisant 'from syslog.alcohol.stats where (subkind = "cert_gtb_bam" or subkind = "gtb_bam") and now()-24h <= eventdate < now() group every 1h by subkind select sum(partialEvents) as events'

# If showing only 1 event/day → cert trust issue or NLB routing issue
# Check oem.scib.bam.* for data
source ~/.zshrc && maquisant 'from oem.scib.bam where eventdate >= now() - 24h and eventdate < now() select eventdate, client limit 5'

# Verify customer IP is connecting to batrasio
ssh 172.27.18.235 "sudo ss -tn state established | grep 193.127.189"
ssh 172.27.57.246 "sudo ss -tn state established | grep 193.127.189"

# Verify what cert batrasio is presenting
ssh 172.27.57.246 "sudo openssl x509 -in /etc/logtrust/batrasio/keys/wildcard.devo.io.crt -noout -subject -issuer -dates -serial"
```

---

## Key Findings

- `gtb_bam` and `pre_gtb_bam` domains **never stopped** ingesting (they use different sending paths)
- Only `cert_gtb_bam` (port 443/1515 with cert impersonation) was affected
- `oem.scib.bam.*` tables are populated directly from `cert_gtb_bam` domain ingestion — NOT from Flows/Pipes
- The `my.app.gtb_bam.*` tables (alerts, flow_conciliados, etc.) continued working fine throughout
- Customer source IP: `193.127.189.15` — connects to batrasio on port 443

---

## Customer Communication

When customer claims "data is being sent" but Devo shows no ingestion:

1. Check `syslog.alcohol.stats` for `subkind = "cert_gtb_bam"` — if showing 1 event/day, it's a TLS or NLB routing issue
2. Check which batrasio IP customer is pointing to — verify it maps to a healthy NLB AZ with a registered target
3. Verify batrasio cert presented on port 443: `openssl s_client -connect <batrasio-ip>:443`
4. Check if intermediate CA changed recently
5. Ask customer to verify their trust store includes the full DigiCert chain:
   - `DigiCert Global Root G2`
   - `DigiCert Global G2 TLS RSA SHA256 2020 CA1`

---

## Current Santander Batrasio TLS Chain (as of April 2026)

```
*.devo.io  (CN, issued Mar 21 – Oct 5, 2026)
└── DigiCert Global G2 TLS RSA SHA256 2020 CA1
    └── DigiCert Global Root G2 (root, self-signed)
```

**Serial:** `0B63FF6FEBDEE13F00835AF240B35B51`  
**Cert file:** `/etc/logtrust/batrasio/keys/wildcard.devo.io.crt` on all Santander batrasios

---

## Santander Cluster Reference

| Component | Value |
|-----------|-------|
| NLB | `public-batrasio-santander` — see [santander-nlb-batrasio-ISM-16535.md](santander-nlb-batrasio-ISM-16535.md) |
| batrasio-2 | `172.27.18.235` (eu-west-1a) — handles `54.216.125.87` |
| batrasio-3 | `172.27.57.246` (eu-west-1b) — handles `52.48.53.0` |
| Metamalote | `172.27.25.107:10100` |
| Maqui alias | `maquisant` |
| BAM customer tables | `oem.scib.bam.*`, `my.app.gtb_bam.*`, `my.app.pre_gtb_bam.*` |
| BAM ingestion domain | `cert_gtb_bam` (cert impersonation, port 443/1515) |
| Customer source IPs | `193.127.189.15`, `180.44.44.0/25`, `180.44.44.128/25` |

---

## Fixes Applied

| Date | Fix |
|------|-----|
| 2026-05-06 | Affinity restored: `adolfo affinity update -e santander_eu -d cert_gtb_bam --exec` |
| 2026-05-07 | DN2 re-enabled; CF whitelist added for BAM source IPs |
| 2026-05-07 | Notified customer to update trust store for new DigiCert G2 intermediate CA |
| 2026-05-22 | Added batrasio-2 to `batrasio-santander-443-tcp` TG — fixed NLB AZ routing |

---

## Important: wildcard.devo.io Rotation History

| Backup | Valid From | Valid To | Intermediate CA |
|--------|-----------|---------|----------------|
| `pre_CHG-6250` (Jun 2024) | Apr 2023 | May 2024 | DigiCert TLS RSA SHA256 2020 CA1 |
| `keys_CHG-6924` (Aug 2024) | May 2024 | Jun 2025 | DigiCert TLS RSA SHA256 2020 CA1 |
| **Current** | **Mar 21, 2026** | **Oct 5, 2026** | **DigiCert Global G2 TLS RSA SHA256 2020 CA1** ← changed! |

**Lesson:** When rotating `wildcard.devo.io`, notify customers with restricted TLS trust stores if the intermediate CA changes.
