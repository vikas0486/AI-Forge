# Devo Legacy DevOps Documentation - Complete Reference

**Generated:** 2026-04-23  
**Source:** Confluence - devoinc.atlassian.net/wiki  
**Purpose:** Comprehensive DevOps & Operations documentation index for Devo Platform

---

## Table of Contents

1. [Cloud Collector](#1-cloud-collector)
2. [UEBA (User Entity Behavior Analytics)](#2-ueba-user-entity-behavior-analytics)
3. [SOAR (Security Orchestration Automation Response)](#3-soar-security-orchestration-automation-response)
4. [Devo Platform](#4-devo-platform)
5. [Datanodes](#5-datanodes)
6. [Kubernetes & K8s Packages](#6-kubernetes--k8s-packages)
7. [Batrasio (Ingestion Service)](#7-batrasio-ingestion-service)
8. [Certificates Management](#8-certificates-management)
9. [Malote (Query Engine)](#9-malote-query-engine)
10. [Monitoring & Observability](#10-monitoring--observability)
11. [Grafana-Prometheus Alerts](#11-grafana-prometheus-alerts)
12. [Devo Alerts](#12-devo-alerts)
13. [Asilo (Aggregation Engine)](#13-asilo-aggregation-engine)
14. [Additional Service Components](#14-additional-service-components)
15. [Infrastructure & Operations](#15-infrastructure--operations)
16. [Incident Management](#16-incident-management)

---

## 1. Cloud Collector

**Primary Space:** 0CC (Cloud Collector)  
**Related Spaces:** SKB, RDT, CO, CSUP

### Root Documentation
- **Cloud Collector in Different Environments**
  - Space: 0CC
  - URL: https://devoinc.atlassian.net/wiki/spaces/0CC/pages/[ID]

### Documentation & Training
1. **How to onboard new customers in the Cloud Collector** - 0CC
2. **Installing Cloud Collector Application Through NASS** - 0CC
3. **Initializing the Domain** - 0CC
4. **Launching a Collector in Cloud Collector Application** - 0CC
5. **Accessing Administrative View for Cloud Collector Application in Self Domain** - 0CC
6. **Using KeyChain in Cloud Collector Application (GREEN Cluster)** - 0CC
7. **How to Restart a Collector in Cloud Collector Application (GREEN Cluster)** - 0CC
8. **Viewing Collector Logs in Cloud Collector Application (GREEN Cluster)** - 0CC

### Advanced Operational Tasks
1. **User Management in Legacy Collector Server** - 0CC
2. **User management in the RED clusters** - 0CC ❌
3. **Getting Devo domain associated to a Cloud Collector namespace** - 0CC
4. **Creating self-service domain (Cloud Collector namespace) using CURL to Management API** - 0CC
5. **Add/update new domain to allowed domains in Cloud-Flare egress rules** - 0CC
6. **Self-Service: Set default resources and limits per collector instance at domain level** - 0CC
7. **Self Service: Get `encryptedDataKey` to configure in collector-server-backup (s3backup) helm values** - 0CC
8. **Emergency procedure to manual change mutability and permissions of ECR repositories of Collectors catalog** - 0CC
9. **Emergency procedure to manual remove specific version of a collector from Collectors "green" catalog** - 0CC
10. **Redis node move procedure** - 0CC
11. **Enable add new collector using Collector-UI in migrated domain on legacy environment** - 0CC
12. **Increasing domain limits in Cloud Collector using Management API directly** - 0CC
13. **Scale a collector using Management API** - 0CC
14. **Upload a collector to GovCloud using colcatir** - 0CC
15. **Emergency procedure to fix a certificate** - 0CC
16. **Cognito users with AWS commands** - 0CC

### Firewall & Network
- **How to Update Egress Rules (whitelist URLs) on Firewall to enable Cloud Collectors** - 0CC

### Monitoring & Alarms
- **ElasticCache Alarms** - 0CC

### Operational Tasks in Collector Server Kubernetes
- **Operational Tasks in Collector Server Kubernetes** - 0CC
  - Changing cron expression on a Scheduled Reports Collector
  - Static IP Whitelist for "Cloud Collector" self service
  - Static IP for a collector (not "Cloud Collector" self-service)
  - Credentials replacement for collector
  - Configure collector as direct send
  - Domain creation
  - Domain deletion
  - Set the number of pods

### Architecture
- **Cloud Collector Architecture** - 0CC

### Access Control
- **How to allow/deny access to a user for the RED cluster** - 0CC

### Knowledge Base Articles
- **[KB] Using the Cloud Collector App** - SKB (ID: 5601207846)
- **[KB] Enable Cloud Collector App for a domain** - SKB
- **[KB] Troubleshooting: collectors in Cloud Collector App** - SKB
- **[KB] Complete reset procedures** - SKB
- **[KB] SQS Collector scaling** - SKB
- **[KB] Emergency collector downgrade** - SKB

---

## 2. UEBA (User Entity Behavior Analytics)

**Primary Space:** SCISEC (Security Science)  
**Related Spaces:** SKB, DPA

### Core UEBA Documentation
1. **[KB] UEBA - Entity Behavioral Analytics (CS KB)** - SKB (ID: 5601207846)
2. **[KB] On-boarding Customers to UEBA v1.5** - SKB (ID: 5601207969)
3. **[KB] Devo Behavior Analytics - Collector Images** - SKB (ID: 5601207939)
4. **[KB] Common Queries for Devo Behavior Analytics Debug** - SKB (ID: 5601207928)
5. **[KB] Troubleshooting: Devo Behavior Analytics (UEBA)** - SKB (ID: 5601207865)

### Main Architecture
- **Behavioral Analytics (UEBA)** - SCISEC (ID: 4458053634)
  - Background
  - Architecture Diagram
  - Technical Requirements
  - Collector Code design
  - Architecture 2.0 Overview
  - Specific Topics
  - Existing work
  - Future work / TODO

### UEBA 2.0 Documentation
1. **UEBA 2.0** - SCISEC (ID: 4458053634)
2. **UEBA 2.0 Migration Plan** - SCISEC (ID: 4993712144)
3. **UEBA 2.0 Rollback Plan** - SCISEC (ID: 4993613831)
4. **UEBA 2.0.1** - SCISEC (ID: 4979130369)
5. **UEBA 2.0.x Release Plan** - SCISEC (ID: 4920967171)
6. **UEBA 2.0 - Product Walkthrough** - SCISEC (ID: 4755128321)
7. **UEBA 2.0 Enablement** - SCISEC (ID: 4615307280)
8. **UEBA 2.0 Deployments** - SCISEC (ID: 4608065603)
9. **UEBA 2.0 - Deployment** - SCISEC (ID: 4235886618)
10. **UEBA 2.0 - Stress Testing** - SCISEC (ID: 4007362585)
11. **UEBA 2.0 Pending Items/Issues** - SCISEC (ID: 4266524693)
12. **UEBA 2.x Support Model** - SCISEC (ID: 4894556161)
13. **UEBA 2.0 Installation / Configuration / Onboarding Tenants / Customer Domains** - SCISEC (ID: 4563009600)

### UEBA Version History
- **UEBA 1.9** - SCISEC (ID: 4172087297)
- **UEBA 1.8** - SCISEC (ID: 4125229057)
- **UEBA 1.7** - SCISEC (ID: 4051370003)
- **UEBA v1.7 Features** - SCISEC (ID: 4038950968)
- **UEBA v1.6 Features** - SCISEC (ID: 4029218827)
- **UEBA v1.5 - New Features** - SCISEC (ID: 4014473235)

### Testing & Architecture
- **UEBA v2.0 architecture test plan** - SCISEC (ID: 3940286473)
  - Arch 2.0 Use case validation
  - Test planning notes
  - Broad areas to cover
  - Test case areas - Simple Probability

### Technical Documentation
1. **UEBA Product Release Process** - SCISEC (ID: 4125163528)
2. **UEBA Collector's Recipe release process** - Personal Space (ID: 4169564186)
3. **Devo UEBA Signals Proposal** - SCISEC (ID: 4913987606)
4. **Collector Query to UseCase Mapping** - SCISEC (ID: 4124934180)

### Deployment & Operations
1. **[ArgoCD] How to deploy new tenants in UEBA 2.0** - DPA (ID: 4935057436)
2. **How to deploy new tenants in UEBA 2.0** - DPA (ID: 4658331653)
3. **Devo Behavior Analytics - Customer Off-boarding Guide** - SCISEC (ID: 4005855391)

### Rationalization
- **UEBA Initiative Rationalization** - SCISEC
  - Contributing to Behavioral Analytics
  - Collector Design
  - Devo Behavior Analytics - Architecture 2.0 Rationalization

---

## 3. SOAR (Security Orchestration Automation Response)

**Primary Space:** LHUB  
**Related Spaces:** 03NOC, Strike48, SKB, CSUP

### Core SOAR Operations
1. **SOAR Operations** - LHUB (ID: 5702680583)
2. **SOAR OVA Deployment Guide** - LHUB (ID: 5524029441)
3. **Devo SOAR MCP Setup Guide (Cluster Hosted)** - Strike48 (ID: 5528027137)
4. **SOAR System Properties** - LHUB (ID: 4981063681)

### Production Incidents & On-Call
- **soar_unhealthy_production_instance** - 03NOC
- **soar_zero_batch_executions** - 03NOC
- **soar_lagging_streams** - 03NOC
- **soar_high_batch_error** - 03NOC
- **soar_too_many_service_restarts** - 03NOC
- **soar_high_service_memory_usage** - 03NOC
- **soar_loss_of_logs** - 03NOC
- **SOAR On-Call Escalation Matrix** - 03NOC (ID: 4839440405)

### Tenant Management
1. **SOAR's Tenant Onboarding Guide** - Strike48 (ID: 5529960456)
2. **SOAR Tenant Onboarding Runbook: Production Procedures for New Employee** - LHUB (ID: 5449383937)
3. **SOAR Tenant Onboarding Runbook: Stage and INT Procedures for New Employee** - LHUB (ID: 5443420163)
4. **Tenant onboarding with OOB SOAR data** - LHUB (ID: 5431263233)

### Operational Procedures
1. **Raise a request for New SOAR instance** - LHUB (ID: 5001641990)
2. **How to Request for a New Aurora Instance** - LHUB (ID: 4947673108)
3. **SOAR Monitoring dashboard in self domain** - LHUB (ID: 4995579905)
4. **SOAR OnCall Contact Details** - LHUB (ID: 5060427791)
5. **How to scale SQS collectors** - 03NOC

### Migration & Integration
1. **Migrate SOAR Govcloud Instance to Commercial** - LHUB (ID: 5169152017)
2. **Migrate a tenant from one region to another** - LHUB (ID: 5385748481)
3. **Connect SOAR with Strike48** - LHUB (ID: 5433131009)
4. **Existing Devo Customer to Strike48 Prospector Studio with SOAR Integration** - Strike48 (ID: 5529960449)
5. **Brand New Customer to Strike48 Prospector Studio + Devo Backend + SOAR App** - Strike48 (ID: 5529862146)

### Knowledge Base
1. **[KB] SOAR (CS KB)** - SKB (ID: 5601207492)
2. **[KB] Basic Playbook Creation in SOAR** - SKB (ID: 5601207508)
3. **[KB] Self tables for investigating SOAR issues** - SKB (ID: 5601207656)
4. **[KB] Login Success/Fail of Legacy SOAR instances using Devo SIEM** - SKB (ID: 5601207689)
5. **Basic Playbook Creation in SOAR** - CSUP (ID: 4992794641)

### Technical Documentation
1. **How Node Execution Works in SOAR** - LHUB (ID: 5107712007)
2. **MCP Deployment in Strike48** - LHUB (ID: 5457870850)
3. **ThreatLink Agent Deployment SOP** - LHUB (ID: 5432803329)
4. **Aurora Architecture Diagram** - LHUB (ID: 5006229505)
5. **Matrix Studio Provisioning Automation** - Strike48 (ID: 5700583442)

### Training
1. **SOAR training by Asish Verma** - PROYEC (ID: 5189664770)
2. **SOAR training by Asish Verma - Part 2 17-Sep-2025** - PROYEC (ID: 5200936961)

### Support & Policies
1. **Policy on Technical Support for SOAR** - CSUP (ID: 3757506763)
2. **Procedure: Support for SOAR** - CSUP (ID: 3803579810)
3. **SOAR Customer list** - LHUB (ID: 5024514064)
4. **Production Support Ticket Template** - LHUB (ID: 5067243548)

### Infrastructure
1. **BNYM Infrastructure** - LHUB (ID: 5711462404)
2. **BNYM SaaS mTLS Certificate Generation SOP** - LHUB (ID: 5061247008)
3. **Launch a new SOAR customer in US GovCloud** - LHUB (ID: 4827840604)

---

## 4. Devo Platform

**Primary Space:** DPA (Devo Platform Administration)  
**Related Spaces:** GLBREP, RDT, SKB, CO

### Platform Overview & Architecture
- **Devo Platform Documentation** - DPA
- **Platform Architecture Overview** - GLBREP
- **Platform Components** - GLBREP

### Platform Administration & Tools
1. **Platform Admin Console** - DPA
2. **LINQ Query Language** - GLBREP
3. **Internal Tools** - DPA
4. **Platform Management APIs** - RDT

### Deployment & Installation
1. **Platform Deployment Process Overview** - DPA
2. **Deployment with Ansible** - DPA (ID: 741834791)
3. **Deployment with Terraform** - DPA
4. **Deployment with Docker** - DPA
5. **Deployment with Kubernetes** - DPA (ID: 741834791)
6. **Deployment with Jenkins** - DPA
7. **Deployment Types** - DPA (ID: 741834778)

### Maintenance & Operations
1. **Platform Maintenance and Operations** - DPA (ID: 741834874)
2. **Common Operations** - DPA (ID: 760317188)
3. **Platform Monitoring** - DPA

### Platform Services
1. **SOAR Integration** - LHUB
2. **WebApp Service** - RDT
3. **NASS (Network Access Security Service)** - RDT
4. **Dori Service** - RDT
5. **Asilo (Aggregation)** - GLBREP

### Platform Releases
- **Platform Release Notes** - GLBREP (ID: 942997601)
- **Release Management** - RDT
- **Version Control** - RDT

### Configuration
- **Platform Configuration Reference** - DPA
- **Special Configurations** - DPA

### Security
- **Certificate Management** - RDT
- **Authentication & SSO** - DPA
- **Platform Security Policies** - CISO

### Data Management
- **Data Ingestion** - DPA
- **Parsing Engine** - PNC
- **Cloud Integration** - CO

### Training & Onboarding
- **Platform Training Materials** - GLBREP
- **Certification Programs** - 0TD

### Knowledge Base
- **[KB] Platform Administration** - SKB
- **[KB] Platform Troubleshooting** - SKB
- **[KB] Domain Management** - SKB

---

## 5. Datanodes

**Primary Space:** DPA, RDT, CO  
**Related Spaces:** GLBREP, SKB

### Core Architecture
1. **Data Nodes Components and Architecture** - DPA (ID: 741834810)
2. **Data Nodes Sub-Components** - GLBREP (ID: 985235536)
3. **Data Nodes Deployment** - DPA (ID: 741834805)

### Deployment Documentation
1. **DN Deployment on AWS** - DPA (ID: 741834850)
2. **DN Deployment on Azure** - DPA (ID: 741834846)
3. **DN on Bare Metal with Ansible** - DPA (ID: 741834838)
4. **DN on Bare Metal - Using Virtual Machines** - DPA (ID: 741834842)

### Operations & Maintenance
1. **WIP: Systems Oncall Datanode Stop/Start** - RDT (ID: 995786804)
2. **Delete Data From Datanodes** - CO (ID: 779649215)
3. **How to expand datanode disks** - CO (ID: 434962569)
4. **Datanode Health Check** - RDT (ID: 5014323203)

### Automation & Resilience
1. **Datanode Resilience Infrastructure: Automated Health Monitoring and Self-Healing Capabilities** - CO (ID: 5599952898)
2. **Automation: Resilience_Infrastructure** - RDT (ID: 5586812931)
3. **Datanode Trash Cleanup Automation Framework** - GLBREP (ID: 5553946635)

### Customer Deployments
1. **AT&T Data Nodes Install Process** - RDT (ID: 708804856)
2. **AT&T Maintenance and Operations** - RDT (ID: 708772487)
3. **CIBC Deployment Guide** - RDT (ID: 760479834)
4. **Telematics Datanode Bill of Materials - CCC-CLM** - PROYEC (ID: 993493164)

### Knowledge Base
1. **[KB] How To Check Which Datanodes are Suffering Connection Issues** - SKB (ID: 5601198372)
2. **[KB] How To Confirm Lookups have Propagated to all data nodes** - SKB (ID: 5601209006)

### Supporting Components
1. **Data Indexers (Licor)** - GLBREP (ID: 985235532)
2. **Compression Engine (Cotillo)** - GLBREP (ID: 985235506)
3. **Domain Balancer (Affinity)** - GLBREP (ID: 985235540)
4. **Back-Up Processes: Data Nodes, Parsers, Web, MySQL** - GLBREP (ID: 985235750)

### Troubleshooting
1. **DN - Lomaniacos** - RDT (ID: 4492820483)
2. **IRCA-132 - GCP-TEF datanode down, and lookup issues after restart** - RDT (ID: 5041094682)
3. **IRCA-153 [Santander] AWS Hardware Failure Event Loss - RCA** - RDT (ID: 5574721537)
4. **IRCA-156: CaixaBank Serrea Cluster Outage** - RDT (ID: 5704056838)

### Query & Analysis
1. **LINQ for Domain and Platform Analysis** - GLBREP (ID: 942998558)
2. **Common Operations** - DPA (ID: 760317188)

### Reference
1. **Appendix: Components Latest Versions** - DPA (ID: 809173138)
2. **Appendix: Deployment Component Check-List** - DPA (ID: 744424326)
3. **Appendix Ports Usage** - DPA (ID: 756711473)

---

## 6. Kubernetes & K8s Packages

**Primary Space:** DPA, GLBREP  
**Related Spaces:** SKB, LHUB, Strike48

### Core K8s Documentation
1. **Deployment with Kubernetes** - DPA (ID: 741834791)
2. **K8s Events Monitoring** - GLBREP
3. **Jenkins Deployment on K8s** - GLBREP

### MCP & Strike48 Cluster Setup Guides
1. **Devo SOAR MCP Setup Guide (Cluster Hosted)** - Strike48 (ID: 5528027137)
2. **Strike48 Splunk MCP Setup Guide (Cluster Hosted)** - Strike48
3. **Strike48 Matrix MCP Setup Guide (Cluster Hosted)** - Strike48
4. **Strike48 Security Analytics MCP Setup Guide (Cluster Hosted)** - Strike48
5. **Strike48 Atlassian MCP Setup Guide (Cluster Hosted)** - Strike48

### Collector Management
1. **[KB] Collector Setup & Configuration** - SKB
2. **[KB] Troubleshooting Collectors** - SKB
3. **[KB] Collector Scaling** - SKB
4. **[KB] Certificate Issues** - SKB

### SOAR K8s Operations
1. **SOAR Tenant Onboarding Runbooks** - LHUB
2. **SOAR System Properties** - LHUB
3. **SOAR Operations** - LHUB

### Platform Services on K8s
- **Microservices Documentation** - GLBREP (30+ services):
  - Maqui
  - Batrasio
  - Malote
  - Lomana
  - Adolfo
  - Mason
  - Affinity
  - And 23+ more services

### Monitoring & APM
1. **APM (Application Performance Management)** - TV
2. **Telemetry** - GLBREP
3. **Redis Capacity Planning** - GLBREP

### Platform Deployment Process
1. **Platform Deployment Process Overview** - DPA
2. **Deployment with Ansible** - DPA
3. **Deployment with Terraform** - DPA
4. **Deployment with Docker** - DPA
5. **Deployment with Jenkins** - DPA
6. **Data Nodes Deployment** - DPA
7. **Relay Deployment** - DPA
8. **Auxiliaries Services Deployment** - DPA
9. **Platform Deployment Appendices** - DPA

---

## 7. Batrasio (Ingestion Service)

**Primary Space:** CO (Cloud Operations)  
**Related Spaces:** GLBREP, RDT, 03NOC

### Core Documentation
1. **Batrasio ⚙** - GLBREP (ID: 5486379024)
2. **Event Load Balancer (ELB - Batrasio)** - GLBREP (ID: 631538081)
3. **Batrasio Ingestion Dashboard (Connections & Data)** - RDT (ID: 5384765446)
4. **Batrasio Documentation** - CO

### Operations & Troubleshooting
1. **Batrasio Deployment Issue in APAC - Root Cause and Resolution** - RDT (ID: 5742788618)
2. **IRCA-152 - Batrasio hanged out caused ingestion loss for Caixa** - RDT (ID: 5551423489)
3. **IRCA-116 - [AWS-APAC] Low ingestion due to self sign cert update on APAC Batrasio** - RDT (ID: 4957601816)
4. **BATRASIO/ALCOHOL: Subida manual ficheros .alc.js** - CO (ID: 673054749)

### Certificate Management
1. **Generate Certificate for Batrasio** - CO
   - Overview
   - Step 1: Create Key
   - Step 2: Create CSR
   - Step 3: Sign Certificate
   - To Do
2. **Ticket Sample - AWS Batrasio Certificate Replacement** - CO
3. **Ticket Sample - IBM VPC Batrasio Certificate Replacement** - CO
4. **Emergency procedure to fix a certificate** - 0CC
5. **(OBSOLETE) Certification revocation list in batrasio** - CO (ID: 984580150)

### Maintenance Procedures
1. **How to Upgrade Ubuntu LTS Release for Batrasio | 16.04 (xenial), 18.04 (bionic), 20.04 (focal)** - CO
2. **Ticket Sample - Preemptive Batrasio Process Restart on Increased Error Rate Detection** - CO
3. **Fix the Status Check 1/2 on Batrasio machines (WIP)** - CO
   - Overview
   - Step 1: Connect to AWS console through SSO
   - Step 2: Looking for the instance affected
   - Step 3: Procedure to fix the issue
     - Reboot the machine
     - Register targets

### Public Endpoint Configuration
- **Deploy Public ZeroSSL/Let's Encrypt Public Endpoint Batrasio POC** - CO
  - Overview
  - Steps (AWS-CLI, Acme.sh, Route53, Certificate deployment)
  - Troubleshooting

---

## 8. Certificates Management

**Primary Space:** RDT, CO  
**Related Spaces:** PROYEC, CSUP, ITS, SKB

### Certificate Management Systems
1. **Devo Certificate Management System** - RDT (ID: 5322702850)
2. **Certificate Management - Maintenance Procedures** - RDT (ID: 5325225985)
3. **Devo domain certificates** - RDT (ID: 3621584922)

### Certificate Generation
1. **How to generate Devo certificates** - RDT (ID: 3921805479)
2. **How to manage Devo certificates with Argo Workflows** - RDT (ID: 4180967428)
3. **Generate certificates and import** - PROYEC (ID: 996114586)
4. **How to Install Internal Certificates** - RDT (ID: 691044449)

### Certificate Renewal & Rotation
1. **Renew SSL Web Certificate** - PROYEC (ID: 806289535)
2. **How to: Renew LetsEncrypt Certificate** - CO (ID: 3914334272)
3. **How to: Renew Digicert Certificate** - CO (ID: 3088023619)
4. **Procedure: Create proactive cases for domain certificate renewals** - CSUP (ID: 4351197209)
5. **Apple Push Notifications Certificate Renewal Guide** - ITS (ID: 3889004600)
6. **How-to renew certificate and key for 11paths_dm impersonation** - RDT (ID: 3873964287)

### Certificate Validation & Troubleshooting
1. **[KB] Validate Domain Certificates for a customer domain** - SKB (ID: 5601199925)
2. **Validate Domain Certificates for a customer domain** - CSUP (ID: 4404150301)
3. **[KB] Troubleshooting: Multiple collectors failed due to expired certificate/key pair** - SKB (ID: 5601201604)
4. **[KB] Troubleshooting: Okta Collector Certificate Problems** - SKB (ID: 5601200567)
5. **How to Check the Expiration Date of your X.509 Certificates** - IM (ID: 3700555926)
6. **Investigate client.jks file on a Relay** - CSUP (ID: 4740349987)
7. **Verify Collectors Balancer's certification expiration** - O2GerSIEM (ID: 2114617361)

### Collector Certificate Operations
1. **[KB] Direct a customer to download certificates for collectors** - SKB (ID: 5601199948)
2. **[KB] Certificates and Tokens (CS KB)** - SKB (ID: 5601199881)
3. **Collector Cases Handling Guide** - CSUP (ID: 4988370945)

### JKS & CA Management
1. **JKS certificate administration** - CO (ID: 803438595)
2. **How to Exchange Certificate Authority (Intermediate CA/Root CA) In Maduro API and Relay** - GLBREP (ID: 3400073246)
3. **Internal Certificate Management (Digicert)** - ITS (ID: 3104604165)

### Special Use Cases
1. **Caixa Certificates with Alternate DNS Names (SAN)** - PROYEC (ID: 514752528)
2. **Deploy Public ZeroSSL/Let's Encrypt Public Endpoint Batrasio POC** - CO (ID: 3277127725)

---

## 9. Malote (Query Engine)

**Primary Space:** GLBREP, RDT  
**Related Spaces:** CO, SKB, PROYEC

### Core Documentation
1. **Query Engine (Malote)** - GLBREP
2. **Meta-Malote** - GLBREP
3. **Query Data Cleaner (Malolete)** - GLBREP
4. **Malote Pragmas** - GLBREP
5. **malote tips** - GLBREP

### Related Services
1. **Maqui (Query Script Interface)** - GLBREP
2. **Metamalote (lookup operations)** - GLBREP
3. **Quelato (Query Management)** - GLBREP
4. **Loxcope (Web Query Builder)** - GLBREP
5. **Gambitero (Global Access)** - GLBREP
6. **Affinity (Domain Balancer)** - GLBREP

### Operations & Troubleshooting
- **[KB] Malote Troubleshooting** - SKB (15+ articles)
- **Malote Performance Tuning** - RDT
- **Malote Connection Pool Analysis** - RDT
- **Malote Heap Exhaustion Diagnostics** - RDT

### Customer Deployments
- **CaixaBank Malote Configuration** - PROYEC
- **AT&T Malote Setup** - PROYEC
- **CIBC Malote Deployment** - PROYEC
- **NHL Malote Implementation** - PROYEC

### Incident Reports
- **Systems OnCall Reports** - RDT (25+ incidents)
- **Malote 2026 Incident Coverage** - RDT
- **IRCA Reports mentioning Malote** - RDT

### MA Space (Malote Development)
1. **Malote (dev) Home** - MA
2. **Lookups historicos** - MA

---

## 10. Monitoring & Observability

**Primary Space:** 03NOC (Monitoring Operations)  
**Related Spaces:** TE, RDT, GLBREP

### Infrastructure Monitoring
1. **03. Monitoring Operations Home** - 03NOC (ID: 1294467226)
2. **Monitoring Operations Welcome Pack** - 03NOC (ID: 1329954973)
3. **Monitoring Ops Procedures** - 03NOC (ID: 1291485814)
4. **Monitoring Channels** - TE (ID: 4842717189)
5. **Observability** - RDT (ID: 4785766469)
6. **006 - Observability High Level Architecture** - TE (ID: 4521459739)
7. **Application Performance Management (APM)** - TV (ID: 937066499)

### External Monitoring
1. **UptimeRobot (External)** - 03NOC (ID: 1627750707)
2. **Healthchecks.io: Devo Alerts Monitor (External)** - 03NOC (ID: 1051853151)
3. **Netdata - obtaining node performance metrics** - 03NOC (ID: 1034158097)

### Procedures & Operations
1. **CloudOps Incident Management Procedure** - 03NOC (ID: 1329889471)
2. **Alertmanager Silence Procedures** - 03NOC (ID: 1718716455)
3. **Alcohol Process Monitoring and Alert Response Procedure** - 03NOC (ID: 5549555729)

---

## 11. Grafana-Prometheus Alerts

**Primary Space:** 03NOC  
**Related Spaces:** TE, GLBREP

### Technical Documentation
1. **External Monitoring Tool (Prometheus)** - GLBREP (ID: 989823078)
2. **Monitoring Systems [TBU]** - 03NOC (ID: 730595776)
3. **Grafana for Platform Monitoring** - 03NOC (ID: 1034059822)
4. **Prometheus** - 03NOC (ID: 1033961680)
5. **AlertManager** - 03NOC (ID: 1033961684)
6. **Grafana & Prometheus** - 03NOC (ID: 1564672602)

### Operational Guides
1. **Create a dashboard in Grafana** - TE (ID: 4657086494)
2. **Create an Alert in Grafana** - TE (ID: 4656037921)
3. **Case Study: Low Disk Space - T02: Alert Noise in Grafana** - 03NOC (ID: 4979425287)

---

## 12. Devo Alerts

**Primary Space:** 03NOC  
**Related Spaces:** TE, GLBREP, SKB

### Core Documentation
1. **Devo Alert Manager – Design and Documentation** - TE (ID: 5024546820)
2. **Devo Alert Manager - Knowledge Transfer Session** - TE (ID: 5181669406)
3. **Alerts and Notifications** - GLBREP (ID: 943751695)
4. **Devo alerts** - 03NOC (ID: 1771634723)
5. **Alerts Documentation** - 03NOC (ID: 1771143211)
6. **All Alerts Catalogue & Labels List** - 03NOC (ID: 1780090029)
7. **Deprecated Alerts** - 03NOC (ID: 5741576193)
8. **Cartero (Alert Delivery Controller)** - GLBREP (ID: 985235770)
9. **Devo Alert MAnaGEer (DAMAGE)** - PROYEC (ID: 649396787)

### Platform Alerts
1. **noc_asilo_has_job_failures** - 03NOC
2. **cs_batrasio_events_max_length_exceeded** - 03NOC
3. **noc_batrasio_connection_error** - 03NOC
4. **noc_batrasio_has_no_targets** - 03NOC
5. **noc_licor_has_problems_indexing** - 03NOC
6. **noc_secops_empty_lookups** - 03NOC
7. **noc_malote_access_denied** - 03NOC
8. **noc_malote_outconError** - 03NOC
9. **noc_orientdb_database_error** - 03NOC
10. **noc_orientdb_server_error** - 03NOC
11. **noc_batrasio_event_stalled** - 03NOC
12. **noc_sudden_drop** - 03NOC
13. **noc_chasys_serreacluster** - 03NOC
14. **bcache_hit_ratio** - 03NOC
15. **Lomana: Healthcheck** - 03NOC
16. **devo.mason.healthcheck** - 03NOC (ID: 3967451145)

### Additional Alert Categories
1. **ServiceOps Alerts** - 03NOC
2. **Marketplace Alerts** - 03NOC

### Knowledge Base
1. **[KB] Alerts Troubleshooting (CS KB)** - SKB (ID: 5601206659)
2. **[KB] How To Deploy SecOps Out of the Box (OOTB) Alerts** - SKB (ID: 5601207194)
3. **[KB] Troubleshooting: Alert Delayed or Stopped Due to Query Timeouts** - SKB (ID: 5601206818)
4. **[KB] How to Get a List of the Current Active Alert Queries Within a Domain** - SKB (ID: 5601206396)

---

## 13. Asilo (Aggregation Engine)

**Primary Space:** GLBREP  
**Related Spaces:** 03NOC

### Core Documentation
1. **Aggregation Engine (Asilo)** - GLBREP
2. **Aggregation Engine (Asilo) - Introduction** - GLBREP
3. **Aggregation Engine (Asilo) - Installation** - GLBREP
4. **Aggregation Engine (Asilo) - Configuration** - GLBREP
5. **Aggregation Engine (Asilo) - Upgrade** - GLBREP
6. **Aggregation Engine (Asilo) - Diagram** - GLBREP
7. **Aggregation Engine (Asilo) - Monitoring** - GLBREP
8. **Aggregation Engine (Asilo) - Troubleshooting** - GLBREP
9. **Aggregation Engine (Asilo) - Operations/Management** - GLBREP
10. **Aggregation Engine (Asilo) [INTERNAL AND FOR REVIEW]** - GLBREP

### Monitoring
- **noc_asilo_has_job_failures** - 03NOC

---

## 14. Additional Service Components

### Mason (Health Check Service)
- **devo.mason.healthcheck** - 03NOC (ID: 3967451145)
- **Mason Health Check Documentation** - GLBREP

### Lomana (Data Processing)
- **Lomana: Healthcheck** - 03NOC
- **Lomana Service Documentation** - GLBREP

### Affinity (Domain Balancer)
- **Domain Balancer (Affinity)** - GLBREP (ID: 985235540)
- **Affinity Configuration** - DPA

### Adolfo (Database Orchestrator)
- **Adolfo Service Documentation** - GLBREP
- **Direct database access via Adolfo** - RDT

### Maqui (Query Script Interface)
- **Maqui Service Documentation** - GLBREP
- **Maqui CLI** - RDT
- **Maqui Helper Functions** - Personal Scripts

### Licor (Data Indexers)
- **Data Indexers (Licor)** - GLBREP (ID: 985235532)
- **noc_licor_has_problems_indexing** - 03NOC

### Cotillo (Compression Engine)
- **Compression Engine (Cotillo)** - GLBREP (ID: 985235506)

### OrientDB
- **noc_orientdb_database_error** - 03NOC
- **noc_orientdb_server_error** - 03NOC

### Cartero (Alert Delivery)
- **Cartero (Alert Delivery Controller)** - GLBREP (ID: 985235770)

---

## 15. Infrastructure & Operations

### Cloud Platforms
**AWS Operations** - CO, RDT
- AWS Deployment Guides
- AWS Certificate Management
- AWS Batrasio Operations
- AWS Datanode Deployment

**Azure Operations** - CO, RDT
- Azure Deployment Guides
- Azure DN Deployment

**GCP Operations** - CO, RDT
- GCP Infrastructure
- GCP Datanode Setup

### Automation
**Ansible** - DPA, CO
- Deployment with Ansible (ID: 741834791)
- DN on Bare Metal with Ansible
- Ansible Vault Usage

**Terraform** - DPA
- Deployment with Terraform
- Infrastructure as Code

**Jenkins** - DPA
- Deployment with Jenkins
- CI/CD Pipelines

### Database Operations
**MySQL** - CO, RDT
- MySQL Operations
- Database Maintenance
- Back-Up Processes

**Aurora** - LHUB
- Aurora Architecture Diagram (ID: 5006229505)
- How to Request for a New Aurora Instance (ID: 4947673108)

### Backup & Recovery
1. **Back-Up Processes: Data Nodes, Parsers, Web, MySQL** - GLBREP (ID: 985235750)
2. **Barcenas Backup System** - CO
3. **Disaster Recovery Procedures** - DPA

### Network & Security
**VPN Access** - ITS
- VPN Configuration
- Remote Access

**Firewall Rules** - CO
- Egress Rules Management
- Whitelist Management

**Security Policies** - CISO
- Security Best Practices
- Access Control

### Runbooks & Procedures
**Operational Runbooks** - 03NOC
- Systems OnCall Procedures
- Incident Response
- Escalation Matrices

**SOPs (Standard Operating Procedures)** - CO, DPA
- Maintenance Procedures
- Deployment Procedures
- Certificate Rotation

### Performance & Capacity
**Capacity Planning** - RDT
- Datanode Capacity
- Redis Capacity Planning
- Storage Management

**Performance Tuning** - RDT
- Query Optimization
- Service Performance
- Connection Pool Tuning

---

## 16. Incident Management

### IRCA (Incident Root Cause Analysis)
**Recent IRCAs (2025-2026)** - RDT
1. **IRCA-157: Cloud Collector App page not accessible** - RDT
2. **IRCA-156: CaixaBank Serrea Cluster Outage** - RDT (ID: 5704056838)
3. **IRCA-153: [Santander] AWS Hardware Failure Event Loss** - RDT (ID: 5574721537)
4. **IRCA-152: Batrasio hanged out caused ingestion loss for Caixa** - RDT (ID: 5551423489)
5. **IRCA-151: Widespread collector outage** - RDT
6. **IRCA-135: SDK failures** - RDT
7. **IRCA-132: GCP-TEF datanode down, and lookup issues after restart** - RDT (ID: 5041094682)
8. **IRCA-120: Vanity URLs not working for CCApp** - RDT
9. **IRCA-116: [AWS-APAC] Low ingestion due to self sign cert update** - RDT (ID: 4957601816)

### Systems OnCall Reports
**Location:** RDT Space
- 25+ Systems OnCall Reports (2026)
- Malote Incidents
- Service Outages
- Performance Issues

### CloudOps Procedures
1. **CloudOps Incident Management Procedure** - 03NOC (ID: 1329889471)
2. **Incident Response Workflows** - 03NOC
3. **Escalation Procedures** - 03NOC

### On-Call Contacts
1. **SOAR OnCall Contact Details** - LHUB (ID: 5060427791)
2. **SOAR On-Call Escalation Matrix** - 03NOC (ID: 4839440405)
3. **NOC On-Call Contacts** - 03NOC

---

## Quick Access by Space

### Primary Operations Spaces
- **CO (Cloud Operations):** 205 pages - Cloud infrastructure, Batrasio, Datanodes
- **DPA (Devo Platform Administration):** 200 pages - Deployments, Ansible, Docker, DR
- **RDT (R&D Teams):** 159 pages - Release notes, IRCA reports, Systems OnCall
- **GLBREP (Global Repository):** 121 pages - Core platform docs
- **03NOC (Monitoring Operations):** 34 pages - Prometheus, Grafana, AlertManager
- **SKB (Support Knowledge Base):** 69 pages - Troubleshooting guides
- **LHUB:** 24 pages - SOAR operations hub
- **PROYEC (Professional Services):** 115 pages - Customer implementations
- **SRE (Site Reliability):** 15 pages - SRE practices

### Specialized Spaces
- **0CC (Cloud Collector):** Cloud Collector documentation
- **SCISEC (Security Science):** UEBA documentation
- **Strike48:** Strike48 integration
- **MA (Malote):** Malote development
- **CSUP:** Customer support policies
- **TE (Technical Engineering):** Design & architecture

---

## Search Tips

### CQL Search Examples
```cql
# Find all datanode documentation
space IN (DPA, RDT, CO) AND text~"datanode"

# Find certificate procedures
space IN (CO, RDT) AND text~"certificate" AND type=page

# Find monitoring alerts
space=03NOC AND text~"alert OR monitoring"

# Find IRCA reports
space=RDT AND title~"IRCA"

# Find KB articles
space=SKB AND title~"[KB]"

# Recent updates (last 7 days)
lastModified >= now("-7d") ORDER BY lastModified DESC

# Find deployment guides
text~"deployment" AND space IN (DPA, CO)
```

---

## Key URLs

- **Confluence Base:** https://devoinc.atlassian.net/wiki
- **Monitoring Ops:** https://devoinc.atlassian.net/wiki/spaces/03NOC
- **Cloud Operations:** https://devoinc.atlassian.net/wiki/spaces/CO
- **Platform Admin:** https://devoinc.atlassian.net/wiki/spaces/DPA
- **Knowledge Base:** https://devoinc.atlassian.net/wiki/spaces/SKB
- **Original Glossary:** https://devoinc.atlassian.net/wiki/spaces/RDT/pages/5762187266

---

## Document Metadata

- **Total Pages Indexed:** 1,150+
- **Categories Covered:** 16
- **Spaces Scanned:** 25+
- **Search Queries Executed:** 15+
- **Last Updated:** 2026-04-23
- **Compiled By:** Vikash Jaiswal
- **Original Glossary By:** Rahat (RDT Space)

---

## Notes

- All page IDs and URLs are direct links to Confluence
- Use Confluence search or CQL for finding specific content
- Refer to SKB space for troubleshooting guides
- Check RDT space for incident reports (IRCA)
- Monitor 03NOC space for platform alerts
- Access credentials configured in `~/.devo/credentials`

---

**End of Document**
