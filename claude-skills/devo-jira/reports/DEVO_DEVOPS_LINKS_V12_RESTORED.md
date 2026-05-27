# DevOps Quick Reference - Devo Platform

**By:** Vikash Jaiswal
**Generated:** 2026-04-23
**Base URL:** https://devoinc.atlassian.net/
**Status:** Version 12 Restored

---
---

## 1. Infrastructure

### A. Cloud Platforms

#### AWS Operations
| Title | Description | Link |
|-------|-------------|------|
| DN Deploy AWS | Deploy datanodes on AWS cloud infrastructure with automated provisioning and configuration management | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/1273233532) |
| EBS Expand | Expand AWS EBS volumes for datanodes to increase storage capacity for data ingestion | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3623354542) |
| Backup Disk Expand | Expand backup disk storage capacity for increased data retention and archival requirements | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3825598512) |
| Volume Expansion | Online EC2 volume expansion procedures without downtime or service interruption | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/1718354160) |
| EBS Advanced Ops | MBR to GPT partition table conversion procedures for large disk support | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/1791099239) |
| Disk Replace | Replace failing AWS disk volumes with automated snapshot creation and data migration | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/4644896793) |
| DN Data Restore | Restore datanode data from EBS snapshots with verification and integrity checks | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3707798095) |
| Resize Pipeline | Automated AWS infrastructure resizing for scaling datanode clusters up or down | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/4867719187) |
| EBS Cost Optimize | Reduce EBS costs through cleanup of unused snapshots and orphaned volumes | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/5183569936) |
| Remove DN Safely | Safely remove datanodes from ingestion pipeline with data preservation and validation | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/4342480924) |


#### Azure Operations
| Title | Description | Link |
|-------|-------------|------|
| DN Deploy Azure | Deploy datanodes on Azure platform using managed disks and virtual network infrastructure | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/1273233532) |


#### IBM Cloud
| Title | Description | Link |
|-------|-------------|------|
| IBM Cert Replace | IBM VPC certificate replacement procedures for secure ingestion with validation and testing | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3635511387) |


#### GovCloud
| Title | Description | Link |
|-------|-------------|------|
| GovCloud Migration | Migrate SOAR platform from AWS GovCloud to commercial cloud with tenant validation | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5169152017) |
| Launch GovCloud | Launch SOAR orchestration platform in AWS GovCloud for federal compliance requirements | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/4827840604) |


### B. Datanodes & Instances

#### Architecture
| Title | Description | Link |
|-------|-------------|------|
| DN Architecture | Complete datanode architecture documentation covering ingestion pipeline storage and query processing | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/741834810) |
| DN Deployment | Step-by-step datanode deployment guide with prerequisites configuration and validation procedures | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/741834805) |


#### Deployment
| Title | Description | Link |
|-------|-------------|------|
| DN Bare Metal | Deploy datanodes on bare metal hardware for maximum performance and control | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/741834838) |
| DN VMs | Deploy datanodes using virtual machines on VMware vSphere or KVM infrastructure | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/741834842) |


#### Operations
| Title | Description | Link |
|-------|-------------|------|
| Stop/Start | Safe datanode stop and start procedures to prevent data loss and corruption | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/995786804) |
| Delete Data | Delete specific data from datanodes by table name or time range | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/779649215) |
| Expand Disks | Expand datanode disk storage capacity for increased ingestion rates and retention | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/434962569) |
| Health Check | Datanode health validation procedures checking ingestion query and storage systems | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5014323203) |


#### Automation
| Title | Description | Link |
|-------|-------------|------|
| Resilience Infra | Automated health monitoring and self-healing infrastructure for proactive issue resolution | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/5599952898) |
| Auto Resilience | Deploy resilience automation framework to datanodes with monitoring and alert integration | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5586812931) |
| Trash Cleanup | Automated trash cleanup framework to recover disk space from deleted data | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/5553946635) |


#### Customer Deployments
| Title | Description | Link |
|-------|-------------|------|
| Telefonica Migration | Telefonica AWS instance migration project with minimal downtime and data validation | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4752965639) |
| US3 Deployment | US3 production environment deployment with high availability configuration and testing | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4200824896) |
| AT&T DR | AT&T cross-region disaster recovery setup with automated failover and replication | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/3434938375) |


#### Troubleshooting
| Title | Description | Link |
|-------|-------------|------|
| DN Lomaniacos | Troubleshoot datanode Lomaniacos service issues including ingestion failures and metadata errors | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4492820483) |


#### Advanced Operations
| Title | Description | Link |
|-------|-------------|------|
| Full DN Backup | Complete datanode backup using Barcenas system with incremental snapshots and archival | [View](https://devoinc.atlassian.net/wiki/x/93VBrg) |
| DN Restoration AWS | AWS datanode restoration from backup procedures with data integrity validation and verification | [View](https://devoinc.atlassian.net/wiki/x/AyWWSQ) |
| DN Data Migration | Migrate old datanode data to new instances with minimal downtime and validation | [View](https://devoinc.atlassian.net/wiki/x/r0-E4A) |

| Title | Description | Link |
|-------|-------------|------|
| Add Datanode | Add datanode into production ingestion pipeline with load balancing and health verification | [View](https://devoinc.atlassian.net/wiki/x/OPChqg) |
| Remove Datanode | Remove datanode from production safely with data preservation and graceful shutdown | [View](https://devoinc.atlassian.net/wiki/x/2YJouQ) |
| Rename Datanode | Rename datanode hostname procedures updating DNS records and configuration files | [View](https://devoinc.atlassian.net/wiki/x/E49IQA) |

| Title | Description | Link |
|-------|-------------|------|
| Storage Reduction | Reduce cloud datanode storage capacity through data deletion and volume shrinking | [View](https://devoinc.atlassian.net/wiki/x/Kgz9Lg) |
| Expand Disks | Datanode disk expansion procedures for filesystem growth and partition resizing | [View](https://devoinc.atlassian.net/wiki/x/6YWZGg) |
| Decrease EBS | AWS EBS disk size reduction through snapshot creation and volume replacement | [View](https://devoinc.atlassian.net/wiki/x/VfnV3Q) |
| Free Data Space | Free space on data partition by removing old files and compacting tables | [View](https://devoinc.atlassian.net/wiki/x/A-nU4w) |
| Free Root Space | Root partition cleanup procedures removing logs temporary files and old packages | [View](https://devoinc.atlassian.net/wiki/x/BEbsvA) |

| Title | Description | Link |
|-------|-------------|------|
| Delete Tables | Delete tables and metadata files from datanode storage with verification and cleanup | [View](https://devoinc.atlassian.net/wiki/x/CAOoqg) |
| Compress Table | ASAZ SIP table compression procedures to reduce storage footprint and improve performance | [View](https://devoinc.atlassian.net/wiki/x/rbLUtQ) |
| Conceal Rows | Make table rows non-searchable while preserving data for compliance and audit requirements | [View](https://devoinc.atlassian.net/wiki/x/H3Lg4A) |

| Title | Description | Link |
|-------|-------------|------|
| Licor Reindex | Licor index reindex and consolidation to improve query performance and reduce fragmentation | [View](https://devoinc.atlassian.net/wiki/x/VwOoqg) |
| Change AGE | Modify AGE configuration parameters for data retention policies and storage management | [View](https://devoinc.atlassian.net/wiki/x/ARtSvQ) |
| Identify Sources | Identify datanode ingestion source configuration checking relay and batrasio connections | [View](https://devoinc.atlassian.net/wiki/x/YSbT0w) |
| Check Datanodes | Legacy datanode health check procedures validating ingestion query and storage subsystems | [View](https://devoinc.atlassian.net/wiki/x/7AVbUQ) |


### C. Kubernetes
| Title | Description | Link |
|-------|-------------|------|
| K8s Deployment | Platform deployment on Kubernetes cluster with helm charts and service orchestration | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/741834791) |


### D. Infrastructure Services

#### Backup & Recovery
| Title | Description | Link |
|-------|-------------|------|
| Backup Processes | Comprehensive backup procedures for platform including databases datanodes and configuration files | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/985235750) |
| Barcenas Deploy | Deploy Barcenas backup management system with S3 integration and retention policies | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/312803337) |
| Barcenas Restore | Restore data from AWS DEEP ARCHIVE tier with retrieval time estimation | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5286952963) |
| Barcenas Export | Export archived data to external storage for customer delivery and compliance | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5026480178) |
| Barcenas Inventory | Query and manage backup inventory tracking snapshots retention and storage costs | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4643946520) |


#### Cloud Integration
| Title | Description | Link |
|-------|-------------|------|
| AWS SES | AWS Simple Email Service dedicated IP configuration for alert delivery and reputation | [View](https://devoinc.atlassian.net/wiki/x/MoGDN) |
| Azure Event Hub | Azure Event Hub integration to Devo for streaming data ingestion from Azure | [View](https://devoinc.atlassian.net/wiki/x/cAJvO) |
| Hybrid SaaS | Hybrid-SaaS deployment network connectivity with VPN and PrivateLink configuration | [View](https://devoinc.atlassian.net/wiki/x/fgBSNg) |


#### Domain Operations
| Title | Description | Link |
|-------|-------------|------|
| Delete Domain | Complete domain deletion operational procedures including data cleanup and resource decommissioning | [View](https://devoinc.atlassian.net/wiki/x/nwCbNg) |

---
---

## 2. Ingestion

### A. Cloud Collector

#### Core Documentation
| Title | Description | Link |
|-------|-------------|------|
| CC Environments | Cloud Collector deployment environments documentation covering production staging and development clusters | [View](https://devoinc.atlassian.net/wiki/spaces/0CC) |
| CC Architecture | Cloud Collector architecture and design patterns for scalable multi-tenant data collection | [View](https://devoinc.atlassian.net/wiki/spaces/0CC) |
| Onboard Customers | Customer onboarding procedures for Cloud Collector including domain creation and configuration | [View](https://devoinc.atlassian.net/wiki/spaces/0CC) |


#### Collector Operations
| Title | Description | Link |
|-------|-------------|------|
| Launch Collector | Launch collector instances in application with source configuration and credential management | [View](https://devoinc.atlassian.net/wiki/spaces/0CC) |
| Restart GREEN | Restart collector services in GREEN cluster for applying updates and resolving issues | [View](https://devoinc.atlassian.net/wiki/spaces/0CC) |
| View Logs | Access collector logs in GREEN cluster for troubleshooting ingestion and connectivity problems | [View](https://devoinc.atlassian.net/wiki/spaces/0CC) |
| Scale Collector | Scale collector resources using Management API to handle increased data volume | [View](https://devoinc.atlassian.net/wiki/spaces/0CC) |


#### Advanced Operations
| Title | Description | Link |
|-------|-------------|------|
| CC Backend SDLC | Cloud Collector backend development lifecycle covering build test deploy and release workflows | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4544167950) |
| CC Training | Cloud Collector documentation training materials for operations teams and support staff | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4135976963) |
| Onboard Customers | Customer onboarding in Cloud Collector with domain provisioning and initial configuration | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4256202781) |
| Restart Collector | Restart procedures for Cloud Collector services with graceful shutdown and validation | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4222779425) |
| Collector UI Auth | Authentication mechanisms for Collector UI including SAML OAuth and API tokens | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3937042550) |
| K8s Operations | Kubernetes operations for Collector Server including pod management scaling and monitoring | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3670671473) |
| Self-Service Collectors | Self-service collector configuration guide enabling customers to manage their own collectors | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3992191011) |
| Install via NASS | NASS-based Cloud Collector installation for network-attached storage service integration | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4135747595) |
| Enable Collector UI | Enable UI on legacy migrated domains to provide modern management interface | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4340088841) |


#### Migration & Administration
| Title | Description | Link |
|-------|-------------|------|
| Cluster Migration | Migration procedures between collector clusters including data validation and rollback plans | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3899818028) |
| Migration Checklist | Complete Cloud Collector migration checklist covering pre-migration validation and post-migration testing | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4191813797) |
| Domain Migration | Domain migration process documentation with step-by-step procedures and verification steps | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3912695916) |
| Get Domain Namespace | Map Cloud Collector namespace to domain for identifying cluster and namespace | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3922297033) |
| Superadmin User | Superadmin user management procedures for creating updating and revoking elevated privileges | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4680187936) |
| Legacy User Mgmt | Legacy collector server user management for pre-Kubernetes collector deployments | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3673686144) |
| Create Domain API | Create self-service domain using Management API with resource limits and quotas | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4275109889) |
| Domain Limits API | Increase domain limits via API for storage collectors and ingestion rate | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4347920385) |
| Scale Collector API | Scale collector via Management API adjusting CPU memory and replica count | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4389240834) |


#### Emergency Procedures
| Title | Description | Link |
|-------|-------------|------|
| Emergency Reset | Cloud Collector emergency reset procedures for service recovery during critical failures | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3885826349) |
| Emergency Cert Fix | Emergency certificate fix procedures for restoring ingestion when certificates expire unexpectedly | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4659642385) |
| ECR Repository Mgmt | Emergency ECR repository permission changes to restore image pull access during outages | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4208623681) |


#### Knowledge Base
| Title | Description | Link |
|-------|-------------|------|
| Using CC | Cloud Collector operations and troubleshooting guide covering common issues and resolutions | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207846) |
| Troubleshoot Collectors | Collector troubleshooting guide for diagnosing ingestion failures and connectivity problems | [View](https://devoinc.atlassian.net/wiki/spaces/SKB) |
| SQS Scaling | Scale SQS collectors for throughput to handle increased message volume from AWS | [View](https://devoinc.atlassian.net/wiki/spaces/SKB) |
| Emergency Downgrade | Emergency collector downgrade procedures when new version causes stability or ingestion issues | [View](https://devoinc.atlassian.net/wiki/spaces/SKB) |
| Scale SQS | SQS collector scaling procedures for adjusting workers polling interval and batch size | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC) |


### B. Batrasio

#### Core Documentation
| Title | Description | Link |
|-------|-------------|------|
| Batrasio Service | Event load balancer ingestion documentation covering architecture deployment and operations | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/5486379024) |
| ELB Batrasio | Event load balancer configuration for distributing ingestion traffic across datanodes | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/631538081) |
| Ingestion Dashboard | Batrasio ingestion monitoring dashboard tracking throughput latency and datanode health | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5384765446) |


#### Troubleshooting
| Title | Description | Link |
|-------|-------------|------|
| APAC Issue | Batrasio APAC deployment issue root cause analysis for regional ingestion failures | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5742788618) |
| IRCA-152 | Batrasio hang causing ingestion loss with mitigation steps and permanent fix | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5551423489) |
| Process Restart | Preemptive Batrasio process restart procedures to prevent memory leaks and connection exhaustion | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3591569467) |
| Batrasio Deploy | Deploy Batrasio load balancer service with TLS configuration and datanode registration | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/1949106177) |


#### Certificate Management
| Title | Description | Link |
|-------|-------------|------|
| Cert Replace HA | Replace certificate on HA Batrasio cluster with zero downtime rolling update | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3305308280) |
| AWS Cert Replace | AWS Batrasio certificate replacement using ACM and load balancer integration | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3305308280) |
| IBM Cert Replace | IBM VPC Batrasio certificate replacement for secure ingestion with certificate chain validation | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3635511387) |


### C. Relay

#### Relay & In-House Deployment
| Title | Description | Link |
|-------|-------------|------|
| NG-Relay | NG-Relay orchestrator documentation for managing distributed relay deployments at scale | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198879) |
| In-House Relay | On-premise relay deployment guide for customer datacenter installations with secure connectivity | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198854) |
| AWS Relay Deploy | AWS-based in-house relay deployment using EC2 instances with auto-scaling configuration | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198888) |
| Virtual Appliance | Virtual appliance relay deployment for VMware vSphere and other hypervisor environments | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198892) |
| Software Package | Relay software package documentation covering installation upgrade and configuration management | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198893) |
| Log Filtering | Filter logs at Devo Relay level to reduce ingestion costs and noise | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/337594) |


#### Syslog & Log Ingestion
| Title | Description | Link |
|-------|-------------|------|
| File Monitoring | Syslog-ng file monitoring setup for tracking changes and ingesting file-based logs | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198845) |
| Rsyslog Send | Rsyslog configuration for log sending to Devo platform with TLS encryption | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198859) |
| Secure Rsyslog | Secure rsyslog configuration using mutual TLS authentication and certificate validation | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198865) |
| Secure Syslog-ng | Secure syslog-ng configuration with encrypted transport and trusted certificate authorities | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198868) |
| Rsyslog Processing | Rsyslog log file processing with parsing enrichment and field extraction rules | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/198871) |
| Multiline Rsyslog | Multiline log handling with rsyslog for stack traces and multi-line messages | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/199010) |

---
---

## 3. Database

### A. Database Tools

#### Maqui
| Title | Description | Link |
|-------|-------------|------|
| Maqui CLI | Maqui command-line interface documentation for querying platform metadata and configuration data | [View](https://devoinc.atlassian.net/wiki/spaces/RDT) |


### B. Database Services

#### MySQL
| Title | Description | Link |
|-------|-------------|------|
| MySQL Operations | MySQL operations maintenance and tuning for optimal platform database performance | [View](https://devoinc.atlassian.net/wiki/spaces/CO) |
| MySQL Backup | MySQL backup processes and retention policies for disaster recovery and compliance | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/985235750) |


#### Aurora
| Title | Description | Link |
|-------|-------------|------|
| Aurora Architecture | Aurora database architecture diagram showing cluster topology replication and failover mechanisms | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5006229505) |
| Aurora Instance | Request new Aurora database instance for application deployment with sizing recommendations | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/4947673108) |


### C. Database Operations

#### Affinity (Domain Balancer)
| Title | Description | Link |
|-------|-------------|------|
| Affinity Balancer | Domain load balancer service distributing domains across datanodes for optimal performance | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/985235540) |


#### Backup & Recovery
| Title | Description | Link |
|-------|-------------|------|
| Backup Processes | Database backup and recovery procedures including automated snapshots and point-in-time recovery | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/985235750) |


### D. Lookups & Data Enrichment
| Title | Description | Link |
|-------|-------------|------|
| Lookups | Data enrichment using lookup tables for adding context and correlation to events | [View](https://devoinc.atlassian.net/wiki/x/WwM1O) |
| MySQL Central DB | MySQL central database component storing platform metadata domains and user information | [View](https://devoinc.atlassian.net/wiki/x/8oC5Og) |
| Database Components | Overview of database system components including MySQL Aurora and caching layers | [View](https://devoinc.atlassian.net/wiki/x/7oC5Og) |
| Maquier GUI | Graphical interface for MAQUI tool providing visual query builder and result visualization | [View](https://devoinc.atlassian.net/wiki/x/Q4CLGgE) |

---
---

## 4. Query & Data Processing

### A. Query Engine - Malote
| Title | Description | Link |
|-------|-------------|------|
| Malote Engine | Distributed LINQ query engine across datanode cluster processing queries in parallel for performance | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Meta-Malote | Query orchestration layer coordinating distributed Malote instances and aggregating results across cluster | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Metamalote Lookup | Lookup table propagation and synchronization across cluster ensuring data consistency for enrichment | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Malolete | Query result cleaner managing stale data cache and removing old temporary files | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Malote Pragmas | Query optimization directives and execution behavior hints for performance tuning and debugging | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| malote tips | Operational tips for query performance optimization including indexing and time range best practices | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Malote Dev | Developer documentation and architecture design guidelines for contributing to query engine | [View](https://devoinc.atlassian.net/wiki/spaces/MA) |
| Malote Access | Alert for query access denied errors indicating permission or authentication issues | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC) |
| Malote Error | Alert for output connection failures when query results cannot be delivered | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC) |


### B. Query Interface

#### Query Engine Operations
| Title | Description | Link |
|-------|-------------|------|
| Malolete Cleaner | Library for generating Malote deletion queries to remove old cached results automatically | [View](https://devoinc.atlassian.net/wiki/x/HQJpOw) |
| Quelato Tools | Collection of tools for managing queries including scheduling execution and result management | [View](https://devoinc.atlassian.net/wiki/x/jYG5Og) |
| Gambitero Access | Library for Malote access in projects providing programmatic query execution and result handling | [View](https://devoinc.atlassian.net/wiki/x/XIC5Og) |
| Time Control | Event creation vs ingestion date handling for accurate time-based query filtering | [View](https://devoinc.atlassian.net/wiki/x/AYDuKgE) |
| Hot Swapping | Hot swapping mechanisms for Malote enabling zero-downtime version upgrades and configuration changes | [View](https://devoinc.atlassian.net/wiki/x/AQCNGwE) |


#### Query Optimization
| Title | Description | Link |
|-------|-------------|------|
| LINQ Optimizations | Comprehensive query optimization for alerts reducing execution time and resource consumption | [View](https://devoinc.atlassian.net/wiki/x/cwBWOQ) |
| Index Usage | Data indexing and token usage strategies for accelerating query performance on large tables | [View](https://devoinc.atlassian.net/wiki/x/G4FuO) |
| Platform Analysis | LINQ usage for platform monitoring and operational metrics collection from internal tables | [View](https://devoinc.atlassian.net/wiki/x/HgQ1O) |


#### Lookups & Tables
| Title | Description | Link |
|-------|-------------|------|
| Lookups Historic | Historical lookup tables version management and archival for tracking changes over time | [View](https://devoinc.atlassian.net/wiki/spaces/MA) |
| Empty Lookups | Alert when critical lookup tables empty indicating propagation failures or data loss | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC) |
| Lookups Propagated | Confirm lookup table propagation to datanodes ensuring enrichment data is available cluster-wide | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601209006) |


#### Query Tools
| Title | Description | Link |
|-------|-------------|------|
| Quelato Mgmt | Query scheduling and saved query management for automating recurring analytical workloads | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Loxcope Builder | Visual LINQ query builder interface enabling drag-and-drop query construction without coding | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Gambitero Access | Global access control for query execution managing permissions and resource quotas | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |


### C. Devo Query Tools

#### Data Processing
| Title | Description | Link |
|-------|-------------|------|
| Asilo Aggregation | Real-time data aggregation storage for pre-computed statistics and dashboards | [View](https://devoinc.atlassian.net/wiki/x/kIC5Og) |
| Asilo Engine | Real-time data aggregation and statistical analysis engine for continuous metric calculation | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Introduction | Asilo engine architecture and capabilities overview covering use cases and design patterns | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Installation | Deployment guide for Asilo aggregation components including prerequisites and configuration steps | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Config | Configuration settings and performance tuning parameters for memory CPU and job scheduling | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Upgrade | Version upgrade procedures with rollback plans and backward compatibility testing | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Diagram | Architecture diagram showing components data flow and integration with Malote and datanodes | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Monitoring | Health monitoring and performance metrics tracking using Grafana Prometheus and internal tables | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Troubleshoot | Troubleshooting guide for engine failures covering OOM errors job hangs and result inconsistencies | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Operations | Job scheduling maintenance and capacity planning for optimizing aggregation workload distribution | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Asilo Failures | Alert for aggregation job failures indicating calculation errors or resource exhaustion | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC) |


#### Data Indexing
| Title | Description | Link |
|-------|-------------|------|
| Licor Indexers | Indexing engine for compressed logs enabling fast search and retrieval from storage | [View](https://devoinc.atlassian.net/wiki/x/TIC5Og) |
| Licor Indexing | Alert for indexing problems and failures preventing query access to recent data | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC) |


#### Health Check
| Title | Description | Link |
|-------|-------------|------|
| Mason Healthcheck | Platform component availability monitoring service tracking uptime and service dependencies | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3967451145) |
| Mason Docs | Service architecture and monitoring capabilities documentation for understanding component interactions | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Lomana Healthcheck | Datanode health and resource utilization monitoring for CPU memory disk and ingestion rate | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC) |
| Lomana Docs | Ingestion pipeline and cluster coordination documentation covering load balancing and failover | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |


#### Caparable
| Title | Description | Link |
|-------|-------------|------|
| Caparable | Capacity planning and resource utilization analysis tool for forecasting infrastructure needs | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |

---
---

## 5. Certificates Management

### Certificate System
| Title | Description | Link |
|-------|-------------|------|
| Cert Maintenance | Certificate renewal rotation validation troubleshooting procedures covering entire certificate lifecycle management | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5325225985) |


### Certificate Generation
| Title | Description | Link |
|-------|-------------|------|
| Generate Certs | SSL TLS certificate generation using internal CA with CSR creation and signing | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/3921805479) |
| Argo Workflows | Certificate lifecycle automation using Argo Workflows for generation renewal and deployment | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4180967428) |
| Internal Certs | Installation procedures for internal platform certificates ensuring secure inter-service communication | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/691044449) |


### Certificate Renewal
| Title | Description | Link |
|-------|-------------|------|
| SSL Renew | SSL web service certificate renewal procedures for public-facing endpoints with validation | [View](https://devoinc.atlassian.net/wiki/spaces/PROYEC/pages/806289535) |
| LetsEncrypt | Automated free SSL certificate renewal using ACME protocol with DNS validation | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3914334272) |
| Digicert | Commercial certificate renewal with CSR validation and extended validation procedures | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3088023619) |
| Proactive Renewal | Customer support proactive certificate renewal procedures preventing expiration-related outages | [View](https://devoinc.atlassian.net/wiki/spaces/CSUP/pages/4351197209) |
| Apple Push | APNs certificate renewal for mobile notifications ensuring continuous push notification delivery | [View](https://devoinc.atlassian.net/wiki/spaces/ITS/pages/3889004600) |
| 11paths Cert | 11paths Telefonica customer certificate renewal procedures with specific compliance requirements | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/3873964287) |


### Certificate Administration
| Title | Description | Link |
|-------|-------------|------|
| AWS Cert Import | Import certificates into AWS Certificate Manager for load balancer and CloudFront integration | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3386605624) |
| JKS Admin | Java KeyStore certificate administration procedures for importing exporting and converting formats | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/803438595) |
| Digicert Mgmt | Enterprise PKI certificate issuance lifecycle management with role-based access control | [View](https://devoinc.atlassian.net/wiki/spaces/ITS/pages/3104604165) |
| Update Alcohol | Deploy SSL certificates for Alcohol ingestion service with zero-downtime rotation | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3104408010) |


### Certificate Validation
| Title | Description | Link |
|-------|-------------|------|
| Validate Certs | Customer domain certificate validation procedures verifying chain of trust and expiration | [View](https://devoinc.atlassian.net/wiki/spaces/CSUP/pages/4404150301) |
| X.509 Expiration | Automated certificate expiration checking and notifications with configurable thresholds and alerts | [View](https://devoinc.atlassian.net/wiki/spaces/IM/pages/3700555926) |


### Special Certificates
| Title | Description | Link |
|-------|-------------|------|
| Collector Handling | Customer support certificate troubleshooting workflows for collector authentication and TLS errors | [View](https://devoinc.atlassian.net/wiki/spaces/CSUP/pages/4988370945) |


### Knowledge Base
| Title | Description | Link |
|-------|-------------|------|
| Validate Certs | Domain certificate validation and trust chain verification for ingestion connectivity | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601199925) |
| Expired Certs | Troubleshooting guide for expired certificate errors including ingestion failures and authentication issues | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601201604) |
| Okta Collector | Okta collector certificate configuration procedures for OAuth and SAML integration | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601200567) |
| Download Certs | Download domain certificates for collectors using web UI or API | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601199948) |
| Certs Tokens | Certificates and authentication tokens documentation covering generation distribution and rotation | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601199881) |

---
---

## 6. Monitoring & Observability

### A. Core Monitoring
| Title | Description | Link |
|-------|-------------|------|
| Monitoring Home | Monitoring operations hub and operational guidelines for 24x7 platform surveillance | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1294467226) |
| Monitoring Systems | Core monitoring architecture reference covering Prometheus Grafana and alert routing infrastructure | [View](https://devoinc.atlassian.net/wiki/x/wAGMKw) |
| Welcome Pack | Onboarding materials for monitoring ops team with training resources and access procedures | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1329954973) |
| Procedures | SOPs and runbooks for daily operations covering routine tasks and emergency response | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1291485814) |
| Channels | Communication channels and escalation paths for incident coordination and status updates | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/4842717189) |
| Monitoring Channels | Slack monitoring channels for regions with dedicated feeds per geographic deployment | [View](https://devoinc.atlassian.net/wiki/x/BQCmIAE) |
| Observability | Observability framework for platform infrastructure using metrics logs and distributed tracing | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4785766469) |
| HLA | High-level architecture diagram for observability showing data flow and component relationships | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/4521459739) |
| APM | Application performance monitoring framework tracking latency throughput and error rates | [View](https://devoinc.atlassian.net/wiki/spaces/TV/pages/937066499) |
| Synthetic Monitoring | Dynatrace synthetic monitoring metrics for proactive availability and performance testing | [View](https://devoinc.atlassian.net/wiki/x/QoB1AwE) |
| Incident Mgmt | Incident management and resolution procedures following ITIL best practices and SLA targets | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1329889471) |
| Silence Procedures | AlertManager silence management procedures for maintenance windows and known issues | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1718716455) |
| Alcohol Monitor | Alcohol ingestion process monitoring tracking throughput latency and error rates | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/5549555729) |


### B. Grafana
| Title | Description | Link |
|-------|-------------|------|
| Grafana Monitoring | Guide for using Grafana dashboards with panels queries and visualization best practices | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1034059822) |
| Grafana Prometheus | Integration with Prometheus metrics backend for time-series data visualization and analysis | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1564672602) |
| Create Dashboard | Create custom Grafana dashboards with variables templates and responsive layout design | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/4657086494) |
| Create Alert | Configure Grafana alert rules with thresholds notification channels and evaluation intervals | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/4656037921) |
| Low Disk Case | Case study for low disk alerts covering detection investigation and remediation procedures | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/4979425287) |


### C. Prometheus
| Title | Description | Link |
|-------|-------------|------|
| External Monitoring | Prometheus component reference for scraping targets service discovery and metric exporters | [View](https://devoinc.atlassian.net/wiki/x/ZoD-Og) |
| Prometheus Tool | Time-series metrics collection system with powerful query language and alerting capabilities | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/989823078) |
| Prometheus | Main documentation and PromQL guide covering aggregation functions and query optimization | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1033961680) |


### D. Netdata
| Title | Description | Link |
|-------|-------------|------|
| Netdata | Real-time node performance monitoring with per-second metrics and automatic anomaly detection | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1034158097) |


### E. AlertManager
| Title | Description | Link |
|-------|-------------|------|
| AlertManager | Alert routing and notification configuration with grouping silencing and inhibition rules | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1033961684) |


### F. External Monitoring
| Title | Description | Link |
|-------|-------------|------|
| UptimeRobot | External uptime monitoring service checking endpoint availability from multiple global locations | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1627750707) |
| Healthchecks.io | External monitoring for alert delivery verifying notification system uptime and response time | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1051853151) |

---
---

## 7. Devo Alerts

### A. Alert System

#### Alert Management
| Title | Description | Link |
|-------|-------------|------|
| Devo Alert Manager | Comprehensive alert management with Grafana JSM sync for incident tracking and automation | [View](https://devoinc.atlassian.net/wiki/x/BIB8KwE) |
| DAM KT | Devo Alert Manager knowledge transfer documentation covering architecture operations and troubleshooting | [View](https://devoinc.atlassian.net/wiki/x/HgDaNAE) |
| Grafana Alerts | Step-by-step guide for Grafana alerts including rule creation notification setup and testing | [View](https://devoinc.atlassian.net/wiki/x/IYCFFQE) |
| Helm Annotations | Metric-based alert generation using Helm chart annotations for automated rule deployment | [View](https://devoinc.atlassian.net/wiki/x/KYAbBgE) |
| False Positives | Troubleshooting collector alert false positives with tuning thresholds and filtering techniques | [View](https://devoinc.atlassian.net/wiki/x/DwCXFQE) |
| Alert Automation | Automated response procedures for alerts including auto-remediation and escalation workflows | [View](https://devoinc.atlassian.net/wiki/x/D4BuIgE) |


#### Platform Alerts
| Title | Description | Link |
|-------|-------------|------|
| Alert Manager | Alert manager architecture and design covering routing grouping and notification pipelines | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/5024546820) |
| Alert Manager KT | Knowledge transfer and operational procedures for managing alert lifecycle and configurations | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/5181669406) |
| NOC Alerts | Platform monitoring alert definitions for infrastructure services and system health | [View](https://devoinc.atlassian.net/wiki/x/5gI1j) |
| Monitoring Alerts | Core monitoring alert configurations covering thresholds severity and notification channels | [View](https://devoinc.atlassian.net/wiki/x/2QgD) |
| Dynatrace Alerts | Dynatrace-specific alerting config for application performance and synthetic monitoring | [View](https://devoinc.atlassian.net/wiki/x/O4CZCwE) |
| Alerts Notifications | Alerts system architecture and delivery covering email Slack PagerDuty and webhook integrations | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/943751695) |
| Devo Alerts | Main documentation hub for alerts including setup configuration and best practices | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1771634723) |
| Alerts Docs | Alert types and response procedures with runbooks for common platform issues | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1771143211) |
| Alerts Catalogue | Complete catalog of platform alerts with descriptions severity and remediation steps | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1780090029) |
| Deprecated Alerts | Inventory of deprecated alerts tracking alerts removed from active monitoring | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/5741576193) |
| DAMAGE | Alert manager component documentation for distributed alert generation and management engine | [View](https://devoinc.atlassian.net/wiki/spaces/PROYEC/pages/649396787) |
| Cartero Delivery | Alert delivery controller service managing notification routing retry logic and delivery guarantees | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/985235770) |


#### Alert APIs & Tools
| Title | Description | Link |
|-------|-------------|------|
| Alerts Ecosystem | Overview of Devo alerts ecosystem covering components integrations and data flow | [View](https://devoinc.atlassian.net/wiki/x/B4AERwE) |
| Alert Engine | Alert engine component documentation describing query evaluation and alert firing logic | [View](https://devoinc.atlassian.net/wiki/x/MIAKRwE) |
| Alerts API | REST API reference for alerts supporting CRUD operations programmatic alert management | [View](https://devoinc.atlassian.net/wiki/x/A4AQRwE) |
| Ingestion Monitor | Script for monitoring data ingestion tracking throughput lag and failure rates | [View](https://devoinc.atlassian.net/wiki/x/UwM1O) |
| Relay Monitoring | Relay monitoring KPIs and health metrics covering uptime connectivity and buffer status | [View](https://devoinc.atlassian.net/wiki/x/MoHsbg) |


### B. Knowledge Base
| Title | Description | Link |
|-------|-------------|------|
| Troubleshoot Alerts | Alert troubleshooting guide covering false positives missing alerts and delivery failures | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601206659) |
| Deploy OOTB | Deploy out-of-the-box SecOps alerts for common security use cases and threat detection | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207194) |
| Query Timeouts | Resolve delayed alert queries by optimizing LINQ expressions and adjusting time ranges | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601206818) |
| List Queries | List active alert queries to identify resource-intensive alerts and optimization candidates | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601206396) |

---
---

## 8. Security Products

### A. UEBA

#### Current Version
| Title | Description | Link |
|-------|-------------|------|
| UEBA 2.0 | Behavioral analytics platform for threat detection using machine learning and anomaly detection | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4458053634) |
| Deployment Guide | Complete deployment procedures for UEBA tenants including infrastructure sizing and configuration | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4235886618) |
| Support Model | Maintenance workflows and escalation paths for tenant support and issue resolution | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4894556161) |


#### Deployment & Operations
| Title | Description | Link |
|-------|-------------|------|
| ArgoCD Deploy | Deploy UEBA tenants using GitOps workflows with automated configuration management and rollback | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/4935057436) |
| Deploy Tenants | Provision new behavioral analytics environments with model training and baseline establishment | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/4658331653) |
| Off-boarding | Decommission tenants and archive analytics data ensuring compliance with retention policies | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4005855391) |
| Release Process | Build testing and production deployment workflows with staged rollout and validation | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4125163528) |


#### Knowledge Base
| Title | Description | Link |
|-------|-------------|------|
| Entity Analytics | Investigation workflows and anomaly detection techniques for identifying insider threats | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207846) |
| Troubleshooting | Diagnostic procedures and resolution steps for model accuracy and data ingestion issues | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207865) |


### B. SOAR

#### Operations
| Title | Description | Link |
|-------|-------------|------|
| SOAR Operations | Platform management and incident response workflows for orchestrating security operations playbooks | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5702680583) |
| System Properties | Configuration settings and performance tuning parameters for playbook execution and resource limits | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/4981063681) |
| Monitoring Dashboard | Platform health metrics and incident tracking with visualization of playbook runs and errors | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/4995579905) |
| Contact Details | OnCall escalation and emergency response contacts for critical platform and tenant issues | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5060427791) |
| Escalation Matrix | Incident severity and notification procedures defining priority levels and response times | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/4839440405) |


#### Tenant Management
| Title | Description | Link |
|-------|-------------|------|
| Prod Runbook | Production environment operational procedures covering deployments upgrades and incident response | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5449383937) |
| Stage Runbook | Staging environment testing and validation procedures for new features and configuration changes | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5443420163) |
| New Instance | Request procedures for provisioning SOAR instances including sizing requirements and approval workflows | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5001641990) |
| Region Migration | Migrate tenant between regions with validation ensuring data integrity and minimal downtime | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5385748481) |


#### Technical
| Title | Description | Link |
|-------|-------------|------|
| Node Execution | Playbook workflow engine architecture and processing covering action execution concurrency and error handling | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5107712007) |
| ThreatLink Agent | Deploy threat intelligence integration components for enriching incidents with external threat data | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5432803329) |


#### Support
| Title | Description | Link |
|-------|-------------|------|
| Support Policy | Service levels and customer support procedures defining response times and coverage hours | [View](https://devoinc.atlassian.net/wiki/spaces/CSUP/pages/3757506763) |
| Support Procedure | Ticket creation and resolution tracking workflow for handling customer issues and requests | [View](https://devoinc.atlassian.net/wiki/spaces/CSUP/pages/3803579810) |
| Customer List | Active tenants and configuration details tracking deployments versions and custom integrations | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5024514064) |


#### Knowledge Base
| Title | Description | Link |
|-------|-------------|------|
| SOAR KB | Platform features and troubleshooting procedures covering common issues and resolution steps | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207492) |
| Playbook Creation | Workflow design and automation configuration guide with best practices for building playbooks | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207508) |
| Self Tables | Platform troubleshooting using internal queries for analyzing playbook runs and system metrics | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207656) |

---
---

## 9. Incident Management

### A. IRCA Reports
| Title | Description | Link |
|-------|-------------|------|
| IRCA-156 | CaixaBank Serrea cluster outage analysis with root cause identification and preventive measures | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5704056838) |
| IRCA-153 | Santander AWS hardware failure and mitigation covering detection response and recovery procedures | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5574721537) |
| IRCA-152 | Batrasio hang causing CaixaBank data loss with detailed timeline and remediation actions | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5551423489) |
| IRCA-132 | GCP Telefonica datanode lookup propagation failure resulting in enrichment errors and resolution | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5041094682) |
| IRCA-116 | APAC low ingestion from certificate issues with impact analysis and certificate renewal procedures | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4957601816) |


### B. Systems OnCall
| Title | Description | Link |
|-------|-------------|------|
| OnCall Reports | Production incidents and resolution timelines tracking response times and lessons learned | [View](https://devoinc.atlassian.net/wiki/spaces/RDT) |


### C. JIRA Operations
| Title | Description | Link |
|-------|-------------|------|
| JIRA Portal | Bug tracking and operational task management for coordinating development and operations work | [View](https://devoinc.atlassian.net/jira) |

---
---

## 10. Devo Platform

### Core Platform
| Title | Description | Link |
|-------|-------------|------|
| Platform Overview | Platform architecture and infrastructure design overview covering ingestion storage query and delivery | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |
| Platform Architecture | System components and integration patterns for distributed log analytics and security monitoring | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |
| Release Notes | Version updates and deployment changes with new features bug fixes and upgrade procedures | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/942997601) |


### Deployment
| Title | Description | Link |
|-------|-------------|------|
| Deployment Process | Platform deployment stages overview covering planning preparation execution and validation | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |
| Deploy Terraform | Terraform infrastructure provisioning guide for automated cloud resource creation and management | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |
| Deploy Docker | Docker isolated service deployment using containerization for consistent application packaging | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |
| Deploy Jenkins | Jenkins CI/CD configuration guide for automating build test and deployment pipelines | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |
| Auxiliaries Services | Auxiliary services deployment procedures for supporting infrastructure like monitoring and logging | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |

---
---

## 11. Deployment

### A. Ansible Playbooks
| Title | Description | Link |
|-------|-------------|------|
| Cleanup Framework | Automated datanode trash cleanup framework using Ansible for scheduled execution across clusters | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/5553946635) |
| Alcoholicos Deploy | Alcoholicos service deployment automation using Ansible playbooks with configuration management and validation | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4949114957) |


### B. Terraform
| Title | Description | Link |
|-------|-------------|------|
| EKS Terraform | EKS cluster Terraform deployment with node groups networking and IAM configuration | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3334406145) |
| Aurora DB | Aurora database Terraform deployment with replica configuration backup and security settings | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3334373377) |
| Deploy Terraform | Platform Terraform deployment guide covering infrastructure as code best practices and workflows | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |


### C. Docker
| Title | Description | Link |
|-------|-------------|------|
| Docker Deploy | Platform Docker deployment guide covering image building registry management and container orchestration | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |


### D. Kubernetes
| Title | Description | Link |
|-------|-------------|------|
| K8s Reference | Kubernetes operations reference guide covering deployments services ingress and persistent volumes | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3458957453) |
| Deploy Jenkins | Jenkins K8s deployment guide using helm charts with persistent storage and plugin management | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP) |


### E. CI/CD & ArgoCD
| Title | Description | Link |
|-------|-------------|------|
| Deploy UEBA | Deploy UEBA 2.0 tenants using ArgoCD with GitOps workflows and automated rollback | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/4658331653) |
| Deploy Jenkins | Jenkins CI/CD automation guide for building testing and deploying applications with pipelines | [View](https://devoinc.atlassian.net/wiki/spaces/DPA) |


### F. Service Deployments
| Title | Description | Link |
|-------|-------------|------|
| Matas-Mafias | Deploy Matas-Mafias data processing service with stream processing and aggregation capabilities | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/642121877) |
| Barcenas Backup | Barcenas backup system deployment with S3 integration retention policies and monitoring | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/312803337) |

---
---

## 12. Strike48 - AI Platform

### A. Platform Overview
| Title | Description | Link |
|-------|-------------|------|
| Strike48 Platform | AI security analytics platform using machine learning for threat detection and response | [View](https://devoinc.atlassian.net/wiki/spaces/Strike48) |


### B. Managed Control Plane (MCP)
| Title | Description | Link |
|-------|-------------|------|
| Splunk MCP | Strike48 Splunk control plane setup for centralized management of Splunk deployments and integrations | [View](https://devoinc.atlassian.net/wiki/spaces/Strike48) |
| Security MCP | Security analytics control plane setup for orchestrating security tools and correlation workflows | [View](https://devoinc.atlassian.net/wiki/spaces/Strike48) |
| Atlassian MCP | Atlassian tools control plane setup integrating Jira Confluence and incident management systems | [View](https://devoinc.atlassian.net/wiki/spaces/Strike48) |
| MCP Deployment | MCP deployment procedures guide covering installation configuration and multi-tenant management | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5457870850) |


### C. Matrix Studio
| Title | Description | Link |
|-------|-------------|------|
| Matrix MCP | Matrix control plane deployment for AI model training deployment and lifecycle management | [View](https://devoinc.atlassian.net/wiki/spaces/Strike48) |

---
---
---

---

**End of Document**
