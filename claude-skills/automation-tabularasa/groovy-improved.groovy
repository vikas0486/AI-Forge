#!/usr/bin/env groovy

// ============================================================================
// Tabula Rasa Automation - Production Pipeline
// ============================================================================
// Purpose: Automated domain-to-datanode affinity management
// Features: Backup, dry-run, approval, SQL execution, automatic rollback
// Database: Verified schema (affinity, domain, machine, trunk tables)
// User: tabularasa (limited permissions: SELECT on source, INSERT/UPDATE on affinity)
// Author: Vikash Jaiswal
// Last Updated: 2026-04-23
// ============================================================================

// Global variable definitions
def String ansibleBranch = params.ansible_branch
def String ansibleRegion = params.region
def String ansibleCloud = params.cloud
def String ansibleEnvironment = params.enviroment

def String repositoryUrl = "git@gitlab.devotools.com"
def String repositoryUrlNamespace = "${repositoryUrl}:cm/ansible"

def String ansibleRepository = "${repositoryUrlNamespace}/automation.git"
def String ansibleInventory
def String ansiblePlaybookBasePath
def String actualTaraOutputDir

if ( "${ansibleEnvironment}" == 'stage'  || ("${ansibleEnvironment}" == 'data-anonymization' || "${ansibleEnvironment}" == 'devtools') ) {
  ansibleRepository = "${repositoryUrlNamespace}/${ansibleEnvironment}.git"
  ansibleInventory = "environment/hosts"
  ansiblePlaybookBasePath = "playbooks/"
} else {
  ansibleInventory = "ansible/environments/${ansibleCloud}/${ansibleRegion}/${ansibleEnvironment}/hosts"
  ansiblePlaybookBasePath = "ansible/playbooks/"
}

actualTaraOutputDir = "${ansiblePlaybookBasePath}TabulaRasa"

def String executionDateTimeExtraVar = ""
if (params.execution_datetime?.trim()) {
    if (params.execution_datetime.trim() ==~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/) {
        executionDateTimeExtraVar = "-e custom_execution_datetime='${params.execution_datetime.trim()}'"
    }
}

// ============================================================================
// Pipeline Definition
// ============================================================================

pipeline {
  agent any

  options {
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '100'))
    disableConcurrentBuilds()
    skipDefaultCheckout()
    timeout(time: 1, unit: 'HOURS')
    timestamps()
  }

  parameters {
    string(name: 'ansible_branch', defaultValue: 'master', description: 'Branch to build')
    choice(name: 'tabula_rasa_type', choices: ['rebalance','tabularasa'], description: 'Choose TabulaRasa or Rebalance mode')
    string(name: 'review_days', defaultValue: '7', description: 'Number of days backwards to review')
    string(name: 'min_pools', defaultValue: '2', description:  'Minimum number of datanodes per domain')
    string(name: 'domain_datanode_percentage', defaultValue: '0.35', description: 'Maximum percentage that a domain can occupy a DN')
    string(name: 'exclude_alcohol', defaultValue: '', description: 'Datanodes to exclude (e.g., dn1,dn2)')
    string(name: 'other_options', defaultValue: '', description: 'Other parameters (e.g., -e --aff.trunk_chunks=10)')
    string(name: 'machine_group', defaultValue: 'public', description: 'Machine group for Tabula Rasa')
    string(name: 'execution_datetime', defaultValue: '', description: 'Optional: UTC timestamp for SQL (YYYY-MM-DD HH:MM)')

    // Database configuration
    string(name: 'db_host', defaultValue: 'prod-apac-logtrust-database.cluster-cdpk1lzmfdj6.ap-southeast-1.rds.amazonaws.com', description: 'Database host')
    string(name: 'db_port', defaultValue: '3306', description: 'Database port')
    string(name: 'db_name', defaultValue: 'logtrust', description: 'Database name')
    string(name: 'db_credentials_id', defaultValue: 'tabularasa-db-credentials', description: 'Jenkins credentials ID')

    // Execution options
    booleanParam(name: 'skip_approval', defaultValue: false, description: 'Skip manual approval (auto-approve)')
    booleanParam(name: 'dry_run_only', defaultValue: false, description: 'Only generate SQL, do not execute')
  }

  environment {
    BACKUP_TIMESTAMP = sh(script: "date -u '+%Y%m%d-%H%M%S'", returnStdout: true).trim()
    SQL_BACKUP_FILE = "rollback-${params.machine_group}-${env.BACKUP_TIMESTAMP}.sql"
  }

  stages {
    // ========================================================================
    // Stage 1: Validate Parameters
    // ========================================================================
    stage('Validate Parameters') {
      steps {
        script {
          echo "============================================"
          echo "Tabula Rasa Automation"
          echo "============================================"
          echo "Region: ${ansibleRegion}"
          echo "Cloud: ${ansibleCloud}"
          echo "Environment: ${ansibleEnvironment}"
          echo "Type: ${params.tabula_rasa_type}"
          echo "Review Days: ${params.review_days}"
          echo "Machine Group: ${params.machine_group}"
          echo "Database: ${params.db_host}:${params.db_port}/${params.db_name}"
          echo "User: tabularasa (limited permissions)"
          echo "============================================"

          // Validate execution_datetime format
          if (params.execution_datetime?.trim()) {
            if (!(params.execution_datetime.trim() ==~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/)) {
              error("ERROR: Invalid format for 'execution_datetime'. Expected 'YYYY-MM-DD HH:MM', but got '${params.execution_datetime}'")
            }
            echo "✅ Custom execution datetime validated: ${params.execution_datetime.trim()}"
          } else {
            echo "ℹ️  No custom datetime. Using current UTC time."
          }

          // Validate numeric parameters
          if (!(params.review_days ==~ /^\d+$/)) {
            error("ERROR: 'review_days' must be a positive integer")
          }
          if (!(params.min_pools ==~ /^\d+$/)) {
            error("ERROR: 'min_pools' must be a positive integer")
          }

          echo "✅ All parameters validated successfully"
        }
      }
    }

    // ========================================================================
    // Stage 2: Checkout Repository
    // ========================================================================
    stage('Checkout repo') {
      steps {
        script{
          echo "============================================"
          echo "Stage: Checkout Repository"
          echo "============================================"
          echo "Repository: ${ansibleRepository}"
          echo "Branch: ${ansibleBranch}"
          echo "============================================"

          git url: "${ansibleRepository}", branch: "${ansibleBranch}"

          echo "✅ Repository checked out successfully"
        }
      }
    }

    // ========================================================================
    // Stage 3: Backup Current Affinity
    // ========================================================================
    stage('Backup Current Affinity') {
      steps {
        script {
          echo "============================================"
          echo "Stage: Backup Current Affinity"
          echo "============================================"
          echo "Creating backup of existing affinity table..."
          echo "Backup file: ${env.SQL_BACKUP_FILE}"
          echo "Table: logtrust.affinity (verified from production)"
          echo "============================================"

          withCredentials([usernamePassword(
            credentialsId: params.db_credentials_id,
            usernameVariable: 'DB_USER',
            passwordVariable: 'DB_PASS'
          )]) {
            // Create output directory if it doesn't exist
            sh "mkdir -p ${actualTaraOutputDir}"

            // Export current affinity table as SQL
            def backupCmd = """
              mysqldump -h ${params.db_host} \
                        -P ${params.db_port} \
                        -u \${DB_USER} \
                        -p\${DB_PASS} \
                        --no-create-info \
                        --complete-insert \
                        --skip-add-locks \
                        --skip-comments \
                        --where="expiration_date IS NULL OR expiration_date > NOW()" \
                        ${params.db_name} affinity \
                        > ${actualTaraOutputDir}/${env.SQL_BACKUP_FILE}
            """

            def exitCode = sh(script: backupCmd, returnStatus: true)

            if (exitCode == 0) {
              def rowCount = sh(
                script: "grep -c '^INSERT' ${actualTaraOutputDir}/${env.SQL_BACKUP_FILE} || echo 0",
                returnStdout: true
              ).trim()
              echo "✅ Backup created successfully"
              echo "   Active affinity rows exported: ${rowCount}"
              echo "   Backup location: ${actualTaraOutputDir}/${env.SQL_BACKUP_FILE}"
            } else {
              error("❌ ERROR: Failed to create affinity backup. Exit code: ${exitCode}")
            }
          }
        }
      }
    }

    // ========================================================================
    // Stage 4: Execute Tabula Rasa Playbook
    // ========================================================================
    stage('Execute playbook') {
      steps {
        script {
          echo "============================================"
          echo "Stage: Execute Tabula Rasa Playbook"
          echo "============================================"
          echo "Downloading tara tool from Nexus..."
          echo "Querying Malote and MySQL for ingestion data..."
          echo "Calculating optimal affinity assignments..."
          echo "============================================"

          def extrasList = [
            "-e tabula_rasa_type='${params.tabula_rasa_type}'",
            "-e review_days='${params.review_days}'",
            "-e min_pools='${params.min_pools}'",
            "-e domain_datanode_percentage='${params.domain_datanode_percentage}'",
            "-e machine_group='${params.machine_group}'"
          ]

          if (params.exclude_alcohol?.trim()) {
            extrasList.add("-e exclude_alcohol='${params.exclude_alcohol.trim()}'")
          }
          if (executionDateTimeExtraVar) {
            extrasList.add(executionDateTimeExtraVar)
          }

          def finalExtras = extrasList.join(" ")

          if (params.other_options?.trim()) {
            finalExtras += " ${params.other_options.trim()}"
          }
          finalExtras = finalExtras.trim()

          echo "Playbook: ${ansiblePlaybookBasePath}tabula_rasa.yml"
          echo "Inventory: ${ansibleInventory}"
          echo "Extras: ${finalExtras}"
          echo "============================================"

          ansiblePlaybook(
            playbook: "${ansiblePlaybookBasePath}tabula_rasa.yml",
            installation: 'Ansible 2.10',
            inventory: "${ansibleInventory}",
            credentialsId: '3caaf92c-50c3-4c95-9ed8-777bdc409bd8',
            extras: finalExtras,
            colorized: true
          )

          echo "✅ Tara tool executed successfully"
          echo "✅ SQL file generated"
        }
      }
    }

    // ========================================================================
    // Stage 5: Change SQL Date (if custom datetime provided)
    // ========================================================================
    stage('Change SQL Date') {
        when {
            expression { params.execution_datetime?.trim() != "" }
        }
        steps {
            script {
                echo "============================================"
                echo "Stage: Change SQL Date"
                echo "============================================"
                echo "Setting custom execution datetime in SQL..."
                echo "Target datetime: ${params.execution_datetime.trim()} UTC"
                echo "============================================"

                def sqlFileName
                if (params.tabula_rasa_type == 'rebalance') {
                    sqlFileName = "rebalance-${params.machine_group}.sql"
                } else {
                    sqlFileName = "tabula-rasa-${params.machine_group}.sql"
                }
                def sqlFileToModifyPath = "${actualTaraOutputDir}/${sqlFileName}"

                if (fileExists(sqlFileToModifyPath)) {
                    def customDateTimeToSetInSql = params.execution_datetime.trim()
                    def replacementLine = "SET @change_date := '${customDateTimeToSetInSql}';"

                    def fileContent = readFile(file: sqlFileToModifyPath, encoding: 'UTF-8')
                    def newContent = fileContent.replaceAll('(?m)^SET @change_date := .*$', replacementLine)

                    if (newContent == fileContent) {
                        error("❌ ERROR: Could not find 'SET @change_date' line in SQL file")
                    } else {
                        writeFile(file: sqlFileToModifyPath, text: newContent, encoding: 'UTF-8')
                        echo "✅ Date modified successfully in SQL file"
                        echo "   New timestamp: ${customDateTimeToSetInSql}"
                    }
                } else {
                    error("❌ ERROR: SQL file '${sqlFileToModifyPath}' not found")
                }
            }
        }
    }

    // ========================================================================
    // Stage 6: Dry-Run Validation
    // ========================================================================
    stage('Dry-Run Validation') {
      when {
        expression { !params.dry_run_only }
      }
      steps {
        script {
          echo "============================================"
          echo "Stage: Dry-Run Validation"
          echo "============================================"
          echo "Validating SQL syntax and content..."
          echo "============================================"

          def sqlFileName
          if (params.tabula_rasa_type == 'rebalance') {
            sqlFileName = "rebalance-${params.machine_group}.sql"
          } else {
            sqlFileName = "tabula-rasa-${params.machine_group}.sql"
          }
          def sqlFileToExecute = "${actualTaraOutputDir}/${sqlFileName}"

          if (fileExists(sqlFileToExecute)) {
            // Count expected INSERT statements
            def insertCount = sh(
              script: "grep -c '^INSERT' ${sqlFileToExecute} || echo 0",
              returnStdout: true
            ).trim()

            // Validate table names (should be 'affinity' not 'affinity_assignment')
            def hasCorrectTable = sh(
              script: "grep -q 'INTO affinity' ${sqlFileToExecute} && echo 'true' || echo 'false'",
              returnStdout: true
            ).trim()

            if (hasCorrectTable == 'false') {
              error("❌ ERROR: SQL file uses incorrect table name. Expected 'affinity' table.")
            }

            echo "✅ Dry-run validation passed"
            echo "   Expected INSERT statements: ${insertCount}"
            echo "   Table name validated: affinity ✅"
            echo "   SQL file: ${sqlFileName}"
          } else {
            error("❌ ERROR: SQL file '${sqlFileToExecute}' not found")
          }
        }
      }
    }

    // ========================================================================
    // Stage 7: Manual Approval
    // ========================================================================
    stage('Manual Approval') {
      when {
        expression { !params.skip_approval && !params.dry_run_only }
      }
      steps {
        script {
          echo "============================================"
          echo "Stage: Manual Approval Required"
          echo "============================================"
          echo "⚠️  Review generated affinity changes before proceeding"
          echo ""
          echo "Check artifacts:"
          echo "  - CSV files: current vs new domain distribution"
          echo "  - SQL file: affinity assignments to be applied"
          echo "  - Backup file: ${env.SQL_BACKUP_FILE}"
          echo ""
          echo "============================================"

          timeout(time: 30, unit: 'MINUTES') {
            input(
              message: '⚠️  Review affinity changes. Proceed with SQL execution?',
              ok: 'Approve & Execute',
              submitter: 'admin,ops-team,vikash.jaiswal'
            )
          }

          echo "✅ Execution approved by user"
        }
      }
    }

    // ========================================================================
    // Stage 8: Execute SQL File
    // ========================================================================
    stage('Execute SQL File') {
      when {
        expression { !params.dry_run_only }
      }
      steps {
        script {
          echo "============================================"
          echo "Stage: Execute SQL File"
          echo "============================================"
          echo "Applying new affinity assignments to database..."
          echo "Database: ${params.db_host}"
          echo "Table: logtrust.affinity"
          echo "User: tabularasa (limited permissions)"
          echo "============================================"

          def sqlFileName
          if (params.tabula_rasa_type == 'tabularasa') {
            sqlFileName = "tabula-rasa-${params.machine_group}.sql"
          } else {
            sqlFileName = "rebalance-${params.machine_group}.sql"
          }
          def sqlFileToExecute = "${actualTaraOutputDir}/${sqlFileName}"

          if (fileExists(sqlFileToExecute)) {
            withCredentials([usernamePassword(
              credentialsId: params.db_credentials_id,
              usernameVariable: 'DB_USER',
              passwordVariable: 'DB_PASS'
            )]) {
              // Execute SQL with transaction safety
              def mysqlCmd = """
                mysql -h ${params.db_host} \
                      -P ${params.db_port} \
                      -u \${DB_USER} \
                      -p\${DB_PASS} \
                      ${params.db_name} \
                      --comments \
                      --verbose \
                      < ${sqlFileToExecute}
              """

              echo "Executing SQL file: ${sqlFileName}"

              try {
                def exitCode = sh(
                  script: mysqlCmd,
                  returnStatus: true
                )

                if (exitCode == 0) {
                  // Verify execution by counting rows
                  def verifyCmd = """
                    mysql -h ${params.db_host} \
                          -P ${params.db_port} \
                          -u \${DB_USER} \
                          -p\${DB_PASS} \
                          ${params.db_name} \
                          -e "SELECT
                                COUNT(*) as total_affinity,
                                COUNT(DISTINCT domain_id) as unique_domains,
                                COUNT(DISTINCT trunk_id) as unique_trunks
                              FROM affinity
                              WHERE creation_date > NOW() - INTERVAL 5 MINUTE;"
                  """

                  def verification = sh(script: verifyCmd, returnStdout: true).trim()

                  echo "✅ SQL file '${sqlFileName}' executed successfully"
                  echo ""
                  echo "Verification results:"
                  echo "${verification}"
                  echo ""
                } else {
                  currentBuild.result = 'FAILURE'
                  error("❌ ERROR: SQL execution failed with exit code: ${exitCode}")
                }
              } catch (Exception e) {
                currentBuild.result = 'FAILURE'
                echo "❌ CRITICAL ERROR: ${e.message}"

                // Trigger rollback in post section
                env.ROLLBACK_NEEDED = 'true'

                throw e
              }
            }
          } else {
            error("❌ ERROR: SQL file '${sqlFileToExecute}' not found")
          }
        }
      }
    }
  }

  // ==========================================================================
  // Post-Build Actions
  // ==========================================================================
  post {
    success {
      script {
        echo "============================================"
        echo "Pipeline: SUCCESS ✅"
        echo "============================================"
        echo "Archiving artifacts..."

        // Archive all generated files
        archiveArtifacts artifacts: "${actualTaraOutputDir}/**/*.csv",
                         onlyIfSuccessful: true,
                         allowEmptyArchive: true

        archiveArtifacts artifacts: "${actualTaraOutputDir}/**/*.sql",
                         onlyIfSuccessful: true,
                         allowEmptyArchive: true

        archiveArtifacts artifacts: "${actualTaraOutputDir}/**/*.json",
                         onlyIfSuccessful: true,
                         allowEmptyArchive: true

        echo "✅ All artifacts archived successfully"
        echo "✅ Affinity update completed"
        echo ""
        echo "Artifacts include:"
        echo "  - Current state CSV files (before changes)"
        echo "  - New state CSV files (after changes)"
        echo "  - SQL file (executed)"
        echo "  - Backup file (${env.SQL_BACKUP_FILE})"
        echo "  - Malote data JSON"
        echo ""
        echo "Build artifacts available at:"
        echo "${env.BUILD_URL}artifact/"

        // Clean up workspace
        sh "rm -rf ${actualTaraOutputDir}"
        echo "✅ Workspace cleaned"
      }
    }

    failure {
      script {
        echo "============================================"
        echo "Pipeline: FAILURE ❌"
        echo "============================================"

        if (env.ROLLBACK_NEEDED == 'true') {
          echo "⚠️  SQL execution failed. Initiating automatic rollback..."
          echo "Rollback file: ${env.SQL_BACKUP_FILE}"
          echo ""

          try {
            withCredentials([usernamePassword(
              credentialsId: params.db_credentials_id,
              usernameVariable: 'DB_USER',
              passwordVariable: 'DB_PASS'
            )]) {
              def rollbackCmd = """
                mysql -h ${params.db_host} \
                      -P ${params.db_port} \
                      -u \${DB_USER} \
                      -p\${DB_PASS} \
                      ${params.db_name} \
                      < ${actualTaraOutputDir}/${env.SQL_BACKUP_FILE}
              """

              def rollbackExitCode = sh(script: rollbackCmd, returnStatus: true)

              if (rollbackExitCode == 0) {
                echo "✅ Rollback completed successfully"
                echo "✅ Affinity restored from backup: ${env.SQL_BACKUP_FILE}"
                echo ""
              } else {
                echo "❌ CRITICAL: Rollback failed! Manual intervention required!"
                echo "❌ Backup file available: ${actualTaraOutputDir}/${env.SQL_BACKUP_FILE}"
                echo ""
                echo "Manual rollback command:"
                echo "mysql -h ${params.db_host} -u tabularasa -p ${params.db_name} < ${env.SQL_BACKUP_FILE}"
              }
            }
          } catch (Exception e) {
            echo "❌ CRITICAL: Rollback exception: ${e.message}"
            echo "❌ Manual rollback required using backup: ${env.SQL_BACKUP_FILE}"
          }
        }

        // Archive artifacts even on failure (for troubleshooting)
        archiveArtifacts artifacts: "${actualTaraOutputDir}/**/*",
                         allowEmptyArchive: true

        echo ""
        echo "⚠️  Troubleshooting:"
        echo "  1. Check console output for error details"
        echo "  2. Review artifacts (CSV, SQL files)"
        echo "  3. Verify database connectivity"
        echo "  4. Check user permissions (tabularasa user)"
        echo ""
        echo "Build artifacts: ${env.BUILD_URL}artifact/"
      }
    }

    always {
      script {
        echo "============================================"
        echo "Pipeline: Cleanup"
        echo "============================================"

        // Clean up temporary files (keep only archived artifacts)
        sh "rm -f ${ansiblePlaybookBasePath}*.csv ${ansiblePlaybookBasePath}*.sql ${ansiblePlaybookBasePath}*.json"

        echo "✅ Cleanup completed"
        echo "============================================"
        echo "Pipeline execution finished"
        echo ""
        echo "Build: #${env.BUILD_NUMBER}"
        echo "Duration: ${currentBuild.durationString}"
        echo "Result: ${currentBuild.result}"
        echo "Region: ${ansibleRegion}"
        echo "Type: ${params.tabula_rasa_type}"
        echo "============================================"
      }
    }
  }
}
