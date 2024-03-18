#!/bin/bash

##############################################
# VirusTotal Scan
# Author: esstat17
# Website: datacareph.com
# Description: Malware scanning for website
# Usage: ./virustotal-scan.sh <urls_to_scan> <force_send_notif>
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

# Env Variables
# Virus Total
debug=${DEBUG:-"false"}
virustotal_api_key=${VIRUSTOTAL_API_KEY:-"YOUR-VIRUSTOTAL-API_KEY_OR_TOKEN"} # Get from virustotal
urls_to_scan=${1:-"$URLS_TO_SCAN"} # Separated by spaces e.g. "https://google.com https://yahoo.com"
force_send_notif=${2:-"$FORCE_SEND_NOTIFICATION"} # prioritize param
urls_to_scan=($urls_to_scan) # Convert string to array
request_timeout=${REQUEST_TIMEOUT:-10}
timestamp="$(date +%s)"
# DEBUG
# for url in "${urls_to_scan[@]}"; do
#     echo "$url"
# done
# exit 1

# Main script execution
main() {
  # Initialize an empty array
  final_output=() # init
  final_output+=("*MALWARE STATUS REPORT:* ID-$timestamp")
  final_output+=("*_VIRUSTOTAL SCAN:_*")
  status_report="good"
  is_detected="no"

  # Loop through each URL in the array
  for url in "${urls_to_scan[@]}"; do

    if [[ "$debug" != "true" ]]; then
    # Submit a URL for scanning
    request_scan=$(curl --silent --request POST \
      --url 'https://www.virustotal.com/api/v3/urls' \
      --form "url=$url" \
      --max-time "$request_timeout" \
      --header "x-apikey: $virustotal_api_key")

    # request_scan="$(cat <<-EOF
  # $request_scan
  # EOF
  # )"

  else

    # DEBUG
    request_scan="$(cat <<-EOF
{
    "data": {
        "type": "analysis",
        "id": "u-892d081f917376365d37b2885e098764a32f5a1d8d493a89bec2615c7cf0ec02-1707319175",
        "links": {
            "self": "https://www.virustotal.com/api/v3/analyses/u-892d081f917376365d37b2885e098764a32f5a1d8d493a89bec2615c7cf0ec02-1707319175"
        }
    }
}
EOF
)"

  fi

    # DEBUG
    # Request results
    # echo "$request_scan"
    # exit 1

    # The first one works as well
    # id=$(echo "$request_scan" | grep -o '"id": "[^"]*' | grep -o '[^"]*$') || id=-1
    id=$(echo "$request_scan" | sed -n 's/.*"id": "\(.*\)".*/\1/p') || id=-1

    # DEBUG
    # echo "REQUEST ID: xxX${id}Xxx"
    # exit 0

    if [[ -z "$id" ]]; then
      warn "Failed to get request ID"
      break
    fi

    sleep 1

    # Use the analysis ID to check the analysis status
    if [[ "$debug" != "true" ]]; then
      analysis_response=$(curl --silent --request GET \
        --url "https://www.virustotal.com/api/v3/analyses/$id" \
        --max-time "$request_timeout" \
        --header "x-apikey: $virustotal_api_key")
    else
      # DEBUG
      # Hard-coded analysis response
      analysis_response='{
          "data": {
              "status": "completed",
              "stats": {
                  "malicious": 0,
                  "suspicious": 0,
                  "undetected": 20,
                  "harmless": 71,
                  "timeout": 0
              }
          }
      }'
    fi

    # DEBUG
    # echo $analysis_response

    # Extract the malicious, suspicious, and undetected counts using grep
    malicious=$(echo "$analysis_response" | sed -n 's/.*"malicious": \([0-9]*\).*/\1/p') || id=-1
    suspicious=$(echo "$analysis_response" | sed -n 's/.*"suspicious": \([0-9]*\).*/\1/p') || id=-1
    undetected=$(echo "$analysis_response" | sed -n 's/.*"undetected": \([0-9]*\).*/\1/p') || id=-1

    # DEBUG
    if [[ $debug == "true" ]]; then
      echo "Malicious: $malicious"
      echo "Suspicious: $suspicious"
      echo "Undetected: $undetected"
    fi

    # Add the results to the final output array
    final_output+=("*URL*: $url")
    final_output+=("*Malicious:* $malicious")
    final_output+=("*Suspicious:* $suspicious")
    final_output+=("*Undetected:* $undetected")

    if [[ "$malicious" -gt 0 || "$suspicious" -gt 0 ]]; then
      final_output+=("*Summary:* ALERT! Malware or suspicious content *detected*.")  
      is_detected="yes"
    elif [ "$undetected" -le 0 ]; then
      final_output+=("*Summary:* No malware detected, all engines reported clean.")  
    else
      final_output+=("*Summary:* No malware detected, but further investigation may be *needed*.")  
    fi
    final_output+=("")

  done

  # Join array elements into a single string with line breaks
  final_output_plain=$(printf "%s\n" "${final_output[@]}")

  if [[ "$is_detected" == "yes" || "$force_send_notif" == "yes" ]]; then
      status_report="$final_output_plain"
  else
      status_report="$status_report"
  fi

  # Display monitoring information
  echo "$status_report"
}

# Execute the main script
main "$@"