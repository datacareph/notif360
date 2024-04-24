#!/bin/bash

##############################################
# SSL Expiry Check
# Author: esstat17
# Website: datacareph.com
# Description: Curl command to check the SSL Expiry
# Usage: ./ssl-expiry-check.sh <domains_to_check> <force_send_notif>
##############################################

start="$(date +%s)" # Kick-off

ask() { echo -e "$(date '+%Y/%m/%d %H:%M:%S') - ASK: $1"; }
info() { echo -e "$(date '+%Y/%m/%d %H:%M:%S') - INFO: $1"; }
success() { echo -e "$(date '+%Y/%m/%d %H:%M:%S') - SUCCESS: $1"; }
warn() { echo -e "$(date '+%Y/%m/%d %H:%M:%S') - WARNING: $1"; }
fail() { echo -e "$(date '+%Y/%m/%d %H:%M:%S') - ERROR: $1"; }
failsoexit() {
    echo -e "$(date '+%Y/%m/%d %H:%M:%S') - ERROR: $1"
    exit 1
}

# Validate input parameters
if [ "$#" -ne 2 ]; then
    info "Usage: $0 <urls_to_scan> <force_send_notif>"
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

# Env Variables
debug=${DEBUG:-"false"}
domains_to_check=${1:-"$DOMAINS_TO_CHECK"} # "google.com yahoo.com"
force_send_notif=${2:-"$FORCE_SEND_NOTIFICATION"} # prioritize param
request_timeout=${REQUEST_TIMEOUT:-10}
domains_to_check=($domains_to_check) # Convert string to array
timestamp="$(date +%s)"
ssl_alert_before=${SSL_ALERT_BEFORE:-1728000} # 20 days (20 days * 24 hours * 60 minutes * 60 seconds = 1296000 seconds).

# Main script execution
main() {
    # Initialize an empty array
    local expiry_date
    local expiry_timestamp
    local current_timestamp
    local os=$(uname)

    local final_output=("") # init
    local final_output+=("*SSL CERTIFICATE STATUS:* ID-$timestamp")
    final_output+=("*_SSL CHECK:_*")

    local status_report="good"
    local has_alert="no"

    # Loop through each URL in the array
    for domain in "${domains_to_check[@]}"; do
      # Add the results to the final output array

        # Initialize openssl_starts
        openssl_starts=$(date +%s)

        # Retrieve certificate expiry date
        not_after=$(openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -enddate)
        absolute_expiry=$(echo "$not_after" | cut -d'=' -f2)
        expiry_date=$(echo "$not_after" | awk -F'=' '{print $2}' | awk -F' ' '{print $1, $2, $3, $4}')
        final_output+=("*DOMAIN NAME*: $domain")

        # Convert expiry date to timestamp based on OS
        if [ "$os" == "Darwin" ]; then
            expiry_timestamp=$(date -u -jf "%b %d %T %Y" "$expiry_date" +"%s" 2>/dev/null)
        else
            expiry_timestamp=$(date -d "$expiry_date" +"%s" 2>/dev/null)
        fi

        # Get current timestamp
        current_timestamp=$(date +"%s")
        
        # Check if expiry date is obtained
        if [ -z "$expiry_timestamp" ]; then
            final_output+="Summary: Unable to retrieve expiry date."
            final_output+=("*Expiry Date*: $absolute_expiry")
            continue
        fi

        # Check if the certificate is still valid
        if [[ "$expiry_timestamp" -ge "$current_timestamp" ]]; then
            final_output+=("*Summary*: SSL certificate is still valid.")
            final_output+=("*Expiry Date*: $absolute_expiry")
        elif [[ "$((expiry_timestamp - current_timestamp))" -le "$ssl_alert_before" ]]; then
            has_alert="yes"
            final_output+=("*Summary*: Alert! SSL certificate will expire in less than 20 days.")
            final_output+=("*Expiry Date*: $absolute_expiry")
        else
            has_alert="yes"
            final_output+=("*Summary*: Alert! SSL certificate has expired.")
            final_output+=("*Expiry Date*: $absolute_expiry")
        fi

        final_output+=("")

        openssl_ends=$(date +%s)
        elapsed_time=$((openssl_ends - openssl_starts))
        if [ $elapsed_time -gt $request_timeout ] && pgrep -f "openssl" > /dev/null; then
            # Terminate the OpenSSL process
            pkill -f "openssl"
            # continue
        fi
        sleep 1
    done

    # Join array elements into a single string with line breaks
    final_output_plain=$(printf "%s\n" "${final_output[@]}")

    if [[ "$has_alert" == "yes" || "$force_send_notif" == "yes" ]]; then
        status_report="$final_output_plain"
    else
        status_report="$status_report"
    fi

    # Display monitoring information
    echo "$status_report"
}

# Execute the main script
main "$@"