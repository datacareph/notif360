#!/bin/bash

##############################################
# System Monitoring Script
# Author: esstat17
# Description: This script monitors system memory, CPU, disk usage, and target directories.
# Usage: ./monitoring_script.sh <memory_threshold> <cpu_threshold> <disk_threshold> <check_target_directories> \
#   <target_dir_max_size> <partial_system_check> <force_send_notif> <domains_to_check>
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
if [ "$#" -ne 8 ]; then
    info "Usage: $0 <memory_threshold> <cpu_threshold> <disk_threshold> <check_target_directories> \
    <target_dir_max_size> <partial_system_check> <force_send_notif> <domains_to_check>"
    exit 1
fi

# Define thresholds for memory and CPU usage
memory_threshold="$1"  # Example memory threshold: 85%
cpu_threshold="$2"     # Example cpu threshold: 70%
disk_threshold="$3"     # Example disk threshold: 90%
# check_target_directories=${SCAN_DIRECTORIES:-"/home/ /opt/"} # Separated by spaces e.g. "/home/ /opt/"
check_target_directories="$4"
target_dir_max_size="$5"
partial_system_check="$6"
force_send_notif="$7"
domains_to_check="$8"
check_target_directories=($check_target_directories) # Convert string to array

# Get system hostname
hostname=$(hostname)
timestamp="$(date +%s)"

# Only get the first index from the array of URLs; thus website
domains_to_check=($domains_to_check) # Convert string to array
first_domain=${domains_to_check[0]:-}

# Default values when information cannot be retrieved
mem_usage=-1
cpu_usage=-1
disk_usage=-1
available_mem=-1

# Main script execution
main() {
    if [[ "$partial_system_check" != "yes" ]]; then

        # Gather memory information
        # mem_info=$(free -m 2>/dev/null | grep Mem) || mem_info="-1"
        # total_mem=$(echo "$mem_info" 2>/dev/null | awk '{print $2}') || total_mem="-1"
        # used_mem=$(echo "$mem_info" 2>/dev/null | awk '{print $3}') || used_mem="-1"
        # available_mem=$(echo "$mem_info" 2>/dev/null | awk '{print $7}') || available_mem="-1"
        # mem_usage=$(( total_mem == -1 ? 0 : used_mem * 100 / total_mem )) 2>/dev/null || mem_usage="-1"
        # echo "mem: $total_mem"

        # Gather memory information
        mem_info=$(free -m 2>/dev/null | grep Mem) || mem_info="-1"

        if [ "$mem_info" != "-1" ]; then
            total_mem=$(echo "$mem_info" | awk '{print $2}')
            used_mem=$(echo "$mem_info" | awk '{print $3}')
            available_mem=$(echo "$mem_info" | awk '{print $7}')

            # Avoid division by zero errors
            if [ "$total_mem" -ne 0 ]; then
                mem_usage=$((used_mem * 100 / total_mem))
            fi
        else
            # Reset default; # Default values when information cannot be retrieved
            mem_usage=-1
            total_mem=-1
            used_mem=-1
            available_mem=-1
        fi

        # Gather CPU information only if /proc/ exists
        if [ -d "/proc/" ]; then
            # Get the number of CPU cores
            cpu_cores=$(grep -c '^processor' /proc/cpuinfo)

            # Get CPU usage statistics
            cpu_stats=$(grep '^cpu ' /proc/stat)

            # Calculate the total CPU time
            total_cpu_time=$(( $(echo "$cpu_stats" | awk '{total = $2 + $3 + $4 + $5 + $6 + $7 + $8} END {print total}') ))

            # Calculate the idle CPU time
            idle_cpu_time=$(( $(echo "$cpu_stats" | awk '{idle = $5} END {print idle}') ))

            # Calculate the non-idle CPU time
            non_idle_cpu_time=$((total_cpu_time - idle_cpu_time))

            # Calculate the CPU usage percentage as the average of all cores
            cpu_usage=$(( non_idle_cpu_time * 100 / total_cpu_time / cpu_cores ))
        else
            # Set default
            cpu_usage=-1
            cpu_cores=-1
        fi

        # Check if uptime command is present
        if command -v uptime > /dev/null; then
            # Get system load average
            load_avg=$(uptime)
        else
            load_avg="-1"  # Set to -1 if uptime command is not present
        fi

        # Check if df command is present
        if command -v df > /dev/null; then
            # Disk Information
            # Get disk header
            disk_head=$(df -h | grep -E 'Filesystem')

            # Get disk usage information for devices under /dev/ excluding /boot and /boot/efi
            disk_content=$(df -h | grep '^/dev/' | grep -v -e '/boot*')

            # Get disk usage percentage for the root filesystem "/"
            disk_usage=$(df -h | awk '$NF=="/"{print $5}' | sed 's/%//')
        else
            disk_content="-1"
            disk_usage="-1"  # Set to -1 if df command is not present
        fi

    fi # end partial_system_check no

    # Allowed Target Disk 
    total_mb_size=0
    dir_check_combined=()
    if [[ -n "$check_target_directories" ]]; then
        dir_check_combined+=("*_ALLOCATED DISK CHECK:_*")
        total_kb_size=0
        for dir in "${check_target_directories[@]}"; do
            dir_kb_size=$(du -s "$dir" 2>/dev/null | cut -f1) || dir_kb_size=0
            if [[ "$dir_kb_size" != 0 ]]; then
                total_kb_size=$((dir_kb_size + total_kb_size))
            fi
            dir_check_combined+=("*Disk:* $(du -sh "$dir" 2>/dev/null || echo -1)")
        done

        target_dir_usage=0
        # Convert total KiB to MiB
        if [[ $total_kb_size -ge 0 ]]; then
            total_mb_size=$((total_kb_size / 1024))
            target_dir_usage=$(( (total_mb_size * 100) / target_dir_max_size ))
            dir_check_combined+=("*Mount Disk Usage:* $target_dir_usage%")
            dir_check_combined+=("*Total Used Size:* $total_mb_size MiB")
            dir_check_combined+=("*Allocated Disk Size:* $target_dir_max_size MiB")
        fi

        if [[ "$total_mb_size" -gt "$target_dir_max_size" ]]; then
            dir_check_combined+=("*Summary:* Alert! Mount disk is *full*.")
        elif [[ $target_dir_usage -gt $disk_threshold ]]; then
            dir_check_combined+=("*Summary:* Warning! Mount disk is almost *full*.")
        else
            dir_check_combined+=("*Summary:* Mount disk is *good.*")
        fi
        # DEBUG
        # echo "*Disk Usage:* $target_dir_usage%"
        # echo "*Total Used Size:* $total_mb_size MiB"
        # echo "*Max Target Dir Size:* $target_dir_max_size MiB"
    fi
    dir_check_text=$(printf "%s\n" "${dir_check_combined[@]}")

    final_output=("") # Initialize the array
    status_report="good"
    is_critical=""

    # Only echo monitoring information if memory usage or CPU usage exceeds thresholds
    if [[ "$mem_usage" -gt "$memory_threshold" \
        || "$cpu_usage" -gt "$cpu_threshold" \
        || "$disk_usage" -gt "$disk_threshold" \
        || "$target_dir_usage" -gt "$disk_threshold" \
        || "$force_send_notif" == "yes" ]]; then
        # Format data
        final_output+=("*SERVER STATUS REPORT:* ID-$timestamp")
        final_output+=("*_NETWORK:_*")
        [[ -n "$first_domain" ]] && final_output+=("*Website:* $first_domain")
        final_output+=("*Hostname:* $hostname")
        final_output+=("")
        if [[ "$partial_system_check" != "yes" ]]; then
            final_output+=("*_MEMORY:_*")
            final_output+=("*Total Memory:* $total_mem MiB")
            final_output+=("*Used Memory:* $used_mem MiB")
            final_output+=("*Available Memory:* $available_mem MiB")
            final_output+=("*Memory Usage:* $mem_usage%")
            final_output+=("")
            final_output+=("*_CPU AND SYSTEM:_*")
            final_output+=("*CPU Core:* $cpu_cores")
            final_output+=("*Average CPU Usage:* $cpu_usage%")
            final_output+=("*System Load Average:* $load_avg")
            final_output+=("")
        fi

        final_output+=("$dir_check_text")
        final_output+=("")

        if [[ "$partial_system_check" != "yes" ]]; then
            final_output+=("*_DISK SYSTEM:_*")
            final_output+=("*Disk Usage:* $disk_usage%")
            final_output+=("$disk_head")
            final_output+=("$disk_content")
            final_output+=("")
        fi
        # meets the critical status
        is_critical="yes"
    fi

    final_output_plain=$(printf "%s\n" "${final_output[@]}")

    if [[ "$is_critical" == "yes" || "$force_send_notif" == "yes" ]]; then
        status_report="$final_output_plain"
    else
        status_report="$status_report"
    fi

    # Display monitoring information
    echo "$status_report"
}

# Execute the main script
main "$@"