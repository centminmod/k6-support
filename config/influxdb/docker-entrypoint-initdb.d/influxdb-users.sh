#!/bin/bash

# Wait for InfluxDB to be ready
echo "Waiting for InfluxDB to start..."
timeout 60 bash -c 'until curl -s http://localhost:8086/health | grep -q "ready"; do sleep 1; done'
echo "InfluxDB is ready"

# Function to create a bucket if it doesn't exist
create_bucket() {
    local bucket_name=$1
    local retention_period=$2
    influx bucket create \
        --name "${bucket_name}" \
        --org "${DOCKER_INFLUXDB_INIT_ORG}" \
        --retention "${DOCKER_INFLUXDB_INIT_RETENTION}" 
}

# Function to create a token for a user with specific permissions
create_user_token() {
    local username=$1
    local bucket=$2
    influx auth create \
        --org "${DOCKER_INFLUXDB_INIT_ORG}" \
        --user "${username}" \
        --read-bucket "${bucket}" \
        --write-bucket "${bucket}"
}

# Setup K6 compatibility
echo "Setting up K6 compatibility..."
create_bucket "k6" "0s"
K6_TOKEN=$(create_user_token "k6" "k6")
echo "K6_TOKEN=${K6_TOKEN}"

# Setup Telegraf compatibility
echo "Setting up Telegraf compatibility..."
create_bucket "telegraf" "0s"
TELEGRAF_TOKEN=$(create_user_token "telegraf" "telegraf")
echo "TELEGRAF_TOKEN=${TELEGRAF_TOKEN}"

# Setup PSRecord compatibility
echo "Setting up PSRecord compatibility..."
create_bucket "psrecord" "0s"
PSRECORD_TOKEN=$(create_user_token "psrecord" "psrecord")
echo "PSRECORD_TOKEN=${PSRECORD_TOKEN}"

# Create V1 compatibility API mappings for K6
echo "Setting up V1 compatibility mappings for K6..."
influx v1 dbrp create \
    --bucket-id $(influx bucket list --name k6 --hide-headers | cut -f 1) \
    --db k6 \
    --rp autogen \
    --default \
    --org "${DOCKER_INFLUXDB_INIT_ORG}"

# Create V1 compatibility API mappings for Telegraf
echo "Setting up V1 compatibility mappings for Telegraf..."
influx v1 dbrp create \
    --bucket-id $(influx bucket list --name telegraf --hide-headers | cut -f 1) \
    --db telegraf \
    --rp autogen \
    --default \
    --org "${DOCKER_INFLUXDB_INIT_ORG}"

# Create V1 compatibility API mappings for PSRecord
echo "Setting up V1 compatibility mappings for PSRecord..."
influx v1 dbrp create \
    --bucket-id $(influx bucket list --name psrecord --hide-headers | cut -f 1) \
    --db psrecord \
    --rp autogen \
    --default \
    --org "${DOCKER_INFLUXDB_INIT_ORG}"

# Create auth for V1 API compatibility
echo "Setting up V1 API compatibility..."
influx v1 auth create \
    --username k6 \
    --password k6 \
    --read-bucket $(influx bucket list --name k6 --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name k6 --hide-headers | cut -f 1)

influx v1 auth create \
    --username telegraf \
    --password password \
    --read-bucket $(influx bucket list --name telegraf --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name telegraf --hide-headers | cut -f 1)

influx v1 auth create \
    --username psrecord \
    --password password \
    --read-bucket $(influx bucket list --name psrecord --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name psrecord --hide-headers | cut -f 1)

echo "Setting up V1 compatibility mappings for internal metrics..."
influx v1 dbrp create \
    --bucket-id $(influx bucket list --name _internal --hide-headers | cut -f 1) \
    --db _internal \
    --rp autogen \
    --default \
    --org "${DOCKER_INFLUXDB_INIT_ORG}"

# Add internal metrics auth
influx v1 auth create \
    --username admin \
    --password password \
    --read-bucket $(influx bucket list --name _internal --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name _internal --hide-headers | cut -f 1)

echo "InfluxDB 2.x initialization complete!"