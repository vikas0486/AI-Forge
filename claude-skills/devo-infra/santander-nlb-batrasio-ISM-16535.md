# Santander NLB — Batrasio Target Group Fix (ISM-16535)

**Date:** 2026-05-22  
**Ticket:** ISM-16535  
**Customer:** Santander (dedicated cluster, eu-west-1)  
**NLB:** `public-batrasio-santander` (internet-facing, created 2021-03-24)  
**ARN:** `arn:aws:elasticloadbalancing:eu-west-1:275752367115:loadbalancer/net/public-batrasio-santander/38c591e952925b7c`

---

## NLB Node → AZ Mapping

| Public IP | AZ | NLB Node |
|---|---|---|
| `54.216.125.87` | eu-west-1a | ELB net node |
| `52.48.53.0` | eu-west-1b | ELB net node |
| `54.75.1.216` | eu-west-1c | ELB net node |

DNS: `public-batrasio-santander-38c591e952925b7c.elb.eu-west-1.amazonaws.com` → resolves to all 3 IPs  
`collector-54ad5.devo.io` → same ELB DNS (A record)

---

## Batrasio Instances

| Instance | Name | AZ | Private IP |
|---|---|---|---|
| `i-035dcd19503f48a87` | batrasio-2-santander-cloud-shared-aws-eu-west-1 | eu-west-1a | 172.27.18.235 |
| `i-045b0c7ee5e9f0b21` | batrasio-3-santander-cloud-shared-aws-eu-west-1 | eu-west-1b | 172.27.57.246 |

---

## Listeners & Target Groups

| Listener | Target Group | Targets (post-fix) |
|---|---|---|
| TCP:80 | `batrasio-santander-443-pro` | batrasio-2 + batrasio-3 |
| TCP:443 | `batrasio-santander-443-tcp` | batrasio-2 + batrasio-3 |

**Cross-zone load balancing:** Off (intentional — targets now cover eu-west-1a and eu-west-1b)

---

## Root Cause (ISM-16535)

Customer hardcoded `54.216.125.87` (eu-west-1a NLB node) in `kafka-devo.json`.  
`batrasio-santander-443-tcp` TG (TCP:443) only had batrasio-3 (eu-west-1b) registered.  
With cross-zone disabled, traffic hitting eu-west-1a had no target → connections dropped.  
`52.48.53.0` (eu-west-1b) worked because batrasio-3 is in eu-west-1b.

**Fix applied 2026-05-22:** Added batrasio-2 (`i-035dcd19503f48a87`) to `batrasio-santander-443-tcp` TG.  
Both targets healthy immediately. Customer `193.127.189.15` connected to batrasio-2 on port 443 within minutes. `cert_gtb_bam` ingestion ramped from ~477 → 12,000+ events/15min.

---

## AWS Access

```bash
# Santander AWS account: 275752367115
source ~/.zshrc && aws elbv2 describe-target-health --profile santander-limited --region eu-west-1 \
  --target-group-arn "arn:aws:elasticloadbalancing:eu-west-1:275752367115:targetgroup/batrasio-santander-443-tcp/8cbcd0d0a6fd25d2"

# List all NLB node IPs
aws ec2 describe-network-interfaces --profile santander-limited --region eu-west-1 \
  --filters "Name=description,Values=*public-batrasio-santander*" \
  --query 'NetworkInterfaces[*].{AZ:AvailabilityZone,PrivateIP:PrivateIpAddress,PublicIP:Association.PublicIp,Status:Status}'
```

---

## Lesson Learned

- NLBs with cross-zone disabled will silently drop traffic if no target exists in the AZ of the connecting IP
- When adding a new batrasio to a Santander TG, ensure it is added to **all relevant TGs** (TCP:80 and TCP:443), not just one
- batrasio-2 was added to TCP:80 TG (`batrasio-santander-443-pro`) in Feb 2026 but missed TCP:443 TG (`batrasio-santander-443-tcp`) — that gap caused this outage
