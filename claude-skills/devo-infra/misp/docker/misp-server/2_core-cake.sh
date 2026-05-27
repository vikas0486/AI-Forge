
PATH_TO_MISP=$1
CAKE=$PATH_TO_MISP/app/Console/cake
GPG_EMAIL_ADDRESS=$2
GPG_PASSPHRASE=$3
FLAVOUR=$4
MISP_BASEURL=$5

$CAKE userInit -q

# This makes sure all Database upgrades are done, without logging in.
$CAKE Admin updateDatabase

# Setup some more MISP default via cake CLI

# The default install is Python in a virtualenv, setting accordingly
$CAKE Admin setSetting "MISP.python_bin" "${PATH_TO_MISP}/venv/bin/python"

# Tune global time outs
$CAKE Admin setSetting "Session.autoRegenerate" 0
$CAKE Admin setSetting "Session.timeout" 600
$CAKE Admin setSetting "Session.cookieTimeout" 3600

# Change base url, either with this CLI command or in the UI
$CAKE Baseurl $MISP_BASEURL
# example: 'baseurl' => 'https://<your.FQDN.here>',
# alternatively, you can leave this field empty if you would like to use relative pathing in MISP
# 'baseurl' => '',

# Enable GnuPG
$CAKE Admin setSetting "GnuPG.email" "$GPG_EMAIL_ADDRESS"
$CAKE Admin setSetting "GnuPG.homedir" "$PATH_TO_MISP/.gnupg"
$CAKE Admin setSetting "GnuPG.password" "$GPG_PASSPHRASE"

# Enable installer org and tune some configurables
$CAKE Admin setSetting "MISP.host_org_id" 1
$CAKE Admin setSetting "MISP.email" "info@admin.test"
$CAKE Admin setSetting "MISP.disable_emailing" true
$CAKE Admin setSetting "MISP.contact" "info@admin.test"
$CAKE Admin setSetting "MISP.disablerestalert" true
$CAKE Admin setSetting "MISP.showCorrelationsOnIndex" true
$CAKE Admin setSetting "MISP.default_event_tag_collection" 0

# Provisional Cortex tunes
$CAKE Admin setSetting "Plugin.Cortex_services_enable" false
$CAKE Admin setSetting "Plugin.Cortex_services_url" "http://127.0.0.1"
$CAKE Admin setSetting "Plugin.Cortex_services_port" 9000
$CAKE Admin setSetting "Plugin.Cortex_timeout" 120
$CAKE Admin setSetting "Plugin.Cortex_authkey" ""
# Mysteriously removed?
#$CAKE Admin setSetting "Plugin.Cortex_services_timeout" 120
# Mysteriously removed?
#$CAKE Admin setSetting "Plugin.Cortex_services_authkey" ""
$CAKE Admin setSetting "Plugin.Cortex_ssl_verify_peer" false
$CAKE Admin setSetting "Plugin.Cortex_ssl_verify_host" false
$CAKE Admin setSetting "Plugin.Cortex_ssl_allow_self_signed" true

# Various plugin sightings settings
$CAKE Admin setSetting "Plugin.Sightings_policy" 0
$CAKE Admin setSetting "Plugin.Sightings_anonymise" false
$CAKE Admin setSetting "Plugin.Sightings_range" 365

# Plugin CustomAuth tuneable
$CAKE Admin setSetting "Plugin.CustomAuth_disable_logout" false

# RPZ Plugin settings
$CAKE Admin setSetting "Plugin.RPZ_policy" "DROP"
$CAKE Admin setSetting "Plugin.RPZ_walled_garden" "127.0.0.1"
$CAKE Admin setSetting "Plugin.RPZ_serial" "\$date00"
$CAKE Admin setSetting "Plugin.RPZ_refresh" "2h"
$CAKE Admin setSetting "Plugin.RPZ_retry" "30m"
$CAKE Admin setSetting "Plugin.RPZ_expiry" "30d"
$CAKE Admin setSetting "Plugin.RPZ_minimum_ttl" "1h"
$CAKE Admin setSetting "Plugin.RPZ_ttl" "1w"
$CAKE Admin setSetting "Plugin.RPZ_ns" "localhost."
$CAKE Admin setSetting "Plugin.RPZ_ns_alt" ""
$CAKE Admin setSetting "Plugin.RPZ_email" "root.localhost"

# Force defaults to make MISP Server Settings less RED
$CAKE Admin setSetting "MISP.language" "eng"
$CAKE Admin setSetting "MISP.proposals_block_attributes" false

# Redis block
$CAKE Admin setSetting "MISP.redis_host" "127.0.0.1"
$CAKE Admin setSetting "MISP.redis_port" 6379
$CAKE Admin setSetting "MISP.redis_database" 13
$CAKE Admin setSetting "MISP.redis_password" ""

# Force defaults to make MISP Server Settings less YELLOW
$CAKE Admin setSetting "MISP.ssdeep_correlation_threshold" 40
$CAKE Admin setSetting "MISP.extended_alert_subject" false
$CAKE Admin setSetting "MISP.default_event_threat_level" 4
$CAKE Admin setSetting "MISP.newUserText" "Dear new MISP user,\\n\\nWe would hereby like to welcome you to the \$org MISP community.\\n\\n Use the credentials below to log into MISP at \$misp, where you will be prompted to manually change your password to something of your own choice.\\n\\nUsername: \$username\\nPassword: \$password\\n\\nIf you have any questions, don't hesitate to contact us at: \$contact.\\n\\nBest regards,\\nYour \$org MISP support team"
$CAKE Admin setSetting "MISP.passwordResetText" "Dear MISP user,\\n\\nA password reset has been triggered for your account. Use the below provided temporary password to log into MISP at \$misp, where you will be prompted to manually change your password to something of your own choice.\\n\\nUsername: \$username\\nYour temporary password: \$password\\n\\nIf you have any questions, don't hesitate to contact us at: \$contact.\\n\\nBest regards,\\nYour \$org MISP support team"
$CAKE Admin setSetting "MISP.enableEventBlacklisting" true
$CAKE Admin setSetting "MISP.enableOrgBlacklisting" true
$CAKE Admin setSetting "MISP.log_client_ip" false
$CAKE Admin setSetting "MISP.log_auth" false
$CAKE Admin setSetting "MISP.disableUserSelfManagement" false
$CAKE Admin setSetting "MISP.block_event_alert" false
$CAKE Admin setSetting "MISP.block_event_alert_tag" "no-alerts=\"true\""
$CAKE Admin setSetting "MISP.block_old_event_alert" false
$CAKE Admin setSetting "MISP.block_old_event_alert_age" ""
$CAKE Admin setSetting "MISP.incoming_tags_disabled_by_default" false
$CAKE Admin setSetting "MISP.footermidleft" "This is an initial install"
$CAKE Admin setSetting "MISP.footermidright" "Please configure and harden accordingly"
$CAKE Admin setSetting "MISP.welcome_text_top" "Initial Install, please configure"
# TODO: Make sure $FLAVOUR is correct
$CAKE Admin setSetting "MISP.welcome_text_bottom" "Welcome to MISP on $FLAVOUR, change this message in MISP Settings"

# Force defaults to make MISP Server Settings less GREEN
$CAKE Admin setSetting "Security.password_policy_length" 12
$CAKE Admin setSetting "Security.password_policy_complexity" '/^((?=.*\d)|(?=.*\W+))(?![\n])(?=.*[A-Z])(?=.*[a-z]).*$|.{16,}/'

# Set MISP Live
$CAKE Live 1

# This updates Galaxies, ObjectTemplates, Warninglists, Noticelists, Templates
/bin/bash

