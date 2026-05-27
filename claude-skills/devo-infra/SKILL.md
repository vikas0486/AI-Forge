---
name: devo-infra
description: Infrastructure deployment and operations — Ansible (datanodes, myapp-loader, alcohol, MISP), Kubernetes EKS (4 AWS accounts, 20 clusters, kube alias), Malote JVM tuning, Serrea HMAC suppression, SOAR (LogicHub/XSOAR). Source of truth: automation repo at /Users/vikash.jaiswal/Documents/Repository/automation
argument-hint: "[component] [issue]"
tags: [ansible, kubernetes, eks, datanode, alcohol, myapp-loader, misp, soar]
---

## ⛔ CRITICAL — Never Use `find` on Datanodes

**NEVER run `find /var/logt ...` or any recursive file search on datanode hosts.**  
Datanodes store TBs of data. A `find` will run for hours, peg disk I/O, and degrade live query performance for all customers.

**Use instead:**
- Maqui: `from system.delegated.internal.tableFile where ...` — indexed, fast
- Maqui: `from system.delegated.internal.table where ...` — for table metadata
- `ls` only on a fully-known specific path (exact trunk/bucket/date/customer)
- Asilo commander `status` to understand what partition slots Asilo expects

---

## Platform Architecture Overview

Devo is a multi-tenant log analytics platform deployed across 6 active environments:

| Environment | Cloud | Region | Admin URL |
|---|---|---|---|
| AWS EU Pro | AWS | eu-west-1 | eu.devo.com |
| AWS US Pro | AWS | us-east-1 | us.devo.com |
| AWS US Pro3 | AWS | us-east-2 | us3.devo.com |
| AWS AP Pro | AWS | ap-southeast-1 | apac.devo.com |
| AWS EU Santander | AWS | eu-west-1 | dataplatform.san.devo.com |
| GCP EU TEF | GCP | europe-west1 | sasr.devo.com |

**Core service stack per environment:**
```
Batrasio (collector/relay, port 1514/1515)
    → Alcohol (log ingestion, 8 instances per datanode, port varies)
    → Datanode (storage, malote query engine, port 10100+)
    ← Metamalote (query router/load balancer, port 10100)
    ← Asilo (aggregation engine)
    ← Lomana + Mason Agent (metadata/lookup distribution — lookup ops in /devo-tools)
    ← Pilot (streaming analytics / Flow)
    ← Chasys (event classification, monitoring alerts)
```

**Key internal endpoints:**
| Service | EU | US |
|---|---|---|
| MySQL (RDS) | `rds.shared.pro.aws.eu-west-1.devo.internal:3306` | `amazon.usa-east.dbpro.logtrust.net:3306` |
| Metamalote LB | `metamalote-eu.devo.internal:10100` | `metamalote-us.devo.com:10100` |
| Batrasio collector | `batrasio.shared.pro.aws.eu-west-1.devo.internal:1514` | `batrasio.shared.pro.aws.us-east-1.devo.internal:1514` |
| Self collector | `collector-self-eu.devo.internal:1514` | `collector-self-us.devo.internal:1514` |
| RabbitMQ | `rabbitmq-eu.devo.com` | — |
| API (internal) | `api-internal-eu.devo.com` | `api-internal-us.devo.com` |
| APIv2 (Serrea) | `apiv2-eu-internal.devo.com` | `apiv2-us-internal.devo.com` |

---

## Component Versions (AWS EU Pro — as of 2026-05)

| Component | Version | Notes |
|---|---|---|
| malote / metamalote | 2.0.12 | collection-malote 2.73.11 |
| batrasio | 8.13.1 | collection-batrasio v2.4.26 |
| alcohol | 2.4.0 | config 2.9.6, tech-int 0.4.38, tech-ext 0.15.168 |
| asilo engine | 7.5.5 | commander 5.4.5 |
| mason_agent | 2.6.13 | collection-mason 1.14.5 |
| barcenas | 8.0.2 | role v8.0.4 |
| licor | 4.7.2 | role v1.8.3 |
| pilot-server | 1.25.2 | role v1.14.2 |
| pilot | 0.11.4 | role v1.20.0 |
| chasys | role v1.22.0 | |
| serrea (APIv2) | 4.3.3 | |
| myapp-loader | v2.1.4 | |
| Java | 17 (datanode), 11 (metamalote/monitoring) | |
| Node.js | 14.21.2 | role v1.0.1 |
| MySQL | 5.7.26 | RDS, not managed by Ansible |
| Redis | 5.0.5 | |
| OrientDB | 3.2.18 | US only |

---

## Ansible Roles Reference

All roles from `gitlab.com/devo_corp/platform/ansible/roles`. Clone to `/Users/vikash.jaiswal/Documents/Repository/Roles/`.

**Core platform roles:**
| Role | GitLab name | EU Pro ver | Purpose | Key Playbooks |
|---|---|---|---|---|
| devoinc.datanode | ansible-datanode | v2.6.7 | Datanode deployment | datanode.yml |
| devoinc.datanode_dailytasks | ansible-dn-dailytasks | v1.12.6 | Daily maintenance | datanode-dailytask.yml, datanode.yml |
| collection-malote | collection-malote | 2.73.11 | Malote + metamalote + maqui + lomana | malote.yml, metamalote.yml, datanode.yml |
| collection-batrasio | collection-batrasio | v2.4.26 | Batrasio data relay | batrasio.yml, datanode.yml |
| collection-mason | collection-mason | 1.14.5 | Mason metadata distribution | mason-agent.yml, datanode.yml |
| devoinc.alcohol | ansible-alcohol | v2.17.8 | Log collector (8 instances/node) | alcohol.yml, alcohol-restart-procedure.yml, datanode.yml |
| devoinc.asilo | ansible-asilo | v1.16.2 | Aggregation engine | asilo.yml |
| devoinc.asilo_inspector | ansible-asilo-inspector | v1.0.1 | Asilo monitoring | asilo-inspector.yml |
| devoinc.lomana | ansible-lomana | (via collection) | Metadata distribution orchestrator (see `/devo-tools` for lookup ops) | lomana.yml |
| devoinc.mmupdater | ansible-maduro | v1.3.0 | Metadata updater | lomana.yml |
| devoinc.myapp-loader | ansible-myapp-loader | v2.1.4 | my.app table distribution | myapp-loader.yml |
| devoinc.pilot | ansible-pilot | 1.20.0 | Streaming analytics (Flow) | pilot.yml |
| devoinc.pilot-server | ansible-pilot-server | 1.14.2 | Pilot server | pilot-server.yml |
| devoinc.chasys | ansible-chasys | v1.22.0 | Event classification / alerting | chasys.yml |
| devoinc.barcenas | ansible-barcenas | v8.0.4 | Time-series data manager | barcenas.yml, datanode.yml |
| devoinc.licor | ansible-licor | v1.8.3 | Data compression | licor.yml, datanode.yml |
| devoinc.cotillo | ansible-cotillo | v1.0.4 | Log compression | datanode.yml |
| devoinc.casperable-updater | ansible-casperable-updater | v1.4.0 | Aggregation cache updater | casperable-updater.yml |
| devoinc.resilient-infra | ansible-resilient-infra | v1.1.0 | Health-check agents (auto-healing) | deploy-datanode-resilience.yml |
| devoinc.monitor | ansible-devo-monitor | v1.2.1 | Devo monitoring agent | devo-monitor.yml |
| devoinc.alertmanager | ansible-alertmanager | v4.1.2 | Alert management | monitoring.yml |
| devoinc.prometheus | ansible-prometheus | v7.0.3 | Metrics collection | monitoring.yml |
| devoinc.prometheus-rules | ansible-prometheus-rules | master | Alert rules | monitoring.yml |
| devoinc.netdata | ansible-netdata | v5.6.15 | System monitoring | netdata.yml |
| logtrust.base | ansible-base | v3.0.5 | Base system setup | almost all playbooks |
| devoinc.bootstrap | ansible-bootstrap | v1.1.3 | System bootstrap | (auxiliary) |
| devoinc.logrotate | ansible-logrotate | v1.3.0 | Log rotation | datanode.yml, batrasio.yml, asilo.yml |
| devoinc.sysctl | ansible-sysctl | v1.2.0 | Kernel parameters | lomana.yml |
| devoinc.nodejs | ansible-nodejs | v1.0.1 | Node.js runtime | datanode.yml, batrasio.yml, alcohol.yml |
| devoinc.offboarding | (standalone) | master | Customer offboarding | offboarding.yml |

**Collection version differences per environment:**
| Collection | EU Pro | US Pro | US Pro3 | AP Pro | Santander | GCP TEF |
|---|---|---|---|---|---|---|
| collection-malote | **2.73.11** | 2.73.8 | 2.73.8 | 2.73.8 | 2.73.8 | 2.73.8 |
| collection-mason | **1.14.5** | 1.14.1 | 1.14.2 | 1.14.1 | 1.14.1 | 1.14.2 |
| collection-batrasio | **v2.4.26** | 2.4.17 | 2.4.17 | 2.4.22 | v2.4.25 | 2.4.17 |

EU Pro is always the most up-to-date. US Pro3 runs older base (logtrust.base v2.2.0 vs v3.0.5) and older pilot (1.13.0 vs 1.20.0).

---

## Key Playbooks

All at `/Users/vikash.jaiswal/Documents/Repository/automation/ansible/playbooks/`

| Playbook | Targets | Roles Used | Purpose |
|---|---|---|---|
| `datanode.yml` | datanode | base, logrotate, datanode, nodejs, openjdk, alcohol, batrasio, maqui, malote, metamalote, mason_agent, licor, cotillo, datanode_dailytasks, barcenas | Full datanode deploy |
| `metamalote.yml` | `{{ host }}` | base, rsyslog, maqui, metamalote | Metamalote deploy |
| `batrasio.yml` | batrasio | base, logrotate, nodejs, batrasio | Batrasio relay deploy |
| `alcohol.yml` | datanode | base, rsyslog, nodejs, alcohol | Alcohol redeploy (preserves techs/detechs/keys) |
| `alcohol-restart-procedure.yml` | `{{ host }}` | alcohol (restart-procedure task) | Production-safe restart (affinity disable→restart→re-enable) |
| `alcohol-restart-procedure-old.yml` | `{{ host }}` | alcohol | Legacy restart (deprecated envs only) |
| `alcohol-techs.yml` | datanode | alcohol (techs task) | Deploy alcohol techs only |
| `asilo.yml` | asilo | base, logrotate, openjdk, asilo | Asilo aggregation engine deploy |
| `asilo-inspector.yml` | asilo_inspector | openjdk, asilo_inspector | Asilo monitoring deploy |
| `mason-agent.yml` | mason-agent | mason_agent | Mason agent deploy |
| `mason-agent-service-restart.yml` | mason-agent | (systemd) | Mason agent restart |
| `myapp-loader.yml` | metamalote-general | myapp-loader | myapp-loader deploy |
| `lomana.yml` | lomana | base, logrotate, sysctl, openjdk, lomana, mmupdater | Lomana + mmupdater deploy |
| `pilot.yml` | pilot | base, logrotate, rsyslog, pilot | Pilot (Flow) deploy |
| `monitoring.yml` | monitoring | base, repositories, openjdk, prometheus, prometheus-rules, prometheus-pushgateway, alertmanager, devoalerts | Full monitoring stack |
| `chasys.yml` | chasys | base, openjdk, chasys | Chasys event classifier |
| `matasmafias.yml` | matasmafias | (S3 sync tasks) | Sync mata/mafia defs → `/etc/logtrust/malote/defs` |
| `devo-monitor.yml` | `{{ host }}` | rsyslog, monitor | Devo monitoring agent |
| `licor.yml` | `{{ host }}` | base, logrotate, rsyslog, monitor, licor | Licor data compression |
| `barcenas.yml` | barcenas | logrotate, barcenas | Barcenas time-series manager |
| `maqui.yml` | `{{ host }}` | openjdk, maqui | Maqui client deploy |
| `deploy-datanode-resilience.yml` | datanode/metamalote/batrasio | resilient-infra | Health-check agent deploy |
| `datanode-dailytask.yml` | datanode | datanode_dailytasks | Daily maintenance (move/compress/delete) |
| `datanode-trash-cleanup.yml` | datanode | (dynamic maqui cmds) | Trash-amnesia cleanup |
| `malote-service-restart.yml` | datanode | (systemd) | Malote instance restart |
| `metamalote-service-restart.yml` | metamalote | (systemd + port checks) | Metamalote restart |
| `metamalote-HA-service-restart.yml` | metamalote | (systemd HA) | HA-aware metamalote restart |
| `batrasio_service_restart.yml` | batrasio | (AWS ELB + systemd) | Batrasio restart with ALB deregistration |
| `tabula_rasa.yml` | localhost | (Tara CLI) | Domain affinity rebalancing |
| `offboarding.yml` | localhost | offboarding | Customer domain offboarding |
| `kafka-pipeline.yml` | kafka/zookeeper | base, rsyslog, Confluent roles | Confluent Kafka pipeline (US only) |
| `injection.yml` | injection | base, injection | Injection service deploy |
| `relay.yml` | `{{ host }}` | base, relay | Relay deploy |
| `base.yml` | all | base | Base system hardening |
| `users.yml` | all | (user tasks) | User account management |
| `cis-ubuntu.yml` | all | cis-ubuntu | CIS Ubuntu hardening |

---

## JVM & Memory Configuration

| Service | Heap | GC | Notes |
|---|---|---|---|
| Metamalote (EU Pro) | -Xms4G -Xmx80G | G1 | x2gd.2xlarge (8-core/124GB RAM). +UseCompressedOops +ObjectAlignmentInBytes=8 allows >32GB. Matches US. (CHG-10643) |
| Malote (datanode) | -Xms17G -Xmx17G | G1 | Per instance; configure via JAVA_OPTIONS in .conf |
| Asilo (US) | 31g | — | Max metaspace 256m |
| Goloso | -Xms6G -Xmx6G | — | |

**Critical:** Per-instance `malote.javaoptions` files are NOT read. Use `JAVA_OPTIONS` env var in `/etc/logtrust/systemd/malote/<hostname>/i?.conf`

---

## Customer Affinity / Delegation

Metamalotes use delegate tags to route queries to dedicated datanodes per tenant:

| Tag | Routes to | Notes |
|---|---|---|
| `cloud,common,i30` | datanode-shared | Multi-tenant default |
| `cloud,self` | datanode-self | Internal platform data |
| `cloud,ipanda` | datanode-panda | PandaSecurity |
| `cloud,caixabank` | metamalote-middle-caixabank | CaixaBank dedicated middle layer |
| `cloud,bitdefender` | metamalote-middle-bitdefender | Bitdefender dedicated |
| `cloud,catawiki` | datanode-catawiki | Catawiki — added MR-134 (CHG-10531); was missing, causing Asilo deletion failures |
| `cloud,talion` | datanode-talion | Talion |
| `cloud,envision,bitkub,traveloka` | datanode-apac (shared-apse1) | APAC shared |

Delegation tree is controlled by the `installation` table in RDS — NOT conf files. See **Datanode Decommission** section.

---

## Network & Ports

| Port | Service |
|---|---|
| 1514 | Batrasio/Alcohol primary collector |
| 1515 | Alcohol impersonated/internal relay |
| 10100 | Metamalote LB (query entry point) |
| 10101–10116 | Malote instances (per-datanode, per-instance) |
| 3306 | MySQL (RDS) |
| 27017 | MongoDB |
| 6661 | OAuth2 server (internal) |

---

## S3 Buckets

| Purpose | EU | US |
|---|---|---|
| Deployments | `logtrust-eu-deployments` | `logtrust-eu-deployments` |
| MyApp | `logtrust-myapp` | `logtrust-myapp-usa` |
| Aggregation cache | `logtrust-myaggregationtask` | `logtrust-myaggregationtask-usa` |
| Relay certs | `logtrust-eu-relay-certs-pro` | — |
| Asilo | — | `devo-asilo-prod-us` |
| Datanode backup | — | `logtrust-backup-datanodes-usa` |

---

## Key Paths on Hosts

```
/etc/logtrust/alcohol-new/          ← Alcohol config
/etc/logtrust/systemd/malote/       ← Per-instance malote .conf files
/etc/logtrust/malote/defs/          ← Matasmafias definitions (mata/mafia)
/etc/logtrust/malote/defs/myapp-custom/  ← MyApp custom definitions
/opt/logtrust/malote/               ← Malote binary home
/opt/logtrust/alcohol-new/          ← Alcohol binary
/opt/nodejs/                        ← Node.js runtime
/var/log/malote/                    ← Malote logs + GC logs
/var/log/metamalote/                ← Metamalote logs
/var/log/alcohol/                   ← Alcohol logs
/var/log/cotillo/                   ← Compression logs
/var/log/barcenas.log               ← Barcenas logs
/var/logt/                          ← All data storage (trunks/buckets)
/var/logt/backup/logs/licor         ← Licor logs
```

---

## SSH Default — Always Use sudo

**CRITICAL:** SSH keys are pre-deployed to all Devo datanodes, serreas, metamalotes, and other infra nodes. Direct SSH works without a password. However, **all commands run on the remote side MUST use `sudo`** — most system paths are permission-restricted.

```bash
# CORRECT
ssh datanode-2-pro-cloud-shared-aws-eu-west-1 "sudo cat /etc/logtrust/..."
ssh datanode-2-pro-cloud-shared-aws-eu-west-1 "sudo systemctl restart malote@i2"
ssh datanode-2-pro-cloud-shared-aws-eu-west-1 "sudo bash -c 'echo always > /sys/kernel/mm/...'"

# WRONG — will get Permission denied
ssh datanode-2-pro-cloud-shared-aws-eu-west-1 "cat /etc/logtrust/..."
```

---

## Key Paths

**Local:**
- Automation: `/Users/vikash.jaiswal/Documents/Repository/automation`
- Roles: `/Users/vikash.jaiswal/Documents/Repository/Roles/` — manually created dir; clone individual roles here as needed
- Terraform Environments: `/Users/vikash.jaiswal/Documents/Repository/Terraform/Environments/` — clone environment repos here
- Terraform Modules: `/Users/vikash.jaiswal/Documents/Repository/Terraform/Modules/` — clone module repos here (currently empty)

**Clone a role:**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/Roles
source ~/.zshrc && git clone git@gitlab.com:devo_corp/platform/ansible/roles/ansible-<rolename>.git
```

**Currently cloned roles:**
`ansible-resilient-infra`, `ansible-datanode`, `ansible-alcohol`, `ansible-asilo`, `ansible-pilot`, `ansible-pilot-server`, `ansible-barcenas`, `ansible-chasys`, `ansible-myapp-loader`, `ansible-dn-dailytasks`, `ansible-licor`, `ansible-mmupdater`, `ansible-offboarding`, `ansible-casperable-updater`, `ansible-base`, `collection-malote`, `collection-batrasio`, `collection-mason`

**Clone terraform repos:**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/Terraform/Environments
source ~/.zshrc && git clone git@gitlab.com:devo_corp/platform/terraform/environments/<env>.git

cd /Users/vikash.jaiswal/Documents/Repository/Terraform/Modules
source ~/.zshrc && git clone git@gitlab.com:devo_corp/platform/terraform/modules/<module>.git
```

**Currently cloned terraform environments:**
`prod-eu`, `prod-us`, `prod-us-3`, `prod-apac`, `prod-caixa-ibm`, `prod-ncsc-bahrain`, `prod-telefonica-gcp`

**GitLab:**
- Automation: `gitlab.com/devo_corp/platform/ansible/environments/automation`
- All Ansible roles: `gitlab.com/devo_corp/platform/ansible/roles`
- Terraform Environments: `gitlab.com/devo_corp/platform/terraform/environments`
- Terraform Modules: `gitlab.com/devo_corp/platform/terraform/modules`

---

## Repository Map

All repos cloned at `/Users/vikash.jaiswal/Documents/Repository/`:

| Repo | Purpose | Relevance |
|---|---|---|
| `automation` | Ansible playbooks + inventory (source of truth for infra deploy) | Core |
| `Roles/` | Cloned Ansible roles (see above) | Core |
| `Terraform/Environments/` | IaC per environment (prod-eu, prod-us, prod-us-3, prod-apac, prod-caixa-ibm, prod-ncsc-bahrain, prod-telefonica-gcp) | Core |
| `jenkinsfiles` | Jenkins job definitions (seed jobs, 76+ Groovy job files) | Core |
| `hydra` | ArgoCD GitOps — K8s manifests for all services | Core |
| `cerberus` | Deployment promotion pipeline: Stage → Int → Prod, MR creation, Helm | Core |
| `matasmafias` | Malote/mafia table definitions per environment (cloud, gcp, sant, on-prem) | Core |
| `alcohol-techs-external` | External Alcohol tech packages (cloud-specific, per region) | Core |
| `alcohol-techs-internal` | Internal Alcohol techs (R&D maintained, core minimal config) | Core |
| `templates-gitlab-cicd` | Reusable GitLab CI/CD pipeline templates (versioning, build, deploy, vuln) | Core |
| `updating-and-deploying-cloud-collectors` | Cloud collector CI/CD: build → scan → ECR → EKS deploy (6 envs, OIDC) | Core |
| `webapp` | Main Devo webapp (Java/Gradle backend + JS frontend, Jetty/Tomcat) | Core |
| `automation_devtool` | DevOps automation — CI/CD tooling, release automation, Vagrant local dev | Medium |
| `cerberus` | Deployment orchestration + promotion | High |
| `datanode-observability` | Monitoring dashboards/alerts for datanodes (mirror of gitlab.devotools.com/engineering/observability/) | Medium |
| `infra-deployment` | Infrastructure deployment configs | Medium |
| `operations` | CloudOps operations runbooks | Medium |
| `redis-cluster` | Helm chart: Redis 6.2.7, 6-replica K8s cluster | Medium |
| `redada` | Dashboard widget/grid framework (QuVis squad) | Low |
| `scheduler-ui` | Vue UI for Cronos scheduler API (localhost:5173) | Low |
| `usage-analytics` | Platform usage metrics/analytics app | Low |
| `misp-k8s-deployment` | MISP K8s Helm deployment (see MISP section) | Low |
| `misp-secops` | MISP security ops automation + lookup generation | Low |
| `ansible-myapp-loader` | Standalone myapp-loader Ansible role repo | Low (role in Roles/) |

---

## Ansible Access

> **IMPORTANT:** For all operational Ansible commands — disk scanning (`du` glob patterns), service management, GC log analysis, Adolfo datanode enable/disable, rsync, file distribution, user management, malote/metamalote ops — see **`/devo-devtool` → "Ansible — Infrastructure Management"** section. That skill is the single source of truth for Ansible operational patterns. This section covers inventory layout and access config only.

**Config:** `/Users/vikash.jaiswal/Documents/Repository/automation/ansible.cfg`

**Inventory Locations (active environments):**

**Deprecated (do not use):** `aws/ca/pro`, `aws/us/poc`, `aws/eu/tef`, `aws/me/ncscbh`

#### aws/eu/pro
| Type | Groups |
|---|---|
| Datanodes | `datanode-shared`, `datanode-self`, `datanode-deloitte`, `datanode-deloitte-uk`, `datanode-deloitte-query`, `datanode-hybrid-indra01`, `datanode-bitdefender` (+4 groups), `datanode-talion`, `datanode-caixabank`, `datanode-shared-euw1-use1`, `datanode-shared-apse1`, `datanode-gitlab`, `datanode-panda`, `datanode-catawiki` |
| Metamalotes | `metamalote-general`, `metamalote-pre`, `metamalote-bitdefender` (×4), `metamalote-caixabank`, `metamalote-middle-caixabank`, `metamalote-middle-bitdefender`, `metamalote-euw1-use1`, `metamalote-euw1-apse1`, `metamalote-middle-euw1-peering-endpoint` |
| Batrasios | `batrasio-shared`, `batrasio-self`, `batrasio-deloitte`, `batrasio-deloitte-uk`, `batrasio-talion`, `batrasio-caixabank`, `batrasio-shared-apac`, `batrasio-euw1-use1`, `batrasio-euw1-apse1`, `batrasio-euw1-euw2` |
| Other | `asilo`, `asilo_inspector`, `monitoring-active/dr`, `matasmafias`, `lomana`, `pilot`, `redis`, `injection`, `orientdb-*`, `relay-caixabank`, `api-serrea-caixabank`, `malcom` |

#### aws/eu/santander
| Type | Groups |
|---|---|
| Datanodes | `datanode-santander` |
| Metamalotes | `metamalote-general` |
| Batrasios | `batrasio-public` |
| Other | `asilo`, `asilo_inspector`, `matasmafias`, `monitoring-active/dr` |

#### aws/us/pro
| Type | Groups |
|---|---|
| Datanodes | `datanode-shared` (+4 groups), `datanode-self`, `datanode-nielsen` (+3 groups), `datanode-equifax` (5 regions), `datanode-criticalstart`, `datanode-ultabeauty`, `datanode-hrblock`, `datanode-teconnectivity`, `datanode-capgemini`, `datanode-cslbehring`, `datanode-sandisk`, `datanode-nycedu`, `datanode-lendingtree`, `datanode-csg`, `datanode-talion`, `datanode-texascapital`, `datanode-mxenabled`, `datanode-assuredpartners` |
| Metamalotes | `metamalote-general`, `metamalote-general-dr`, `metamalote-pre`, `metamalote-shared` (×4), `metamalote-middle-shared`, `metamalote-nielsen` (×3), `metamalote-middle-nielsen`, `metamalote-middle-equifax`, `metamalote-use1-apse2` |
| Batrasios | `batrasio-shared`, `batrasio-self`, `batrasio-internal`, `batrasio-sandisk`, `batrasio-criticalstart`, `batrasio-hrblock`, `batrasio-use1apse2/euw1/euw2/cac1/aps1` |
| Other | `asilo`, `matasmafias`, `matasmafias-dr`, `lomana`, `pilot`, `injection`, `kafka_broker`, `kafka-relay`, `kastle`, `scuba`, `kafka-pipeline`, `alcohol-techs`, `orientdb-*`, `zookeeper`, `bastion`, `deeptrace-proxy/customer`, `mongodb-*`, `relay`, `monitoring-active/dr` |

#### aws/us/pro3
| Type | Groups |
|---|---|
| Datanodes | `datanode-shared`, `datanode-self`, `datanode-trustwave`, `datanode-dr-trustwave`, `datanode-deepseas`, `datanode-trustwave-euw1/apse2`, `datanode-dr-trustwave-euw1/apse2` |
| Metamalotes | `metamalote-general`, `metamalote-dr` |
| Batrasios | `batrasio-shared`, `batrasio-self`, `batrasio-trustwave`, `batrasio-dr-trustwave`, `batrasio-trustwave-euw1/apse2`, `batrasio-dr-trustwave-euw1/apse2` |
| Other | `asilo`, `monitoring-active/dr`, `devoalerts` |

#### aws/ap/pro
| Type | Groups |
|---|---|
| Datanodes | `datanode-shared-ap1/ap2/ap3`, `datanode-self` |
| Metamalotes | `metamalote-general` |
| Batrasios | `batrasio-general-ap1/ap2/ap3` |
| Other | `asilo`, `matasmafias`, `deeptrace`, `api-alerts`, `kafka_broker`, `kafka-relay`, `kastle`, `lookups`, `monitoring-active/dr`, `devoalerts` |

#### gcp/eu/tef
| Type | Groups |
|---|---|
| Datanodes | `datanode-tefsistemas` (24 nodes), `datanode-imagenio` (21 nodes), `datanode-1002` (2 nodes) |
| Metamalotes | `metamalote-general`, `metamalote-tefsistemas`, `metamalote-imagenio` |
| Batrasios | `batrasio-shared` |
| Other | `asilo`, `asilo-inspector`, `matasmafias`, `lomana`, `pilot-general/custom/ps`, `injection`, `injection-ipebot`, `auxiliary`, `monitoring-active/dr`, `devoalerts` |

**Node Naming:**
- Datanodes: `datanode[1-9]-<account>-cloud-<env>-<cloud>-<region>`
- Metamalotes: `metamalote-[1-9]-<env>-cloud-<env>-<cloud>-<region>`

**EU Pro — metamalote-general (10 nodes):**
`metamalote-{1..10}-pro-cloud-general-aws-eu-west-1`

**Common Ansible Commands:**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation

# List inventory
ansible-inventory -i ansible/environments/aws/eu/santander/hosts --list

# Ping group
ansible all -i ansible/environments/aws/eu/santander/hosts -m ping

# Run shell command
ansible datanode-santander -i ansible/environments/aws/eu/santander/hosts -m shell -a "df -h /var/logt/backup"

# Install roles
ansible-galaxy install -r ansible/requirements-<region>.yml --force
```

**Ansible vars:** `ansible_user=ubuntu`, `ansible_become=yes`, `ansible_ssh_private_key_file=~/.ssh/id_rsa`

**Inventory example (Santander):**
```ini
[datanode-santander]
datanode1-santander-cloud-shared-aws-eu-west-1 ansible_host=172.27.30.47
datanode2-santander-cloud-shared-aws-eu-west-1 ansible_host=172.27.28.41

[datanode-santander:vars]
ansible_user=ubuntu
ansible_become=yes
```

---

## Ansible Roles — Detail Reference

### Core Services

| Service | Systemd Unit | Listen Ports | Config Path | Data Path | JVM / Runtime |
|---|---|---|---|---|---|
| **Malote** (per-instance) | `malote@i0..iN.service` + `malote.target` | 10101+ (base; 2 ports default) | `/etc/logtrust/malote-conf/` | `/var/logt/tr*/b*/t*/` | Java, -Xms17G -Xmx17G (prod), 1M FD limit |
| **Metamalote** | `metamalote@.service` + `metamalote.target` | 10100 (2 ports default) | `/etc/logtrust/malote/` | `/var/logt/data/malote/` | Java, -Xms4G -Xmx80G (EU Pro, CHG-10643), 5M FD limit |
| **Malote-Controller** | `malote-controller.service` | 10000 (health check), JDBC 10100 | `/etc/logtrust/malote-controller/malote-controller.conf` | — | -Xms128m -Xmx128m, poll 2000ms |
| **Batrasio** | `batrasio.service` | 1514 (TCP log), 1515 (logDomain), 3030 (metrics/HTTP) | `/etc/logtrust/batrasio/batrasio.conf` | — | Node.js 12.22.6, 2 workers, 1M FD limit |
| **Alcohol** | `alcohol@i0..i7.service` (8 per node) | 80, 443, 1514, 6514 (ext); 1515 (int relay) | `/etc/logtrust/alcohol-new/` | — | Node.js 14.21.2, 8 instances |
| **Mason-Agent** | `mason-agent.service` | None (RabbitMQ consumer, AMQP 5672) | `/etc/logtrust/mason-agent/` | `/var/logt/data/malote/udlu` (see `/devo-tools` for lookup ops) | -Xms1G -Xmx1G |
| **Mason-Lodge** | `mason_lodge.service` | None (AMQP 5672) | `/etc/logtrust/mason-lodge/` | — | -Xms512m -Xmx512m |
| **Asilo** | `asilo-engine.service` | None | `/etc/logtrust/asilo/` | — | Java, -Xms16G -Xmx16G (EU), 31G (US) |
| **Pilot** (legacy) | `pilot.service` | 11011, 11012 | `/etc/logtrust/pilot/contexts/conf/` | — | -Xms512M -Xmx512M |
| **Pilot-Server** | `pilot-server.service` | 8081 (HTTP API) | `/etc/logtrust/pilot/` | — | -Xms1G -Xmx1G, GraalVM 21.2.0 |
| **Chasys** | `chasys.service` | 18888 (HTTP) | `/etc/logtrust/chasys/` | — | -Xms1g -Xmx4g |
| **Barcenas** | cron-based (no systemd service) | — | `/opt/logtrust/barcenas/etc/` | — | S3/GCP/AZ backend |
| **Licor** | `licor.service` | — | `/etc/logtrust/licor/` | — | -Xms512m -Xmx4g, 16 index threads |
| **MyApp-Loader** | service (cron-triggered) | — | `/etc/logtrust/myapp-loader/` | — | Python 3 |
| **Dailytasks** | cron `@00:31` | — | Scripts at `/usr/local/bin/daily_*.sh` | Logs `/var/log/daily_*.log` | Bash |
| **Health-Check-Agent** | `health-check-agent.service` | — | — | `/var/log/health-check/agent.log` | Bash, 60s interval |
| **MmUpdater** | K8s CronJob | — | — | — | MaxMind GeoIP update |
| **Casperable-Updater** | service | — | `/opt/logtrust/casperable-updater/` | — | -Xms512m -Xmx512m |

### Role — ansible-datanode
**Purpose:** Configures storage, networking, and disk layout on datanodes. Dependency for all other datanode-resident services.

**Key vars:**
- `datanode_use_bcache` — legacy (yng/old/t02) vs WSBC (t00/t01/t02)
- `datanode_disk_layout` — instance type (e.g. `i3.16xlarge`)
- `datanode_swap_Mb` — swap (default: 32GB)
- `datanode_raid_level` — RAID level (default: 10)
- `datanode_tier_names` — dynamically computed tier name mapping

**Tasks:** Load AWS facts → configure sysctl → deploy aliaser → set up LVM/RAID/bcache → create ZFS pools (optional) → set queue scheduler.

### Role — ansible-alcohol
**Purpose:** Deploys 8 alcohol collector instances per datanode.

**Config:** `/etc/logtrust/alcohol-new/current/index.alc.js`  
**Binary:** `/opt/logtrust/alcohol-new/current → releases/<version>/`  
**Key vars:**
- `alcohol_auth_service` — `oauth` or `tapu`
- `alcohol_max_event_size` — 32MB default
- `alcohol_http_input_enabled` — HTTP input (default true)
- `alcohol_log_write_ops` — 100 legacy / 10 bcache

**Disable restart handler** with `alcohol_disable_restart_handler: true` for controlled rolling restarts.

### Role — ansible-asilo
**Purpose:** Deploys Asilo aggregation/deletion engine. Two components: asilo-engine and asilo-commander.

**Key vars:**
- `asilo_memory` — JVM heap (default 1g; EU prod sets 16g)
- `asilo_engine_id` — engine identifier
- `asilo_malote` — metamalote LB address
- `asilo_max_concurrent_delete_commands` — default 3

### Role — collection-malote / ansible-malote
**Purpose:** Deploys malote query engine (datanodes), metamalote federation layer, maqui CLI, and malote-controller.

**Collection:** `devoinc.malotev2` — contains roles: malote, metamalote, maqui, malote_controller

**Keystore:** `/etc/logtrust/malote/.ks/datamalote.jks` and `metamalote.jks` — SSL/signing  
**Trunk data:** `/var/logt/ebs/`, `/var/logt/young/`, `/var/logt/old/`, `/var/logt/t02/` (legacy) or `/var/logt/t00/t01/t02/` (bcache)

**CRITICAL — JVM config:** Per-instance `malote.javaoptions` files are NOT read. Use `JAVA_OPTIONS` env var in `/etc/logtrust/systemd/malote/<hostname>/iN.conf`

### Role — collection-batrasio / ansible-batrasio
**Purpose:** Deploys Batrasio Node.js event relay/broker. Acts as primary data ingestion endpoint. Handles mTLS, CRL validation (from TAPU), event batching (100 events/round).

**Service ordering:** `After=alcohol.target`, `Before=malote.target`  
**CRL certs:** `/etc/logtrust/batrasio/crl/` | Relay certs: `relay.crt/relay.key`

### Role — collection-mason / ansible-mason-agent + mason-lodge
**Purpose:** Mason Agent runs on every datanode, polls Lodge via RabbitMQ, downloads metadata/lookups from S3.

**RabbitMQ exchanges:** `mq_exchange_mason_lodge_requests`, `mq_exchange_mason_lodge_responses`, `mq_mason_lodge_changes`  
**Sync period:** 30000ms | Max backoff: 60s  
**Lookup troubleshooting (missing data, udlu, blank grid) → `/devo-tools`**

### Role — ansible-barcenas
**Purpose:** Data backup/restore to S3 (or Azure/GCP/filesystem). Cron-based daily backup.

**Key vars:**
- `barcenas_repo_type` — `S3`, `AZ`, `GC`, `FS`
- `barcenas_repo_path` — bucket name
- `barcenas_store_ages: [7d]` — retention per tier
- `barcenas_threads_disk` — parallelism = number of disks

### Role — ansible-chasys
**Purpose:** Platform monitoring/alerting orchestration. 20+ built-in chascos for infra monitoring.

**Chascos include:** syslogSender, httpSender, eventLifeCycle, dynLookGen, alertDispatchMonitor, droppedDatanodesDetector, backupChecker, compressionChecker  
**Signed queries:** keystore + privatekey passwords  
**Email:** SMTP with anti-flooding

### Role — ansible-licor
**Purpose:** Full-text search indexing on datanodes. Consolidates daily, reviews past 30 days.

**Key vars:**
- `licor_num_threads: 16` — indexing parallelism
- `licor_daily_consolide_time: "00:05"` — consolidation schedule
- `licor_min_size_to_index: 10*MB` — minimum file size

### Role — ansible-pilot / ansible-pilot-server
**Purpose:** pilot = legacy streaming analytics (Flow); pilot-server = modern alert context engine.

**Pilot contexts:** alertDispatch, metaTable, myappGenerator, etc.  
**MySQL schema:** `alerts` DB with dedicated `alerts` user  
**Anti-flooding:** time windows 3600s-60s, email limits

### Role — ansible-mmupdater
**Purpose:** MaxMind GeoIP database updates via K8s CronJob with External Secrets Operator.

**Account:** 54997 | Also manages: squidupdater, public_suffix, iputacion crons

### Role — ansible-offboarding
**Purpose:** Customer domain offboarding automation. Stages: delete domain → casperables → lookups → S3 bucket (dedicated) → files → data.

**Vars loaded from:** `vars-{region}-{env}.yml` (region/env aware)

### Role — ansible-casperable-updater
**Purpose:** Deploys alert/aggregation rule definitions. Heavily credential-laden — 18 secrets encrypted via cry_encrypt.

### Role — ansible-resilient-infra
**Purpose:** Auto-healing health-check agent for datanode/batrasio/metamalote. Detects process crashes and restarts services.

**Detection:** Hostname-based auto-detect of node type  
**State files:** `/var/lib/health-check/*.cooldown`, `*.count`  
**Cooldown:** 300s after restart, max 3 restarts before Slack escalation

### Role — logtrust.base (ansible-base)
**Purpose:** Base OS setup required by all Devo services. Creates `logtrust` user/group, directory structure, bash history, DEVO_XCONFIG env var.

**Directories created:**
- `/etc/logtrust/` — permissions 0770
- `/opt/logtrust/` — permissions 0775
- `/var/tmp/logtrust/`, `/var/run/logtrust/` — permissions 0770

---

## Deployment Operations

### myapp-loader

**Role:** `devoinc.myapp-loader`
- GitLab: https://gitlab.com/devo_corp/platform/ansible/roles/ansible-myapp-loader
- Current Version (all regions): **v2.1.4** (deployed April 30, 2026)
- Target: metamalote-general servers
- Log: `/var/log/myapp-loader.log` | Script: `/opt/logtrust/myapp-loader/myapp-loader.py`
- Config: `/opt/logtrust/myapp-loader/myapp-loader.conf`

**Known Fix (v2.1.4) — Python 2/3 urllib.quote (ISM-16277, ISM-16503):**
```python
# Before (Python 2 only)
import urllib
urllib.quote(...)

# After (Python 2/3 compatible)
try:
    from urllib import quote as urllib_quote       # Python 2
except (ImportError, AttributeError):
    from urllib.parse import quote as urllib_quote  # Python 3
```

**Environment → Requirements File mapping:**

| Environment | Requirements File | Hosts |
|-------------|-------------------|-------|
| AWS US Pro | `requirements-aws-us-pro.yml` | `aws/us/pro/hosts` |
| AWS US Pro3 | `requirements-aws-us-pro3.yml` | `aws/us/pro3/hosts` |
| AWS US POC | `requirements-aws-us-poc.yml` | `aws/us/poc/hosts` |
| AWS EU Pro | `requirements-aws-eu-pro.yml` | `aws/eu/pro/hosts` |
| AWS EU Santander | `requirements-aws-eu-santander.yml` | `aws/eu/santander/hosts` |
| AWS EU NCSC Bahrain | `requirements-aws-eu-ncscbh.yml` | `aws/eu/ncscbh/hosts` |
| AWS APAC Pro | `requirements-aws-ap-pro.yml` | `aws/ap/pro/hosts` |
| AWS Canada Pro | `requirements-aws-ca-pro.yml` | `aws/ca/pro/hosts` |
| AWS ME NCSC | `requirements-aws-me-ncscbh.yml` | `aws/me/ncscbh/hosts` |
| GCP EU TEF | `requirements-gcp-eu-tef.yml` | `gcp/eu/tef/hosts` |

**Requirements file snippet (all 10 environments):**
```yaml
- src: git@gitlab.com:devo_corp/platform/ansible/roles/ansible-myapp-loader.git
  scm: git
  name: devoinc.myapp-loader
  version: v2.1.4
```

**Deployment (single env template):**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation
ENV=aws/us/pro          # set per environment
REQ=aws-us-pro          # matching requirements filename

ansible-galaxy install -r ansible/requirements-${REQ}.yml --force
ansible-playbook ansible/playbooks/myapp-loader.yml \
  -i ansible/environments/${ENV}/hosts \
  --limit metamalote-general
ansible metamalote-general -i ansible/environments/${ENV}/hosts \
  --become -m shell -a "systemctl restart metamalote"
```

**Version check (all 10 environments):**
```bash
for file in requirements-aws-us-pro.yml requirements-aws-us-pro3.yml \
            requirements-aws-us-poc.yml requirements-aws-eu-pro.yml \
            requirements-aws-eu-santander.yml requirements-aws-eu-ncscbh.yml \
            requirements-aws-ap-pro.yml requirements-aws-ca-pro.yml \
            requirements-aws-me-ncscbh.yml requirements-gcp-eu-tef.yml; do
  echo "$(basename $file): $(grep -A3 'ansible-myapp-loader' automation/ansible/$file | grep version | awk '{print $2}')"
done
```

**Post-deploy verification:**
```bash
# Verify urllib_quote fix deployed (expect 3)
ansible metamalote-general -i ansible/environments/<ENV>/hosts \
  -m shell -a "grep -c 'urllib_quote' /opt/logtrust/myapp-loader/myapp-loader.py"

# Check for Python errors
ansible metamalote-general -i ansible/environments/<ENV>/hosts \
  -m shell -a "grep -i 'importerror\|attributeerror\|urllib' /var/log/myapp-loader.log | tail -10"
```

**Config variables:**
```yaml
myapp_loader_aws_access_key: "{{ vault_aws_access_key }}"
myapp_loader_aws_secret_key: "{{ vault_aws_secret_key }}"
myapp_loader_aws_region: "us-east-1"
myapp_loader_bucket: "devo-myapp-prod-us"
myapp_loader_malote_conf_path: "/opt/logtrust/malote/conf"
myapp_loader_collector_ip: "{{ relay_ip }}"
myapp_loader_collector_port: 13000
```

---

### alcohol

**Role:** `devoinc.alcohol`
- GitLab: https://gitlab.com/devo_corp/platform/ansible/roles/ansible-alcohol
- Confluence Deploy Guide: https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4949114957
- Binary: Node.js alcohol-new v2.4.0 (at `/opt/logtrust/alcohol-new/`) — 8 instances per node (alcohol@i0-i7.service)
- Config version: 2.9.6 | Tech internal: 0.4.38 | Tech external: 0.15.161

**Key insight — role version ≠ binary version:**
- Role version (`requirements-*.yml`) controls deployment *tasks* only
- Binary version controlled by `software_versions.yml` → `alcohol_version: 2.4.0`
- Updating v2.17.7→v2.17.8 updates task logic only; binary stays 2.4.0 unless `alcohol_version` changes

**Recent fixes:**
- **v2.17.7 (MAQ-1139):** `mysql_server` → `alcohol_mysql_server` in `restart-procedure.yml`, `re-affinity.yml`, `re-variables.yml`
- **v2.17.8 (CHG-10541):** Strip leading `/` from S3 object paths in `deploy.yml`, `configure-main.yml`, `configure-techs.yml`

**Version matrix (as of 2026-04-30):**

| Environment | Hosts File | Role Version | Jenkins Job |
|-------------|-----------|--------------|-------------|
| AWS-EU-PRO | `aws/eu/pro/hosts` | v2.17.8 | [aws-eu-pro/alcohol](https://jenkins.devotools.com/job/RaD-Deployments/job/aws-eu-pro/job/alcohol/) |
| AWS-US-PRO | `aws/us/pro/hosts` | v2.17.8 | [aws-us-pro/alcohol](https://jenkins.devotools.com/job/RaD-Deployments/job/aws-us-pro/job/alcohol/) |
| AWS-US-PRO3 | `aws/us/pro3/hosts` | v2.17.7 | [aws-us-pro3/alcohol](https://jenkins.devotools.com/job/RaD-Deployments/job/aws-us-pro3/job/alcohol/) |
| AWS-AP-PRO | `aws/ap/pro/hosts` | v2.17.7 | [aws-ap-pro/alcohol](https://jenkins.devotools.com/job/RaD-Deployments/job/aws-ap-pro/job/alcohol/) |
| GCP-EU-TEF | `gcp/eu/tef/hosts` | v2.17.7 | [gcp-eu-tef/alcohol](https://jenkins.devotools.com/job/RaD-Deployments/job/gcp-eu-tef/job/alcohol/) |
| AWS-EU-SANTANDER | `aws/eu/santander/hosts` | v2.17.7 | Direct Ansible only |

**Jenkins techs jobs:** `[region]/alcohol-techs` (e.g. [aws-eu-pro/alcohol-techs](https://jenkins.devotools.com/job/RaD-Deployments/job/aws-eu-pro/job/alcohol-techs/))

**Jenkins parameters:**
```
SERVICE: alcohol
ANSIBLE_BRANCH: master
ANSIBLE_TAGS: role::alcohol
TARGET: datanode (or specific host)
```

**Update requirements (all regions to v2.17.8):**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation
for region in aws-eu-pro aws-us-pro aws-us-pro3 aws-ap-pro gcp-eu-tef aws-eu-santander; do
  sed -i '' 's/ansible-alcohol.git$/&/; /ansible-alcohol.git/{n;n;n;s/version: v2.17.[0-7]/version: v2.17.8/;}' ansible/requirements-${region}.yml
done
# Verify
for region in aws-eu-pro aws-us-pro aws-us-pro3 aws-ap-pro gcp-eu-tef aws-eu-santander; do
  echo -n "$region: "; grep -A3 "ansible-alcohol" ansible/requirements-${region}.yml | grep "version:"
done
```

**Deploy via Ansible (direct):**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation
ansible-galaxy install -r ansible/requirements-aws-us-pro.yml --force

# Full deploy
ansible-playbook ansible/playbooks/alcohol.yml \
  -i ansible/environments/aws/us/pro/hosts \
  --limit datanode-3-pro-cloud-shared-aws-us-east-1

# Tags: role::alcohol::deploy (binary only), role::alcohol::configure (config only)

# Production-safe restart (with affinity management)
ansible-playbook ansible/playbooks/alcohol-restart-procedure-v2.yml \
  -i ansible/environments/aws/us/pro/hosts \
  -e "host=datanode-3-pro-cloud-shared-aws-us-east-1"
```

**Restart procedure steps (what the playbook does):**
1. Disable datanode in affinity DB
2. Wait 60s for buffer flush
3. Restart alcohol@i0-i3
4. Wait 10s
5. Restart alcohol@i4-i7
6. Re-enable in affinity DB

**Santander (no Jenkins job):**
```bash
ansible-playbook ansible/playbooks/alcohol-restart-procedure-v2.yml \
  -i ansible/environments/aws/eu/santander/hosts \
  -e "host=datanode1-santander-cloud-shared-aws-eu-west-1"
```

**Post-deploy verification:**
```bash
ENV="aws/us/pro"
# Check 8 instances running
ansible datanode -i ansible/environments/$ENV/hosts \
  -m shell -a "systemctl is-active alcohol.target"
ansible datanode -i ansible/environments/$ENV/hosts \
  -m shell -a "cat /opt/logtrust/alcohol-new/current/package.json | grep '\"version\"'"
# Verify no S3 errors (CHG-10541)
ansible datanode -i ansible/environments/$ENV/hosts \
  -m shell -a "grep -c \"should not start with a leading '/'\" /var/log/alcohol/alcohol.log 2>/dev/null || echo 0"
```

**Verify role has fixes:**
```bash
# MAQ-1139 MySQL fix
grep "alcohol_mysql_server" ansible/roles/devoinc.alcohol/tasks/restart-procedure.yml
# CHG-10541 S3 fix
grep 'object: "alcohol/' ansible/roles/devoinc.alcohol/tasks/deploy.yml
```

**Deployment paths:**
```
/opt/logtrust/alcohol-new/releases/2.4.0/   # binary
/opt/logtrust/alcohol-new/current → 2.4.0   # symlink
/etc/logtrust/alcohol-new/current → 2.9.6   # config symlink
/opt/logtrust/tmp/alcohol-techs/            # tech .tgz files
/var/log/alcohol/alcohol.log
```

---

### Dailytasks Role

**Role:** `devoinc.datanode_dailytasks`
- GitLab: https://gitlab.com/devo_corp/platform/ansible/roles/ansible-dn-dailytasks
- Latest: v1.12.5

**Key scripts deployed:**
- `/usr/local/bin/daily_move.sh` — moves data, cleans backups
- `/usr/local/bin/daily_compress.sh` — compresses yesterday's data
- `/usr/local/bin/daily_tasks.sh` — main orchestrator
- `/usr/local/bin/daily_del.sh` — deletes per retention policy
- `/etc/ansible/facts.d/devo_infra.fact` — must exist with `{"backup": true}` for cleanup to run

**Deploy:**
```bash
cd /Users/vikash.jaiswal/Documents/Repository/automation
ansible-galaxy install -r ansible/requirements-aws-eu-santander.yml --force
ansible-playbook /path/to/playbook.yml \
  -i ansible/environments/aws/eu/santander/hosts
```

**Verify:**
```bash
ansible datanode-santander -i ansible/environments/aws/eu/santander/hosts \
  -m shell -a "wc -l /usr/local/bin/daily_move.sh && cat /etc/ansible/facts.d/devo_infra.fact"
```

---

### MISP Threat Intelligence

**Purpose:** Kubernetes-based MISP replacing legacy Docker instance. Generates `mispIndicator` lookup table used across all Devo regions. (ISM-15510)

**Files:** `~/.claude/skills/devo-infra/misp/`

**Architecture:**
```
Kubernetes (misp-prod namespace)
├── MISP Server — 2 replicas, image: docker.devo.internal/devo/misp:v2.0.0
├── MySQL StatefulSet — 100Gi PVC
├── Redis StatefulSet — 20Gi PVC
└── Lookup Generator CronJob — daily 00:00 UTC (PyMISP → CSV → Devo SDK upload)
```

**Resources:** CPU 3.75/8 cores, Memory 7.5/16Gi, Storage 175Gi total

**Quick Deployment:**
```bash
cd ~/.claude/skills/devo-infra/misp

# Build images
docker build -t docker.devo.internal/devo/misp:v2.0.0 docker/misp-server/
docker push docker.devo.internal/devo/misp:v2.0.0
docker build -t docker.devo.internal/devo/misp-lookup-generator:v1.0.0 docker/lookup-generator/
docker push docker.devo.internal/devo/misp-lookup-generator:v1.0.0

# Create secrets
source ~/.zshrc && kube create secret generic misp-mysql-secret \
  --from-literal=root-password="$(openssl rand -base64 32)" \
  --from-literal=misp-db-password="$(openssl rand -base64 32)" \
  -n misp-prod
source ~/.zshrc && kube create secret generic devo-api-secret \
  --from-literal=api-key='YOUR_DEVO_API_KEY' \
  --from-literal=api-url='https://apiv2-us.devo.com' \
  -n misp-prod

# Deploy (one-command)
cd scripts && ./deploy.sh

# Or manually:
source ~/.zshrc && kube apply -f k8s-manifests/namespace.yaml
source ~/.zshrc && kube apply -f k8s-manifests/configmap.yaml
source ~/.zshrc && kube apply -f k8s-manifests/storage.yaml
source ~/.zshrc && kube apply -f k8s-manifests/mysql-statefulset.yaml
source ~/.zshrc && kube apply -f k8s-manifests/redis-statefulset.yaml
source ~/.zshrc && kube apply -f k8s-manifests/misp-deployment.yaml
source ~/.zshrc && kube apply -f k8s-manifests/services.yaml
source ~/.zshrc && kube apply -f k8s-manifests/ingress.yaml
source ~/.zshrc && kube apply -f k8s-manifests/lookup-cronjob.yaml
source ~/.zshrc && kube apply -f k8s-manifests/monitoring/
```

**Verify:**
```bash
source ~/.zshrc && kube get all -n misp-prod
cd ~/.claude/skills/devo-infra/misp/scripts && ./test-lookup-generation.sh
# Devo: from lookup.mispIndicator | group | select count() as total_indicators
```

---

## Malote JVM Heap Tuning

**Symptoms:** Malote instances crash with OOM / "To-space exhausted" GC errors (G1GC heap filling faster than it can collect).

**Investigated node:** `datanode-2-pro-cloud-shared-aws-eu-west-1` (May 2026 — 20 days of hourly crashes on i2 and i5)

### Root Causes & Fixes

| # | Root Cause | Fix |
|---|-----------|-----|
| 1 | alcohol workers running 6+ months — 19 GB swap, GC threads starved | Restart alcohol.target |
| 2 | trash-amnesia not purged on DN2 — 178 GB (1702 entries) | Delete entries older than 7 days |
| 3 | Heavy tenant licor indexes (signalit ~1.3 GB/day) | Delete old meta.info dirs |
| 4 | G1GC IHOP=45% default — heap fills before GC kicks in | Tune G1GC flags + Xmx |

### Fix 1 — Restart Alcohol

```bash
# Check swap per alcohol process
for pid in $(pgrep -f 'alcohol'); do
  echo -n "PID $pid: "; awk '/VmSwap/{print $2/1024 " MB"}' /proc/$pid/status
done
systemctl stop alcohol.target && systemctl start alcohol.target
free -h
```

### Fix 2 — Trash-Amnesia Cleanup

```bash
du -sh /var/logt/tr2/b0*/t02/trash-amnesia
ls /var/logt/tr2/b00/t02/trash-amnesia/ | wc -l

# Delete entries older than 7 days
find /var/logt/tr2/b00/t02/trash-amnesia -maxdepth 1 -mindepth 1 -mtime +7 | xargs -P4 -I{} sudo rm -rf {}
find /var/logt/tr2/b01/t02/trash-amnesia -maxdepth 1 -mindepth 1 -mtime +7 | xargs -P4 -I{} sudo rm -rf {}
find /var/logt/tr5/b00/t02/trash-amnesia -maxdepth 1 -mindepth 1 -mtime +7 | xargs -P4 -I{} sudo rm -rf {}
find /var/logt/tr5/b01/t02/trash-amnesia -maxdepth 1 -mindepth 1 -mtime +7 | xargs -P4 -I{} sudo rm -rf {}
```

Restart affected malote instances after cleanup.

### Fix 3 — Delete Heavy Tenant licor Indexes

```bash
# Find heaviest tenants
du -sh /var/logt/tr?/b0?/t02/tn_*/meta.info | sort -h | tail -20

# Delete old meta.info dirs (regenerate on next query — no data loss)
rm -rf /var/logt/tr?/b0?/t02/2023/*/*tn_5a1cb408*/meta.info/*
rm -rf /var/logt/tr?/b0?/t02/2024/*/*tn_5a1cb408*/meta.info/*
# Bulk delete multiple tenants:
find /var/logt/tr?/b0?/t02/202[34] -name meta.info -type d | \
  grep -E 'tn_5a1cb408|icd_de|tn_111764' | \
  xargs -P4 -I{} sudo rm -rf {}/*
```

**Note:** `meta.info` is a directory — use `rm -rf dir/*`, not `rm -f dir`.

### Fix 4 — G1GC Tuning

**File:** `/etc/logtrust/malote-conf/malote.javaoptions`
```
-XX:+UseG1GC
-XX:G1HeapRegionSize=32m
-XX:G1ReservePercent=15
-XX:InitiatingHeapOccupancyPercent=35
-XX:G1MixedGCCountTarget=16
-XX:MaxGCPauseMillis=200
-XX:ParallelGCThreads=16
-XX:ConcGCThreads=4
```

**CRITICAL:** Per-instance `malote.javaoptions` files are NOT read — startup script finds the main file and breaks. Use `JAVA_OPTIONS` env var in the instance `.conf` file instead.

**Files:** `/etc/logtrust/systemd/malote/<hostname>/i2.conf` and `i5.conf`
```
JAVA_OPTIONS=-Xms55G -Xmx55G -XX:G1HeapRegionSize=32m -XX:G1ReservePercent=15 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1MixedGCCountTarget=16 -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=16 -XX:ConcGCThreads=4
```

**Transparent Hugepages:**
```bash
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo defer+madvise | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
```

**Restart affected instances:**
```bash
systemctl restart malote@i2 malote@i5
```

### Monitoring Commands

```bash
# OOM count
grep -c 'To-space exhausted\|OutOfMemoryError' \
  /var/log/malote/malote2.gc.log /var/log/malote/malote5.gc.log

# Latest GC pause
tail -3 /var/log/malote/malote2.gc.log

# RSS and swap per instance
cat /proc/$(systemctl show malote@i2 --property=MainPID --value)/status | grep -E 'VmRSS|VmSwap'

# Verify GC flags loaded
cat /proc/$(systemctl show malote@i2 --property=MainPID --value)/cmdline | tr '\0' '\n' | grep -i 'initiating\|ConcGC\|HeapRegion'
```

### Maqui — Live Query Health Validation

GC=0 on the instance alone does NOT confirm the malote is serving queries — it could be idle. Use these to confirm active processing.

**Important field notes:**
- `queryClon` is always `null` in `siem.logtrust.malote.query` — use `instance` field instead
- Instance format: `<hostname>-i<clon>` e.g. `datanode-2-pro-cloud-shared-aws-eu-west-1-i2`
- Filter `action = "alive"` for in-flight query activity (excludes `new`/`cancel` noise)

```bash
# Confirm instance is present in query log (sanity check — returns distinct machines)
source ~/.zshrc && maquieu 'from siem.logtrust.malote.query where client = "self" and now()-24h <= eventdate < now() and machine ~ "shared" select machine group by machine select count() as cnt limit 20'

# CPU + bytes + events per instance per day (compare multiple instances, adjust date range)
source ~/.zshrc && maquieu 'from siem.logtrust.malote.query where client = "self" and "2026-05-10" <= eventdate < "2026-05-16" and (instance = "datanode-2-pro-cloud-shared-aws-eu-west-1-i2" or instance = "datanode-2-pro-cloud-shared-aws-eu-west-1-i5" or instance = "datanode-1-pro-cloud-shared-aws-eu-west-1-i2" or instance = "datanode-1-pro-cloud-shared-aws-eu-west-1-i5") and action = "alive" group every 1d by instance select sum(totalCPUMillisDelta) as total_cpu_ms, sum(bytesParsedDelta) as bytes_parsed, sum(eventsParsedDelta) as events_parsed limit 200'

# GC events per instance per day (healthy = Young-gen only, no Full GC spike)
source ~/.zshrc && maquieu 'from siem.logtrust.malote.gc where client = "self" and "2026-05-10" <= eventdate < "2026-05-16" and (instance = "datanode-2-pro-cloud-shared-aws-eu-west-1-i2" or instance = "datanode-2-pro-cloud-shared-aws-eu-west-1-i5" or instance = "datanode-1-pro-cloud-shared-aws-eu-west-1-i2" or instance = "datanode-1-pro-cloud-shared-aws-eu-west-1-i5") group every 1d by instance select count() as gc_events limit 200'

# CPU breakdown across all instances on a single node (spot idle or overloaded instances)
source ~/.zshrc && maquieu 'from siem.logtrust.malote.query where client = "self" and now()-24h <= eventdate < now() and machine = "datanode-2-pro-cloud-shared-aws-eu-west-1" and action = "alive" group by instance select sum(totalCPUMillisDelta) as total_cpu_ms limit 20'

# Log level breakdown per instance last 6 days (error = 0 is the health signal)
source ~/.zshrc && maquieu 'from siem.logtrust.malote.free where client = "self" and now()-6d <= eventdate < now() and (instance = "datanode-2-pro-cloud-shared-aws-eu-west-1-i2" or instance = "datanode-2-pro-cloud-shared-aws-eu-west-1-i5") group every 1d by instance, level select count() as events limit 100'
```

**Reading the results — healthy baseline (DN2-shared post-tuning):**

| Metric | i2 typical/day | i5 typical/day | Signal |
|---|---|---|---|
| `total_cpu_ms` | 50–220M | 120–310M | Non-zero = processing |
| `bytes_parsed` | 2–10 TB | 9–34 TB | i5 carries heavier load |
| `events_parsed` | 2–16B | 9–28B | Proportional to bytes |
| `gc_events` | 2K–10K | 4K–150K | Young-gen only = healthy |
| `error` log level | 0 | 0 | Must be 0 |

**Typical CPU/hr** = `total_cpu_ms / 24` (no built-in hourly field — change `every 1d` to `every 1h` for hourly breakdown).

### Key Learnings

1. Per-instance `malote.javaoptions` NOT read — use `JAVA_OPTIONS` in `.conf` file
2. trash-amnesia is the silent killer — compare DN1 vs DN2 entry counts; 1000+ old entries → clean
3. IHOP=35 is the key flag — starts GC at 35% instead of 45%, prevents heap filling before collection
4. meta.info is safe to delete — licor.idx regenerates on next query, no data loss
5. alcohol swap accumulation — check datanodes with long uptime; weekly restart prevents recurrence
6. GC=0 alone ≠ healthy — always validate with `siem.logtrust.malote.query` to confirm active processing; a tuned instance could simply be idle

---

## Metamalote — EU General Instance Upgrade (CHG-10643)

### Instance Type Change: x2gd.xlarge → x2gd.2xlarge

| Spec | Before | After |
|---|---|---|
| Instance | x2gd.xlarge | x2gd.2xlarge |
| CPU cores | 4 | 8 |
| RAM | 32GB | 124GB usable |
| `metamalote_xmx` | 31G | **80G** |
| `metamalote_memory_limit` | 16GB | **40GB** |
| Threads per node | ~2,000 | ~4,500 |
| Connections per node | ~7,000–9,600 | matches US ~15,000 |

**JVM flags (identical EU + US):**
```
-Xms4G -Xmx80G -XX:+UseG1GC -XX:MaxMetaspaceSize=800M
-XX:+UseNUMA -XX:+UseCompressedOops -XX:+UseCompressedClassPointers
-XX:ObjectAlignmentInBytes=8 -XX:+TieredCompilation
```
`+UseCompressedOops` with `ObjectAlignmentInBytes=8` allows heap >32GB without 64-bit pointer penalty on modern JDK. 80G is safe — US runs identically.

**Ansible config (MR-134):**
```yaml
# metamalote-general.yml (AWS EU Pro only)
metamalote_xmx: "80G"
metamalote_memory_limit: "40GB"
```

---

### NVMe Device Reordering Incident (CHG-10643 post-upgrade)

**Incident:** All 10 EU general metamalotes failed on boot after instance type change. `/var/logt/data` mount failed → crash loop → all lookups lost → 7h outage.

**Root cause:** x2gd.2xlarge reorders NVMe devices vs x2gd.xlarge:

| Device | x2gd.xlarge | x2gd.2xlarge (Graviton) |
|---|---|---|
| `nvme0n1` | Root EBS | Root EBS |
| `nvme1n1` | **Instance store** ← `/var/logt/data` | **EBS volume** ← wrong! |
| `nvme2n1` | — | **Instance store** ← correct |

`fstab` still pointed to `nvme1n1` (old instance store) — on new instance type that's an EBS with no XFS → mount failed.

**Remediation (Victor, ~15min):**
1. Format new instance store: `mkfs.xfs /dev/nvme2n1`
2. Update fstab: `/dev/nvme2n1 /var/logt/data xfs defaults,nofail,noatime,lazytime 0 0`
3. Mount + rsync ~82GB lookups from bitdefender metamalotes (parallel, 3 sources)
4. Restart metamalote — all 10 nodes confirmed port 10100 listening

**Ansible fix (MR-134) — prevents recurrence:**
```yaml
# metamalote-general.yml (AWS EU Pro only)
# x2gd.2xlarge (Graviton): nvme2n1 is instance store, nvme1n1 is EBS — device order differs from x2gd.xlarge
metamalote_configure_lookup_disk: true
metamalote_lookup_disk: '/dev/nvme2n1'
```
`metamalote_configure_lookup_disk: true` → Ansible owns fstab via `ansible.posix.mount (boot: true)`. `force: false` on `community.general.filesystem` — skips format if XFS already exists (safe on redeploy).

**Do NOT add to `metamalote.yml`** (base group) — would apply to bitdefender (x2gd.xlarge, correct on nvme1n1) and caixabank (IBM Cloud, uses /dev/vdd).

**Disk layout per metamalote type:**

| Group | Cloud | Instance | lookup disk |
|---|---|---|---|
| `metamalote-general` (10 nodes) | AWS | x2gd.2xlarge | `/dev/nvme2n1` ✅ |
| `metamalote-bitdefender` (12 nodes) | AWS | x2gd.xlarge | `/dev/nvme1n1` (role default) ✅ |
| `metamalote-caixabank` (2 nodes) | IBM Cloud | Intel Xeon | `/dev/vdd` (set in metamalote-caixabank.yml) ✅ |
| `metamalote-pre` (1 node) | AWS | r5.2xlarge | no instance store — N/A ✅ |

**Santander precedent:** Same fix already applied — `metamalote_lookup_disk: '/dev/nvme2n1'` in santander `metamalote-general.yml` with comment: *"Be careful Graviton shows the /dev/nvme disk as the ephemeral depending on instance"*

**MR:** https://gitlab.com/devo_corp/platform/ansible/environments/automation/-/merge_requests/134

---

## Kubernetes (EKS Multi-Account)

### Check SSO First

```bash
# Test kube access (wrapper handles auth automatically)
source ~/.zshrc && kube get nodes --no-headers | wc -l
# If expired:
source ~/.zshrc && aws sso login --profile production   # covers production/santander/datateam
source ~/.zshrc && aws sso login --profile collector
source ~/.zshrc && aws sso login --profile devotools
```

### AWS Accounts & Clusters (20 total)

| Account ID | Name | Profile | Clusters |
|------------|------|---------|----------|
| 175688291360 | Production/LogicHub | `production` | 10 |
| 476382791543 | Cloud Collector | `collector` | 7 (prod-us3 in us-east-2) |
| 281139278838 | DevTools/Hydra | `devotools` | 1 |
| 275752367115 | Santander | `santander` | 1 |
| 837131528613 | DataTeam | `datateam` | 1 (prod-v2, us-east-1) |

**Note:** `santander` shares the `production` sso-session — login with `production` covers Santander and DataTeam too.

**Production/LogicHub clusters:**
`prod-apac`, `prod-eu`, `prod-us`, `prod-us3`, `logichub-prod-apac`, `logichub-prod-apac-aus`, `logichub-prod-eu`, `logichub-prod-us`, `observability` (eu-west-1, central monitoring), `ueba-prod-us`

**Cloud Collector clusters:**
`cloud-collector-prod-{apac,eu,us}` (ap-southeast-1/eu-west-1/us-east-1), `cloud-collector-prod-us3` (us-east-2), `cloud-collector-red-prod-{apac,eu,us}`

**DevTools:** `hydra` (eu-west-1) — OpenBao secrets management (`openbao-prod` namespace)

**Santander:** `prod-san` (eu-west-1) — Dedicated Devo platform for Santander Bank

**DataTeam:** `prod-v2` (us-east-1) — Legacy collector cluster, 124 nodes, `r5n.4xlarge`, ASG `eksctl-prod-v2-nodegroup-worker-NodeGroup-VrMa2npPXp6C` (unmanaged, desired=22 workers + others). Mixed node versions: `v1.28.3` (original launch template) and `v1.28.5` (recent replacements) — not a problem for day-to-day ops. ⚠️ Cluster has 17 CrashLoopBackOff + 274 Error pods — legacy bad configs from ~418 days ago, never fixed. Namespaces include test leftovers (`example-domain-collectors`, `nickg-devo-collectors`). Timea/Krishan own collector config decisions.

### kube Alias

**ALWAYS use `source ~/.zshrc && kube` — NEVER raw `kubectl`.** The wrapper auto-unsets Bedrock AWS env vars that conflict with SSO and sets the correct profile from the cluster ARN.

**Profile auto-detection (kubectl-wrapper.sh):**
- `476382791543` → `collector`
- `175688291360` → `production`
- `281139278838` → `devotools`
- `275752367115` → `santander`
- `837131528613` → `datateam`

### SSO Login

```bash
aws sso login --profile production   # Production / LogicHub / Observability / Santander / DataTeam
aws sso login --profile collector    # Cloud Collector
aws sso login --profile devotools    # DevTools / Hydra
```

### Context Management

```bash
source ~/.zshrc && kube config use-context prod-san
source ~/.zshrc && kube config use-context observability
source ~/.zshrc && kube config use-context hydra
source ~/.zshrc && kube config get-contexts
```

**Update kubeconfig (if context missing) — unset Bedrock vars first, then use correct profile:**
```bash
# Production account (175688291360)
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=production aws eks update-kubeconfig --name prod-eu --region eu-west-1 --alias prod-eu
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=production aws eks update-kubeconfig --name prod-us --region us-east-1 --alias prod-us
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=production aws eks update-kubeconfig --name prod-us3 --region us-east-2 --alias prod-us3
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=production aws eks update-kubeconfig --name prod-apac --region ap-southeast-1 --alias prod-apac
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=production aws eks update-kubeconfig --name observability --region eu-west-1 --alias observability
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=production aws eks update-kubeconfig --name ueba-prod-us --region us-east-1 --alias ueba-prod-us
# Santander account (275752367115)
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=santander aws eks update-kubeconfig --name prod-san --region eu-west-1 --alias prod-san
# DevTools account (281139278838)
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=devotools aws eks update-kubeconfig --name hydra --region eu-west-1 --alias hydra
# Collector account (476382791543)
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=collector aws eks update-kubeconfig --name cloud-collector-prod-eu --region eu-west-1 --alias cloud-collector-prod-eu
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=collector aws eks update-kubeconfig --name cloud-collector-prod-us --region us-east-1 --alias cloud-collector-prod-us
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=collector aws eks update-kubeconfig --name cloud-collector-prod-us3 --region us-east-2 --alias cloud-collector-prod-us3
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=collector aws eks update-kubeconfig --name cloud-collector-prod-apac --region ap-southeast-1 --alias cloud-collector-prod-apac
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=collector aws eks update-kubeconfig --name cloud-collector-red-prod-eu --region eu-west-1 --alias cloud-collector-red-prod-eu
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=collector aws eks update-kubeconfig --name cloud-collector-red-prod-us --region us-east-1 --alias cloud-collector-red-prod-us
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=collector aws eks update-kubeconfig --name cloud-collector-red-prod-apac --region ap-southeast-1 --alias cloud-collector-red-prod-apac
# DataTeam account (837131528613)
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY && AWS_PROFILE=datateam aws eks update-kubeconfig --name prod-v2 --region us-east-1 --alias prod-v2
```

### Common kube Operations

```bash
source ~/.zshrc && kube get pods -n <namespace>
source ~/.zshrc && kube describe pod <pod-name> -n <namespace>
source ~/.zshrc && kube logs <pod-name> -n <namespace> --tail=100
source ~/.zshrc && kube logs <pod-name> -n <namespace> --previous --tail=100
source ~/.zshrc && kube get events -n <namespace> --sort-by='.lastTimestamp'
source ~/.zshrc && kube rollout restart deployment/<name> -n <namespace>
source ~/.zshrc && kube rollout status deployment/<name> -n <namespace>
source ~/.zshrc && kube exec -it <pod-name> -n <namespace> -- /bin/sh
source ~/.zshrc && kube top pods -n <namespace>
source ~/.zshrc && kube top nodes
```

### Santander Cluster

**Context:** `prod-san` | **Namespace:** `devo-pro-san-core` | **Web UI:** https://dataplatform.san.devo.com/
**DB:** logtrust.ccjhewr9ahgq.eu-west-1.rds.amazonaws.com

```bash
source ~/.zshrc && kube config use-context prod-san
source ~/.zshrc && kube get pods -n devo-pro-san-core

# Webapp (table creation)
source ~/.zshrc && kube get pods -n devo-pro-san-core -l app=webapp
source ~/.zshrc && kube logs -n devo-pro-san-core -l app=webapp --tail=100
source ~/.zshrc && kube rollout restart deployment/webapp -n devo-pro-san-core

# Serrea (query engine, StatefulSet)
source ~/.zshrc && kube get pods -n devo-pro-san-core | grep serrea
source ~/.zshrc && kube logs serrea-0 -n devo-pro-san-core --tail=100
```

**Namespaces:** `devo-pro-san-core` (webapp, serrea, alerts), `devo-pro-san-devoapps` (vulcan), `devo-pro-san-serviceops`
**Known issue:** `goloso` pod in CrashLoopBackOff (as of 2026-03-01)

### Santander NLB — public-batrasio-santander

**ARN:** `arn:aws:elasticloadbalancing:eu-west-1:275752367115:loadbalancer/net/public-batrasio-santander/38c591e952925b7c`  
**DNS:** `public-batrasio-santander-38c591e952925b7c.elb.eu-west-1.amazonaws.com` = `collector-54ad5.devo.io`  
**Cross-zone:** Off — targets must cover the correct AZ or traffic drops silently

| Public IP | AZ | Routes to |
|---|---|---|
| `54.216.125.87` | eu-west-1a | batrasio-2 (`172.27.18.235`) |
| `52.48.53.0` | eu-west-1b | batrasio-3 (`172.27.57.246`) |
| `54.75.1.216` | eu-west-1c | (no target) |

**Listeners:**
- TCP:80 → TG `batrasio-santander-443-pro` (batrasio-2 + batrasio-3)
- TCP:443 → TG `batrasio-santander-443-tcp` (batrasio-2 + batrasio-3) — batrasio-2 added 2026-05-22 (ISM-16535)

**⚠️ Lesson:** When adding a batrasio to Santander, register it in **all TGs** (TCP:80 and TCP:443). Missing one TG causes silent drops for whichever AZ IP the customer hardcoded.

- NLB details: [santander-nlb-batrasio-ISM-16535.md](santander-nlb-batrasio-ISM-16535.md)
- Full outage RCA (TLS + affinity + NLB): [santander-bam-ingestion-outage-ISM-16535.md](santander-bam-ingestion-outage-ISM-16535.md)

### OpenBao / Hydra Cluster

**Context:** `hydra` | **Namespace:** `openbao-prod` | **URL:** https://openbao-prod.devo.com  
**Cluster:** DevTools EKS (eu-west-1, account 281139278838) | 3-replica HA StatefulSet, Raft storage, 3×10Gi gp3-encrypted PVCs

```bash
source ~/.zshrc && kube config use-context hydra
source ~/.zshrc && kube get pods -n openbao-prod
source ~/.zshrc && kube exec -n openbao-prod openbao-0 -- bao status
source ~/.zshrc && kube get svc,ingress,certificate -n openbao-prod
```

**Root Token:** `~/.devo/credentials` → `OPENBAO_ROOT_TOKEN` | also in AWS Secrets Manager → `openbao_root_token` (account 281139278838, eu-west-1)

**CI Token (terraform-ci):** `~/.devo/credentials` → `OPENBAO_CI_TOKEN` | policy: `terraform-ci`, expires ~2026-06-06 (renewable), set as `VAULT_TOKEN` in GitLab project 71295288

**KV paths seeded:**

| Engine | Path | Notes |
|--------|------|-------|
| `devo/` (KV v2) | `devo/gitlab`, `devo/gitlab-runner/cache`, `devo/gitlab-dot-com` | ⚠️ PLACEHOLDER values — need real values from old vault.devotools.com |
| `DevoTools/` (KV v1) | `DevoTools/argocd` | ⚠️ PLACEHOLDER values — clientID, clientSecret, slack-token, argocd passwords |

**⚠️ Action required:** All seeded secrets have `PLACEHOLDER` values. Terraform `plan` passes but `apply` will write placeholders into Kubernetes secrets. Populate from old `vault.devotools.com` before running apply.

### Prometheus / Robusta

**Namespace:** `robusta` | **Alerts:** 140 rules

```bash
source ~/.zshrc && kube get pods -n robusta | grep prometheus
source ~/.zshrc && kube port-forward -n robusta prometheus-robusta-kube-prometheus-st-prometheus-0 9090:9090
# Access: http://localhost:9090/alerts
```

**Grafana:** grafana.observability.devo.com (central) | grafana-{eu,us,us3,apac}.devo.com (per-cluster)

### EC2 Node Retirement (AWS scheduled retirement)

When AWS schedules an EKS worker node for retirement ("running on degraded hardware"):

1. **Identify the node** — match instance IP to kubectl node name:
```bash
source ~/.zshrc && kube get nodes -o wide | grep <instance-private-ip>
```

2. **Check pods on node** — confirm what will be evicted:
```bash
source ~/.zshrc && kube get pods --all-namespaces -o wide | grep <node-hostname>
```

3. **Cordon** — stop new pods scheduling:
```bash
source ~/.zshrc && kube cordon <node-hostname>
```

4. **Drain** — evict all non-daemonset pods (they reschedule automatically on other nodes):
```bash
source ~/.zshrc && kube drain <node-hostname> --ignore-daemonsets --delete-emptydir-data --force --timeout=300s
```

5. **Terminate** — do from AWS console or CLI. ASG auto-replaces (desired count maintained).

6. **Verify replacement** — new node joins within ~3-5 min:
```bash
source ~/.zshrc && kube get nodes --no-headers --sort-by=.metadata.creationTimestamp | tail -3
```

**Notes:**
- DaemonSet pods (`aws-node`, `kube-proxy`, `filebeat`, `ebs-csi-node`, `node-exporter`) remain during drain — they terminate when instance is terminated, normal behaviour
- ASG replacement uses the nodegroup's launch template — may come up on older k8s patch version if launch template is old (e.g. `v1.28.3` vs `v1.28.5`), not an issue
- No need to stop before terminate — direct terminate is fine once drained

**prod-v2 nodegroup:** `eksctl-prod-v2-nodegroup-worker-NodeGroup-VrMa2npPXp6C`, desired=22, `r5n.4xlarge`, us-east-1a. Resolved: OP-32090 (2026-05-21, `i-017d93d29a93a55a5` → replaced by `i-065f5776cca9d77df`).

---

### Troubleshooting

```bash
# Auth expired — re-login then retry kube command
source ~/.zshrc && aws sso login --profile production

# CrashLoopBackOff
source ~/.zshrc && kube logs <pod> -n <ns> --previous
source ~/.zshrc && kube describe pod <pod> -n <ns>

# OOMKilled
source ~/.zshrc && kube describe pod <pod> -n <ns> | grep -A 20 "Last State:"
```

---

## CaixaBank Serrea — HMAC Log Suppression (ISM-15453)

**Problem:** 22,767 HMAC authentication errors/day flooding Serrea logs (CaixaBank Go client at 213.229.173.244 using invalid credentials)
**Solution:** Suppress `UserDomainHMACAccessService` and `HMAC` loggers from ERROR → WARN in log4j2.xml
**Duration:** 10 min | **Downtime:** ~30s per node (rolling restart)

### Affected Nodes

| Node | Hostname | IP |
|------|----------|----|
| Serrea-1 | serrea-1-pro-cloud-caixa-ibm-eu-de-2 | 10.9.64.20 |
| Serrea-2 | serrea-2-pro-cloud-caixa-ibm-eu-de-3 | 10.9.128.20 |
| Serrea-3 | serrea-3-pro-cloud-caixa-ibm-eu-de-2 | 10.9.128.21 |

### Config Change

**File:** `/etc/logtrust/serrea/log4j2.xml`
```xml
<!-- Suppress HMAC authentication failures -->
<Logger name="com.devo.lugin.hmac.services.UserDomainHMACAccessService" level="WARN"/>
<Logger name="com.devo.web.common.api.auth.HMAC" level="WARN"/>
```

### Quick Runbook

```bash
# PRE-CHECK
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  echo -n "$node: "; ssh $node "systemctl is-active serrea"
done

# BACKUP
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo cp /etc/logtrust/serrea/log4j2.xml /etc/logtrust/serrea/log4j2.xml.backup.$(date +%Y%m%d_%H%M%S)"
done

# APPLY CONFIG
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo sed -i '/<\/Loggers>/i\    <!-- Suppress HMAC authentication failures -->\n    <Logger name=\"com.devo.lugin.hmac.services.UserDomainHMACAccessService\" level=\"WARN\"/>\n    <Logger name=\"com.devo.web.common.api.auth.HMAC\" level=\"WARN\"/>' /etc/logtrust/serrea/log4j2.xml"
  ssh $node "sudo grep -A 2 'Suppress HMAC' /etc/logtrust/serrea/log4j2.xml"
done

# ROLLING RESTART (one at a time)
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo systemctl restart serrea" && sleep 30
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30

# VERIFY — all nodes Up, no new HMAC ERRORs
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "curl -sk http://localhost:8855/search/system/health" | jq .
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "tail -100 /var/log/serrea/serrea.log | grep 'ERROR.*Invalid domain credentials'"
```

### Rollback

```bash
for node in serrea-{1,3}-pro-cloud-caixa-ibm-eu-de-2 serrea-2-pro-cloud-caixa-ibm-eu-de-3; do
  ssh $node "sudo cp /etc/logtrust/serrea/log4j2.xml.backup.* /etc/logtrust/serrea/log4j2.xml"
done
ssh serrea-3-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
ssh serrea-2-pro-cloud-caixa-ibm-eu-de-3 "sudo systemctl restart serrea" && sleep 30
ssh serrea-1-pro-cloud-caixa-ibm-eu-de-2 "sudo systemctl restart serrea" && sleep 30
```

**Full runbook:** `~/.claude/skills/devo-infra/serrea/SKILL.md`

---

## SOAR (LogicHub / Cortex XSOAR)

**Devo SOAR** is built on **LogicHub** — native Devo security orchestration platform.
**Team SOAR GitLab:** https://gitlab.com/groups/devo_corp/engineering/soar
**Slack:** Tag `@devo_corp/engineering/soar` or contact sharad.mehrotra@devo.com, aman.tiwari@devo.com

### Key Repositories

| Repo | Purpose |
|------|---------|
| `soar/app` | LogicHub UI |
| `soar/helm-charts/soar-app` | Helm deployment charts |
| `soar/applications/devo-soar-app` | Devo SOAR integration app |
| `observability/soar-observability` | SOAR monitoring |

**Terraform environments:** `platform/terraform/environments/logichub-prod-{us,eu,apac,us3,ncscbh}`
**Argo CD:** `platform/argo/hydra/soar/` and `platform/argo/cerberus/soar/`

### Devo Native Integration (LogicHub)

**Docs:** https://help.logichub.com/docs/devo
**API endpoints:** `https://apiv2-us.devo.com` (US), `https://apiv2-eu.devo.com` (EU)
**Auth:** API Token (OAuth or API key/secret)
**Millisecond precision preserved — no duplicate alert issues**

Available actions: List/get/update alerts, run LINQ queries, send events, manage lookups.

### Cortex XSOAR — Known Timestamp Bug (ISM-15655)

**Problem:** Duplicate alerts in Cortex XSOAR (Palo Alto community integration)

**Root cause** in `Packs/Devo/Integrations/Devo_v2/Devo_v2.py` lines 98-100:
```python
# BUGGY — truncates milliseconds
def timestamp_to_date(timestamp):
    return datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d %H:%M:%S")

# FIX — preserve milliseconds
def timestamp_to_date(timestamp):
    return datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
```

**Impact:** XSOAR saves `00:00:06` instead of `00:00:06.311` → next fetch re-fetches all alerts from `.000`–`.999` → duplicates.

**Submit fix:** PR to https://github.com/demisto/content
**Long-term fix:** Migrate customer to Devo SOAR (LogicHub)

**Full details:** `~/.claude/skills/devo-infra/soar/SKILL.md`

---

## UEBA — User and Entity Behavior Analytics

### What Is UEBA

UEBA 2.0 is Devo's Behavior Analytics product. It runs Apache Spark Streaming against customer log data via Kafka to detect behavioral anomalies (auth patterns, risk scoring, threat signals). Unlike UEBA 1.x (which used Collector Servers), UEBA 2.0 is fully Kubernetes-native — deployed as an EKS cluster inside the Devo Platform VPC for each zone.

**Key concepts:**
- **Tenant** = one customer domain (e.g. `vsoc`, `nrdc`) — gets its own K8s namespace
- **Zone** = one Devo deployment (US-1, US-3, EU, APAC, CA) — gets its own UEBA EKS cluster + Kafka (MSK) + Aurora RDS
- All models sharing the same source table (e.g. `auth.all`) reuse a single Kafka topic → single open query on the platform side

---

### Architecture

```
Customer log data (Devo platform)
    ↓ Open/continuous Kafka query (via Serrea/APIv2)
Apache Kafka (MSK per zone)
    ↓ Apache Spark Streaming jobs
UEBA 2.0 EKS cluster (per zone, inside Devo VPC)
    ├── ueba-common     — shared platform services (per zone)
    ├── ueba-tenant     — per-tenant namespace (models, risk scoring, signals)
    ├── ueba-api        — management API (onboarding domains, config)
    └── ueba-public-ingress-router — ingress routing
    ↓ Results written back via HTTP ingestion token
Devo platform (entity groups, risk calculations, signals, multilookups)
    ↓
Webapp (app.custom.Behavior_Analytics VApp — shared from self domain → customer domain)
```

**AWS services per zone:**
| Service | Notes |
|---------|-------|
| EKS cluster | UEBA workloads, inside Devo VPC |
| MSK (Kafka) | Open query streaming, port 9092 |
| Aurora RDS | UEBA state / tenant config |

---

### EKS Clusters

UEBA has two cluster planes per zone:
- **`ueba-prod-*`** — runs UEBA workloads (tenant namespaces, ueba-common, ArgoCD)
- **`prod-*`** (Devo main cluster) — runs `ueba-public-ingress-router` + `ueba-api` in `devo-{env}-core` namespace

| Zone | UEBA Cluster | Devo Cluster | Tenant namespaces on |
|------|-------------|--------------|----------------------|
| US-1 | `ueba-prod-us` (us-east-1) | `prod-us` | `ueba-prod-us` |
| EU | `ueba-prod-eu` (eu-west-1) | `prod-eu` | `ueba-prod-eu` |
| US-3 | `ueba-prod-us3` (us-east-2) | `prod-us3` | `ueba-prod-us3` |
| APAC | `ueba-prod-apac` | `prod-apac` | `ueba-prod-apac` |
| CA | `ueba-prod-ca` | `prod-ca` | `ueba-prod-ca` |
| NCSCBH | `ueba-prod-ncscbh` | `prod-ncscbh` | `ueba-prod-ncscbh` |
| (stage) | `ueba-stage` (eu-west-1) | cerberus `stage` | `ueba-stage` |
| (int) | `ueba-int` (eu-west-1) | cerberus `int` | `ueba-int` |

**ArgoCD runs on `hydra` context** — not on ueba or prod clusters.

```bash
# List all UEBA ArgoCD apps
source ~/.zshrc && kube --context hydra get application -n argocd | grep ueba

# Tenant pods (on ueba cluster)
source ~/.zshrc && kube --context ueba-prod-us get pods -n nrdcvsoc

# Ingress router / ueba-api (on devo main cluster)
source ~/.zshrc && kube --context prod-us get deploy -n devo-prod-us-core | grep ueba

# Check DEVO_ZONE in running ingress router
source ~/.zshrc && kube --context prod-us get deploy ueba-public-ingress-router \
  -n devo-prod-us-core -o jsonpath='{.spec.template.spec.containers[0].env}'
```

---

### Helm Charts & GitLab

**Helm chart source:** GitLab project `31713500` — `gitlab.com/devo_corp/engineering/ueba/ueba` (helm-charts)

**Application source repos:**
| Repo | GitLab URL | Purpose |
|------|-----------|---------|
| `ueba-backend` | `gitlab.com/devo_corp/engineering/ueba/ueba/ueba-backend` | Backend application |
| `ueba-frontend` | `gitlab.com/devo_corp/engineering/ueba/ueba/ueba-frontend` | Frontend application |
| `ueba-management-api` | `gitlab.com/devo_corp/engineering/ueba/ueba/ueba-management-api` | Management REST API |
| `ueba-whitelist` | `gitlab.com/devo_corp/engineering/ueba/ueba/ueba-whitelist` | Whitelist config |

**Helm charts (project 31713500):**
| Chart | Purpose | Deployed to |
|-------|---------|------------|
| `ueba-common` | Shared zone services | `{cluster}-core` namespace |
| `ueba-tenant` | Per-tenant models + risk | `<tenant>` namespace |
| `ueba-api` | Management REST API | `devo-{cluster}-core` namespace |
| `ueba-public-ingress-router` | External ingress routing | all prod zones + stage/int |

**⚠️ base-chart wrapper:** Chart versions up to `2.0.2` wrap all values under a `base-chart:` top-level key. Chart `2.0.3+` dropped this wrapper. If the hydra/cerberus values file still uses `base-chart:`, the overrides are silently ignored and the chart's embedded defaults win. Always match the wrapper style to the chart version in use.

---

### ArgoCD Deployment — Two Repos

**Production (hydra):** `gitlab.com/devo_corp/platform/argo/hydra` — manages all `prod-*` clusters  
**Local clone:** `/Users/vikash.jaiswal/Documents/Repository/hydra`

**Stage/Int (cerberus):** `gitlab.com/devo_corp/platform/argo/cerberus` — manages stage/int  
**Local clone:** `/Users/vikash.jaiswal/Documents/Repository/cerberus`

**ArgoCD server:** runs on the `hydra` K8s context (`kube --context hydra`)

**ApplicationSets:**

| Repo | File | Chart | Targets |
|------|------|-------|---------|
| hydra | `devo/ueba-public-ingress-router.yaml` | `ueba-public-ingress-router` | prod-us, prod-eu, prod-us3, prod-apac, prod-ca, prod-ncscbh, poc-us |
| hydra | `ueba-api.yaml` | `ueba-api` | prod-* clusters |
| hydra | `ueba/ueba-common.yaml` | `ueba-common` | ueba-prod-* clusters |
| hydra | `ueba/ueba-tenant.yaml` | `ueba-tenant` | ueba-prod-* clusters (per-tenant matrix) |
| cerberus | `ueba/ueba-common.yaml` | `ueba-common` | ueba-stage, ueba-int |
| cerberus | `ueba/ueba-tenant.yaml` | `ueba-tenant` | ueba-stage, ueba-int (per-tenant matrix) |
| cerberus | `devo/ueba-public-ingress-router.yaml` | `ueba-public-ingress-router` | stage, int |
| cerberus | `devo/ueba-api.yaml` | `ueba-api` | int, stage, k8s |

**Ingress router is deployed on `prod-us` devo cluster** (`devo-prod-us-core` namespace) — NOT on the `ueba-prod-us` cluster.

---

### Hydra Repo — Full UEBA Path Reference

```
hydra/
├── devo/
│   ├── ueba-public-ingress-router.yaml          ← AppSet (ingress router, all prod zones)
│   ├── versions/prod-{us,eu,us3,apac,ca,ncscbh}/config.yaml   ← ⚠️ chart versions (uebaPublicIngressRouter, uebaApi)
│   └── config/
│       └── ueba-public-ingress-router/
│           ├── prod-us_values.yaml              ← DEVO_ZONE + ingress host for US
│           ├── prod-eu_values.yaml
│           ├── prod-us3_values.yaml
│           ├── prod-apac_values.yaml
│           ├── prod-ca_values.yaml
│           ├── prod-ncscbh_values.yaml
│           └── poc-us_values.yaml
├── ueba-api.yaml                                ← AppSet (ueba-api, all prod devo clusters)
├── config/
│   └── ueba-api/
│       └── global_values.yaml
├── ueba/
│   ├── ueba-common.yaml                         ← AppSet (ueba-common, all ueba-prod-* clusters)
│   ├── ueba-tenant.yaml                         ← AppSet (per-tenant, all ueba-prod-* clusters)
│   ├── versions/
│   │   ├── ueba-prod-{us,eu,us3,apac,ca,ncscbh}/config.yaml   ← ueba-common chart version
│   │   └── tenants/ueba-prod-{us,eu,us3,apac,ca,ncscbh}/config.yaml  ← tenant chart versions
│   └── config/
│       ├── ueba-common/ueba-prod-{us,eu,us3,apac,ca,ncscbh}_values.yaml  ← zone common config
│       └── tenants/global/ueba-prod-{us,eu,us3,apac,ca,ncscbh}_values.yaml  ← Kafka, RDS, API endpoints
└── default/
    └── secretstore-resources/ueba-prod-{us,eu,us3,apac,ca,ncscbh}/cluster-secret-store.yaml
```

### Cerberus Repo — Full UEBA Path Reference

```
cerberus/
├── devo/
│   ├── ueba-public-ingress-router.yaml          ← AppSet (ingress router, stage+int)
│   ├── ueba-api.yaml                            ← AppSet (ueba-api, stage+int+k8s)
│   └── config/
│       ├── ueba-public-ingress-router/
│       │   ├── stage_values.yaml                ← DEVO_ZONE: api-internal.ueba-stage.devo.com
│       │   └── int_values.yaml                  ← DEVO_ZONE: api-internal.ueba-int.devo.com
│       └── ueba-api/
│           ├── global_values.yaml
│           ├── stage_values.yaml
│           ├── int_values.yaml
│           └── k8s_values.yaml
├── ueba/
│   ├── ueba-common.yaml                         ← AppSet (ueba-common, ueba-stage+ueba-int)
│   ├── ueba-tenant.yaml                         ← AppSet (per-tenant, ueba-stage+ueba-int)
│   ├── versions/
│   │   ├── ueba-common/ueba-{stage,int}/config.yaml   ← ueba-common chart version
│   │   └── tenants/ueba-{stage,int}/config.yaml       ← tenant chart versions
│   └── config/
│       ├── ueba-common/ueba-{stage,int}_values.yaml
│       └── tenants/global/ueba-{stage,int}_values.yaml
└── default/
    └── secretstore-resources/ueba-{stage,int,da}/cluster-secret-store.yaml
```

**Values merge order (last wins):**
```
1. values/{env}.yaml          ← embedded in Helm chart package (may be broken — see ISM-16605)
2. devo/config/global/{env}_values.yaml
3. devo/config/ueba-public-ingress-router/{env}_values.yaml  ← our override
```

**Deploy new tenant (prod):**
1. Add tenant + version to `hydra/ueba/versions/tenants/ueba-prod-us/config.yaml`
2. Add domain config to `hydra/ueba/config/tenants/ueba-prod-us/{tenant}.yaml` (or `global/` for env-wide)
3. Create MR in hydra → merge → ArgoCD auto-deploys within ~30s

**Check ArgoCD app status:**
```bash
source ~/.zshrc && kube --context hydra get application -n argocd | grep ueba
```

---

### Key Configuration (per zone)

**stage config (from cerberus `ueba-stage_values.yaml`):**
```yaml
kafka:
  bootstrapServer: "b-2.kafkauebastage.<...>.kafka.eu-west-1.amazonaws.com:9092,..."
rds:
  host: "ueba-stage.cluster-c04thzqpgowh.eu-west-1.rds.amazonaws.com"
ingress:
  host: "api-internal.ueba-stage.devo.com"
devo:
  query_endpoint: "https://apiv2-eu.devo.com/search/query"
  http_endpoint: "https://http-eu.devo.com"
```

**Zone API endpoints:**
| Zone | Query API (Serrea) | HTTP Ingestion | DEVO_ZONE value |
|------|--------------------|----------------|-----------------|
| EU | `https://apiv2-eu.devo.com/search` | `https://http-eu.devo.com` | `api-internal-ueba-eu.devo.com` |
| US-1 | `https://apiv2-us.devo.com/search` | `https://http-us.devo.com` | `api-internal-ueba-us.devo.com` |
| US-3 | `https://apiv2-us3.devo.com/search` | `https://http-us3.devo.com` | `api-internal-ueba-us3.devo.com` |
| APAC | `https://api-apac.devo.com/search` | — | — |

---

### Onboarding a New Customer Domain

1. **Submit DBAS Jira ticket** — include: Devo Zone, full domain name, data ingest sizing; notify Michael Lyons, Chris Phillips, Rakesh Nair for hardware/pod allocation pre-check
2. **Enable UEBA 2.0 VApp** — via NASS, share `app.custom.Behavior_Analytics` from `self` → customer domain
3. **Create tokens in customer domain** — Query API token + HTTP ingestion token (both must have `*.**` permissions)
4. **Register domain via ueba-api:**
   ```bash
   curl --location 'http://ueba-api.data.devo.com/domain' \
     --header 'x-api-key: 4fd0802e-d4ec-4df3-bb41-cbc55eb35499' \
     --header 'Content-Type: application/json' \
     --data @domain_data.json
   ```
   `domain_data.json` format:
   ```json
   { "domain_name": "<domain>", "environment": "<query_api_url>", "collector_server_domain": "<cs_domain>", "needs_sidecar": 0, "alert_environment": "<alert_api_url>" }
   ```
5. **Configure multilookups** — `AlertRiskScore` and `TechniqueRiskScore` lists must exist in customer domain
6. **Deploy tenant via ArgoCD (cerberus MR)** — add to `versions/tenants/{env}/config.yaml`
7. Allow up to 30 min for changes to reflect

---

### Troubleshooting

#### Blank widgets / data not populating
- Verify API tokens are valid and have `*.**` permissions
- Check `http-endpoint` is configured correctly for the zone (Devo Administration UI)
- Tokens expired → UEBA silently fails to fetch/write data

#### Unable to add Risk Groups / Notables
- HTTP ingestion token invalid or `http-endpoint` misconfigured
- Verify via Devo Administration UI → HTTP endpoint setting for customer domain

#### Model stuck "creating data pipeline"
- Serrea unable to create open query → verify Kafka bootstrap server includes port 9092
- Check: `source ~/.zshrc && kube logs -n <tenant-ns> <spark-pod> --tail=100`

#### Secrets pull failure
- Check `ueba-api` pod logs for secret-fetch errors
- Verify Vault/Secrets Manager access from UEBA EKS cluster IAM role

#### ISM-16605 — DEVO_ZONE `da` bug + chart wrapper mismatch (Nightwing/NRDC@vsoc, prod-us)

**Symptoms:** UEBA webapp blank/error for all US domains (`nrdcvsoc`, `security_intelligence`, `soardev`, `carhartt_inc`); requests not reaching UEBA pods; CORS errors.

**Root cause (two bugs combined):**

1. **Chart version mismatch:** `ueba-public-ingress-router` chart was upgraded to `2.0.3` in hydra `devo/versions/prod-us/config.yaml`. Chart `2.0.3` dropped the `base-chart:` wrapper, but `hydra/devo/config/ueba-public-ingress-router/prod-us_values.yaml` still uses `base-chart:` as the top-level key → our overrides are silently ignored → chart's embedded `values/prod-us.yaml` wins unchallenged.

2. **Chart's embedded `values/prod-us.yaml` is broken in 2.0.3:** Sets `DEVO_ZONE: da` (legacy short value from `ueba-da` cluster) and has a malformed ingress host `api.da.devo.com/v2ueba/?(.*)` (path leaked into host field).

**Result:** ArgoCD `prod-us-ueba-public-ingress-router` stuck **OutOfSync**, self-heal retrying 5 times and failing with:
```
Ingress "ueba-public-ingress-router" invalid: spec.rules[0].host: Invalid value:
"api.da.devo.com/v2ueba/?(.*)" — a wildcard DNS-1123 subdomain must start with '*.'
```
Last successful deploy was chart `2.0.2` (Aug 2024) which left pod running `DEVO_ZONE: da`.

**Fix options (both require a hydra MR):**

*Option A — Pin back to chart 2.0.2 (quick rollback):*
```yaml
# hydra/devo/versions/prod-us/config.yaml
uebaPublicIngressRouter:
  helmChartVersion: 2.0.2   # was 2.0.3
```
`prod-us_values.yaml` already has correct `DEVO_ZONE: api-internal-ueba-us.devo.com` and correct host — once chart version is fixed, ArgoCD auto-syncs and values apply correctly.

*Option B — Remove `base-chart:` wrapper from values file (proper fix for 2.0.3):*
```yaml
# hydra/devo/config/ueba-public-ingress-router/prod-us_values.yaml
# Remove the "base-chart:" top-level key — chart 2.0.3 reads values at root level
image:
  name: ueba_public_ingress_router
env:
  - name: DEVO_ZONE
    value: api-internal-ueba-us.devo.com
...
```

**Verify after fix:**
```bash
# Watch ArgoCD sync (should go Synced within ~30s of MR merge)
source ~/.zshrc && kube --context hydra get application prod-us-ueba-public-ingress-router -n argocd -w

# Confirm correct DEVO_ZONE in running pod
source ~/.zshrc && kube --context prod-us get deploy ueba-public-ingress-router -n devo-prod-us-core \
  -o jsonpath='{.spec.template.spec.containers[0].env}' | python3 -m json.tool
```

**Check pod env vars:**
```bash
source ~/.zshrc && kube --context prod-us exec -n <tenant-ns> <pod> -- env | grep DEVO_ZONE
```

**Check ArgoCD sync error detail:**
```bash
source ~/.zshrc && kube --context hydra get application prod-us-ueba-public-ingress-router -n argocd \
  -o jsonpath='{.status.conditions[0].message}'
```

---

### Confluence References
- **UEBA 2.0 Installation/Config/Onboarding:** https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4563009600
- **ArgoCD — Deploy new tenants:** https://devoinc.atlassian.net/wiki/spaces/DPA/pages/4935057436
- **Enable UEBA for customer domain:** https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/3794993153
- **KB Troubleshooting:** https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207865

---

## Datanode Decommission — RDS installation Table

When a customer is decommissioned, their datanode/metamalote/alcohol entries must be disabled in the shared RDS `installation` table. If left `enabled=1`, all EU metamalotes keep trying to connect to dead IPs — causing Chasys `droppedDatanodesDetector` alerts.

**`installation` table** in `rds.shared.pro.aws.eu-west-1.devo.internal:3306` (db: `logtrust`) is the single source of truth for the delegation tree. Metamalotes cache it in memory — a restart is required to pick up changes.

```bash
# Check rows for customer
source ~/.zshrc && sql eu_pro -e "SELECT type, COUNT(*), SUM(IF(enabled=1,1,0)) as enabled FROM installation WHERE name LIKE '%<customer>%' GROUP BY type;"

# Disable all entries
source ~/.zshrc && sql eu_pro -e "UPDATE installation SET enabled = 0 WHERE name LIKE '%<customer>%';"

# Restart all 10 EU general metamalotes
for i in 1 2 3 4 5 6 7 8 9 10; do
  ssh metamalote-${i}-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && systemctl is-active metamalote"
done
```

**Rules:**
- Do NOT edit metamalote conf files or `--delegate-tags` — Lomana/DB controls delegation dynamically
- Precedent: Deloitte CHG-10524 (2026-05-04) — 86 rows disabled, dead IPs in eu-west-1 and eu-west-2

See `/automation-offboarding` for the full customer offboarding workflow (Probio API, admin user creation, etc.)

---

## Related Skills

- **`/devo-devtool`** — **ALL SSH and Ansible operational commands** (disk scanning, service management, GC analysis, Adolfo, rsync, file distribution, user management, malote/metamalote ops). Invoke this for any hands-on infrastructure operation.
- **`/automation-offboarding`** — Full customer offboarding workflow (Probio API, admin user, decommission)
- **`/automation-resilience-infra`** — Health-check agent and auto-healing deployment
- **`/devo-database`** — Database access for datanode queries (MySQL/Adolfo)
- **`/devo-query`** — Maqui queries for infrastructure investigation
- **`/devo-tools`** — Platform architecture (Mason, Lomana, Asilo) + **all lookup troubleshooting** (missing data, udlu, blank grid)
- **`/devo-alert`** — Alert management, Flow/Pilot/Cockpit
- **`/devo-security`** — Vault/OpenBao credentials and security
