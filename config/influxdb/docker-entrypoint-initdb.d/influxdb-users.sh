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

# Setup K6 compatibility
echo "Setting up K6 compatibility..."
create_bucket "k6" "0s"
K6_TOKEN=$(influx auth create \
    --org "${DOCKER_INFLUXDB_INIT_ORG}" \
    --read-bucket k6 \
    --write-bucket k6)
echo "K6_TOKEN=${K6_TOKEN}"

# Setup Telegraf compatibility
echo "Setting up Telegraf compatibility..."
create_bucket "telegraf" "0s"
TELEGRAF_TOKEN=$(influx auth create \
    --org "${DOCKER_INFLUXDB_INIT_ORG}" \
    --read-bucket telegraf \
    --write-bucket telegraf)
echo "TELEGRAF_TOKEN=${TELEGRAF_TOKEN}"

# Setup PSRecord compatibility
echo "Setting up PSRecord compatibility..."
create_bucket "psrecord" "0s"
PSRECORD_TOKEN=$(influx auth create \
    --org "${DOCKER_INFLUXDB_INIT_ORG}" \
    --read-bucket psrecord \
    --write-bucket psrecord)
echo "PSRECORD_TOKEN=${PSRECORD_TOKEN}"

# Create V1 compatibility API mappings
for db in k6 telegraf psrecord _internal; do
    echo "Setting up V1 compatibility mappings for ${db}..."
    influx v1 dbrp create \
        --bucket-id $(influx bucket list --name ${db} --hide-headers | cut -f 1) \
        --db ${db} \
        --rp autogen \
        --default \
        --org "${DOCKER_INFLUXDB_INIT_ORG}"
done

# Create auth for V1 API compatibility
echo "Setting up V1 API compatibility..."
# K6 auth
influx v1 auth create \
    --username k6 \
    --password k6 \
    --read-bucket $(influx bucket list --name k6 --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name k6 --hide-headers | cut -f 1)

# Telegraf auth
influx v1 auth create \
    --username "${INFLUXDB_TELEGRAF_USER}" \
    --password "${INFLUXDB_TELEGRAF_PASSWORD}" \
    --read-bucket $(influx bucket list --name telegraf --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name telegraf --hide-headers | cut -f 1)

# PSRecord auth
influx v1 auth create \
    --username psrecord \
    --password password \
    --read-bucket $(influx bucket list --name psrecord --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name psrecord --hide-headers | cut -f 1)

# Admin auth for internal metrics
influx v1 auth create \
    --username admin \
    --password password \
    --read-bucket $(influx bucket list --name _internal --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name _internal --hide-headers | cut -f 1)

echo "InfluxDB 2.x initialization complete!"