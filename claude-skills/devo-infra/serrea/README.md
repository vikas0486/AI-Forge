# CaixaBank Serrea Cluster - Operations Reference

**Cluster:** CaixaBank Dedicated Serrea (IBM Cloud EU-DE)
**Environment:** Production

## Nodes

| Node | Hostname | IP |
|------|----------|----|
| Serrea-1 | serrea-1-pro-cloud-caixa-ibm-eu-de-2 | 10.9.64.20 |
| Serrea-2 | serrea-2-pro-cloud-caixa-ibm-eu-de-3 | 10.9.128.20 |
| Serrea-3 | serrea-3-pro-cloud-caixa-ibm-eu-de-2 | 10.9.64.21 |

**HTTP Port:** 8855 | **Akka Port:** 2551

---

## HMAC Error Suppression (ISM-15453)

Suppress HMAC auth failures (ERROR → WARN) in log4j2.xml. Applied 2026-03-01.

**Apply config (all 3 nodes):**
```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo sed -i '/<\/Loggers>/i\\    <!-- Suppress HMAC authentication failures -->\\n    <Logger name=\"com.devo.lugin.hmac.services.UserDomainHMACAccessService\" level=\"WARN\"/>\\n    <Logger name=\"com.devo.web.common.api.auth.HMAC\" level=\"WARN\"/>' /etc/logtrust/serrea/log4j2.xml"
  ssh $node "sudo grep -A 2 'Suppress HMAC' /etc/logtrust/serrea/log4j2.xml"
done
```

**Rolling restart (one at a time):**
```bash
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo systemctl restart serrea" && sleep 30
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
```

**Verify:**
```bash
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq .
```

---

## Quick Health Check

```bash
# Service status + memory
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "=== $node ==="
  ssh $node "systemctl is-active serrea && ps aux | grep '[j]ava.*serrea' | awk '{printf \"Memory: %.1f GB, CPU: %.1f%%\n\", \$6/1024/1024, \$3}'"
done

# Cluster health
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq '{ok, cluster: .results.cluster.ok, mysql: .results.mysql.message, malote: .results.maloteLinq.message}'
```

---

## Memory Leak Detection

```bash
# OutOfMemoryError count per node
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "$node: $(ssh $node 'sudo grep -c OutOfMemoryError /var/log/serrea/serrea.log' 2>/dev/null || echo 0) OOM events"
done

# Connection leak warnings
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "$node: $(ssh $node 'sudo grep -c "Connection leak" /var/log/serrea/serrea.log' 2>/dev/null || echo 0) leak warnings"
done
```

---

## GC Statistics

```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo "=== $node ==="
  ssh $node "tail -10 /var/log/serrea/serrea.gc.log | grep -E 'Pause|GC\(' | tail -3"
done
```

---

## Connection Pool Status

```bash
# MySQL connections from database
/opt/homebrew/opt/mysql-client/bin/mysql -h "logtrustdb-production.c70tbv6xtaqr.eu-west-1.rds.amazonaws.com" \
  -u "logtrust" -p"z410(i7I25,3" -D "logtrust" -e "
  SELECT SUBSTRING_INDEX(host, ':', 1) as node, COUNT(*) as total,
         SUM(CASE WHEN command='Sleep' THEN 1 ELSE 0 END) as idle,
         SUM(CASE WHEN command!='Sleep' THEN 1 ELSE 0 END) as active
  FROM information_schema.PROCESSLIST
  WHERE SUBSTRING_INDEX(host, ':', 1) IN ('10.9.64.20', '10.9.128.20', '10.9.64.21')
  GROUP BY SUBSTRING_INDEX(host, ':', 1);" 2>&1 | grep -v Warning
```

---

## MySQL Host Blocking Recovery (IRCA-156)

If nodes are blocked (Error 1129 - too many connection errors):

```bash
# Test MySQL handshake
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "python3 << 'EOF'
import socket, struct
host = 'logtrustdb-production.c70tbv6xtaqr.eu-west-1.rds.amazonaws.com'
sock = socket.socket(); sock.connect((host, 3306)); data = sock.recv(4096)
if data[4] == 0xFF:
    print(f'BLOCKED: {data[13:].decode(errors=\"ignore\")}')
else:
    print('OK: Connected')
sock.close()
EOF
"

# Fix: FLUSH HOSTS using root creds from ~/.adolfo.yaml
mysql -h logtrustdb-production.c70tbv6xtaqr.eu-west-1.rds.amazonaws.com \
  -u root -p"<password from ~/.adolfo.yaml>" -e "FLUSH HOSTS;" 2>&1 | grep -v Warning
```

---

## Phase 3: Code Fixes (Pending)

Status: Awaiting source code access. Patterns documented in `04_java_code_fixes.md` — replace unbounded `HashMap` caches with Guava `CacheBuilder` (bounded + expiring), add try-with-resources for JDBC connections, fix Hibernate session cleanup in finally blocks.

---

## Configuration Files

| File | Path |
|------|------|
| Properties | `/opt/logtrust/serrea/conf/logtrust.properties` |
| EHCache | `/opt/logtrust/serrea/conf/ehcache.xml` |
| Log4j2 | `/etc/logtrust/serrea/log4j2.xml` |
| JVM / systemd | `/etc/systemd/system/serrea.service` (Xms20G -Xmx20G) |
| Environment | `/etc/logtrust/serrea/enviroment.properties` |
| MySQL creds (admin) | `~/.adolfo.yaml` (eu_pro) |

## Script Files

```
~/Documents/Scripts/serrea-cluster/memory-leak-fixes/
├── deploy_memory_leak_fixes.sh
├── monitor_memory_leaks.sh
├── 01_hikaricp_leak_detection.properties
├── 02_bounded_cache_config.properties
├── 03_ehcache.xml
├── 04_java_code_fixes.md
└── POST_DEPLOYMENT_STATUS_20260414.txt
```

---

**Last Updated:** 2026-04-20
**Status:** All 3 nodes healthy — memory leak fixes deployed 2026-04-14, stable since
