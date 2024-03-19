#!/bin/bash

##############################################
# SMTP Email Script
# Author: esstat17
# Description: This script sends stmp email via OpenSSL
# Usage: ./slack.sh <slack_webhook_url> <status>
##############################################

set -o pipefail

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
if [ "$#" -ne 1 ]; then
    info "Usage: $0 <status>"
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

            # DEBUG
            # echo "KEY: $key"
            # echo "VALUE: xxX${value}Xxx"

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

# Env Vars
# SMTP Credentials
smtp_server=${SMTP_SERVER:-"smtp.localhost"}
smtp_username=${SMTP_USERNAME:-"smtp-user"}
smtp_password=${SMTP_PASSWORD:-"MustBeSecurePassword"}
smtp_port=${4:-$SMTP_PORT}
openssl_options=${OPENSSL_OPTIONS:-"-ign_eof -quiet"} # -debug
use_ssl="${USE_SSL:-false}"  # Set to "true" to use SSL/TLS, otherwise STARTTLS
request_timeout=${REQUEST_TIMEOUT:-30}
max_tries=${MAX_TRIES:-3}
max_tries_interval=${MAX_TRIES_INTERVAL:-10}
send_commands_delay=${SEND_COMMANDS_DELAY:-3}

# Sender and Receiver
sender_name=${SENDER_NAME:-"Sender Name"}
sender_email=${SENDER_EMAIL:-""}
receiver_name=${RECEIVER_NAME:-"Mx Tool"}
receiver_email=${RECEIVER_EMAIL:-"ping@tools.mxtoolbox.com"} # Check https://mxtoolbox.com/deliverability
carbon_copy=${CARBON_COPY:-""}
carbon_copies=($carbon_copy) # Convert string to array
carbon_copy_full=${CARBON_COPY_FULL:-""}
email_subject=${EMAIL_SUBJECT:-"Subject: Test Email - Do Not Reply"}
email_subject="$email_subject ID: $(date +%s)"
email_body=${EMAIL_BODY:-""}
unsubscribe_url=${UNSUBSCRIBE_URL:-""}
company_address=${COMPANY_ADDRESS:-"Iloilo, 5000, Philippines"}
preheader_text=${PREHEADER_TEXT:-"This is preheader text. Some clients will show this text as a preview."}

# Define the Slack webhook URL
status=${1:-"Null"}

sender_or_smtp_email=${sender_email:-"$smtp_username"}

# Sender details
sender="$sender_name <$sender_or_smtp_email>"

# Recipient details
recipient="$receiver_name <$receiver_email>"

# Path to your template file
template_file="./email-template/notification.html"

# Check if the template file exists
if [ ! -f "$template_file" ]; then
    failsoexit "Template file $template_file not found."
fi

# Read the template content
template_content=$(<"$template_file")

# Function to URL encode a string using sed
urlencode() {
  local string="$1"
  echo "$string" | sed -e 's/ /%20/g' -e 's/&/%26/g' -e 's/?/%3F/g' -e 's/=/\%3D/g'
}

# URL encode the unsubscribe URL
unsubscribe_url_encoded=$(urlencode "$unsubscribe_url")

# Use a heredoc for $status
status_content=$(cat <<-EOF
$status
EOF
)

# Replace newlines and other special characters with placeholders
# status_placeholder=$(echo "$status_content" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' -e 's/\//\\\//g')

# processed_content=$(sed -e "s/\$RECEIVER_NAME/$receiver_name/g" \
#   -e "s/\$RECEIVER_EMAIL/$receiver_email/g" \
#   -e "s#\$UNSUBSCRIBE_URL#$unsubscribe_url_encoded#g" "$template_file")

# Create a temporary file with the status content
status_file="/tmp/status_file.$$.$start"
# Generate Date headers
date_header=$(date -R)

echo -n "$status_content" > "$status_file"

# Perform substitutions using awk
processed_content=$(awk -v receiver_name="$receiver_name" \
    -v receiver_email="$receiver_email" \
    -v company_address="$company_address" \
    -v unsubscribe_url_encoded="$unsubscribe_url_encoded" \
    -v preheader_text="$preheader_text. Sent at $date_header" \
    -v status_file="$status_file" '
function convertMarkdownToHtml(line) {
    # Call the AWK function to convert Markdown to HTML
    gsub(/\*([^*]+)\*/, "<strong>xX&Xx</strong>", line);
    gsub(/_([^_]+)_/, "<em>xX&Xx</em>", line);
    gsub(/xX\*/, "", line); # Remove Trailing xX*
    gsub(/\*Xx/, "", line); # Remove Leading *xXx
    gsub(/xX_/, "", line);
    gsub(/_Xx/, "", line);
    print line "<br>";
}

{
    gsub(/\$RECEIVER_NAME/, receiver_name);
    gsub(/\$RECEIVER_EMAIL/, receiver_email);
    gsub(/\$COMPANY_ADDRESS/, company_address);
    gsub(/\$UNSUBSCRIBE_URL/, unsubscribe_url_encoded);
    gsub(/\$PREHEADER_TEXT/, preheader_text);

    if (/\$STATUS/) {
        while ((getline line < status_file) > 0) {
            # print line "<br>";
            convertMarkdownToHtml(line);
        }
        close(status_file);
    } else {
        print $0;
    }
}
' "$template_file")

# DEBUG
# Print the processed content
# echo "$processed_content"
# exit 0

# Remove the temporary file
rm "$status_file"

html_body="${email_body:-$processed_content}"

# Message-Id headers
message_id=$(openssl rand -hex 16)@datacareph.com || warn "Generate message_id"

message=$(cat <<-EOF
From: $sender
To: $recipient
CC: $carbon_copy_full
Subject: $email_subject
Content-Type: text/html; charset=UTF-8
Date: $date_header
Message-ID: <$message_id>
List-Unsubscribe: <$unsubscribe_url>

$html_body
EOF
)

# Send email commands
send_commands() {
  # Establish connection to SMTP server and send email
  {
    echo -e "EHLO $smtp_server"
    sleep $send_commands_delay  # Add a delay after the EHLO command

    echo -e "AUTH LOGIN"
    echo -e "$(echo -ne "$smtp_username" | base64)"
    echo -e "$(echo -ne "$smtp_password" | base64)"
    
    echo -e "MAIL FROM: <$sender_or_smtp_email>"
    echo -e "RCPT TO: <$receiver_email>"

    # Add CC recipients
    if [[ -n "$carbon_copy" ]]; then
        for cc in "${carbon_copies[@]}"; do
            echo -e "RCPT TO: <$cc>"
            sleep 1
        done
    fi
    
    echo -e "DATA"
    sleep $send_commands_delay  # Add a delay after the DATA command
    echo -e "$message"
    echo -e "."
    echo -e "QUIT"
  }
}

# Main script execution
main() {
    openssl_starts=$(date +%s)

    for ((try=1; try<=max_tries; try++)); do
        if [ "$use_ssl" == "true" ]; then
            send_commands |  openssl s_client -crlf -connect $smtp_server:$smtp_port $openssl_options && \
            break
        else
            send_commands | openssl s_client -starttls smtp -crlf -connect "$smtp_server:$smtp_port" $openssl_options && \
            break
        fi

        if [ $try -lt $max_tries ]; then
            warn "Attempt $try failed. Retrying..."
            sleep $max_tries_interval  # Add a delay between retries, adjust as needed
        else
            warn "All attempts failed. Exiting."
            break
        fi
    done

    openssl_ends=$(date +%s)
    elapsed_time=$((openssl_ends - openssl_starts))
    info "It took $elapsed_time seconds to process the email."

    if [ $elapsed_time -gt $request_timeout ] && pgrep -f "openssl" > /dev/null; then
        info "Force kill openssl for safety"
        # Terminate the OpenSSL process
        pkill -f "openssl"
        failsoexit "Timeout reached. Exiting.."
    fi

    # end=$(date +%s)
    # diff=$(( $end - $start ))
    # # info "Filename: $0"
    # info "SMTP OpenSSL Script:"
    # success "The operation completed in $diff seconds."
}

# Execute the main script
main "$@"