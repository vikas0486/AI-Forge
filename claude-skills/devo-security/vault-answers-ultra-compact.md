# Vault Security Answers - Ultra Compact

**1. Running?** YES - 8 EKS deployments, 24+ pods, 5 regions (US/EU/US3/APAC/NCSC), perfect multi-AZ (1 pod per AZ)

**2. Version:** 1.16.1 (all clusters)

**3. Deployment:** EKS StatefulSet, 3 replicas per cluster, Kubernetes

**4. Storage:** Integrated Storage (Raft), 3-node consensus, no external dependencies

**5. Backup:** US only - CronJob @2h to S3 (SUSPENDED 637 days). EU/US3/APAC/NCSC: None

**6. Unseal keys:** AWS KMS Auto-Unseal (most likely - pods auto-unseal after restart)

**7. Root token:** AWS Secrets Manager (KMS encrypted) - 5 secrets across regions

**8. Secondary cluster:** YES - 8 independent clusters (no replication), Active/Standby per cluster

**9. Secrets count:** ~100-150 across 38+ paths (AWS, DBs, API keys, certs, OAuth)

**10. Dependencies:** 15+ services - Critical: Devo Platform, GitLab, AWS, Databases. High: Grafana, PKI, NASS, Tapu

**Critical Action:** Re-enable US backup + deploy backups to 4 other regions (immediate)

**Score:** 8.0/10 (Production-ready, backup gaps)
