#!/bin/bash

# Script to report Docker Compose resource usage
# Usage: ./docker-stats.sh [-json]

set -eo pipefail

# Default values
FORMAT="pretty"
COMPOSE_PROJECT="k6-support"
DATE_CMD=$(which date)
JQ_CMD=$(which jq 2>/dev/null || echo "")

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
}

# Function to get container stats
get_container_stats() {
    local container_name="$1"
    docker stats --no-stream "$container_name" | tail -n 1 | awk '{
        printf "%s,%s,%s,%s,%s,%s,%s\n",
        $2,           # NAME
        $3,           # CPU%
        $4" "$5" "$6, # MEM USAGE/LIMIT
        $7,           # MEM%
        $8" "$9,      # NET I/O
        $10" "$11,    # BLOCK I/O
        $12           # PIDS
    }'
}

# Function to get volume info
get_volume_info() {
    local volume_name="$1"
    local mountpoint=$(docker volume inspect "$volume_name" -f '{{.Mountpoint}}')
    local size=$(du -sh "$mountpoint" 2>/dev/null | cut -f1 || echo "N/A")
    echo "$volume_name,$size"
}

# Function to format pretty output
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
    
    for container in $(docker compose ps -q); do
        local container_name=$(docker inspect -f '{{.Name}}' "$container" | sed 's/\///')
        IFS=',' read -r name cpu mem mem_perc net_io block_io pids < <(get_container_stats "$container_name")
        printf "%-30s %-8s %-20s %-8s %-20s %-20s %-6s\n" \
            "$name" "$cpu" "$mem" "$mem_perc" "$net_io" "$block_io" "$pids"
    done
    
    echo
    echo "Volume Usage:"
    echo "----------------------------------------"
    printf "%-40s %-10s\n" "VOLUME" "SIZE"
    
    for volume in $(docker volume ls -q -f "name=${COMPOSE_PROJECT}"); do
        IFS=',' read -r vol_name vol_size < <(get_volume_info "$volume")
        printf "%-40s %-10s\n" "$vol_name" "$vol_size"
    done
}

# Function to format JSON output
print_json_output() {
    local timestamp=$(${DATE_CMD} '+%Y-%m-%d %H:%M:%S %Z')
    local json_data="{"
    
    # Add metadata
    json_data+="\"metadata\":{"
    json_data+="\"project\":\"$COMPOSE_PROJECT\","
    json_data+="\"timestamp\":\"$timestamp\"},"
    
    # Add container stats
    json_data+="\"containers\":["
    local first_container=true
    
    for container in $(docker compose ps -q); do
        if [ "$first_container" = true ]; then
            first_container=false
        else
            json_data+=","
        fi
        
        local container_name=$(docker inspect -f '{{.Name}}' "$container" | sed 's/\///')
        IFS=',' read -r name cpu mem mem_perc net_io block_io pids < <(get_container_stats "$container_name")
        
        json_data+="{"
        json_data+="\"name\":\"$name\","
        json_data+="\"cpu_percent\":\"$cpu\","
        json_data+="\"memory\":\"$mem\","
        json_data+="\"memory_percent\":\"$mem_perc\","
        json_data+="\"network_io\":\"$net_io\","
        json_data+="\"block_io\":\"$block_io\","
        json_data+="\"pids\":\"$pids\""
        json_data+="}"
    done
    json_data+="],"
    
    # Add volume info
    json_data+="\"volumes\":["
    local first_volume=true
    
    for volume in $(docker volume ls -q -f "name=${COMPOSE_PROJECT}"); do
        if [ "$first_volume" = true ]; then
            first_volume=false
        else
            json_data+=","
        fi
        
        IFS=',' read -r vol_name vol_size < <(get_volume_info "$volume")
        json_data+="{"
        json_data+="\"name\":\"$vol_name\","
        json_data+="\"size\":\"$vol_size\""
        json_data+="}"
    done
    json_data+="]}"
    
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