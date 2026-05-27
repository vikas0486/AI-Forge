# DevOps Quick Reference - Devo Platform

**By:** Vikash Jaiswal  
**Generated:** 2026-04-23  
**Base URL:** https://devoinc.atlassian.net/  
**Status:** Validated, Cleaned & Enhanced (~334 Pages)  
**Last Updated:** 2026-04-23 - Added 64 pages from Legacy Components

---

## Table of Contents

### 1. [Infrastructure](#1-infrastructure)
- [A. Cloud Platforms](#a-cloud-platforms) - AWS, Azure, IBM, GovCloud
- [B. Datanodes & Instances](#b-datanodes--instances) - Architecture, Deployment, Operations, Automation
- [C. Kubernetes](#c-kubernetes)
- [D. Infrastructure Services](#d-infrastructure-services) - Backup, Cloud Integration, Domain Ops

### 2. [Ingestion](#2-ingestion)
- [A. Cloud Collector](#a-cloud-collector) - Core, Operations, Migration, Emergency
- [B. Batrasio](#b-batrasio) - Service, Troubleshooting, Certificates
- [C. Relay](#c-relay) - Relay Deployment, Syslog Ingestion

### 3. [Database](#3-database)
- [A. Database Tools](#a-database-tools) - Maqui
- [B. Database Services](#b-database-services) - MySQL, Aurora
- [C. Database Operations](#c-database-operations) - Affinity, Backup & Recovery
- [D. Lookups & Data Enrichment](#d-lookups--data-enrichment)

### 4. [Query & Data Processing](#4-query--data-processing)
- [A. Query Engine - Malote](#a-query-engine---malote)
- [B. Query Interface](#b-query-interface) - Operations, Optimization, Lookups, Tools
- [C. Devo Query Tools](#c-devo-query-tools) - Data Processing, Indexing, Health Check

### 5. [Certificates Management](#5-certificates-management)
- Certificate System, Generation, Renewal, Administration, Validation, Knowledge Base

### 6. [Monitoring & Observability](#6-monitoring--observability)
- [A. Core Monitoring](#a-core-monitoring)
- [B. Grafana](#b-grafana)
- [C. Prometheus](#c-prometheus)
- [D. Netdata](#d-netdata)
- [E. AlertManager](#e-alertmanager)
- [F. External Monitoring](#f-external-monitoring)

### 7. [Devo Alerts](#7-devo-alerts)
- [A. Alert System](#a-alert-system) - Management, Platform Alerts, APIs & Tools
- [B. Knowledge Base](#b-knowledge-base)

### 8. [Security Products](#8-security-products)
- [A. UEBA](#a-ueba) - Deployment, Operations, Knowledge Base
- [B. SOAR](#b-soar) - Operations, Tenant Management, Technical, Support

### 9. [Incident Management](#9-incident-management)
- [A. IRCA Reports](#a-irca-reports)
- [B. Systems OnCall](#b-systems-oncall)
- [C. JIRA Operations](#c-jira-operations)

### 10. [Devo Platform](#10-devo-platform)
- Core Platform, Deployment

### 11. [Deployment](#11-deployment)
- [A. Ansible Playbooks](#a-ansible-playbooks)
- [B. Terraform](#b-terraform)
- [C. Docker](#c-docker)
- [D. Kubernetes](#d-kubernetes)
- [E. CI/CD & ArgoCD](#e-cicd--argocd)
- [F. Service Deployments](#f-service-deployments)

### 12. [Strike48 - AI Platform](#12-strike48---ai-platform)
- [A. Platform Overview](#a-platform-overview)
- [B. Managed Control Plane (MCP)](#b-managed-control-plane-mcp)
- [C. Matrix Studio](#c-matrix-studio)

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

**Backup & Recovery:**

**Lifecycle Management:**

**Storage Operations:**

**Data Management:**

**Maintenance:**

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



---

## 2. Ingestion

### A. Cloud Collector



#### Advanced Operations
| Title | Description | Link |
|-------|-------------|------|
| Accessing Admin View | Access administrative interface for Cloud Collector application in self-service domain configuration | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4223369218) |
| CC Architecture | Cloud Collector system architecture and multi-tenant design patterns for scalability | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4788453377) |
| CC Backend SDLC | Cloud Collector backend development lifecycle covering build test deploy and release workflows | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4544167950) |
| CC Environments | Cloud Collector deployment across production staging and development environment configurations | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4256497691) |
| CC Training | Cloud Collector documentation training materials for operations teams and support staff | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4135976963) |
| Cognito Users AWS | Manage AWS Cognito user authentication and authorization using AWS CLI commands | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4864868365) |
| ElasticCache Alarms | Configure AWS ElasticCache monitoring alerts for Redis performance and availability issues | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4892688390) |
| Initialize Domain | Domain initialization procedures for new Cloud Collector namespace setup and configuration | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4145348678) |
| KeyChain GREEN | Configure KeyChain credential management for secure collector authentication in GREEN cluster | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4222976008) |
| Launch Collector | Launch and configure collector instances in Cloud Collector application environment | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4150427750) |
| Onboard Customers | Customer onboarding in Cloud Collector with domain provisioning and initial configuration | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4256202781) |
| Redis Node Move | Relocate Redis cluster nodes with zero downtime using migration procedures | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4243652681) |
| Update CloudFlare | Update CloudFlare egress firewall rules to allow new domains for collectors | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4043604000) |
| Update Egress Rules | Configure firewall whitelist URLs enabling Cloud Collectors to reach external sources | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4486496291) |
| Upload GovCloud | Upload collector images to AWS GovCloud using colcatir tool for deployment | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4423581722) |
| User Mgmt Legacy | User administration and authentication for legacy pre-Kubernetes collector server deployments | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3701800994) |
| User Mgmt RED | Manage user access and permissions for RED cluster collector environments | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4459135004) |
| View Logs GREEN | Access and analyze collector logs in GREEN cluster for troubleshooting | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4305059843) |
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
| Default Resources | Configure default resource limits and requests per collector instance at domain | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4110712939) |
| Domain Limits API | Increase domain limits via API for storage collectors and ingestion rate | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4347920385) |
| Encrypted Data Key | Retrieve encrypted data key for configuring collector-server-backup S3 helm values | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4137910279) |
| RED Access Control | Manage user authentication and access control for RED cluster environment | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/4791074841) |
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


#### From Legacy Components
| Title | Description | Link |
|-------|-------------|------|
| CC in Environments | Cloud Collector deployment and configuration across different production and development environments | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/2951741441) |
| CC Onboarding | Step-by-step guide for onboarding new customers and domains to Cloud Collector platform | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/1338409151) |
| CC Domain Creation | Create self-service domains and namespaces using Management API for Cloud Collector tenants | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/2817753101) |
| CC Management API | Increase domain limits, scale collectors, and manage configurations via Management API | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3355214849) |
| CC Egress Rules | Update firewall whitelist rules and Cloud-Flare egress policies for collector connectivity | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/2913632275) |
| CC User Management | Manage users, access control, and authentication for RED and legacy collector servers | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/1325596733) |
| CC Redis Ops | Redis node migration procedures and operational tasks for Cloud Collector infrastructure | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/3028877334) |
| CC K8s Operations | Kubernetes operational tasks including static IP, credentials, domain management and pod scaling | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/2926215219) |
| CC Architecture | Technical architecture overview of Cloud Collector components and system design patterns | [View](https://devoinc.atlassian.net/wiki/spaces/0CC/pages/2836234255) |

### B. Batrasio

#### Core Documentation
| Title | Description | Link |
|-------|-------------|------|
| Batrasio Docs | Batrasio event load balancer comprehensive documentation covering architecture and operations | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/4070146065) |
| Batrasio Service | Event load balancer ingestion documentation covering architecture deployment and operations | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/5486379024) |
| ELB Batrasio | Event load balancer configuration for distributing ingestion traffic across datanodes | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/631538081) |
| Ingestion Dashboard | Batrasio ingestion monitoring dashboard tracking throughput latency and datanode health | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5384765446) |

#### Operations
| Title | Description | Link |
|-------|-------------|------|
| Status Check Fix | Resolve AWS status check failures on Batrasio EC2 instances | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3834052609) |
| Ubuntu Upgrade | Upgrade Ubuntu LTS version on Batrasio servers across multiple releases | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3379986496) |

#### Troubleshooting
| Title | Description | Link |
|-------|-------------|------|
| APAC Issue | Batrasio APAC deployment issue root cause analysis for regional ingestion failures | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5742788618) |
| Batrasio Deploy | Deploy Batrasio load balancer service with TLS configuration and datanode registration | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/1949106177) |
| IRCA-152 | Batrasio hang causing ingestion loss with mitigation steps and permanent fix | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5551423489) |
| Process Restart | Preemptive Batrasio process restart procedures to prevent memory leaks and connection exhaustion | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3591569467) |

#### Certificate Management
| Title | Description | Link |
|-------|-------------|------|
| AWS Cert Replace | AWS Batrasio certificate replacement using ACM and load balancer integration | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3305308280) |
| Cert Replace HA | Replace certificate on HA Batrasio cluster with zero downtime rolling update | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3305308280) |
| Cert Replace Sample | AWS Batrasio certificate replacement workflow example with ACM integration | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3533013037) |
| Generate Cert | Create SSL TLS certificates for Batrasio ingestion endpoints with validation | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/1947435092) |
| IBM Cert Replace | IBM VPC Batrasio certificate replacement for secure ingestion with certificate chain validation | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3635511387) |
| ZeroSSL Deploy | Deploy public endpoint with free ZeroSSL or Let's Encrypt certificates for Batrasio | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3277127725) |


#### From Legacy Components
| Title | Description | Link |
|-------|-------------|------|
| Batrasio Docs | Comprehensive documentation covering Batrasio service architecture configuration and operational procedures | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/1355055106) |
| Batrasio Cert Gen | Generate TLS certificates for Batrasio using CSR signing with relayCA for secure communications | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/1369604128) |
| AWS Batrasio Cert | Complete procedure for AWS Batrasio certificate replacement including backup and validation steps | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/2914123787) |
| IBM Batrasio Cert | IBM VPC Batrasio certificate replacement workflow for secure relay endpoint configuration | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3028418591) |
| Batrasio Ubuntu Upgrade | Upgrade Ubuntu LTS releases on Batrasio instances from xenial bionic to focal versions | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/2831286284) |
| Batrasio Status Fix | Fix AWS EC2 status check failures on Batrasio machines using reboot and target registration | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/2828730399) |
| Batrasio Public SSL | Deploy ZeroSSL and Let's Encrypt public certificates for Batrasio endpoint POC environment | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/2965012493) |
| Batrasio Auto Restart | Preemptive Batrasio process restart procedure triggered by increased error rate detection monitoring | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/2916499499) |

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

## 3. Database



### B. Database Services

#### MySQL
| Title | Description | Link |
|-------|-------------|------|
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



---

## 4. Query & Data Processing



### B. Query Interface



#### Lookups & Tables
| Title | Description | Link |
|-------|-------------|------|
| Lookups Propagated | Confirm lookup table propagation to datanodes ensuring enrichment data is available cluster-wide | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601209006) |


### C. Devo Query Tools



#### Health Check
| Title | Description | Link |
|-------|-------------|------|
| Mason Healthcheck | Platform component availability monitoring service tracking uptime and service dependencies | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3967451145) |


---


#### From Legacy Components
| Title | Description | Link |
|-------|-------------|------|
| Asilo Overview | Aggregation Engine architecture overview covering distributed job processing and data pipeline management | [View](https://devoinc.atlassian.net/wiki/pages/viewpage.action?pageId=1301168135) |
| Asilo Introduction | Introduction to Asilo aggregation capabilities use cases and core functionality for data processing | [View](https://devoinc.atlassian.net/wiki/pages/viewpage.action?pageId=1301069845) |
| Asilo Installation | Step-by-step Asilo installation guide covering prerequisites dependencies and initial system setup | [View](https://devoinc.atlassian.net/wiki/pages/viewpage.action?pageId=1301299263) |
| Asilo Configuration | Configure Asilo job parameters resource allocation scheduling and integration with Devo platform | [View](https://devoinc.atlassian.net/wiki/pages/viewpage.action?pageId=1301299283) |
| Asilo Upgrade | Upgrade procedures for Asilo including version migration compatibility checks and rollback strategies | [View](https://devoinc.atlassian.net/wiki/pages/viewpage.action?pageId=1301299301) |
| Asilo Monitoring | Monitor Asilo job execution performance metrics and system health using built-in observability tools | [View](https://devoinc.atlassian.net/wiki/pages/viewpage.action?pageId=1301561368) |
| Asilo Troubleshooting | Common Asilo issues error patterns and resolution steps for job failures and performance problems | [View](https://devoinc.atlassian.net/wiki/pages/viewpage.action?pageId=1301626924) |
| Asilo Operations | Day-to-day Asilo operations including job management maintenance tasks and operational best practices | [View](https://devoinc.atlassian.net/wiki/pages/viewpage.action?pageId=1301659682) |

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

## 6. Monitoring & Observability

### A. Core Monitoring

| Title | Description | Link |
|-------|-------------|------|
| Monitoring Home | Monitoring operations hub and operational guidelines for 24x7 platform surveillance | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1294467226) |
| Welcome Pack | Onboarding materials for monitoring ops team with training resources and access procedures | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1329954973) |
| Procedures | SOPs and runbooks for daily operations covering routine tasks and emergency response | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1291485814) |
| Channels | Communication channels and escalation paths for incident coordination and status updates | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/4842717189) |
| Observability | Observability framework for platform infrastructure using metrics logs and distributed tracing | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4785766469) |
| HLA | High-level architecture diagram for observability showing data flow and component relationships | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/4521459739) |
| APM | Application performance monitoring framework tracking latency throughput and error rates | [View](https://devoinc.atlassian.net/wiki/spaces/TV/pages/937066499) |
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

## 7. Devo Alerts

### A. Alert System


#### Platform Alerts
| Title | Description | Link |
|-------|-------------|------|
| Alert Manager | Alert manager architecture and design covering routing grouping and notification pipelines | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/5024546820) |
| Alert Manager KT | Knowledge transfer and operational procedures for managing alert lifecycle and configurations | [View](https://devoinc.atlassian.net/wiki/spaces/TE/pages/5181669406) |
| Alerts Catalogue | Complete catalog of platform alerts with descriptions severity and remediation steps | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1780090029) |
| Alerts Docs | Alert types and response procedures with runbooks for common platform issues | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1771143211) |
| Alerts Notifications | Alerts system architecture and delivery covering email Slack PagerDuty and webhook integrations | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/943751695) |
| bcache_hit_ratio | Alert for low bcache hit ratio indicating storage cache performance degradation | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/5102272513) |
| Cartero Delivery | Alert delivery controller service managing notification routing retry logic and delivery guarantees | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/985235770) |
| cs_batrasio_max_len | Alert when Batrasio event size exceeds maximum length causing ingestion errors | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3542253597) |
| DAMAGE | Alert manager component documentation for distributed alert generation and management engine | [View](https://devoinc.atlassian.net/wiki/spaces/PROYEC/pages/649396787) |
| Deprecated Alerts | Inventory of deprecated alerts tracking alerts removed from active monitoring | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/5741576193) |
| Devo Alerts | Main documentation hub for alerts including setup configuration and best practices | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1771634723) |
| Lomana Health | Lomana datanode health monitoring service tracking ingestion and resource utilization | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3250487339) |
| Marketplace Alerts | Marketplace application monitoring alerts for availability and performance tracking | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3420553262) |
| noc_asilo_failures | Alert for Asilo aggregation job failures indicating data processing errors | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1795850399) |
| noc_batrasio_conn | Alert for Batrasio connection failures affecting data ingestion pipeline | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1933869355) |
| noc_batrasio_stalled | Alert when Batrasio events stall in queue indicating processing bottleneck | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/4033937415) |
| noc_batrasio_targets | Alert when Batrasio load balancer has no available datanode targets | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1937375778) |
| noc_chasys_serrea | Alert for Chasys Serrea cluster issues affecting query processing performance | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/4827840515) |
| noc_licor_indexing | Alert for Licor indexing failures preventing query access to data | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1813676033) |
| noc_malote_access | Alert for Malote query access denied errors indicating permission issues | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2926247937) |
| noc_malote_outcon | Alert for Malote output connection failures when delivering query results | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2263646255) |
| noc_orientdb_db | Alert for OrientDB database errors affecting metadata and configuration storage | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3815800835) |
| noc_orientdb_server | Alert for OrientDB server failures impacting platform metadata services | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3815768069) |
| noc_secops_lookups | Alert when SecOps lookup tables are empty affecting threat intelligence enrichment | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2189656119) |
| noc_sudden_drop | Alert for sudden drop in ingestion rate indicating data pipeline failure | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/4396548099) |
| ServiceOps Alerts | ServiceOps platform alerts for infrastructure monitoring and incident detection | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3398238409) |


### B. Knowledge Base

| Title | Description | Link |
|-------|-------------|------|
| Troubleshoot Alerts | Alert troubleshooting guide covering false positives missing alerts and delivery failures | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601206659) |
| Deploy OOTB | Deploy out-of-the-box SecOps alerts for common security use cases and threat detection | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601207194) |
| Query Timeouts | Resolve delayed alert queries by optimizing LINQ expressions and adjusting time ranges | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601206818) |
| List Queries | List active alert queries to identify resource-intensive alerts and optimization candidates | [View](https://devoinc.atlassian.net/wiki/spaces/SKB/pages/5601206396) |

---

## 8. Security Products

### A. UEBA

#### Current Version
| Title | Description | Link |
|-------|-------------|------|
| UEBA 2.0 | Behavioral analytics platform for threat detection using machine learning and anomaly detection | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4458053634) |
| Architecture 2.0 | UEBA 2.0 architecture rationalization and system design for scalable analytics | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/3936551012) |
| Architecture Test | Testing procedures and validation plans for UEBA 2.0 architecture components | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/3940286473) |
| Behavioral Analytics | User and Entity Behavior Analytics platform for detecting insider threats anomalies | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/3632857089) |
| Collector Design | UEBA data collection architecture and design patterns for behavioral analytics ingestion | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/3653337108) |
| Contributing Guide | Developer guide for contributing features and improvements to UEBA platform | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/3633348635) |
| Deployment Guide | Complete deployment procedures for UEBA tenants including infrastructure sizing and configuration | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4235886618) |
| Initiative Roadmap | Strategic planning and technical rationalization for UEBA product development roadmap | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/3629613364) |
| Install Onboard | Complete installation configuration and tenant onboarding procedures for UEBA 2.0 platform | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/4563009600) |
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


#### From Legacy Components
| Title | Description | Link |
|-------|-------------|------|
| UEBA Architecture | Behavioral Analytics architecture covering background technical requirements and 2.0 design overview | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/1422295041) |
| UEBA Installation | UEBA 2.0 installation configuration onboarding process for tenants and customer domain management | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/2827616304) |
| UEBA Test Plan | Architecture 2.0 validation test plan covering use cases probability models and testing areas | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/1444544522) |
| UEBA Rationalization | Initiative rationalization documentation covering contribution guidelines and collector design patterns | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/2746122241) |
| UEBA Collector Design | Collector code design patterns and architecture principles for behavioral analytics data ingestion | [View](https://devoinc.atlassian.net/wiki/spaces/SCISEC/pages/2745008129) |

### B. SOAR

#### Operations
| Title | Description | Link |
|-------|-------------|------|
| Contact Details | OnCall escalation and emergency response contacts for critical platform and tenant issues | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5060427791) |
| Escalation Matrix | Incident severity and notification procedures defining priority levels and response times | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/4839440405) |
| Monitoring Dashboard | Platform health metrics and incident tracking with visualization of playbook runs and errors | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/4995579905) |
| Scale SQS | Scale SQS collector workers to handle increased AWS message volume throughput | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/5176295438) |
| SOAR Operations | Platform management and incident response workflows for orchestrating security operations playbooks | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5702680583) |
| System Properties | Configuration settings and performance tuning parameters for playbook execution and resource limits | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/4981063681) |

#### Alerts
| Title | Description | Link |
|-------|-------------|------|
| soar_batch_error | Alert for SOAR batch execution errors indicating playbook processing failures | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3844571137) |
| soar_lagging_streams | Alert for SOAR data stream lag affecting real-time incident response | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3868033025) |
| soar_loss_logs | Alert for SOAR log ingestion failures or missing data in platform | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3868164097) |
| soar_memory_usage | Alert for SOAR service memory consumption exceeding safe thresholds | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3868065835) |
| soar_restarts | Alert for excessive SOAR service restarts indicating stability issues | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3868065793) |
| soar_unhealthy | Alert for SOAR production instance health check failures requiring investigation | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3844571158) |
| soar_zero_batch | Alert when SOAR batch jobs stop executing indicating orchestration failure | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/3868065814) |

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


#### From Legacy Components
| Title | Description | Link |
|-------|-------------|------|
| SOAR Unhealthy Instance | Troubleshoot and resolve unhealthy production SOAR instances including service health diagnostics | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1339883530) |
| SOAR Zero Executions | Debug SOAR batch execution failures when zero successful batch runs detected in monitoring | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2820571170) |
| SOAR Lagging Streams | Resolve SOAR stream processing lag issues affecting real-time data ingestion and playbook execution | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2820735032) |
| SOAR High Errors | Investigate and fix high batch error rates impacting SOAR automation workflow execution reliability | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2820800545) |
| SOAR Service Restarts | Address excessive SOAR service restart loops indicating underlying stability or resource issues | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2821062689) |
| SOAR Memory Usage | Monitor and resolve high service memory usage alerts for SOAR components and containers | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2821259283) |
| SOAR Loss of Logs | Diagnose and recover from SOAR log loss incidents affecting audit trails and troubleshooting | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2821324835) |
| SOAR Escalation Matrix | On-call escalation procedures and contact matrix for SOAR production incidents and emergency response | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/2820866079) |
| SOAR SQS Scaling | Scale SQS collectors for SOAR ingestion handling high-volume message queues and throughput optimization | [View](https://devoinc.atlassian.net/wiki/spaces/03NOC/pages/1440047118) |

## 9. Incident Management

### A. IRCA Reports

| Title | Description | Link |
|-------|-------------|------|
| IRCA-156 | CaixaBank Serrea cluster outage analysis with root cause identification and preventive measures | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5704056838) |
| IRCA-153 | Santander AWS hardware failure and mitigation covering detection response and recovery procedures | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5574721537) |
| IRCA-152 | Batrasio hang causing CaixaBank data loss with detailed timeline and remediation actions | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5551423489) |
| IRCA-132 | GCP Telefonica datanode lookup propagation failure resulting in enrichment errors and resolution | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5041094682) |
| IRCA-116 | APAC low ingestion from certificate issues with impact analysis and certificate renewal procedures | [View](https://devoinc.atlassian.net/wiki/spaces/RDT/pages/4957601816) |





---

## 10. Devo Platform

### Core Platform
| Title | Description | Link |
|-------|-------------|------|
| Release Notes | Version updates and deployment changes with new features bug fixes and upgrade procedures | [View](https://devoinc.atlassian.net/wiki/spaces/GLBREP/pages/942997601) |


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

### C. Docker

| Title | Description | Link |
|-------|-------------|------|
| Deploy Docker | Docker container deployment procedures for isolated service packaging and orchestration | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/999424016) |

### D. Kubernetes

| Title | Description | Link |
|-------|-------------|------|
| Deploy K8s | Kubernetes cluster deployment using helm charts for container orchestration | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/3311927338) |
| Deploy Terraform | Terraform infrastructure as code deployment for automated cloud resource provisioning | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/741834801) |
| K8s Reference | Kubernetes operations reference guide covering deployments services ingress and persistent volumes | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/3458957453) |
| Platform Appendices | Additional reference materials and appendices for platform deployment procedures | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/942997687) |
| Platform Process | Deprecated platform deployment documentation marked for removal from confluence | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/741834753) |


#### From Legacy Components
| Title | Description | Link |
|-------|-------------|------|
| K8s Deployment | Kubernetes deployment strategies and best practices for Devo platform services and applications | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/1301102593) |
| Platform Deploy Ansible | Ansible-based platform deployment automation for infrastructure provisioning and configuration management | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/1298956289) |
| Platform Deploy Terraform | Terraform infrastructure-as-code deployment patterns for cloud resources and environment provisioning | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/1298923534) |
| Platform Deploy Docker | Docker containerization and image management strategies for platform service deployment workflows | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/1298890785) |
| Platform Deploy Jenkins | Jenkins CI/CD pipeline configuration for automated build testing and deployment orchestration | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/1300873229) |
| Relay Deployment | Relay service deployment procedures including configuration network setup and health verification | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/1301102627) |
| Auxiliary Services Deploy | Deploy auxiliary platform services including monitoring logging and supporting infrastructure components | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/1301266465) |

### E. CI/CD & ArgoCD

| Title | Description | Link |
|-------|-------------|------|
| Deploy Jenkins CI/CD | Jenkins CI CD pipeline configuration for automated platform build and deployment | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/3313008642) |
| Deploy UEBA | Deploy UEBA 2.0 tenants using ArgoCD with GitOps workflows and automated rollback | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/4658331653) |

### F. Service Deployments

| Title | Description | Link |
|-------|-------------|------|
| Auxiliaries Services | Deploy auxiliary supporting services for platform monitoring logging and operations | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/741834854) |
| Barcenas Backup | Barcenas backup system deployment with S3 integration retention policies and monitoring | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/312803337) |
| Matas-Mafias | Deploy Matas-Mafias data processing service with stream processing and aggregation capabilities | [View](https://devoinc.atlassian.net/wiki/spaces/CO/pages/642121877) |
| Relay Deploy | Deploy relay services for secure log collection from customer environments | [View](https://devoinc.atlassian.net/wiki/spaces/DPA/pages/2189657622) |

---

## 12. Strike48 - AI Platform


### B. Managed Control Plane (MCP)
| Title | Description | Link |
|-------|-------------|------|
| MCP Deployment | MCP deployment procedures guide covering installation configuration and multi-tenant management | [View](https://devoinc.atlassian.net/wiki/spaces/LHUB/pages/5457870850) |

### C. Matrix Studio

---

**End of Document**
