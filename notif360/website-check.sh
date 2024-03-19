#!/bin/bash

##############################################
# Website Status Check
# Author: esstat17
# Website: datacareph.com
# Description: Curl command to check the website
# Usage: ./website-check.sh <urls_to_scan> <force_send_notif>
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
urls_to_scan=${1:-"$URLS_TO_SCAN"} # "https://google.com https://yahoo.com"
force_send_notif=${2:-"$FORCE_SEND_NOTIFICATION"} # prioritize param
request_timeout=${REQUEST_TIMEOUT:-10}
urls_to_scan=($urls_to_scan) # Convert string to array
timestamp="$(date +%s)"

# Main script execution
main() {
    # Array of user-agent strings
    local user_agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Firefox/97.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/98.0.1108.62 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:97.0) Gecko/20100101 Firefox/97.0"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Edge/98.0.1108.62 Safari/537.36"
        "Mozilla/5.0 (iPhone; CPU iPhone OS 15_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/604.1"
        "Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36"
        "Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Mobile Safari/537.36 EdgA/48.4.3.123"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Firefox/96.0"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/97.0.1072.62 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:96.0) Gecko/20100101 Firefox/96.0"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Edge/97.0.1072.62 Safari/537.36"
        "Mozilla/5.0 (iPhone; CPU iPhone OS 15_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.2 Mobile/15E148 Safari/604.1"
        "Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Mobile Safari/537.36"
        "Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Mobile Safari/537.36 EdgA/46.3.3.123"
    )
    
    # Initialize an empty array
    local final_output=("") # init
    local final_output+=("*WEBSITE STATUS REPORT:* ID-$timestamp")

    # Select a random user-agent
    random_index=$(( RANDOM % ${#user_agents[@]} ))
    selected_user_agent="${user_agents[$random_index]}"

    final_output+=("*_URL CHECK:_*")

    local status_report="good"
    local is_down="no"
    # Loop through each URL in the array
    for url in "${urls_to_scan[@]}"; do
      # Add the results to the final output array

        response_code=$(curl -sL --max-time "$request_timeout" -w "%{http_code}" -A "$selected_user_agent" "$url" -o /dev/null)
        final_output+=("*URL*: $url")
        final_output+=("*HTTP Code:* $response_code")
        if [ "$response_code" -ge 200 ] && [ "$response_code" -lt 300 ]; then
            final_output+=("*Summary*: The site is *up and running smoothly*.")
        elif [ "$response_code" -ge 300 ] && [ "$response_code" -lt 400 ]; then
            final_output+=("*Summary*: Notice! The site is in *redirection status*.")
        elif [ "$response_code" -ge 400 ] && [ "$response_code" -lt 500 ]; then
            is_down="yes"
            final_output+=("*Summary*: Warning! The site has a *problem*. Please check manually to resolve the *issues*.")
        else
            is_down="yes"
            final_output+=("*Summary*: Alert! site is *down* or experiencing *server-side issues*.")
        fi
        final_output+=("")
        sleep 1
    done

    # Join array elements into a single string with line breaks
    final_output_plain=$(printf "%s\n" "${final_output[@]}")

    if [[ "$is_down" == "yes" || "$force_send_notif" == "yes" ]]; then
        status_report="$final_output_plain"
    else
        status_report="$status_report"
    fi

    # Display monitoring information
    echo "$status_report"

}

# Execute the main script
main "$@"