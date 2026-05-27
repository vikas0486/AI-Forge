# On-call Report | Vikash Jaiswal | Feb 2-8, 2026

## P1 Cases (High/Critical Priority)

| Date | Ticket Number | Summary | Duration taken |
|------|---------------|---------|----------------|
| 02-Feb-2026 | [CHG-10216](https://devoinc.atlassian.net/browse/CHG-10216) | [IBM-CAIXA] Scheduled: Stop/Start of multiple instance unresponsive caixa-ibm DN | 3h 30 min |
| 02-Feb-2026 | [ISM-14307](https://devoinc.atlassian.net/browse/ISM-14307) | IBM-EU Caixa - noc_dailytasks_failed - datanode-31-pro-cloud-caixa-ng-ibm-eu-de-3 | 6 min |
| 02-Feb-2026 | [ISM-14305](https://devoinc.atlassian.net/browse/ISM-14305) | AWS-EU Self - noc_daily_tasks_failed - datanode-3-pro-cloud-self-aws-eu-west-1 | 14 min |
| 02-Feb-2026 | [ISM-14301](https://devoinc.atlassian.net/browse/ISM-14301) | [Caixabank] Slowness when querying data | 15 min |
| 02-Feb-2026 | [ISM-14299](https://devoinc.atlassian.net/browse/ISM-14299) | [Caixabank] Slowness in web and API | 2h 22 min |
| 03-Feb-2026 | [ISM-14326](https://devoinc.atlassian.net/browse/ISM-14326) | IBM-EU Caixa - Dropped Datanode - datanode-41-pro-cloud-caixa-ng-ibm-eu-de-3 | 1 min |
| 06-Feb-2026 | [ISM-14386](https://devoinc.atlassian.net/browse/ISM-14386) | IBM-EU Caixa - Dropped Datanode - datanode-23 - 47 - 51-pro-cloud-caixa-ng-ibm-eu-de-3 | 30 min |
| 07-Feb-2026 | [ISM-14421](https://devoinc.atlassian.net/browse/ISM-14421) | Low disk space - EBS [17%] - AWS EU - grafana-1-infra-cloud-infra-aws-eu-west-1 - Root Volume | 40 min |
| 07-Feb-2026 | [ISM-14439](https://devoinc.atlassian.net/browse/ISM-14439) | AWS-EU-santander - Low Disk Space on Root Filesystem - datanode-1 - 2-santander-cloud-shared-aws-eu-west-1 | 2h 30 min |
| 07-Feb-2026 | [ISM-14436](https://devoinc.atlassian.net/browse/ISM-14436) | AWS-SANT-Shared - Dropped Datanode - datanode1/2-santander-cloud-shared-aws-eu-west-1 | 6h 30 min |
| 08-Feb-2026 | [ISM-14476](https://devoinc.atlassian.net/browse/ISM-14476) | AWS-EU-santander - Low Disk Space on Root Filesystem - batrasio-3-santander-cloud-shared-aws-eu-west-1 | 8 min |
| 08-Feb-2026 | [ISM-14470](https://devoinc.atlassian.net/browse/ISM-14470) | Dropped Datanodes - AWS SANTANDER - datanode2-santander-cloud-shared-aws-eu-west-1 - 4 affected malotes | 10 min |
| | | **Total Time:** | **16 Hours 56 Minutes** |

## P2 Cases (Medium/Normal Priority)

| Date | Ticket Number | Summary | Duration taken |
|------|---------------|---------|----------------|
| 03-Feb-2026 | [ISM-14315](https://devoinc.atlassian.net/browse/ISM-14315) | AWS-EU Shared - Low disk space - T02 - datanode-1-pro-cloud-shared-aws-eu-west-1 | 13 min |
| 06-Feb-2026 | [ISM-14394](https://devoinc.atlassian.net/browse/ISM-14394) | noc_chasys_barcenas_datanode_without_backup - AWS EU - Deloitte datanodes without backups | 1h 23 min |
| 06-Feb-2026 | [ISM-14393](https://devoinc.atlassian.net/browse/ISM-14393) | noc_chasys_barcenas_datanode_without_backup - AWS EU - Deloitte datanodes without backups | 7 min |
| 06-Feb-2026 | [ISM-14390](https://devoinc.atlassian.net/browse/ISM-14390) | Low disk space - TR t02 - AWS US/NCSCBH - Multiple datanodes - CRITICAL: ~37GB remaining | 10 min |
| 06-Feb-2026 | [ISM-14382](https://devoinc.atlassian.net/browse/ISM-14382) | Low disk space - TR [5%] - AWS NCSCBH - datanode-1-prod-ncscbh - 37.49 GB remaining | 5 min |
| 06-Feb-2026 | [ISM-14377](https://devoinc.atlassian.net/browse/ISM-14377) | Low disk space - TR [5%] - AWS NCSCBH - datanode-1-prod-ncscbh - CRITICAL: 34.6 GB remaining | 5 min |
| 06-Feb-2026 | [ISM-14376](https://devoinc.atlassian.net/browse/ISM-14376) | noc_node_low_filesystem_space_3gb - AWS US - datanode-12-pro-cloud-equifax-aws-us-east-1 - Critical disk space | 15 min |
| 07-Feb-2026 | [ISM-14445](https://devoinc.atlassian.net/browse/ISM-14445) | Low disk space - TR [5%] - AWS NCSCBH - datanode-1-prod-ncscbh-cloud-self-aws-me-south-1 - 37.39 GB remaining | 5 min |
| | | **Total Time:** | 2 Hours 23 Minutes |

## False Positive Cases

| Date | Ticket Number | Summary | Duration taken |
|------|---------------|---------|----------------|
| 02-Feb-2026 | #66871 | AWS-EU Shared - Low disk space - T02 - datanode-7-pro-cloud-shared-aws-eu-west-1 | 10 min |
| 02-Feb-2026 | #66889 | [Telefónica] Lookup stuck in Updating | 10 min |
| 02-Feb-2026 | #66890 | noc_batrasio_has_no_targets - AWS US - Batrasio missing targets - Data ingestion impacted | 10 min |
| 02-Feb-2026 | #66911 | NCSC BH - Swap Errors - datanode-35-17 - Core dumps and disk errors | 10 min |
| 03-Feb-2026 | #66925 | bcache_alert - IBM EU - Bcache failing on datanode-39-pro-cloud-caixa-ng-ibm-eu-de-3 | 10 min |
| 03-Feb-2026 | G5581 | Alert group: devo.mason.sync.errors - AWS US - Mason sync failures on multiple instances | 10 min |
| 03-Feb-2026 | #66932 | Lomana: Healthcheck - AWS US - Multiple instances failing health checks | 10 min |
| 03-Feb-2026 | #66933 | Lomana: Healthcheck - AWS US - Multiple instances failing health checks | 10 min |
| 03-Feb-2026 | #66936 | [ Singtel - AWS-APAC - Devo Docs not redirecting to topic after login via Devo Connect ] | 10 min |
| 03-Feb-2026 | #66937 | Injections not working for Caixabank | 10 min |
| 03-Feb-2026 | #66945 | noc_batrasio_stalled_events - AWS EU - Batrasio stalled events - Data ingestion impact | 10 min |
| 03-Feb-2026 | #66946 | Lomana: Healthcheck - AWS US - Multiple instances failing health checks | 10 min |
| 04-Feb-2026 | #66969 | AWS-US Texascapital - sqs_needs_scaling_outer - collector-502e6cdfa3b20b6c | 10 min |
| 04-Feb-2026 | #66975 | noc_batrasio_connection_error - AWS US - Batrasio connection errors - Multiple connection targets | 10 min |
| 04-Feb-2026 | #66976 | noc_batrasio_connection_error - AWS EU - Batrasio and Alcohol services crashing - datanode-33 | 10 min |
| 04-Feb-2026 | #66979 | noc_batrasio_has_no_targets - AWS EU - Batrasio missing targets - Data ingestion impacted | 10 min |
| 04-Feb-2026 | G5714 | Alert group: devo.mason.sync.errors - AWS US - Mason sync failures on multiple instances | 10 min |
| 04-Feb-2026 | #66990 | Alcohol - AWS EU - Alcohol service down on datanode-5-pro-cloud-caixa-ng-ibm-eu-de-3 | 10 min |
| 04-Feb-2026 | #66991 | Caixa Environment - Multiple Connection Timeouts and High Disk Usage - IBM EU | 10 min |
| 04-Feb-2026 | #66992 | noc_asilo_has_job_failures - AWS US - Asilo aggregation failures - Multiple hosts experiencing Malote connection timeouts | 10 min |
| 04-Feb-2026 | #67000 | noc_backendpipilene_detectInactivity - AWS US - Alert pipeline blocked | 10 min |
| 04-Feb-2026 | #67001 | noc_backendpipilene_detectInactivity - AWS EU - Alert pipeline blocked | 10 min |
| 04-Feb-2026 | #67006 | noc_backendpipilene_detectInactivity - AWS EU - Alert pipeline blocked | 10 min |
| 04-Feb-2026 | #67008 | noc_chasys_serreacluster - AWS EU - Serrea cluster I/O errors on Caixa nodes | 10 min |
| 04-Feb-2026 | [ISM-14344](https://devoinc.atlassian.net/browse/ISM-14344) | noc_chasys_serreacluster - AWS EU - Serrea cluster I/O errors on Caixa nodes | 10 min |
| 04-Feb-2026 | #67009 | noc_backendpipilene_detectInactivity - AWS US - Alert pipeline blocked | 10 min |
| 05-Feb-2026 | #67030 | noc_chasys_barcenas_datanode_without_backup - AWS US - Multiple datanodes without backups | 10 min |
| 05-Feb-2026 | #67031 | noc_chasys_total_delayed - AWS APAC - Alert processing delays detected | 10 min |
| 05-Feb-2026 | #67033 | [GCP EU] Lookup stuck in Updating status | 10 min |
| 05-Feb-2026 | #67034 | [First Watch Technologies] Lookup stuck in Updating status | 10 min |
| 05-Feb-2026 | #67035 | devo.mason.sync.errors - AWS US - Mason synchronization failures to agent 172.25.47.41 | 10 min |
| 05-Feb-2026 | #67036 | noc_low_disk_space_toox - LACAIXA - T000-T001 partitions 93% full - datanode-41 | 10 min |
| 05-Feb-2026 | #67041 | noc_backendpipilene_detectInactivity - AWS US - Alert pipeline blocked | 10 min |
| 05-Feb-2026 | #67042 | Dropped Datanodes - AWS EU - Multiple datanodes unreachable | 10 min |
| 06-Feb-2026 | #67052 | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - CAIXA domain | 10 min |
| 06-Feb-2026 | #67053 | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - Port 660 for CaixaBank domain | 10 min |
| 06-Feb-2026 | #67054 | Low disk space - EBS [1%] - AWS US | 10 min |
| 06-Feb-2026 | #67055 | noc_batrasio_workers_decrease - AWS US - Worker count decreased - devo-prod-us | 10 min |
| 06-Feb-2026 | #67056 | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - Port 660 CAIXA | 10 min |
| 06-Feb-2026 | #67057 | noc_batrasio_workers_decrease - AWS EU - Worker count decreased - devo-prod-eu | 10 min |
| 06-Feb-2026 | #67058 | CRITICAL - Equifax Environment - 100% Disk Usage & No Data Collection for 18+ Hours | 10 min |
| 06-Feb-2026 | #67059 | AWS US3 DeepSeas Changing Domains with the Devo Console is Redirecting Wrong | 10 min |
| 06-Feb-2026 | #67060 | Low disk space - TR t02 - AWS NCSCBH - datanode-1-prod-ncscbh - Multiple partitions <50GB remaining | 10 min |
| 06-Feb-2026 | #67062 | noc_batrasio_connection_error - AWS EU - Batrasio port 660 connection failures - LACAIXA | 10 min |
| 06-Feb-2026 | #67063 | noc_batrasio_ports - AWS EU - Batrasio port failures - Multiple ports failing | 10 min |
| 06-Feb-2026 | #67065 | GCP-EU-TELEFONICA - noc_marketplace_api_error_500 | 10 min |
| 06-Feb-2026 | #67068 | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - cybersecurity@caixabank | 10 min |
| 06-Feb-2026 | [ISM-14419](https://devoinc.atlassian.net/browse/ISM-14419) | noc_batrasio_workers_decrease - AWS US - Worker count decreased on Batrasio instances | 10 min |
| 06-Feb-2026 | [ISM-14416](https://devoinc.atlassian.net/browse/ISM-14416) | noc_batrasio_workers_decrease - AWS US - Potential worker count decrease | 10 min |
| 06-Feb-2026 | [ISM-14397](https://devoinc.atlassian.net/browse/ISM-14397) | noc_batrasio_ports - AWS EU - Batrasio port failures - Multiple instances affected | 10 min |
| 06-Feb-2026 | [ISM-14396](https://devoinc.atlassian.net/browse/ISM-14396) | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - Caixabank cybersecurity domain | 10 min |
| 06-Feb-2026 | [ISM-14395](https://devoinc.atlassian.net/browse/ISM-14395) | noc_batrasio_workers_decrease - AWS US - Multiple batrasio instances - Worker count decreased | 10 min |
| 06-Feb-2026 | [ISM-14392](https://devoinc.atlassian.net/browse/ISM-14392) | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - CAIXA/port 660 | 10 min |
| 06-Feb-2026 | [ISM-14391](https://devoinc.atlassian.net/browse/ISM-14391) | noc_batrasio_workers_decrease - AWS US - Worker count decrease | 10 min |
| 06-Feb-2026 | [ISM-14387](https://devoinc.atlassian.net/browse/ISM-14387) | noc_batrasio_workers_decrease - AWS EU - batrasio-1-pro-cloud-self-aws-eu-west-1 - Worker count: decreased | 10 min |
| 06-Feb-2026 | [ISM-14385](https://devoinc.atlassian.net/browse/ISM-14385) | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - Port 660/CAIXA | 10 min |
| 06-Feb-2026 | [ISM-14384](https://devoinc.atlassian.net/browse/ISM-14384) | noc_batrasio_workers_decrease - AWS US - Worker count decreased - Multiple instances | 10 min |
| 06-Feb-2026 | [ISM-14383](https://devoinc.atlassian.net/browse/ISM-14383) | noc_batrasio_workers_decrease - AWS EU - Worker count decreased - devo-prod-eu | 10 min |
| 06-Feb-2026 | [ISM-14381](https://devoinc.atlassian.net/browse/ISM-14381) | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - port 660 | 10 min |
| 06-Feb-2026 | [ISM-14380](https://devoinc.atlassian.net/browse/ISM-14380) | noc_node_low_filesystem_space_3gb - AWS US - datanode-1-pro-cloud-criticalstart-aws-us-east-1 - Critical disk space | 10 min |
| 06-Feb-2026 | [ISM-14379](https://devoinc.atlassian.net/browse/ISM-14379) | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - cybersecurity@caixabank | 10 min |
| 06-Feb-2026 | [ISM-14378](https://devoinc.atlassian.net/browse/ISM-14378) | noc_batrasio_connection_error - AWS EU - Batrasio port connection failures - CaixaBank domain | 10 min |
| 06-Feb-2026 | [ISM-14375](https://devoinc.atlassian.net/browse/ISM-14375) | noc_batrasio_connection_error - AWS EU - Batrasio port 660 connection failures - LACAIXA | 10 min |
| 06-Feb-2026 | [ISM-14373](https://devoinc.atlassian.net/browse/ISM-14373) | noc_malote_process - AWS EU - Multiple datanodes - Connection reset errors | 10 min |
| 06-Feb-2026 | [ISM-14372](https://devoinc.atlassian.net/browse/ISM-14372) | Low disk space - EBS [1%] - AWS EU - Critical disk space alert | 10 min |
| 06-Feb-2026 | [ISM-14371](https://devoinc.atlassian.net/browse/ISM-14371) | noc_chasys_serreacluster - AWS EU - Serrea cluster node failure | 10 min |
| 07-Feb-2026 | [ISM-14458](https://devoinc.atlassian.net/browse/ISM-14458) | noc_batrasio_ports - AWS EU - Multiple instances - TLS handshake failures on port 443/8443 | 10 min |
| 07-Feb-2026 | [ISM-14457](https://devoinc.atlassian.net/browse/ISM-14457) | noc_batrasio_workers_decrease - AWS US - batrasio-2-pro-cloud-shared-aws-us-east-1 - Worker count decreased | 10 min |
| 07-Feb-2026 | [ISM-14456](https://devoinc.atlassian.net/browse/ISM-14456) | Dropped Datanodes - Multiple Environments - Malote service unreachable - Multiple instances affected | 10 min |
| 07-Feb-2026 | [ISM-14455](https://devoinc.atlassian.net/browse/ISM-14455) | Dropped Datanodes - Multiple Environments - Multiple datanodes unreachable | 10 min |
| 07-Feb-2026 | [ISM-14454](https://devoinc.atlassian.net/browse/ISM-14454) | Dropped Datanodes - AWS EU - Multiple datanodes unreachable - 3 affected malotes | 10 min |
| 07-Feb-2026 | [ISM-14453](https://devoinc.atlassian.net/browse/ISM-14453) | noc_batrasio_ports - AWS EU - Multiple instances - Control port 660 failing | 10 min |
| 07-Feb-2026 | [ISM-14452](https://devoinc.atlassian.net/browse/ISM-14452) | Dropped Datanodes - All Environments - Multiple datanodes unreachable - Potential query impact | 10 min |
| 07-Feb-2026 | [ISM-14451](https://devoinc.atlassian.net/browse/ISM-14451) | noc_batrasio_workers_decrease - AWS US - Multiple instances - Worker count reduction | 10 min |
| 07-Feb-2026 | [ISM-14450](https://devoinc.atlassian.net/browse/ISM-14450) | noc_asilo_process - AWS US - Asilo service down on multiple datanodes | 10 min |
| 07-Feb-2026 | [ISM-14449](https://devoinc.atlassian.net/browse/ISM-14449) | noc_batrasio_opensockets - AWS US - Batrasio - Socket count >540K | 10 min |
| 07-Feb-2026 | [ISM-14448](https://devoinc.atlassian.net/browse/ISM-14448) | Dropped Datanodes - Multiple Environments - Malote services unresponsive on datanodes | 10 min |
| 07-Feb-2026 | [ISM-14447](https://devoinc.atlassian.net/browse/ISM-14447) | noc_batrasio_workers_decrease - AWS US - Workers count reduced on shared instances | 10 min |
| 07-Feb-2026 | [ISM-14446](https://devoinc.atlassian.net/browse/ISM-14446) | noc_asilo_process - AWS EU - Asilo service down on multiple datanodes | 10 min |
| 07-Feb-2026 | [ISM-14444](https://devoinc.atlassian.net/browse/ISM-14444) | Dropped Datanodes - Multiple Environments - Malote processes unreachable - Requires CloudOps investigation | 10 min |
| 07-Feb-2026 | [ISM-14443](https://devoinc.atlassian.net/browse/ISM-14443) | Dropped Datanodes - Multiple Environments - Malotes unreachable | 10 min |
| 07-Feb-2026 | [ISM-14441](https://devoinc.atlassian.net/browse/ISM-14441) | noc_batrasio_ports - AWS EU - Recurring port 660 issues - CaixaBank domain | 10 min |
| 07-Feb-2026 | [ISM-14440](https://devoinc.atlassian.net/browse/ISM-14440) | Dropped Datanodes - Multiple Environments - Multiple datanodes unreachable - Malote service issues | 10 min |
| 07-Feb-2026 | [ISM-14438](https://devoinc.atlassian.net/browse/ISM-14438) | noc_chasys_barcenas_datanode_with_backup_with_gap_files - AWS EU - datanode-16-pro-cloud-gitlab-aws-eu-west-1 | 10 min |
| 07-Feb-2026 | [ISM-14437](https://devoinc.atlassian.net/browse/ISM-14437) | noc_batrasio_workers_decrease - AWS US - Worker count decrease detected | 10 min |
| 07-Feb-2026 | [ISM-14427](https://devoinc.atlassian.net/browse/ISM-14427) | noc_batrasio_workers_decrease - AWS US - Multiple instances affected | 10 min |
| 07-Feb-2026 | [ISM-14426](https://devoinc.atlassian.net/browse/ISM-14426) | noc_batrasio_workers_decrease - AWS US - batrasio-3-pro-cloud-internal-aws-us-east-1 - Worker count decreased | 10 min |
| 07-Feb-2026 | [ISM-14425](https://devoinc.atlassian.net/browse/ISM-14425) | noc_batrasio_workers_decrease - AWS US - Worker count decrease in Batrasio instances | 10 min |
| 07-Feb-2026 | [ISM-14422](https://devoinc.atlassian.net/browse/ISM-14422) | noc_batrasio_workers_decrease - AWS US - Multiple Batrasio instances - Worker count decreased | 10 min |
| 08-Feb-2026 | [ISM-14490](https://devoinc.atlassian.net/browse/ISM-14490) | noc_batrasio_ports - AWS EU - Multiple instances - Port 1212 failing | 10 min |
| 08-Feb-2026 | [ISM-14489](https://devoinc.atlassian.net/browse/ISM-14489) | noc_batrasio_workers_decrease - AWS US - Worker count decreased | 10 min |
| 08-Feb-2026 | [ISM-14485](https://devoinc.atlassian.net/browse/ISM-14485) | noc_batrasio_workers_decrease - AWS US - Multiple instances - Worker count decrease detected | 10 min |
| 08-Feb-2026 | [ISM-14484](https://devoinc.atlassian.net/browse/ISM-14484) | Dropped Datanodes - Multiple Environments - Multiple malotes unresponsive across environments | 10 min |
| 08-Feb-2026 | [ISM-14471](https://devoinc.atlassian.net/browse/ISM-14471) | noc_malote_process - AWS EU - datanode-2-santander-cloud-shared - Missing multiple Malote processes | 10 min |
| 08-Feb-2026 | [ISM-14461](https://devoinc.atlassian.net/browse/ISM-14461) | noc_batrasio_ports - AWS EU - Multiple instances - Port 1212 failing | 10 min |
| 08-Feb-2026 | [ISM-14459](https://devoinc.atlassian.net/browse/ISM-14459) | Dropped Datanodes - AWS SANTANDER - Multiple datamalotes unreachable on datanode2 (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14460](https://devoinc.atlassian.net/browse/ISM-14460) | Dropped Datanodes - AWS SANTANDER - datanode2-santander - Multiple malotes unreachable (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14462](https://devoinc.atlassian.net/browse/ISM-14462) | Dropped Datanodes - AWS SANTANDER - datanode-2-santander-cloud-shared - 4 affected malotes (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14465](https://devoinc.atlassian.net/browse/ISM-14465) | Dropped Datanodes - AWS SANTANDER - datanode2-santander - 4 malote ports unreachable (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14467](https://devoinc.atlassian.net/browse/ISM-14467) | Dropped Datanodes - AWS SANTANDER - datanode2-santander - 4 affected malotes (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14468](https://devoinc.atlassian.net/browse/ISM-14468) | Dropped Datanodes - AWS SANTANDER - datanode2-santander-cloud-shared - 4 affected malotes (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14473](https://devoinc.atlassian.net/browse/ISM-14473) | Dropped Datanodes - AWS SANTANDER - Multiple malote ports unreachable - datanode2 (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14474](https://devoinc.atlassian.net/browse/ISM-14474) | Dropped Datanodes - AWS SANTANDER - datanode2-santander - 4 malotes unreachable (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14478](https://devoinc.atlassian.net/browse/ISM-14478) | Dropped Datanodes - AWS SANTANDER - datanode2-santander-cloud-shared - 4 affected malotes (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14482](https://devoinc.atlassian.net/browse/ISM-14482) | Dropped Datanodes - AWS SANTANDER - datanode2-santander - 4 affected malotes (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14486](https://devoinc.atlassian.net/browse/ISM-14486) | Dropped Datanodes - AWS SANTANDER - datanode2-santander - 4 affected malotes (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14488](https://devoinc.atlassian.net/browse/ISM-14488) | Dropped Datanodes - AWS SANTANDER - datanode2-santander - 4 malotes affected (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14510](https://devoinc.atlassian.net/browse/ISM-14510) | Dropped Datanodes - AWS EU SANTANDER - datanode2-santander - 4 malotes unreachable (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14511](https://devoinc.atlassian.net/browse/ISM-14511) | Dropped Datanodes - AWS SANTANDER - datanode2-santander-cloud-shared - 4 malotes unavailable (Duplicate) | 10 min |
| 08-Feb-2026 | [ISM-14512](https://devoinc.atlassian.net/browse/ISM-14512) | Dropped Datanodes - AWS SANTANDER - datanode2-santander-cloud-shared - 4 malotes affected (Duplicate) | 10 min |
| | | **Total Time:** | **19 Hours 10 Minutes** |

## Summary

- **On-call Period:** February 2-8, 2026
- **Total P1 Cases:** 12
- **Total P2 Cases:** 8
- **Total False Positive Cases:** 115 (including 15 duplicates)
- **Total Cases (P1 + P2):** 20
- **Total Time (P1):** 16 Hours 56 Minutes
- **Total Time (P2):** 2 Hours 23 Minutes
- **Total Time (False Positive):** 19 Hours 10 Minutes
- **Total Time (Overall):** 38 Hours 29 Minutes

**Note:** Durations calculated using MINIMUM of multiple methods (Created→Resolved, FirstComment→Resolved, FirstComment→LastComment, etc.). Capped at 5 hours maximum. False Positive cases are set to 10 minutes each. Duplicate tickets have been identified and moved to False Positive section.
