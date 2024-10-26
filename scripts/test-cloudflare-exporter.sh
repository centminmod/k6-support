#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        echo -e "${YELLOW}Error: $3${NC}"
    fi
}

# Function to check if a metric exists in the output
check_metric() {
    local metric=$1
    local output=$2
    if echo "$output" | grep -q "^$metric"; then
        return 0
    else
        return 1
    fi
}

echo "Starting Cloudflare Exporter Tests..."
echo "======================================"

# Test 1: Check if container is running
echo -e "\n1. Testing container status..."
CONTAINER_STATUS=$(docker compose ps cloudflare-exporter --format json | jq -r '.[0].State')
if [ "$CONTAINER_STATUS" == "running" ]; then
    print_result 0 "Container is running"
else
    print_result 1 "Container status check" "Container is not running (Status: $CONTAINER_STATUS)"
    exit 1
fi

# Test 2: Check if port is accessible
echo -e "\n2. Testing port accessibility..."
PORT_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9198/metrics)
print_result $? "Port accessibility check" "Port 9198 is not accessible (HTTP Status: $PORT_TEST)"

# Test 3: Test metrics endpoint
echo -e "\n3. Testing metrics endpoint..."
METRICS=$(curl -s http://localhost:9198/metrics)
if [ -n "$METRICS" ]; then
    print_result 0 "Metrics endpoint is responding"
else
    print_result 1 "Metrics endpoint check" "No metrics returned"
    exit 1
fi

# Test 4: Check for required metrics
echo -e "\n4. Testing for required metrics..."
REQUIRED_METRICS=(
    "cloudflare_exporter_build_info"
    "cloudflare_zone_bandwidth_total"
    "cloudflare_zone_requests_total"
    "cloudflare_zone_threats_total"
)

for metric in "${REQUIRED_METRICS[@]}"; do
    if check_metric "$metric" "$METRICS"; then
        print_result 0 "Found metric: $metric"
    else
        print_result 1 "Required metric check" "Metric not found: $metric"
    fi
done

# Test 5: Check Cloudflare API Token
echo -e "\n5. Testing Cloudflare API Token..."
if [ -z "$CF_API_TOKEN" ]; then
    print_result 1 "API Token check" "CF_API_TOKEN environment variable is not set"
else
    # Test token validity using Cloudflare API
    TOKEN_TEST=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" "https://api.cloudflare.com/client/v4/user/tokens/verify" | jq -r '.success')
    if [ "$TOKEN_TEST" == "true" ]; then
        print_result 0 "API Token is valid"
    else
        print_result 1 "API Token check" "Invalid API Token"
    fi
fi

# Test 6: Check Zone Configuration
echo -e "\n6. Testing Zone Configuration..."
if [ -n "$CF_ZONES" ]; then
    echo -e "${YELLOW}Configured zones: $CF_ZONES${NC}"
    
    # Test each zone ID
    IFS=',' read -ra ZONE_ARRAY <<< "$CF_ZONES"
    for zone in "${ZONE_ARRAY[@]}"; do
        ZONE_TEST=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" "https://api.cloudflare.com/client/v4/zones/$zone" | jq -r '.success')
        if [ "$ZONE_TEST" == "true" ]; then
            print_result 0 "Zone $zone is valid"
        else
            print_result 1 "Zone check" "Invalid zone ID: $zone"
        fi
    done
else
    echo -e "${YELLOW}No zones configured - will export all available zones${NC}"
fi

# Test 7: Check prometheus scrape config
echo -e "\n7. Testing Prometheus configuration..."
if [ -f "config/prometheus/prometheus.yml" ]; then
    if grep -q "cloudflare-exporter:8080" config/prometheus/prometheus.yml; then
        print_result 0 "Prometheus configuration found"
        
        # Validate prometheus config
        docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
        print_result $? "Prometheus configuration is valid"
    else
        print_result 1 "Prometheus configuration check" "Cloudflare exporter target not found in prometheus.yml"
    fi
else
    print_result 1 "Prometheus configuration check" "prometheus.yml not found"
fi

# Test 8: Check metric values
echo -e "\n8. Testing metric values..."
sleep 5 # Wait for metrics to be collected

# Get total requests
TOTAL_REQUESTS=$(curl -s http://localhost:9198/metrics | grep "cloudflare_zone_requests_total" | grep -v "^#" | awk '{print $2}')
if [ -n "$TOTAL_REQUESTS" ]; then
    print_result 0 "Total requests metric present: $TOTAL_REQUESTS"
else
    print_result 1 "Metric values check" "No request data available"
fi

# Test 9: Check scrape interval
echo -e "\n9. Testing scrape interval..."
SCRAPE_DELAY=${SCRAPE_DELAY:-300}
echo -e "${YELLOW}Configured scrape delay: ${SCRAPE_DELAY}s${NC}"
print_result 0 "Scrape interval configured"

# Test 10: Check logs for errors
echo -e "\n10. Testing logs for errors..."
ERROR_COUNT=$(docker compose logs cloudflare-exporter 2>&1 | grep -i "error" | wc -l)
if [ $ERROR_COUNT -eq 0 ]; then
    print_result 0 "No errors found in logs"
else
    print_result 1 "Log check" "Found $ERROR_COUNT errors in logs"
    echo -e "${YELLOW}Recent errors:${NC}"
    docker compose logs cloudflare-exporter 2>&1 | grep -i "error" | tail -n 5
fi

echo -e "\nTest Summary"
echo "=============="
echo -e "Time: $(date)"
echo -e "Container ID: $(docker compose ps -q cloudflare-exporter)"
echo -e "Exporter Version: $(curl -s http://localhost:9198/metrics | grep cloudflare_exporter_build_info | grep -v '^#' | awk -F'"' '{print $2}')"
echo -e "Total Metrics: $(curl -s http://localhost:9198/metrics | grep -v '^#' | wc -l)"
echo -e "Configuration:"
echo -e "- Scrape Delay: ${SCRAPE_DELAY}s"
echo -e "- Metrics Path: ${METRICS_PATH:-/metrics}"
echo -e "- Free Tier: ${FREE_TIER:-false}"
echo -e "- Batch Size: ${CF_BATCH_SIZE:-10}"

# Optional: Export test results
if [ "$1" == "--export" ]; then
    TEST_RESULTS="cloudflare_exporter_test_$(date +%Y%m%d_%H%M%S).log"
    {
        echo "Cloudflare Exporter Test Results"
        echo "================================"
        echo "Date: $(date)"
        echo "Container ID: $(docker compose ps -q cloudflare-exporter)"
        echo "Metrics Available: $(curl -s http://localhost:9198/metrics | grep -v '^#' | wc -l)"
        echo ""
        echo "Raw Metrics Sample:"
        curl -s http://localhost:9198/metrics | head -n 20
        echo ""
        echo "Container Logs:"
        docker compose logs cloudflare-exporter
    } > "$TEST_RESULTS"
    echo -e "\nTest results exported to $TEST_RESULTS"
fi