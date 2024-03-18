#!/bin/bash

##############################################
# Slack Webhook Script
# Author: esstat17
# Description: This script sends callback to slack
# Usage: ./slack.sh <slack_webhook_url> <status>
##############################################

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
    info "Usage: $0 <slack_webhook_url> <status>"
    exit 1
fi

# Define the Slack webhook URL
slack_webhook_url=${1:-""}
status=${2:-""}
request_timeout=${REQUEST_TIMEOUT:-10}

# Main script execution
main() {
    # Send data to Slack
    # curl -v -sS -H "Content-type: application/json" \
    # --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"$status\"}}]}" \
    # -X POST "$slack_webhook_url" || warn "Fail to send notif via slack webhook"

    response=$(curl -sS -o /dev/null -w "%{http_code}" -H "Content-type: application/json" \
        --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"$status\"}}]}" \
        -X POST --max-time "$request_timeout" "$slack_webhook_url")

    if [ "$response" -ge 200 ] && [ "$response" -lt 300 ]; then
        info "Notification sent (HTTP Status: $response)"
    else
        failsoexit "Fail to send notification (HTTP Status: $response)"
    fi
}

# Execute the main script
main "$@"

