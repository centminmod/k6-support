#!/bin/bash

# Wait for InfluxDB to start...
echo "Waiting for InfluxDB to start..."
timeout 60 bash -c 'until curl -s http://localhost:8086/health | grep -q "ready"; do sleep 1; done'
echo "InfluxDB is ready"

# Function to create a bucket if it doesn't exist
create_bucket() {
    local bucket_name=$1
    if ! influx bucket list --name "${bucket_name}" --hide-headers 2>/dev/null | grep -q "${bucket_name}"; then
        echo "Creating bucket: ${bucket_name}"
        influx bucket create \
            --name "${bucket_name}" \
            --org "${DOCKER_INFLUXDB_INIT_ORG}" \
            --retention "${DOCKER_INFLUXDB_INIT_RETENTION}" \
            --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"
    else
        echo "Bucket ${bucket_name} already exists"
    fi
}

# Function to create a user if it doesn't exist
create_user() {
    local username=$1
    local password=$2
    if ! influx user list --name "${username}" --hide-headers 2>/dev/null | grep -q "${username}"; then
        echo "Creating user: ${username}"
        influx user create \
            --name "${username}" \
            --password "${password}" \
            --org "${DOCKER_INFLUXDB_INIT_ORG}" \
            --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"
    else
        echo "User ${username} already exists"
    fi
}

# Create buckets
echo "Setting up buckets..."
create_bucket "k6"
create_bucket "telegraf"
create_bucket "psrecord"
create_bucket "cloudflare"

# Create users with proper password lengths
echo "Setting up users..."
create_user "${INFLUXDB_TELEGRAF_USER}" "${INFLUXDB_TELEGRAF_PASSWORD}"
create_user "${INFLUXDB_K6_USER}" "${INFLUXDB_K6_PASSWORD}"
create_user "${INFLUXDB_PSRECORD_USER}" "${INFLUXDB_PSRECORD_PASSWORD}"

# Create service tokens
echo "Creating service tokens..."
for service in k6 telegraf psrecord; do
    TOKEN=$(influx auth create \
        --org "${DOCKER_INFLUXDB_INIT_ORG}" \
        --read-bucket ${service} \
        --write-bucket ${service} \
        --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}" 2>/dev/null || true)
    if [ ! -z "$TOKEN" ]; then
        echo "${service^^}_TOKEN=${TOKEN}"
    fi
done

# Setup V1 compatibility mappings
echo "Setting up V1 compatibility mappings..."
for db in k6 telegraf psrecord cloudflare; do
    BUCKET_ID=$(influx bucket list --name ${db} --hide-headers 2>/dev/null | cut -f 1)
    if [ ! -z "$BUCKET_ID" ]; then
        echo "Setting up V1 mapping for ${db}"
        influx v1 dbrp create \
            --bucket-id "${BUCKET_ID}" \
            --db "${db}" \
            --rp autogen \
            --default \
            --org "${DOCKER_INFLUXDB_INIT_ORG}" \
            --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}" 2>/dev/null || true
    fi
done

# Setup V1 API AUTH_MAP
echo "Setting up V1 API compatibility..."
declare -A AUTH_MAP=(
    ["${INFLUXDB_K6_USER}"]="${INFLUXDB_K6_PASSWORD}"
    ["${INFLUXDB_TELEGRAF_USER}"]="${INFLUXDB_TELEGRAF_PASSWORD}"
    ["${INFLUXDB_PSRECORD_USER}"]="${INFLUXDB_PSRECORD_PASSWORD}"
)

for username in "${!AUTH_MAP[@]}"; do
    # Get the bucket name based on the username (k6, telegraf, or psrecord)
    BUCKET_NAME=${username}
    
    # Get the bucket ID using the bucket list command and extract just the ID
    BUCKET_ID=$(influx bucket list --name "${BUCKET_NAME}" --hide-headers | cut -f 1)
    
    if [ ! -z "$BUCKET_ID" ]; then
        echo "Setting up V1 auth for ${username} with bucket ID: ${BUCKET_ID}"
        influx v1 auth create \
            --username "${username}" \
            --password "${AUTH_MAP[$username]}" \
            --read-bucket "${BUCKET_ID}" \
            --write-bucket "${BUCKET_ID}" \
            --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}" 2>/dev/null || true
    else
        echo "Warning: Could not find bucket ID for ${BUCKET_NAME}"
    fi
done

echo "InfluxDB 2.x initialization complete!"