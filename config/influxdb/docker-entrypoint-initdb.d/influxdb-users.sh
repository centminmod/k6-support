#!/bin/bash
# Wait for InfluxDB to be ready
echo "Waiting for InfluxDB to start..."
timeout 60 bash -c 'until curl -s http://localhost:8086/health | grep -q "ready"; do sleep 1; done'
echo "InfluxDB is ready"

echo "Setting up initial users..."
influx user create \
    --name "${INFLUXDB_TELEGRAF_USER}" \
    --password "${INFLUXDB_TELEGRAF_PASSWORD}" \
    --org "${DOCKER_INFLUXDB_INIT_ORG}" \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"

# Function to create a bucket if it doesn't exist
create_bucket() {
    local bucket_name=$1
    influx bucket create \
        --name "${bucket_name}" \
        --org "${DOCKER_INFLUXDB_INIT_ORG}" \
        --retention "${DOCKER_INFLUXDB_INIT_RETENTION}" \
        --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"
}

# Create all buckets
echo "Creating buckets..."
create_bucket "k6"
create_bucket "telegraf"
create_bucket "psrecord"
create_bucket "cloudflare"

# Create tokens for each service
echo "Creating service tokens..."
K6_TOKEN=$(influx auth create \
    --org "${DOCKER_INFLUXDB_INIT_ORG}" \
    --read-bucket k6 \
    --write-bucket k6 \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}")
echo "K6_TOKEN=${K6_TOKEN}"

TELEGRAF_TOKEN=$(influx auth create \
    --org "${DOCKER_INFLUXDB_INIT_ORG}" \
    --read-bucket telegraf \
    --write-bucket telegraf \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}")
echo "TELEGRAF_TOKEN=${TELEGRAF_TOKEN}"

PSRECORD_TOKEN=$(influx auth create \
    --org "${DOCKER_INFLUXDB_INIT_ORG}" \
    --read-bucket psrecord \
    --write-bucket psrecord \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}")
echo "PSRECORD_TOKEN=${PSRECORD_TOKEN}"

echo "Setting up V1 compatibility users..."
echo "Creating telegraf user..."
influx user create \
    --name "${INFLUXDB_TELEGRAF_USER}" \
    --password "${INFLUXDB_TELEGRAF_PASSWORD}" \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"

# Create V1 compatibility API mappings for all buckets
echo "Setting up V1 compatibility mappings..."
for db in k6 telegraf psrecord cloudflare _internal; do
    echo "Setting up V1 compatibility mappings for ${db}..."
    influx v1 dbrp create \
        --bucket-id $(influx bucket list --name ${db} --hide-headers | cut -f 1) \
        --db ${db} \
        --rp autogen \
        --default \
        --org "${DOCKER_INFLUXDB_INIT_ORG}" \
        --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"
done

# Create auth for V1 API compatibility
echo "Setting up V1 API compatibility..."
# K6 auth
influx v1 auth create \
    --username k6 \
    --password k6 \
    --read-bucket $(influx bucket list --name k6 --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name k6 --hide-headers | cut -f 1) \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"

# Telegraf auth
influx v1 auth create \
    --username "${INFLUXDB_TELEGRAF_USER}" \
    --password "${INFLUXDB_TELEGRAF_PASSWORD}" \
    --read-bucket $(influx bucket list --name telegraf --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name telegraf --hide-headers | cut -f 1) \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"

# PSRecord auth
influx v1 auth create \
    --username psrecord \
    --password password \
    --read-bucket $(influx bucket list --name psrecord --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name psrecord --hide-headers | cut -f 1) \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"

# Admin auth for internal metrics
influx v1 auth create \
    --username admin \
    --password password \
    --read-bucket $(influx bucket list --name _internal --hide-headers | cut -f 1) \
    --write-bucket $(influx bucket list --name _internal --hide-headers | cut -f 1) \
    --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"

echo "InfluxDB 2.x initialization complete!"