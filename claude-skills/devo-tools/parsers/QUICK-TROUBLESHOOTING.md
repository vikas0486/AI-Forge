# Parser Deployment - Quick Troubleshooting

**When queries fail after parser deployment, follow this checklist.**

---

## 🚨 Error: "Unknown identifier `field_name`"

```
ERROR: Unknown identifier `action_raw_event`
Code: 1101001, Kind: QUERY_PARSING_ERROR
```

### Quick Fix
```bash
# 1. Verify field exists in parser
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo grep 'action_raw_event' /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata"

# 2. Restart services (BOTH required)
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"

# 3. Wait and test
sleep 30
maquieu 'from cef0.paloAltoNetworks.panOs select action_raw_event limit 1'
```

---

## 🚨 Error: "Unknown table `table.name`"

```
ERROR: Unknown table `cloud.gsuite.reports.takeout`
Code: 2086000, Kind: MISSING_RESOURCE
```

### Quick Fix
```bash
# 1. Check if parser files exist
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo find /etc/logtrust/malote/defs -name '*gsuite-reports-takeout*'"

# If missing: Re-run Jenkins deployment
# If present: Restart services
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"

# Wait and test
sleep 30
maquieu 'from cloud.gsuite.reports.takeout select * limit 1'
```

---

## 🚨 Query Routes to Wrong Datanode

```
ERROR: Unknown identifier `field_name`
Chain: [{/172.17.43.85:10100} -> {/172.17.36.160:10100}]
```

### Quick Fix
```bash
# 1. Identify datanode from error chain
# 172.17.36.160 = second IP in chain

# 2. Find hostname
grep "172.17.36.160" /etc/hosts
# Output: datanode-1-pro-cloud-deloitte-aws-eu-west-1

# 3. Restart that datanode
ssh datanode-1-pro-cloud-deloitte-aws-eu-west-1 "sudo systemctl restart metamalote"

# 4. Wait and test
sleep 30
maquieu 'from table select field limit 1'
```

---

## 🚨 Works in US But Not EU

### Quick Fix
```bash
# 1. Compare S3 timestamps
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awsus.tgz --profile production-limited
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz --profile production-limited

# 2. If EU timestamp old: Re-run Jenkins EU deployment
# https://jenkins.devotools.com/job/deploy-matasmafias/job/deploy-matasmafias-aws-eu-pro/

# 3. Restart all EU services
for i in {1..10}; do ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"; done
```

---

## ✅ Complete EU Region Restart

**Copy-paste this entire block:**

```bash
# Restart all 10 metamalote coordinators (20 services)
for i in {1..10}; do 
    echo "=== metamalote-$i ==="; 
    ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller && echo 'Restarted'"; 
done

# Restart shared datanodes (5 services)
for host in datanode-1-pro-cloud-shared-aws-eu-west-1 datanode-2-pro-cloud-shared-aws-eu-west-1 datanode-3-pro-cloud-shared-aws-eu-west-1 datanode-7-pro-cloud-shared-aws-eu-west-1 datanode-8-pro-cloud-shared-aws-eu-west-1; do 
    echo "=== $host ==="; 
    ssh $host "sudo systemctl restart metamalote && echo 'Restarted'"; 
done

# Wait for services to load parsers
echo "Waiting 30 seconds for services to stabilize..."
sleep 30

# Test
maquieu 'from cef0.paloAltoNetworks.panOs where today()-1d <= eventdate < today() select * limit 1'
```

---

## 📋 Verification Checklist

After any parser deployment:

- [ ] Check S3 timestamp is recent
```bash
aws s3 ls s3://lt-jenkins/matasmafias/master/matasmafias-awseu.tgz --profile production-limited
```

- [ ] Verify files exist on server
```bash
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo ls /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.*"
```

- [ ] Check file content
```bash
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo grep 'action_raw_event' /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata"
```

- [ ] **Restart services** (CRITICAL!)
```bash
for i in {1..10}; do ssh metamalote-$i-pro-cloud-general-aws-eu-west-1 "sudo systemctl restart metamalote && sudo systemctl restart malote-controller"; done
```

- [ ] Wait 30 seconds

- [ ] Test new fields/tables
```bash
maquieu 'from table select new_field limit 1'
```

- [ ] If fails: Check query routing and restart datanode

---

## ⚠️ Critical Rules

1. **ALWAYS restart services after parser deployment**
   - Ansible "touch" doesn't work reliably
   - Services can run for weeks without reloading
   - Parsers cached in memory

2. **Restart BOTH services on metamalote servers**
   - `metamalote.service` (backend)
   - `malote-controller.service` (coordinator)

3. **Restart datanodes if query routing to them**
   - Check error chain for datanode IPs
   - Restart metamalote.service on that datanode

4. **Wait 30 seconds after restart**
   - Services need time to load parsers
   - Don't test immediately

5. **Jenkins timing matters**
   - Wait 5-10 minutes after master merge
   - Check GitLab CI "publish" stage completed
   - Otherwise downloads old parsers from S3

---

## 🔍 Quick Diagnostics

```bash
# Service uptime (how long since restart?)
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo systemctl status metamalote | grep 'Active:'"

# File timestamp
ssh metamalote-1-pro-cloud-general-aws-eu-west-1 "sudo stat /etc/logtrust/malote/defs/cef0/cef0-paloAltoNetworks-panOs.mata | grep Modify"

# S3 upload time
aws s3api head-object --bucket lt-jenkins --key matasmafias/master/matasmafias-awseu.tgz --profile production-limited | jq .LastModified

# Compare times
# If S3 newer than file timestamp: Deployment didn't run
# If file newer than service uptime: Service needs restart
```

---

## 📞 Escalation

If restarts don't fix the issue:

1. Check parser team deployed to correct region
2. Verify Jenkins job completed successfully
3. Check Ansible playbook logs for errors
4. Verify S3 package contains correct parsers
5. Contact parser team (Jyotsna Singh)

---

## 📚 Full Documentation

For complete details: `/devo-tools` skill or read `SKILL.md`

**Key Sections:**
- Deployment Architecture
- Service Management
- Regional Infrastructure
- Complete Troubleshooting Guide
- CHG-10577 Case Study

---

**Last Updated:** 2026-05-01  
**Based On:** CHG-10577 resolution
