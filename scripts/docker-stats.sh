#!/bin/bash

# Script to report Docker Compose resource usage with totals
# Usage: ./docker-stats.sh [-json]

set -eo pipefail

# Default values
FORMAT="pretty"
COMPOSE_PROJECT="k6-support"
DATE_CMD=$(which date)
JQ_CMD=$(which jq 2>/dev/null || echo "")
BC_CMD=$(which bc 2>/dev/null || echo "")

# Function to check dependencies
check_dependencies() {
    if ! command -v docker &> /dev/null; then
        echo "Error: docker is not installed or not in PATH" >&2
        exit 1
    fi

    if [ "$FORMAT" = "json" ] && [ -z "$JQ_CMD" ]; then
        echo "Error: jq is required for JSON output but not installed" >&2
        exit 1
    fi

    if [ -z "$BC_CMD" ]; then
        echo "Error: bc is required for calculations but not installed" >&2
        exit 1
    fi
}

# Function to extract numeric value and convert to MB if needed
convert_to_mb() {
    local value="$1"
    local number=$(echo "$value" | grep -o -E '[0-9.]+' || echo "0")
    local unit=$(echo "$value" | grep -o -E '[A-Za-z]+' || echo "")
    
    case "$unit" in
        "GB"|"GiB") echo "$number * 1024" | bc ;;
        "KB"|"KiB") echo "$number / 1024" | bc ;;
        "B") echo "$number / 1024 / 1024" | bc ;;
        "MB"|"MiB"|"") echo "$number" ;;
        *) echo "0" ;;
    esac
}

# Function to get container stats
get_container_stats() {
    local container_name="$1"
    local stats=$(docker stats --no-stream "$container_name" 2>/dev/null || echo "")
    local values=$(echo "$stats" | tail -n 1)
    
    # Extract values using awk
    echo "$values" | awk -v container="$container_name" '
    {
        # Extract CPU percentage (remove %)
        cpu = $3
        gsub(/%/, "", cpu)
        
        # Extract memory values
        mem_usage = $4
        mem_limit = $6
        mem_perc = $7
        gsub(/%/, "", mem_perc)
        
        # Extract network I/O
        net_in = $8
        net_out = $9
        
        # Extract block I/O
        block_in = $10
        block_out = $11
        
        # Extract PIDs
        pids = $NF  # Last field should be PIDs
        
        printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
            container,
            cpu,
            mem_usage,
            mem_limit,
            mem_perc,
            net_in,
            net_out,
            block_in,
            block_out,
            pids
    }'
}

# Function to get volume info
get_volume_info() {
    local volume_name="$1"
    local mountpoint=$(docker volume inspect "$volume_name" -f '{{.Mountpoint}}')
    local size=$(du -sh "$mountpoint" 2>/dev/null | cut -f1 || echo "N/A")
    local size_bytes=$(du -s "$mountpoint" 2>/dev/null | cut -f1 || echo "0")
    echo "$volume_name,$size,$size_bytes"
}

# Function to format number with specified decimals
format_number() {
    local number="${1:-0}"
    local decimals="${2:-2}"
    if [[ $number =~ ^[0-9.]+$ ]]; then
        printf "%.${decimals}f" "$number"
    else
        echo "0.00"
    fi
}

# Function to print pretty output
print_pretty_output() {
    local timestamp=$(${DATE_CMD} '+%Y-%m-%d %H:%M:%S %Z')
    echo "========================================"
    echo "Docker Compose Resource Usage Report"
    echo "Project: $COMPOSE_PROJECT"
    echo "Timestamp: $timestamp"
    echo "========================================"
    echo
    
    echo "Container Resources:"
    echo "----------------------------------------"
    printf "%-30s %-8s %-20s %-8s %-20s %-20s %-6s\n" \
        "NAME" "CPU%" "MEMORY" "MEM%" "NETWORK I/O" "BLOCK I/O" "PIDS"
    
    # Initialize totals
    local total_cpu=0
    local total_mem_usage=0
    local total_mem_perc=0
    local total_net_in=0
    local total_block_in=0
    local total_pids=0
    local first_mem_limit=""
    
    while read -r container; do
        local container_name=$(docker inspect -f '{{.Name}}' "$container" | sed 's/\///')
        
        # Get stats and parse them
        local stats_line=$(get_container_stats "$container_name")
        if [ -n "$stats_line" ]; then
            IFS=',' read -r name cpu mem_usage mem_limit mem_perc net_in net_out block_in block_out pids <<< "$stats_line"
            
            # Store first memory limit as reference
            if [ -z "$first_mem_limit" ]; then
                first_mem_limit="$mem_limit"
            fi
            
            # Print container stats
            printf "%-30s %-8s %-20s %-8s %-20s %-20s %-6s\n" \
                "$name" \
                "${cpu}%" \
                "$mem_usage / $mem_limit" \
                "${mem_perc}%" \
                "$net_in / $net_out" \
                "$block_in / $block_out" \
                "${pids:-0}"
            
            # Add to totals (with error checking)
            total_cpu=$(echo "$total_cpu + ${cpu:-0}" | bc)
            total_mem_perc=$(echo "$total_mem_perc + ${mem_perc:-0}" | bc)
            
            # Add memory usage (convert to MiB first)
            local mem_usage_mib=$(echo "$mem_usage" | grep -o -E '[0-9.]+' || echo "0")
            total_mem_usage=$(echo "$total_mem_usage + $mem_usage_mib" | bc)
            
            # Convert and add network values
            net_in_mb=$(convert_to_mb "${net_in:-0}")
            total_net_in=$(echo "$total_net_in + $net_in_mb" | bc)
            
            # Convert and add block I/O values
            block_in_mb=$(convert_to_mb "${block_in:-0}")
            total_block_in=$(echo "$total_block_in + $block_in_mb" | bc)
            
            # Add PIDs
            total_pids=$(( total_pids + ${pids:-0} ))
        fi
    done < <(docker compose ps -q)
    
    echo "----------------------------------------"
    printf "%-30s %-8s %-20s %-8s %-20s %-20s %-6s\n" \
        "TOTAL" \
        "$(format_number $total_cpu)%" \
        "${total_mem_usage}MiB / ${first_mem_limit:-N/A}" \
        "$(format_number $total_mem_perc)%" \
        "$(format_number $total_net_in)MB / -" \
        "$(format_number $total_block_in)MB / -" \
        "$total_pids"
    
    echo
    echo "Volume Usage:"
    echo "----------------------------------------"
    printf "%-40s %-10s\n" "VOLUME" "SIZE"
    
    local total_volume_bytes=0
    while read -r volume; do
        IFS=',' read -r vol_name vol_size vol_bytes < <(get_volume_info "$volume")
        printf "%-40s %-10s\n" "$vol_name" "$vol_size"
        total_volume_bytes=$(( total_volume_bytes + ${vol_bytes:-0} ))
    done < <(docker volume ls -q -f "name=${COMPOSE_PROJECT}")
    
    echo "----------------------------------------"
    # Convert bytes to megabytes and gigabytes for total volume size
    local total_volume_mb=$(( total_volume_bytes / 1024 ))  # Convert to MB
    
    if [ $total_volume_mb -ge 1024 ]; then
        # If size is >= 1024MB, show in GB
        printf "%-40s %-10s\n" "TOTAL" "$(format_number "$(echo "scale=1; $total_volume_mb/1024" | bc)")G"
    else
        # Show in MB
        printf "%-40s %-10s\n" "TOTAL" "${total_volume_mb}M"
    fi
}

# Function to format JSON output
print_json_output() {
    local timestamp=$(${DATE_CMD} '+%Y-%m-%d %H:%M:%S %Z')
    local json_data="{"
    
    # Add metadata
    json_data+="\"metadata\":{"
    json_data+="\"project\":\"$COMPOSE_PROJECT\","
    json_data+="\"timestamp\":\"$timestamp\"},"
    
    # Initialize totals
    local total_cpu=0
    local total_mem_usage=0
    local total_mem_perc=0
    local total_net_in=0
    local total_block_in=0
    local total_pids=0
    local first_mem_limit=""
    local total_volume_bytes=0
    
    # Add container stats
    json_data+="\"containers\":["
    local first_container=true
    
    while read -r container; do
        [ "$first_container" = "true" ] || json_data+=","
        first_container=false
        
        local container_name=$(docker inspect -f '{{.Name}}' "$container" | sed 's/\///')
        local stats_line=$(get_container_stats "$container_name")
        
        if [ -n "$stats_line" ]; then
            IFS=',' read -r name cpu mem_usage mem_limit mem_perc net_in net_out block_in block_out pids <<< "$stats_line"
            
            # Store first memory limit
            [ -z "$first_mem_limit" ] && first_mem_limit="$mem_limit"
            
            # Update totals
            total_cpu=$(echo "$total_cpu + ${cpu:-0}" | bc)
            total_mem_perc=$(echo "$total_mem_perc + ${mem_perc:-0}" | bc)
            net_in_mb=$(convert_to_mb "${net_in:-0}")
            total_net_in=$(echo "$total_net_in + $net_in_mb" | bc)
            block_in_mb=$(convert_to_mb "${block_in:-0}")
            total_block_in=$(echo "$total_block_in + $block_in_mb" | bc)
            total_pids=$(( total_pids + ${pids:-0} ))
            
            json_data+="{"
            json_data+="\"name\":\"$name\","
            json_data+="\"cpu_percent\":\"${cpu:-0}%\","
            json_data+="\"memory\":\"$mem_usage / $mem_limit\","
            json_data+="\"memory_percent\":\"${mem_perc:-0}%\","
            json_data+="\"network_io\":\"$net_in / $net_out\","
            json_data+="\"block_io\":\"$block_in / $block_out\","
            json_data+="\"pids\":${pids:-0}"
            json_data+="}"
        fi
    done < <(docker compose ps -q)
    
    # Add totals
    json_data+=",{"
    json_data+="\"name\":\"TOTAL\","
    json_data+="\"cpu_percent\":\"$(format_number $total_cpu)%\","
    json_data+="\"memory\":\"- / ${first_mem_limit:-N/A}\","
    json_data+="\"memory_percent\":\"$(format_number $total_mem_perc)%\","
    json_data+="\"network_io\":\"$(format_number $total_net_in)MB / -\","
    json_data+="\"block_io\":\"$(format_number $total_block_in)MB / -\","
    json_data+="\"pids\":$total_pids"
    json_data+="}],"
    
    # Add volume info
    json_data+="\"volumes\":["
    local first_volume=true
    
    while read -r volume; do
        [ "$first_volume" = "true" ] || json_data+=","
        first_volume=false
        
        IFS=',' read -r vol_name vol_size vol_bytes < <(get_volume_info "$volume")
        total_volume_bytes=$(( total_volume_bytes + ${vol_bytes:-0} ))
        
        json_data+="{"
        json_data+="\"name\":\"$vol_name\","
        json_data+="\"size\":\"$vol_size\""
        json_data+="}"
    done < <(docker volume ls -q -f "name=${COMPOSE_PROJECT}")
    
    # Add volume total
    local total_volume_mb=$(( total_volume_bytes / 1024 ))  # Convert to MB
    local total_size
    
    if [ $total_volume_mb -ge 1024 ]; then
        # If size is >= 1024MB, show in GB
        total_size="$(format_number "$(echo "scale=1; $total_volume_mb/1024" | bc)")G"
    else
        # Show in MB
        total_size="${total_volume_mb}M"
    fi
    
    json_data+=",{"
    json_data+="\"name\":\"TOTAL\","
    json_data+="\"size\":\"$total_size\""
    json_data+="}]}"
    
    if [ -n "$JQ_CMD" ]; then
        echo "$json_data" | $JQ_CMD '.'
    else
        echo "$json_data"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -json|--json)
            FORMAT="json"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [-json]" >&2
            exit 1
            ;;
    esac
done

# Main execution
check_dependencies

if [ "$FORMAT" = "json" ]; then
    print_json_output
else
    print_pretty_output
fi