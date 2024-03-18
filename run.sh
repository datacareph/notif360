#!/bin/bash

##############################################
# Main Script
# Author: esstat17
# Website: https://datacareph.com
# Description: The main script to handle SEIM and notifications
# Usage: ./run.sh <force_send_notif> <skip_system_check> <skip_virustotal_scan>
##############################################

set -o pipefail

start="$(date +%s)" # Kick-off

# Magenta, Blue, Green, Yellow, Red text-color
ask() { printf "\033[00;35m$(date '+%Y/%m/%d %H:%M:%S') - ASK: $1\033[0m\n"; }
info() { printf "\033[00;34m$(date '+%Y/%m/%d %H:%M:%S') - INFO: $1\033[0m\n"; }
success() { printf "\033[00;32m$(date '+%Y/%m/%d %H:%M:%S') - SUCCESS: $1\033[0m\n"; }
warn() { printf "\033[00;33m$(date '+%Y/%m/%d %H:%M:%S') - WARNING: $1\033[0m\n"; }
fail() { printf "\033[00;31m$(date '+%Y/%m/%d %H:%M:%S') - ERROR: $1\033[0m\n"; }
failsoexit() {
    printf "\033[00;31m$(date '+%Y/%m/%d %H:%M:%S') - ERROR: $1\033[0m\n"
    exit 1
}

# Validate input parameters
if [ "$#" -ne 3 ]; then
    info "Usage: $0 <force_send_notif> <skip_system_check> <skip_virustotal_scan>"
    exit 1
fi

# Get the directory of the script
script_dir="$(dirname "${BASH_SOURCE[0]}")"
cd "$script_dir" || failsoexit "Cannot cd into script directory"
current_working_dir="$(pwd)"
env_file="$current_working_dir/.env" # Set the path of the .env

if [ -f "$env_file" ]; then
    # Read .env file and set variables
    while IFS= read -r line || [[ -n "$line" ]]; do

        # Remove comments
        line=$(echo "$line" | sed 's/#.*//')

        if [[ ! -z "$line" ]]; then
            # Split the line into an array
            key="${line%%=*}"
            value="${line#*=}"

            # Remove leading and trailing whitespaces
            value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

            # Remove leading and trailing quotes if present
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"

            # Remove leading and trailing white spaces
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"

            # Declare the variable
            declare "$key=$value"
        fi
    done < "$env_file"
else
    info ".env file not found in $current_working_dir"
    info "Copying from sample.."
    cp "${current_working_dir}/env.sample" "${current_working_dir}/.env" || failsoexit "PATH: $current_working_dir. Cannot copy env.sample file"
    failsoexit "You must modify .env file accordingly and run this again"
fi

# Set default values for env_vars
force_send_notif=${1:-"$FORCE_SEND_NOTIFICATION"} # prioritize param
skip_system_check=${2:-"$SKIP_SYSTEM_CHECK"} # prioritize param
skip_virustotal_scan=${3:-"$SKIP_VIRUSTOTAL_SCAN"} # skip virustotal scan
partial_system_check=${PARTIAL_SYSTEM_CHECK:-"no"}
check_target_directories=${CHECK_TARGET_DIRECTORIES:-"/opt /home /var/www"}
target_dir_max_size=${TARGET_DIR_MAX_SIZE:-"512"} # MiB Total
slack_webhook_url=${SLACK_WEBHOOK_URL:-""}
memory_threshold=${MEMORY_THRESHOLD:-80}  # Example threshold: 80%
cpu_threshold=${CPU_THRESHOLD:-70}     # Example threshold: 70%
disk_threshold=${DISK_THRESHOLD:-90}     # Example disk: 70%
backup_name_prefix=${BACKUP_NAME_PREFIX:-"sys_info_"}
keep_n_files=${MAX_KEEP_LOGS:-"10"}
destination_dir=${DESTINATION_DIR:-"."}
smtp_server=${SMTP_SERVER:-""}
email_subject=${EMAIL_SUBJECT:-"*Security Information and Event Management (SIEM) Notification*"}
virustotal_api_key=${VIRUSTOTAL_API_KEY:-""} # Get from virustotal
urls_to_scan=${URLS_TO_SCAN:-""}
domains_to_check=${DOMAINS_TO_CHECK:-""} # SSL Cert Check
request_timeout=${REQUEST_TIMEOUT:-10}

# Local vars
timestamp="$(date '+%b-%d-%Y_%H-%M-%S')" # $(date '+%b-%d-%Y')

[[ -n $backup_name_prefix ]] || failsoexit "Backup prefix is mandatory"

cd "$destination_dir" && absolute_destination_dir="$(pwd)" \
|| failsoexit "Cannot cd destination directory: $destination_dir"

# Run the backup and log the output
logs_directory="$destination_dir/logs"
log_file="$logs_directory/$backup_name_prefix$timestamp.log"

if [ ! -d "$logs_directory" ]; then
    mkdir -p "$logs_directory" || failsoexit "Cannot create logs directory: mkdir"
fi

# Remove older file first and keep n files
if [ "$keep_n_files" -ne 0 ] && [ -n "$(ls -A "$logs_directory"* 2>/dev/null)" ]; then
    # Only keep 5 recent backup files
    ls -t "$logs_directory/$backup_name_prefix"*".log" | tail -n +"$keep_n_files" | xargs -I {} rm -r "{}" || warn "Fail to remove old backups"
fi
# Initialize an empty array
final_status=("*$email_subject*")

# Website Check Up or Down
status_report="good"
current_state="good"
if [[ -n "$urls_to_scan" ]]; then
    sleep 1
    # Website Up or Down check
    info "Working on website URL check: via cURL" | tee -a "$log_file"
    status_report=$("$current_working_dir/website-check.sh" "$urls_to_scan" "$force_send_notif" 2>/dev/null | \
    tee -a "$log_file" \
    || fail "Fail to run: website-check.sh")

    # No need add into final_status array when it is good status
    if [[ "$status_report" != "good" ]]; then
        final_status+=("$status_report") # Adding into array
        current_state="bad" # status: bad
    fi
else
    info "Missing 'urls_to_scan'. Skipping website check reports" | tee -a "$log_file"
fi

if [[ -n "$domains_to_check" ]]; then
    sleep 1
    # SSL Certificate check
    info "Working on SSL Certificate check: via OpenSSL" | tee -a "$log_file"
    status_report=$("$current_working_dir/ssl-cert-check.sh" "$domains_to_check" "$force_send_notif" 2>/dev/null | \
    tee -a "$log_file" \
    || fail "Fail to run: ssl-cert-check.sh")

    # No need add into final_status array when it is good status
    if [[ "$status_report" != "good" ]]; then
        final_status+=("$status_report") # Adding into array
        current_state="bad" # status: bad
    fi
else
    info "Missing 'domains_to_check'. Skipping SSL Certificate check" | tee -a "$log_file"
fi

if [[ "$skip_system_check" != "yes" ]]; then
    # Capture message from monitoring.sh
    info "Working System Reports." | tee -a "$log_file"
    status_report=$("$current_working_dir/monitoring.sh" "$memory_threshold" "$cpu_threshold" "$disk_threshold" "$check_target_directories" "$target_dir_max_size" "$partial_system_check" "$force_send_notif" "$domains_to_check" 2>/dev/null | \
    tee -a "$log_file" \
    || fail "Fail to run: monitoring.sh")

    # No need add into final_status array when it is good status
    if [[ "$status_report" != "good" ]]; then
        final_status+=("$status_report") # Adding into array
        current_state="bad" # status: bad
    fi
else
    info "Conditions are not met. Skipping system status reports" | tee -a "$log_file"
fi

# VirusTotal Scan
if [[ -n "$virustotal_api_key" && -n "$urls_to_scan" && "$skip_virustotal_scan" != "yes" ]]; then
    sleep 1
     # Virus total scan script
    info "Malware scanning: via VirusTotal API" | tee -a "$log_file"
    status_report=$("$current_working_dir/virustotal-scan.sh" "$urls_to_scan" "$force_send_notif" 2>/dev/null | \
    tee -a "$log_file" \
    || fail "Fail to run: virustotal-scan.sh")
    
    # No need add into final_status array when it is good status
    if [[ "$status_report" != "good" ]]; then
        final_status+=("$status_report") # Adding into array
        current_state="bad" # status: bad
    fi
else
    info "Conditions are not met. Skipping malware scan reports" | tee -a "$log_file"
fi

# Join array elements into a single string with line breaks
final_text_output=$(printf "%s\n" "${final_status[@]}")

# DEBUG
# echo "Force Send Notif: $force_send_notif"
# echo "Status Report: $status_report"
# echo "Current State: $current_state"
# final_text_output=$(printf "%s\n" "${final_status[@]}")
# echo "Final Text Output: $final_text_output"
# exit 1

# Via Slack
if [[ -n "$slack_webhook_url" && ( "$current_state" != "good" || "$force_send_notif" == "yes" ) ]]; then
    sleep 1
    info "Sending reports via Slack.." | tee -a "$log_file"
    # Slack Webhook
    "$current_working_dir/slack.sh" "$slack_webhook_url" "$final_text_output" 2>&1 \
    | tee -a "$log_file" \
    || fail "Fail to run: slack.sh" | tee -a "$log_file"
else
    info "Conditions are not met.. Skipping notif via Slack" | tee -a "$log_file"
fi

# Via Email
if [[ -n "$smtp_server" && ( "$current_state" != "good" || "$force_send_notif" == "yes" ) ]]; then
    sleep 1
    info "Sending reports via email.." | tee -a "$log_file"
    # OPENSSL SMTP
    "$current_working_dir/smtp-openssl.sh" "$final_text_output" 2>&1 | tee -a "$log_file" \
    || fail "Fail to run: smtp-openssl.sh" | tee -a "$log_file"
else
    info "Conditions are not met. Skipping notif via email" | tee -a "$log_file"
fi

# Check the exit status of the run script
if [ $? -eq 0 ]; then
    success "Executed successfully. \n"
    info "Check the log file:\n $log_file \n"
else
    failsoexit "Fail to execute. \nCheck the log file for details:\n $log_file \n"
fi
exit 0