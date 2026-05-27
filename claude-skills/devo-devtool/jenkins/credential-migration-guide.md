# Jenkins GitLab Credential Migration - Permanent Solution

**Problem:** Personal Access Tokens (PAT) expire after 1 year, causing all Jenkins automation to break.

**Solution:** Migrate to permanent credentials (SSH Deploy Keys or Deploy Tokens with no expiration).

---

## Current Credential Setup

**Credential ID:** `gitlab-com-access-token`
**Type:** Username with password (Personal Access Token)
**Username:** `git` (not a personal username)
**Password:** Personal Access Token (e.g., `glpat-xyz123...`)
**Expires:** 1 year from creation
**Used by:**
- Master job: `RaD-Deployments/datanode-trash-deletion-http`
- Checkout stage: Lines 94-97, 103-105
- Target repo: `https://gitlab.com/devo_corp/platform/ansible/environments/automation.git`

**Current authentication format:**
```bash
https://git:glpat-xyz123@gitlab.com/.../automation.git
```

**Current Architecture:**
```
Groovy Scripts: gitlab.devotools.com (OLD GitLab)
      ↓
Jenkins: jenkins.devotools.com (no migration needed)
      ↓
Ansible Repo: gitlab.com (NEW GitLab)
      ↓ (uses gitlab-com-access-token with PAT - expires!)
Ansible Playbooks: datanode-trash-cleanup.yml
```

---

## Permanent Solutions (Ranked)

### ✅ Solution 1: SSH Deploy Keys (Best - If SSH Allowed)

**Advantages:**
- ✅ Never expire
- ✅ More secure (no password in URL)
- ✅ Standard GitLab best practice
- ✅ Project-scoped (not user-dependent)
- ✅ Read-only enforcement

**Requirements:**
- Jenkins agents must have SSH access to gitlab.com (port 22)
- Check with test pipeline (see below)

**Setup Steps:**

#### 1. Generate SSH Key Pair

```bash
# On your local machine
ssh-keygen -t ed25519 -C "jenkins-automation@devo.com" -f ~/.ssh/jenkins-gitlab-deploy

# Output:
# ~/.ssh/jenkins-gitlab-deploy       (private key - add to Jenkins)
# ~/.ssh/jenkins-gitlab-deploy.pub   (public key - add to GitLab)
```

#### 2. Add Public Key to GitLab Projects

**For Automation Repo:**

1. Go to: https://gitlab.com/devo_corp/platform/ansible/environments/automation
2. Settings → Repository → Deploy Keys → Expand
3. Click "Add deploy key"
4. Fill in:
   - **Title:** `jenkins-automation-read-only`
   - **Key:** Paste contents of `~/.ssh/jenkins-gitlab-deploy.pub`
   - **Expires at:** Leave blank (never expires) ⭐
   - **Grant write permissions:** ❌ Unchecked (read-only)
5. Click "Add key"

**For Jenkinsfiles Repo (after migration):**

1. Go to: https://gitlab.com/devo_corp/devops/jenkinsfiles
2. Same process, title: `jenkins-groovy-scripts-read-only`

#### 3. Add Private Key to Jenkins

1. Go to: https://jenkins.devotools.com/credentials/
2. Click "Add Credentials"
3. Fill in:
   - **Kind:** SSH Username with private key
   - **Scope:** Global
   - **ID:** `gitlab-com-deploy-key`
   - **Description:** `GitLab.com Deploy Key (permanent, never expires)`
   - **Username:** `git` ⭐ (important! Not your username)
   - **Private Key:** Enter directly → Paste from `~/.ssh/jenkins-gitlab-deploy`
   - **Passphrase:** Leave blank (or enter if you set one)
4. Click "Create"

#### 4. Update Groovy Script

**File:** `~/Documents/Repository/jenkinsfiles/jobs/job_ops_datanode_trash_deletion_http.groovy`

**Changes:**

```groovy
// BEFORE (HTTPS with PAT):
// Lines 28-29
def String repositoryUrl = "https://gitlab.com"
def String ansibleRepository = "${repositoryUrlNamespace}/automation.git"

// Line 103
git branch: params.ANSIBLE_BRANCH,
    credentialsId: 'gitlab-com-access-token',  // ← Expires!
    url: "${ansibleRepository}"

// Lines 94-97 (Test stage)
withCredentials([usernamePassword(
    credentialsId: 'gitlab-com-access-token',
    passwordVariable: 'GIT_TOKEN',
    usernameVariable: 'GIT_USER')]) {
    sh 'git ls-remote https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/.../automation.git HEAD'
}

// AFTER (SSH with Deploy Key):
// Lines 28-29
def String repositoryUrl = "git@gitlab.com"  // ← Changed to SSH
def String ansibleRepository = "${repositoryUrl}:devo_corp/platform/ansible/environments/automation.git"

// Line 103
git branch: params.ANSIBLE_BRANCH,
    credentialsId: 'gitlab-com-deploy-key',  // ← Permanent!
    url: "${ansibleRepository}"

// Lines 94-97 (Test stage)
withCredentials([sshUserPrivateKey(
    credentialsId: 'gitlab-com-deploy-key',
    keyFileVariable: 'SSH_KEY')]) {
    sh 'GIT_SSH_COMMAND="ssh -i $SSH_KEY -o StrictHostKeyChecking=no" git ls-remote git@gitlab.com:devo_corp/platform/ansible/environments/automation.git HEAD'
}
```

---

### ✅ Solution 2: Deploy Tokens (Good - If SSH Blocked)

**Advantages:**
- ✅ Can be set to never expire
- ✅ Works over HTTPS (port 443 - firewall-friendly)
- ✅ Project-scoped (not user-dependent)
- ✅ Minimal code changes

**Requirements:**
- Jenkins agents have HTTPS access to gitlab.com (port 443) ✅ Always allowed

**Setup Steps:**

#### 1. Create Deploy Token in GitLab

**For Automation Repo:**

1. Go to: https://gitlab.com/devo_corp/platform/ansible/environments/automation
2. Settings → Repository → Deploy Tokens → Expand
3. Click "Add token"
4. Fill in:
   - **Name:** `jenkins-automation-read`
   - **Expires at:** Leave blank (never expires) ⭐
   - **Username:** `jenkins-automation` (custom username)
   - **Scopes:**
     - ✅ `read_repository`
     - ❌ `read_registry`
     - ❌ `write_registry`
5. Click "Create deploy token"
6. **IMPORTANT:** Copy token immediately (shown only once)
   - Username: `jenkins-automation`
   - Token: `gldt-xyz123...` (starts with `gldt-`)

#### 2. Add Deploy Token to Jenkins

1. Go to: https://jenkins.devotools.com/credentials/
2. Add Credentials
3. Fill in:
   - **Kind:** Username with password
   - **Scope:** Global
   - **ID:** `gitlab-com-deploy-token`
   - **Description:** `GitLab.com Deploy Token (permanent, never expires)`
   - **Username:** `jenkins-automation` (from GitLab)
   - **Password:** `gldt-xyz123...` (token from GitLab)
4. Click "Create"

#### 3. Update Groovy Script

**File:** `~/Documents/Repository/jenkinsfiles/jobs/job_ops_datanode_trash_deletion_http.groovy`

**Changes:**

```groovy
// BEFORE:
git branch: params.ANSIBLE_BRANCH,
    credentialsId: 'gitlab-com-access-token',  // ← Expires!
    url: "${ansibleRepository}"

withCredentials([usernamePassword(
    credentialsId: 'gitlab-com-access-token',
    passwordVariable: 'GIT_TOKEN',
    usernameVariable: 'GIT_USER')]) { ... }

// AFTER (minimal changes):
git branch: params.ANSIBLE_BRANCH,
    credentialsId: 'gitlab-com-deploy-token',  // ← Permanent!
    url: "${ansibleRepository}"  // Keep HTTPS URL unchanged

withCredentials([usernamePassword(
    credentialsId: 'gitlab-com-deploy-token',  // ← Changed
    passwordVariable: 'GIT_TOKEN',
    usernameVariable: 'GIT_USER')]) { ... }
```

---

## SSH Connectivity Test Pipeline

**Purpose:** Determine if Jenkins agents can access gitlab.com via SSH (port 22).

**Location:** `~/.jenkins/test-gitlab-ssh-connectivity.groovy`

**Instructions:**

1. **Create Jenkins Job:**
   - Go to: https://jenkins.devotools.com/
   - New Item → Name: `test-gitlab-ssh-connectivity`
   - Type: Pipeline
   - Click OK

2. **Add Pipeline Script:**
   - Scroll to "Pipeline" section
   - Select "Pipeline script"
   - Copy/paste from `/tmp/gitlab-ssh-test-pipeline.groovy`
   - Click Save

3. **Run Test:**
   - Click "Build Now"
   - Wait 10-15 seconds

4. **View Results:**
   ```bash
   source ~/.jenkins/jenkins-helper.sh
   jenkins_console test-gitlab-ssh-connectivity 1
   ```

**Pipeline Script:**

```groovy
pipeline {
    agent any

    stages {
        stage('Identify Agent') {
            steps {
                script {
                    echo "=========================================="
                    echo "Running on Jenkins Agent: ${env.NODE_NAME}"
                    echo "=========================================="
                    sh 'hostname'
                    sh 'uname -a'
                }
            }
        }

        stage('Test SSH to gitlab.com') {
            steps {
                script {
                    echo ""
                    echo "=========================================="
                    echo "TEST 1: Port 22 Connectivity"
                    echo "=========================================="

                    def port22Result = sh(
                        script: '''
                            if nc -zv -w 5 gitlab.com 22 2>&1; then
                                echo "SUCCESS"
                            else
                                echo "FAILED"
                            fi
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Port 22 result: ${port22Result}"

                    echo ""
                    echo "=========================================="
                    echo "TEST 2: SSH Handshake to GitLab"
                    echo "=========================================="

                    def sshResult = sh(
                        script: 'ssh -T -o StrictHostKeyChecking=no -o ConnectTimeout=10 git@gitlab.com 2>&1 || true',
                        returnStdout: true
                    ).trim()

                    echo "${sshResult}"

                    echo ""
                    echo "=========================================="
                    echo "TEST 3: HTTPS Connectivity (comparison)"
                    echo "=========================================="

                    def httpsResult = sh(
                        script: 'curl -I -m 10 https://gitlab.com 2>&1 | head -1',
                        returnStdout: true
                    ).trim()

                    echo "${httpsResult}"

                    echo ""
                    echo "=========================================="
                    echo "ANALYSIS"
                    echo "=========================================="

                    if (port22Result.contains("SUCCESS") || sshResult.contains("Welcome to GitLab")) {
                        echo "✅ RESULT: SSH PORT 22 IS OPEN"
                        echo ""
                        echo "✅ RECOMMENDATION: Use SSH Deploy Keys"
                        echo "   Benefits:"
                        echo "   - Never expire"
                        echo "   - More secure"
                        echo "   - Standard GitLab practice"
                        echo ""
                        echo "   Next Steps:"
                        echo "   1. Generate SSH key pair"
                        echo "   2. Add public key to GitLab projects"
                        echo "   3. Add private key to Jenkins"
                        echo "   4. Update Groovy: git@gitlab.com:..."
                    } else {
                        echo "❌ RESULT: SSH PORT 22 IS BLOCKED"
                        echo ""
                        echo "⚠️  RECOMMENDATION: Use HTTPS Deploy Tokens"
                        echo "   Benefits:"
                        echo "   - Can be set to never expire"
                        echo "   - Works over HTTPS (port 443)"
                        echo "   - Firewall-friendly"
                        echo ""
                        echo "   Next Steps:"
                        echo "   1. Create Deploy Token in GitLab"
                        echo "   2. Set expiration to blank (never)"
                        echo "   3. Add to Jenkins as username/password"
                        echo "   4. Keep HTTPS URLs in Groovy scripts"
                    }

                    echo "=========================================="
                }
            }
        }
    }
}
```

---

## Decision Matrix

| Test Result | Recommended Solution | Credential Type | URL Format | Expires? |
|-------------|---------------------|-----------------|------------|----------|
| ✅ SSH port 22 OPEN | SSH Deploy Keys | SSH private key | `git@gitlab.com:...` | Never |
| ❌ SSH port 22 BLOCKED | Deploy Tokens | Username/password | `https://gitlab.com/...` | Never (if configured) |

---

## Migration Timeline

### Week 1: Test SSH Connectivity
1. Create and run test pipeline
2. Determine SSH vs HTTPS solution
3. Plan implementation

### Week 2: Implement Permanent Credential
1. Generate SSH key or Deploy Token
2. Add to GitLab projects
3. Add to Jenkins credentials
4. Test with single job

### Week 3: Update Master Job
1. Update `job_ops_datanode_trash_deletion_http.groovy`
2. Commit to GitLab
3. Test with DRY_RUN=true
4. Monitor first real execution

### Week 4: Monitor & Validate
1. Verify weekly trash cleanup schedules
2. Confirm no expiration warnings
3. Document credential in Jenkins
4. Remove old PAT credential

---

## Jenkins Infrastructure

**Discovered from automation repo:**

| Component | Hostname | IP Address | Role |
|-----------|----------|------------|------|
| **Master** | jenkins.devotools.com | 10.255.6.111, 10.255.2.55, 10.255.11.72 | Load-balanced |
| **Agent (EU-1)** | jenkins-1-infra-cloud-infra-aws-west-1 | 172.17.25.48 | Build agent |
| **Agent (EU-2)** | jenkins-2-infra-cloud-infra-aws-west-1 | 172.17.14.164 | Build agent |
| **Agent (US)** | jenkins-slave | Unknown | Build agent |

**Note:** Jobs run on **agents** (not master), so SSH test must run from agent.

---

## Cross-GitLab Authentication Flow

**Current (Working but PAT expires):**

```
1. Jenkins loads Groovy from: gitlab.devotools.com (OLD)
   Credential: gitlab-devotools-ssh-key

2. Groovy script checks out Ansible from: gitlab.com (NEW)
   Credential: gitlab-com-access-token (PAT - expires in 1 year!)

3. Ansible executes on datanodes
   Credential: 3caaf92c-50c3-4c95-9ed8-777bdc409bd8 (SSH key)
```

**After migration (Permanent):**

```
1. Jenkins loads Groovy from: gitlab.com (NEW)
   Credential: gitlab-com-deploy-key or gitlab-com-deploy-token

2. Groovy script checks out Ansible from: gitlab.com (NEW)
   Credential: gitlab-com-deploy-key or gitlab-com-deploy-token (same!)

3. Ansible executes on datanodes
   Credential: 3caaf92c-50c3-4c95-9ed8-777bdc409bd8 (unchanged)
```

---

## Troubleshooting

### Deploy Key Not Working

**Symptom:** `Permission denied (publickey)`

**Check:**
1. Verify public key added to GitLab project
2. Verify "Expires at" is blank
3. Check Jenkins credential uses username `git` (not your username)
4. Test SSH from Jenkins agent:
   ```bash
   ssh -T git@gitlab.com
   ```

### Deploy Token Not Working

**Symptom:** `Authentication failed`

**Check:**
1. Verify token hasn't expired (check GitLab settings)
2. Verify token has `read_repository` scope
3. Check username matches token username in GitLab
4. Test HTTPS from Jenkins agent:
   ```bash
   git ls-remote https://jenkins-automation:gldt-xyz@gitlab.com/.../automation.git
   ```

### Firewall Issues

**If SSH suddenly stops working after migration:**
1. Verify network/firewall rules haven't changed
2. Re-run SSH test pipeline
3. Fall back to Deploy Tokens (HTTPS)

---

## Related Files

```
~/.jenkins/
├── credentials                          # API credentials
├── jenkins-helper.sh                    # Helper functions
├── trash-cleanup-helper.sh              # Trash cleanup automation
└── test-gitlab-ssh-connectivity.groovy  # SSH connectivity test

~/.claude/skills/jenkins/
├── SKILL.md                             # Main skill documentation
├── credential-migration-guide.md        # This file
├── trash-cleanup-automation.md          # Trash cleanup details
└── README.md                            # Complete Jenkins docs

~/Documents/Repository/jenkinsfiles/
└── jobs/
    ├── job_ops_datanode_trash_deletion_http.groovy  # Master job (needs update)
    └── trash_clean-up_schedules/                    # Regional wrappers (auto-updated)
```

---

**Created:** 2026-03-22
**Status:** 📋 Ready for Implementation (after SSH test)
**Priority:** HIGH (PAT expires in <1 year)
**Impact:** All Jenkins automation breaks if not addressed
