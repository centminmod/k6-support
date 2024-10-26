# K6 and Cloudflare Monitoring Stack Migration Documentation

## Part 1: Project Migration Summary

### Original Objectives
1. Maintain existing K6 monitoring functionality
2. Add Cloudflare monitoring capabilities using Cloudflare GraphQL API
3. Update InfluxDB from 1.8 to 2.7 while ensuring backward compatibility
4. Preserve existing dashboard functionality
5. Keep monitoring functionality for system metrics via Telegraf

### Key Changes Made

#### 1. Docker Compose Updates
- Maintained original network name `k6-support` for compatibility
- Updated InfluxDB from 1.8 to 2.7 with V1 API compatibility
- Added Cloudflare exporter service
- Updated Telegraf configuration for InfluxDB 2.x
- Added proper environment variable support

#### 2. InfluxDB Migration
- Introduced V1 API compatibility mode
- Created new bucket system while maintaining database compatibility
- Updated initialization scripts for user management
- Added token-based authentication

#### 3. Telegraf Configuration
- Maintained existing metrics collection
- Added support for InfluxDB 2.x output
- Added Cloudflare metrics collection
- Preserved StatsD functionality for K6

#### 4. Grafana Updates
- Updated datasource configurations for InfluxDB 2.x
- Maintained existing dashboard functionality
- Updated query syntax for InfluxDB 2.x
- Added Cloudflare monitoring panels

#### 5. Added Components
- Cloudflare exporter service
- Updated Prometheus configuration
- Enhanced monitoring capabilities

## Part 2: Cloudflare API Token Permissions

The required Cloudflare API token permissions:

Read-Only Access (If you only need monitoring):
- Zone Analytics:
  * Analytics Read
- Zone:
  * Zone Read
- DNS:
  * DNS Read
- Health Check:
  * Healthchecks Read
- WebRTC:
  * Stats Read
- WAF:
  * Read

Edit Access (If you need monitoring and management):
- Zone Analytics:
  * Analytics Read
- Zone:
  * Zone Read
  * Zone Edit
- DNS:
  * DNS Read 
  * DNS Edit
- Health Check:
  * Healthchecks Read
  * Healthchecks Edit
- WebRTC:
  * Stats Read
  * Stats Edit
- WAF:
  * Read
  * Edit

Additional Important Settings:
- Zone Resources:
  * Include: All zones (or specify particular zones)
- Client IP Address Filtering:
  * Optional: Add your server's IP for extra security

Best Practices:
- Create separate tokens for read-only monitoring vs management
- Use the principle of least privilege - only grant permissions needed
- Set expiration dates on tokens if using for temporary purposes
- Record token IDs and their purposes in your documentation
- Store tokens securely in environment variables or secrets management

You can verify token permissions with:
```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer $CF_API_TOKEN"
```

## Part 3: Fresh Installation Guide

### Prerequisites
```bash
# Required packages
dnf install -y wget git curl
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### System Setup
```bash
# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add user to docker group
usermod -aG docker $USER

# Configure firewall
firewall-cmd --permanent --add-port=9409/tcp  # Grafana
firewall-cmd --permanent --add-port=8186/tcp  # InfluxDB
firewall-cmd --permanent --add-port=9199/tcp  # Prometheus
firewall-cmd --permanent --add-port=9100/tcp  # Node Exporter
firewall-cmd --reload
```

* 9409/tcp (Grafana)
* 8186/tcp (InfluxDB)
* 9199/tcp (Prometheus)
* 9100/tcp (Node Exporter)
* 9198/tcp (Cloudflare Exporter)

### Project Setup

1. Create Project Structure
```bash
# Create directories
mkdir -p ~/k6-monitoring
cd ~/k6-monitoring

# Create config structure
mkdir -p config/{grafana/{provisioning/{datasources,dashboards},dashboards},telegraf,influxdb,prometheus}
```

2. Create Environment File
```bash
# Create .env file
cat << EOF > .env
# InfluxDB Configuration
DOCKER_INFLUXDB_INIT_MODE=setup
DOCKER_INFLUXDB_INIT_USERNAME=admin
DOCKER_INFLUXDB_INIT_PASSWORD=password
DOCKER_INFLUXDB_INIT_ORG=myorg
DOCKER_INFLUXDB_INIT_BUCKET=k6
DOCKER_INFLUXDB_INIT_RETENTION=1500d
INFLUX_TOKEN=your-super-secret-admin-token

# Telegraf
TELEGRAF_INFLUXDB_USER=telegraf
TELEGRAF_INFLUXDB_PASSWORD=password

# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin

# Cloudflare Configuration
CF_API_TOKEN=your-cloudflare-api-token
CF_ZONES=zone1,zone2  # Comma-separated zone IDs, optional if you want all zones
# Optional configurations
CF_EXCLUDE_ZONES=  # Comma-separated zone IDs to exclude
METRICS_DENYLIST=  # Comma-separated metrics to exclude

# Legacy Compatibility
INFLUXDB_TELEGRAF_USER=telegraf
INFLUXDB_TELEGRAF_PASSWORD=password
INFLUXDB_K6_USER=k6
INFLUXDB_K6_PASSWORD=k6
INFLUXDB_PSRECORD_USER=psrecord
INFLUXDB_PSRECORD_PASSWORD=password
EOF
```

3. Deploy Configuration Files

a. Create InfluxDB initialization script:
```bash
# Create initialization directory
mkdir -p config/influxdb/docker-entrypoint-initdb.d
cp influxdb-users.sh config/influxdb/docker-entrypoint-initdb.d/
chmod +x config/influxdb/docker-entrypoint-initdb.d/influxdb-users.sh
```

b. Set up Telegraf configuration:
```bash
cp telegraf.conf config/telegraf/telegraf.conf
```

c. Set up Grafana dashboards:
```bash
cp dashboards/*.json config/grafana/dashboards/
```

4. Deploy Stack
```bash
# Start the stack
docker compose up -d

# Verify services
docker compose ps
```

### Post-Installation Steps

1. Verify InfluxDB Setup
```bash
# Check InfluxDB health
curl -i http://localhost:8186/health

# Verify buckets
curl -G "http://localhost:8186/api/v2/buckets" \
  -H "Authorization: Token $INFLUX_TOKEN"
```

2. Test K6 Integration
```bash
# Run a simple K6 test
k6 run --out influxdb=http://localhost:8186/k6 script.js
```

3. Access Grafana
- Open browser to `http://your-server-ip:9409`
- Login with credentials from .env file
- Verify datasource connections
- Import dashboards if not auto-imported

4. Verify Cloudflare Monitoring
```bash
# Check Cloudflare metrics
curl http://localhost:9198/metrics

# Verify in Grafana
# Navigate to Cloudflare dashboard
```

### Maintenance Commands

1. Update Stack
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

2. View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f [service-name]
```

3. Backup Data
```bash
# Create backup directory
mkdir -p backups

# Backup InfluxDB data
docker compose exec influxdb influxd backup /backups/influxdb

# Backup Grafana data
docker compose cp grafana:/var/lib/grafana ./backups/grafana
```

### Troubleshooting

1. InfluxDB Issues
```bash
# Check InfluxDB logs
docker compose logs influxdb

# Verify permissions
sudo chown -R 472:472 $(pwd)/config/influxdb
```

2. Grafana Issues
```bash
# Reset admin password
docker compose exec grafana grafana-cli admin reset-admin-password newpassword

# Check datasource connections
curl -H "Authorization: Bearer $GRAFANA_API_KEY" http://localhost:9409/api/datasources
```

3. Telegraf Issues
```bash
# Test Telegraf config
docker compose exec telegraf telegraf --test

# Check permissions
sudo chown -R telegraf:telegraf config/telegraf
```

### Additional Resources
- Grafana Documentation: https://grafana.com/docs/
- InfluxDB 2.x Documentation: https://docs.influxdata.com/influxdb/v2.7/
- K6 Documentation: https://k6.io/docs/
- Cloudflare API Documentation: https://developers.cloudflare.com/analytics/graphql-api

## Part 4: Environment Teardown and Reset Procedures

### Quick Teardown
For a quick teardown without saving any data:
```bash
# Stop and remove all containers, networks, and volumes
docker compose down -v

# Remove all generated files
rm -rf config/grafana/dashboards/*.json
rm -rf config/influxdb/data/*
rm -rf config/influxdb/config/*
```

### Clean Teardown with Backup
For a clean teardown while preserving data:

1. Backup Existing Data
```bash
# Create backup directory with timestamp
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup InfluxDB data
docker compose exec influxdb influxd backup /backup
docker compose cp influxdb:/backup $BACKUP_DIR/influxdb_backup

# Backup Grafana dashboards and settings
docker compose cp grafana:/var/lib/grafana $BACKUP_DIR/grafana_data

# Backup configuration files
cp -r config/* $BACKUP_DIR/config/

# Backup docker-compose and environment files
cp docker-compose.yml $BACKUP_DIR/
cp .env $BACKUP_DIR/
```

2. Stop and Remove Services
```bash
# Stop all services
docker compose stop

# Remove containers
docker compose rm -f

# Remove networks
docker network rm k6-support

# Remove volumes (optional - will delete all data)
docker volume rm $(docker volume ls -q | grep -E 'influxdb|grafana|prometheus')
```

3. Clean Up Files
```bash
# Remove configuration files
rm -rf config/influxdb/*
rm -rf config/grafana/*
rm -rf config/prometheus/*
rm -rf config/telegraf/*

# Remove environment file
rm .env
```

### Complete Reset
For a complete reset of the environment:

1. Stop and Remove Everything
```bash
# Stop all containers
docker compose down -v

# Remove all project-related containers
docker rm -f $(docker ps -a | grep 'k6-support\|monitoring' | awk '{print $1}')

# Remove all project-related volumes
docker volume rm $(docker volume ls -q | grep -E 'influxdb|grafana|prometheus')

# Remove all project-related networks
docker network rm k6-support
```

2. Clean Docker System (Optional)
```bash
# Remove unused containers, networks, and images
docker system prune -a --volumes

# Remove only dangling images
docker image prune
```

3. Remove Configuration Files
```bash
# Remove all configuration directories
rm -rf config/

# Remove environment and compose files
rm .env
rm docker-compose.yml
```

### Fresh Start
To start fresh after a teardown:

1. Recreate Directory Structure
```bash
# Create fresh directories
mkdir -p config/{grafana/{provisioning/{datasources,dashboards},dashboards},telegraf,influxdb,prometheus}
```

2. Reset Configuration Files
```bash
# Create new .env file from template
cp .env.example .env

# Generate new tokens and update .env
echo "INFLUX_TOKEN=$(openssl rand -hex 32)" >> .env
echo "GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 12)" >> .env
```

3. Restart Services
```bash
# Pull fresh images
docker compose pull

# Start services
docker compose up -d

# Verify services
docker compose ps
```

4. Restore from Backup (if needed)
```bash
# Restore InfluxDB data
docker compose cp $BACKUP_DIR/influxdb_backup influxdb:/backup
docker compose exec influxdb influxd restore /backup

# Restore Grafana data
docker compose cp $BACKUP_DIR/grafana_data grafana:/var/lib/grafana

# Restore configuration files
cp -r $BACKUP_DIR/config/* config/
```

### Post-Reset Verification

1. Check Services
```bash
# Verify all services are running
docker compose ps

# Check service logs
docker compose logs -f
```

2. Verify Data Access
```bash
# Check InfluxDB
curl -I http://localhost:8186/health

# Check Grafana
curl -I http://localhost:9409

# Check Prometheus
curl -I http://localhost:9199
```

3. Verify Monitoring
```bash
# Test K6 connection
k6 run --out influxdb=http://localhost:8186/k6 script.js

# Check Cloudflare metrics
curl http://localhost:9198/metrics
```

### Troubleshooting Post-Reset

If services fail to start after reset:

1. Check Permissions
```bash
# Reset ownership of mounted volumes
sudo chown -R 472:472 config/grafana
sudo chown -R 888:888 config/influxdb

# Check SELinux contexts (if using SELinux)
sudo semanage fcontext -a -t container_file_t "/path/to/config(/.*)?"
sudo restorecon -Rv /path/to/config
```

2. Verify Network
```bash
# Check if networks are created properly
docker network ls | grep k6-support

# Inspect network connectivity
docker network inspect k6-support
```

3. Reset Docker System
```bash
# Restart Docker daemon
sudo systemctl restart docker

# Wait for Docker to be ready
sleep 10

# Start services again
docker compose up -d
```