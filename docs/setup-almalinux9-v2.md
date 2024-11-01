# Complete Setup Guide: Cloudflare Monitoring Stack on AlmaLinux 9

## 1. System Preparation

### Update System
```bash
sudo dnf update -y
sudo dnf upgrade -y
```

### Install Required Packages
```bash
# Install basic requirements
sudo dnf install -y dnf-utils yum-utils
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y git curl wget nano python3 python3-pip

# Install Docker dependencies
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
    "dns": ["172.18.0.1", "1.1.1.1", "8.8.8.8"],
    "dns-opts": ["ndots:1"],
    "dns-search": ["k6-support"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker --no-pager -l

# Add your user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG docker telegraf 
```

### Configure Firewall
```bash
sudo dnf install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Open required ports
sudo firewall-cmd --permanent --add-port=9409/tcp  # Grafana
sudo firewall-cmd --permanent --add-port=8186/tcp  # InfluxDB
sudo firewall-cmd --permanent --add-port=9199/tcp  # Prometheus
sudo firewall-cmd --permanent --add-port=9100/tcp  # Node Exporter
sudo firewall-cmd --reload
```

## 2. Create Project Structure

```bash
# Create project directory
mkdir -p /home/cloudflare-monitoring
cd /home/cloudflare-monitoring
git clone -b cmm-cloudflare https://github.com/centminmod/k6-support
cd k6-support
```

## 3. Configure Components

### Set up Environment Variables

Including Cloudflare API Token, zond IDs nad R2 bucket credentials for Thanos long term Prometheus storage.

```bash
cp -a example.env .env
DOCKER_GID=$(getent group docker | cut -d: -f3)
echo "DOCKER_GROUP_ID=$DOCKER_GID" >> .env
```

If you're using default provided `example.env` derived `.env`, also change the default value for password variables.

```bash
newpass=$(openssl rand -base64 21 | tr -dc 'a-zA-Z0-9')
sed -i "s/=password/=${newpass}/g" .env
```

Same for InfluxDB token

```bash
newtoken=$(openssl rand -base64 21 | tr -dc 'a-zA-Z0-9')
sed -i "s/=yoursupersecretadmintoken/=${newtoken}/g" .env
```

```bash
cat .env
# InfluxDB 2.x Configuration
DOCKER_INFLUXDB_INIT_MODE=setup
DOCKER_INFLUXDB_INIT_USERNAME=admin
DOCKER_INFLUXDB_INIT_PASSWORD=password
DOCKER_INFLUXDB_INIT_ORG=myorg
DOCKER_INFLUXDB_INIT_BUCKET=k6
DOCKER_INFLUXDB_INIT_RETENTION=1500d
INFLUX_TOKEN=yoursupersecretadmintoken
DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=yoursupersecretadmintoken

# Telegraf
TELEGRAF_INFLUXDB_USER=telegraf
TELEGRAF_INFLUXDB_PASSWORD=password

# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin

# Cloudflare Configuration
CF_ACCOUNT_ID='your-cloudflare-account-id'
CF_API_TOKEN=your-cloudflare-api-token
CF_ZONES=your-zone-ids  # Comma-separated list of zone IDs
R2_ACCESS_KEY_ID=your_r2_access_key
R2_SECRET_ACCESS_KEY=your_r2_secret_key
R2_BUCKET_NAME='r2_bucketname'

# User Credentials (for v1 compatibility)
INFLUXDB_TELEGRAF_USER=telegraf
INFLUXDB_TELEGRAF_PASSWORD=password
INFLUXDB_K6_USER=k6
INFLUXDB_K6_PASSWORD=password
INFLUXDB_PSRECORD_USER=psrecord
INFLUXDB_PSRECORD_PASSWORD=password

# Database Names (for v1 compatibility)
INFLUXDB_DB_K6=k6
INFLUXDB_DB_TELEGRAF=telegraf
INFLUXDB_DB_PSRECORD=psrecord

# Network Configuration (if needed)
DOCKER_INFLUXDB_INIT_HOST=influxdb
DOCKER_INFLUXDB_INIT_PORT=8086

# Alertmanager Email Configuration for Amazon SES
ALERTMANAGER_SMTP_SMARTHOST=email-smtp.<region>.amazonaws.com:587
ALERTMANAGER_SMTP_FROM=alertmanager@yourdomain.com
ALERTMANAGER_SMTP_AUTH_USERNAME=your_ses_smtp_username
ALERTMANAGER_SMTP_AUTH_PASSWORD=your_ses_smtp_password
ALERTMANAGER_EMAIL_TO=recipient@yourdomain.com
ALERTMANAGER_EMAIL_CRITICAL_TO=critical-recipient@yourdomain.com
ALERTMANAGER_EMAIL_WARNING_TO=warning-recipient@yourdomain.com
```

If update `CF_ZONES` list in `.env`:

```bash
CF_ZONES=existing-zone-id,new-zone-id-1,new-zone-id-2
```

Reload the environment variables in the updated .env file. You can do this for specific containers without stopping or deleting the entire stack:

```bash
docker-compose up -d --no-deps --force-recreate k6-support-cloudflare-exporter
```

This command will recreate only the `cloudflare-exporter` container (replace `k6-support-cloudflare-exporter` with your container name if different) with the updated environment variables.

## 4. Deploy the Stack

```bash
source .env
# Start the stack
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```
```bash
docker compose up -d
docker compose restart grafana
docker compose exec grafana grafana server -v
```
```bash
time docker compose up -d
[+] Running 20/20
 ✔ Network k6-support                         Created                                                                                                                                     0.1s 
 ✔ Volume "k6-support_prometheus_data"        Created                                                                                                                                     0.0s 
 ✔ Volume "k6-support_thanos_compactor_data"  Created                                                                                                                                     0.0s 
 ✔ Volume "k6-support_thanos_query_data"      Created                                                                                                                                     0.0s 
 ✔ Volume "k6-support_grafana_data"           Created                                                                                                                                     0.0s 
 ✔ Volume "k6-support_grafana_wal"            Created                                                                                                                                     0.0s 
 ✔ Volume "k6-support_thanos_sidecar_data"    Created                                                                                                                                     0.0s 
 ✔ Volume "k6-support_influxdb_data"          Created                                                                                                                                     0.0s 
 ✔ Volume "k6-support_alertmanager_data"      Created                                                                                                                                     0.0s 
 ✔ Container k6-support-prometheus            Healthy                                                                                                                                     6.1s 
 ✔ Container k6-support-alertmanager          Started                                                                                                                                     0.5s 
 ✔ Container k6-support-influxdb              Healthy                                                                                                                                    71.1s 
 ✔ Container k6-support-cloudflare-exporter   Healthy                                                                                                                                     5.6s 
 ✔ Container k6-support-thanos-store-gateway  Healthy                                                                                                                                     6.7s 
 ✔ Container k6-support-node-exporter         Started                                                                                                                                     0.5s 
 ✔ Container k6-support-thanos-compactor      Started                                                                                                                                     6.1s 
 ✔ Container k6-support-telegraf              Started                                                                                                                                    71.3s 
 ✔ Container k6-support-thanos-sidecar        Healthy                                                                                                                                    11.7s 
 ✔ Container k6-support-grafana               Started                                                                                                                                    71.3s 
 ✔ Container k6-support-thanos-query          Started                                                                                                                                    11.9s 

real    1m11.508s
user    0m0.547s
sys     0m0.403s
```
```bash
docker compose restart grafana
[+] Restarting 1/1
 ✔ Container k6-support-grafana  Started                                                                                                                                                  0.3s
```
```bash
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
Checking /etc/prometheus/prometheus.yml
 SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax
```
```bash
docker logs k6-support-grafana | tail -10

```
```bash
docker exec -it k6-support-influxdb env | grep INFLUX_TOKEN
INFLUX_TOKEN=yoursupersecretadmintoken
```
```bash
docker compose ps
NAME                              IMAGE                                  COMMAND                  SERVICE                CREATED              STATUS                        PORTS
k6-support-alertmanager           prom/alertmanager:latest               "/bin/sh /init-alert…"   alertmanager           About a minute ago   Up About a minute (healthy)   0.0.0.0:9093->9093/tcp, :::9093->9093/tcp
k6-support-cloudflare-exporter    cyb3rjak3/cloudflare-exporter:latest   "./cloudflare_export…"   cloudflare-exporter    About a minute ago   Up About a minute (healthy)   0.0.0.0:9198->8080/tcp, [::]:9198->8080/tcp
k6-support-grafana                grafana/grafana-oss:11.3.0             "/run.sh"                grafana                About a minute ago   Up 44 seconds (healthy)       0.0.0.0:9409->3000/tcp, [::]:9409->3000/tcp
k6-support-influxdb               influxdb:2.7                           "/entrypoint.sh infl…"   influxdb               About a minute ago   Up About a minute (healthy)   0.0.0.0:8186->8086/tcp, [::]:8186->8086/tcp
k6-support-node-exporter          prom/node-exporter:latest              "/bin/node_exporter …"   node-exporter          About a minute ago   Up About a minute             0.0.0.0:9100->9100/tcp, :::9100->9100/tcp
k6-support-prometheus             prom/prometheus:latest                 "/bin/prometheus --c…"   prometheus             About a minute ago   Up About a minute (healthy)   0.0.0.0:9199->9090/tcp, [::]:9199->9090/tcp
k6-support-telegraf               telegraf:1.27                          "/entrypoint.sh tele…"   telegraf               About a minute ago   Up 44 seconds (healthy)       8092/udp, 8094/tcp, 127.0.0.1:8125->8125/udp, 0.0.0.0:9273->9273/tcp, :::9273->9273/tcp
k6-support-thanos-compactor       quay.io/thanos/thanos:v0.36.1          "/bin/sh /etc/thanos…"   thanos-compactor       About a minute ago   Up About a minute (healthy)   
k6-support-thanos-query           quay.io/thanos/thanos:v0.36.1          "/bin/sh /etc/thanos…"   thanos-query           About a minute ago   Up About a minute (healthy)   0.0.0.0:19192->19192/tcp, :::19192->19192/tcp
k6-support-thanos-sidecar         quay.io/thanos/thanos:v0.36.1          "/bin/sh /etc/thanos…"   thanos-sidecar         About a minute ago   Up About a minute (healthy)   
k6-support-thanos-store-gateway   quay.io/thanos/thanos:v0.36.1          "/bin/sh /etc/thanos…"   thanos-store-gateway   About a minute ago   Up About a minute (healthy)   
```

Verify InfluxDB buckets

```bash
source .env

docker exec k6-support-influxdb influx bucket list --org "${DOCKER_INFLUXDB_INIT_ORG}" --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"
ID                      Name            Retention       Shard group duration    Organization ID         Schema Type
bf035e21a38369cd        _monitoring     168h0m0s        24h0m0s                 d800bd887a29ba94        implicit
758e6d59863ed294        _tasks          72h0m0s         24h0m0s                 d800bd887a29ba94        implicit
6eeabd0a17ae2d48        cloudflare      36000h0m0s      168h0m0s                d800bd887a29ba94        implicit
a978b335a7b788e8        k6              36000h0m0s      168h0m0s                d800bd887a29ba94        implicit
18356712d8744cb7        psrecord        36000h0m0s      168h0m0s                d800bd887a29ba94        implicit
21140eab75b17c75        telegraf        36000h0m0s      168h0m0s                d800bd887a29ba94        implicit
```

```bash
docker logs k6-support-prometheus 2>&1 | tail -10
ts=2024-10-28T19:13:56.803Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=static/1 subs=[node-exporter]
ts=2024-10-28T19:13:56.803Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=static/2 subs=[cloudflare]
ts=2024-10-28T19:13:56.803Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=dns/3 subs=[telegraf]
ts=2024-10-28T19:13:56.803Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/2
ts=2024-10-28T19:13:56.803Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/0
ts=2024-10-28T19:13:56.803Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/1
ts=2024-10-28T19:13:56.803Z caller=main.go:1441 level=info msg="updated GOGC" old=100 new=75
ts=2024-10-28T19:13:56.803Z caller=main.go:1452 level=info msg="Completed loading of configuration file" filename=/etc/prometheus/prometheus.yml totalDuration=1.301948ms db_storage=902ns remote_storage=1.733µs web_handler=361ns query_engine=952ns scrape=278.443µs scrape_sd=257.484µs notify=1.011µs notify_sd=1.313µs rules=134.944µs tracing=17.392µs
ts=2024-10-28T19:13:56.803Z caller=main.go:1182 level=info msg="Server is ready to receive web requests."
ts=2024-10-28T19:13:56.803Z caller=manager.go:164 level=info component="rule manager" msg="Starting rule manager..."
```
```bash
docker logs k6-support-alertmanager 2>&1 | tail -50
Generating Alertmanager configuration...
Starting Alertmanager...
ts=2024-10-31T07:19:24.622Z caller=main.go:181 level=info msg="Starting Alertmanager" version="(version=0.27.0, branch=HEAD, revision=0aa3c2aad14cff039931923ab16b26b7481783b5)"
ts=2024-10-31T07:19:24.622Z caller=main.go:182 level=info build_context="(go=go1.21.7, platform=linux/amd64, user=root@22cd11f671e9, date=20240228-11:51:20, tags=netgo)"
ts=2024-10-31T07:19:24.623Z caller=cluster.go:186 level=info component=cluster msg="setting advertise address explicitly" addr=172.18.0.7 port=9094
ts=2024-10-31T07:19:24.626Z caller=cluster.go:683 level=info component=cluster msg="Waiting for gossip to settle..." interval=2s
ts=2024-10-31T07:19:24.663Z caller=coordinator.go:113 level=info component=configuration msg="Loading configuration file" file=/etc/alertmanager/config.yml
ts=2024-10-31T07:19:24.664Z caller=coordinator.go:126 level=info component=configuration msg="Completed loading of configuration file" file=/etc/alertmanager/config.yml
ts=2024-10-31T07:19:24.667Z caller=tls_config.go:313 level=info msg="Listening on" address=[::]:9093
ts=2024-10-31T07:19:24.667Z caller=tls_config.go:316 level=info msg="TLS is disabled." http2=false address=[::]:9093
ts=2024-10-31T07:19:26.626Z caller=cluster.go:708 level=info component=cluster msg="gossip not settled" polls=0 before=0 now=1 elapsed=2.000264526s
ts=2024-10-31T07:19:34.628Z caller=cluster.go:700 level=info component=cluster msg="gossip settled; proceeding" elapsed=10.001711542s
```
```bash
docker logs k6-support-influxdb | tail -10
2024-10-28T19:49:54.363483565Z  info    booting influxd server in the background        {"system": "docker"}
2024-10-28T19:49:55.367180901Z  info    pinging influxd...      {"system": "docker", "ping_attempt": "0"}
2024-10-28T19:49:55.379933912Z  info    got response from influxd, proceeding   {"system": "docker", "total_pings": "1"}
2024-10-28T19:49:55.503851116Z  info    Executing user-provided scripts {"system": "docker", "script_dir": "/docker-entrypoint-initdb.d"}
2024-10-28T19:50:56.243264076Z  info    initialization complete, shutting down background influxd       {"system": "docker"}
2024-10-28T19:50:56.338893762Z  info    found existing boltdb file, skipping setup wrapper      {"system": "docker", "bolt_path": "/var/lib/influxdb2/influxd.bolt"}
ts=2024-10-28T19:50:56.461921Z lvl=info msg="Configuring InfluxQL statement executor (zeros indicate unlimited)." log_id=0sXAkQmW000 max_select_point=0 max_select_series=0 max_select_buckets=0
ts=2024-10-28T19:50:56.466241Z lvl=info msg=Starting log_id=0sXAkQmW000 service=telemetry interval=8h
ts=2024-10-28T19:50:56.466286Z lvl=info msg=Listening log_id=0sXAkQmW000 service=tcp-listener transport=http addr=:8086 port=8086
ts=2024-10-28T19:51:11.017839Z lvl=info msg="index opened with 8 partitions" log_id=0sXAkQmW000 service=storage-engine index=tsi
ts=2024-10-28T19:51:11.018302Z lvl=info msg="loading changes (start)" log_id=0sXAkQmW000 service=storage-engine engine=tsm1 op_name="field indices" op_event=start
ts=2024-10-28T19:51:11.018445Z lvl=info msg="loading changes (end)" log_id=0sXAkQmW000 service=storage-engine engine=tsm1 op_name="field indices" op_event=end op_elapsed=0.144ms
ts=2024-10-28T19:51:11.020312Z lvl=info msg="Reindexing TSM data" log_id=0sXAkQmW000 service=storage-engine engine=tsm1 db_shard_id=1
ts=2024-10-28T19:51:11.020333Z lvl=info msg="Reindexing WAL data" log_id=0sXAkQmW000 service=storage-engine engine=tsm1 db_shard_id=1
ts=2024-10-28T19:51:11.050372Z lvl=info msg="saving field index changes (start)" log_id=0sXAkQmW000 service=storage-engine engine=tsm1 op_name=MeasurementFieldSet op_event=start
ts=2024-10-28T19:51:11.052603Z lvl=info msg="saving field index changes (end)" log_id=0sXAkQmW000 service=storage-engine engine=tsm1 op_name=MeasurementFieldSet op_event=end op_elapsed=2.271ms
```
```bash
docker logs k6-support-cloudflare-exporter  | tail -10
time="2024-10-27 00:59:50" level=info msg="Beginning to serve metrics on :8080/metrics"
time="2024-10-27 00:59:51" level=info msg="Filtering zone: xxxx domain-zone.com"
time="2024-10-27 01:00:50" level=info msg="Filtering zone: xxxx domain-zone.com"
```
```bash
docker compose logs telegraf | tail -100
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Loading config: /etc/telegraf/telegraf.conf
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Loading config: /etc/telegraf/telegraf.d/docker.conf
k6-support-telegraf  | 2024-10-28T19:51:04Z W! DeprecationWarning: Option "perdevice" of plugin "inputs.docker" deprecated since version 1.18.0 and will be removed in 2.0.0: use 'perdevice_include' instead
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Starting Telegraf 1.27.4
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Available plugins: 237 inputs, 9 aggregators, 28 processors, 23 parsers, 59 outputs, 4 secret-stores
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Loaded inputs: cpu disk diskio docker http_response interrupts kernel linux_sysctl_fs mem net netstat processes prometheus statsd swap system
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Loaded aggregators: 
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Loaded processors: 
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Loaded secretstores: 
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Loaded outputs: influxdb_v2 prometheus_client
k6-support-telegraf  | 2024-10-28T19:51:04Z I! Tags enabled: host=telegraf
k6-support-telegraf  | 2024-10-28T19:51:04Z W! Deprecated inputs: 0 and 1 options
k6-support-telegraf  | 2024-10-28T19:51:04Z I! [agent] Config: Interval:5s, Quiet:false, Hostname:"telegraf", Flush Interval:1s
k6-support-telegraf  | 2024-10-28T19:51:04Z W! DeprecationWarning: Value "false" for option "ignore_protocol_stats" of plugin "inputs.net" deprecated since version 1.27.3 and will be removed in 1.36.0: use the 'inputs.nstat' plugin instead
k6-support-telegraf  | 2024-10-28T19:51:04Z I! [outputs.prometheus_client] Listening on http://[::]:9273/metrics
k6-support-telegraf  | 2024-10-28T19:51:04Z I! [inputs.statsd] UDP listening on "[::]:8125"
k6-support-telegraf  | 2024-10-28T19:51:04Z I! [inputs.statsd] Started the statsd service on ":8125"
```
```bash
docker exec k6-support-cloudflare-exporter curl -s localhost:8080/metrics | grep HELP | grep -i cloudflare
# HELP cloudflare_exporter_build_info A metric with a constant '1' value labeled by version, revision, branch, and goversion from which the cloudflare_exporter was built.
# HELP cloudflare_r2_operation_count Number of operations performed by R2
# HELP cloudflare_r2_storage_bytes Storage used by R2
# HELP cloudflare_worker_cpu_time CPU time quantiles by script name
# HELP cloudflare_worker_duration Duration quantiles by script name (GB*s)
# HELP cloudflare_worker_errors_count Number of errors by script name
# HELP cloudflare_worker_requests_count Number of requests sent to worker by script name
# HELP cloudflare_zone_bandwidth_cached Cached bandwidth per zone in bytes
# HELP cloudflare_zone_bandwidth_content_type Bandwidth per zone per content type
# HELP cloudflare_zone_bandwidth_country Bandwidth per country per zone
# HELP cloudflare_zone_bandwidth_ssl_encrypted Encrypted bandwidth per zone in bytes
# HELP cloudflare_zone_bandwidth_total Total bandwidth per zone in bytes
# HELP cloudflare_zone_colocation_edge_response_bytes Edge response bytes per colocation
# HELP cloudflare_zone_colocation_requests_total Total requests per colocation
# HELP cloudflare_zone_colocation_visits Total visits per colocation
# HELP cloudflare_zone_firewall_events_count Count of Firewall events
# HELP cloudflare_zone_health_check_events_origin_count Number of Heath check events per region per origin
# HELP cloudflare_zone_pageviews_total Pageviews per zone
# HELP cloudflare_zone_requests_browser_map_page_views_count Number of successful requests for HTML pages per zone
# HELP cloudflare_zone_requests_cached Number of cached requests for zone
# HELP cloudflare_zone_requests_content_type Number of request for zone per content type
# HELP cloudflare_zone_requests_country Number of request for zone per country
# HELP cloudflare_zone_requests_origin_status_country_host Count of not cached requests for zone per origin HTTP status per country per host
# HELP cloudflare_zone_requests_ssl_encrypted Number of encrypted requests for zone
# HELP cloudflare_zone_requests_status Number of request for zone per HTTP status
# HELP cloudflare_zone_requests_status_country_host Count of requests for zone per edge HTTP status per country per host
# HELP cloudflare_zone_requests_total Number of requests for zone
# HELP cloudflare_zone_threats_country Threats per zone per country
# HELP cloudflare_zone_threats_total Threats per zone
# HELP cloudflare_zone_uniques_total Uniques per zone
```

Verify Thanos setup

```bash
docker compose logs thanos-query | tail -100
```

```bash
docker compose logs thanos-sidecar | tail -100
```

```bash
docker compose logs thanos-store-gateway | tail -100
```

```bash
docker compose logs thanos-compactor | tail -100
```

```bash
# Check Thanos Sidecar
curl http://localhost:19191/metrics | tail -10

# Check Thanos Query
curl http://localhost:19192/api/v1/query?query=up

# Check Store Gateway
curl http://localhost:19193/-/ready

# Check Thanos uploads to R2
curl http://localhost:19191/metrics | grep thanos_objstore_bucket_operations_total
```

Verify Prometheus metrics

```bash
curl http://localhost:9199/metrics | grep thanos
```

### Docker Stats


```bash
./docker-stats.sh 
========================================
Docker Compose Resource Usage Report
Project: k6-support
Timestamp: 2024-10-27 20:56:17 UTC
========================================

Container Resources:
----------------------------------------
NAME                           CPU%     MEMORY               MEM%     NETWORK I/O          BLOCK I/O            PIDS  
k6-support-cloudflare-exporter 0.48%    25.59MiB / 3.48GiB   0.72%    142MB / /            839MB / 1.13MB       10    
k6-support-grafana             1.89%    114.7MiB / 3.48GiB   3.22%    61.5MB / /           385MB / 12.6MB       15    
k6-support-influxdb            0.08%    203.6MiB / 3.48GiB   5.71%    493MB / /            42.8MB / 3.19MB      15    
k6-support-node-exporter       0.00%    9.254MiB / 3.48GiB   0.26%    3.14MB / /           69.7MB / 81.9kB      5     
k6-support-prometheus          1.72%    101.7MiB / 3.48GiB   2.85%    595MB / /            67.5MB / 1.52MB      10    
k6-support-telegraf            0.11%    95.16MiB / 3.48GiB   2.67%    874MB / /            1.03GB / 6.6MB       13    
----------------------------------------
TOTAL                          4.28%    550.004MiB / 3.48GiB 15.43%   2168.64MB / -        2458.72MB / -        68    

Volume Usage:
----------------------------------------
VOLUME                                   SIZE      
k6-support_grafana_data                  5.8M      
k6-support_influxdb_data                 52M       
k6-support_prometheus_data               333M      
----------------------------------------
TOTAL                                    389M  
```
```bash
./docker-stats.sh -json | jq -r
```
```json
{
  "metadata": {
    "project": "k6-support",
    "timestamp": "2024-10-27 20:56:41 UTC"
  },
  "containers": [
    {
      "name": "k6-support-cloudflare-exporter",
      "cpu_percent": "0.01%",
      "memory": "28.2MiB / 3.48GiB",
      "memory_percent": "0.79%",
      "network_io": "142MB / /",
      "block_io": "839MB / 1.13MB",
      "pids": 10
    },
    {
      "name": "k6-support-grafana",
      "cpu_percent": "0.09%",
      "memory": "114.7MiB / 3.48GiB",
      "memory_percent": "3.22%",
      "network_io": "61.5MB / /",
      "block_io": "385MB / 12.6MB",
      "pids": 15
    },
    {
      "name": "k6-support-influxdb",
      "cpu_percent": "0.77%",
      "memory": "215.9MiB / 3.48GiB",
      "memory_percent": "6.06%",
      "network_io": "493MB / /",
      "block_io": "42.8MB / 3.19MB",
      "pids": 15
    },
    {
      "name": "k6-support-node-exporter",
      "cpu_percent": "0.00%",
      "memory": "9.254MiB / 3.48GiB",
      "memory_percent": "0.26%",
      "network_io": "3.15MB / /",
      "block_io": "69.7MB / 81.9kB",
      "pids": 5
    },
    {
      "name": "k6-support-prometheus",
      "cpu_percent": "0.00%",
      "memory": "101.7MiB / 3.48GiB",
      "memory_percent": "2.85%",
      "network_io": "595MB / /",
      "block_io": "67.5MB / 1.52MB",
      "pids": 10
    },
    {
      "name": "k6-support-telegraf",
      "cpu_percent": "0.12%",
      "memory": "88.75MiB / 3.48GiB",
      "memory_percent": "2.49%",
      "network_io": "875MB / /",
      "block_io": "1.04GB / 6.6MB",
      "pids": 13
    },
    {
      "name": "TOTAL",
      "cpu_percent": "0.99%",
      "memory": "- / 3.48GiB",
      "memory_percent": "15.67%",
      "network_io": "2169.65MB / -",
      "block_io": "2468.96MB / -",
      "pids": 68
    }
  ],
  "volumes": [
    {
      "name": "k6-support_grafana_data",
      "size": "5.8M"
    },
    {
      "name": "k6-support_influxdb_data",
      "size": "52M"
    },
    {
      "name": "k6-support_prometheus_data",
      "size": "334M"
    },
    {
      "name": "TOTAL",
      "size": "390M"
    }
  ]
}
```

```bash
docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          8         6         2.483GB   923.8MB (37%)
Containers      6         6         152B      0B (0%)
Local Volumes   4         4         404.8MB   0B (0%)
Build Cache     0         0         0B        0B
```
```bash
docker stats --no-stream k6-support-grafana
CONTAINER ID   NAME                 CPU %     MEM USAGE / LIMIT   MEM %     NET I/O          BLOCK I/O         PIDS
82e473e4c0be   k6-support-grafana   0.25%     115MiB / 3.48GiB    3.23%     61.4MB / 385MB   12.6MB / 22.1MB   15

docker stats --no-stream k6-support-influxdb
CONTAINER ID   NAME                  CPU %     MEM USAGE / LIMIT    MEM %     NET I/O          BLOCK I/O         PIDS
8e64ff36506d   k6-support-influxdb   0.05%     135.7MiB / 3.48GiB   3.81%     464MB / 40.2MB   3.19MB / 1.32GB   15

docker stats --no-stream k6-support-telegraf
CONTAINER ID   NAME                  CPU %     MEM USAGE / LIMIT    MEM %     NET I/O         BLOCK I/O     PIDS
08b67cb3778c   k6-support-telegraf   0.13%     81.08MiB / 3.48GiB   2.28%     822MB / 977MB   5.29MB / 0B   13

docker stats --no-stream k6-support-prometheus
CONTAINER ID   NAME                    CPU %     MEM USAGE / LIMIT    MEM %     NET I/O          BLOCK I/O        PIDS
12964b94d6d8   k6-support-prometheus   0.00%     103.8MiB / 3.48GiB   2.91%     564MB / 66.7MB   1.52MB / 649MB   10

docker stats --no-stream k6-support-node-exporter
CONTAINER ID   NAME                       CPU %     MEM USAGE / LIMIT    MEM %     NET I/O           BLOCK I/O     PIDS
e08350e2205f   k6-support-node-exporter   0.00%     9.227MiB / 3.48GiB   0.26%     3.01MB / 66.8MB   81.9kB / 0B   5

docker stats --no-stream k6-support-cloudflare-exporter
CONTAINER ID   NAME                             CPU %     MEM USAGE / LIMIT    MEM %     NET I/O         BLOCK I/O     PIDS
64f720b21834   k6-support-cloudflare-exporter   0.00%     27.18MiB / 3.48GiB   0.76%     136MB / 790MB   1.13MB / 0B   10
```
```bash
docker volume ls
DRIVER    VOLUME NAME
local     1a900e1bb079136b7c850f16d083e3c9648e3932946febe0d6decc05dbd30213
local     k6-support_grafana_data
local     k6-support_influxdb_data
local     k6-support_prometheus_data
```
```bash
docker volume inspect k6-support_grafana_data
[
    {
        "CreatedAt": "2024-10-27T05:19:12Z",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "k6-support",
            "com.docker.compose.version": "2.29.7",
            "com.docker.compose.volume": "grafana_data"
        },
        "Mountpoint": "/var/lib/docker/volumes/k6-support_grafana_data/_data",
        "Name": "k6-support_grafana_data",
        "Options": null,
        "Scope": "local"
    }
]

docker volume inspect k6-support_influxdb_data 
[
    {
        "CreatedAt": "2024-10-27T05:19:12Z",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "k6-support",
            "com.docker.compose.version": "2.29.7",
            "com.docker.compose.volume": "influxdb_data"
        },
        "Mountpoint": "/var/lib/docker/volumes/k6-support_influxdb_data/_data",
        "Name": "k6-support_influxdb_data",
        "Options": null,
        "Scope": "local"
    }
]

docker volume inspect k6-support_prometheus_data 
[
    {
        "CreatedAt": "2024-10-27T05:19:12Z",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "k6-support",
            "com.docker.compose.version": "2.29.7",
            "com.docker.compose.volume": "prometheus_data"
        },
        "Mountpoint": "/var/lib/docker/volumes/k6-support_prometheus_data/_data",
        "Name": "k6-support_prometheus_data",
        "Options": null,
        "Scope": "local"
    }
]
```
```bash
docker compose top
k6-support-cloudflare-exporter
UID    PID      PPID     C    STIME   TTY   TIME       CMD
root   848151   848067   0    05:19   ?     00:08:28   ./cloudflare_exporter   

k6-support-grafana
UID   PID      PPID     C    STIME   TTY   TIME       CMD
472   850655   850634   0    05:21   ?     00:03:25   grafana server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini --packaging=docker cfg:default.log.mode=console cfg:default.paths.data=/var/lib/grafana cfg:default.paths.logs=/var/log/grafana cfg:default.paths.plugins=/var/lib/grafana/plugins cfg:default.paths.provisioning=/etc/grafana/provisioning   

k6-support-influxdb
UID    PID      PPID     C    STIME   TTY   TIME       CMD
1000   848163   848100   1    05:19   ?     00:09:32   influxd   

k6-support-node-exporter
UID      PID      PPID     C    STIME   TTY   TIME       CMD
nobody   848123   848042   0    05:19   ?     00:01:52   /bin/node_exporter --path.procfs=/host/proc --path.rootfs=/rootfs --path.sysfs=/host/sys --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($|/)   

k6-support-prometheus
UID      PID      PPID     C    STIME   TTY   TIME       CMD
nobody   848166   848088   0    05:19   ?     00:04:43   /bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles --web.enable-lifecycle --log.level=debug   

k6-support-telegraf
UID        PID      PPID     C    STIME   TTY   TIME       CMD
systemd+   849452   849409   3    05:20   ?     00:33:05   telegraf   
```

## 5. Post-Installation Steps

### Access Grafana
1. Open web browser and navigate to `http://your-server-ip:9409`
2. Login with default credentials:
   - Username: `admin`
   - Password: `admin`
3. Change the default password when prompted

### Import Cloudflare Dashboards
1. In Grafana, go to `+ > Import`
2. Import the following dashboard IDs or use default dashboards:
   - Cloudflare Analytics Dashboard: 22131
   - Cloudflare Firewall Analytics: 22154

### Verify Data Collection
1. Check InfluxDB status:
```bash
curl -I http://localhost:8186/ping
```

2. Check Prometheus targets:
```bash
curl http://localhost:9199/metrics
```

## 6. Maintenance Tasks

### Backup Configuration
```bash
# Create backup directory
mkdir -p /home/cloudflare-monitoring-backup

# Backup configurations
cp -r config /home/cloudflare-monitoring-backup/
cp docker-compose.yml /home/cloudflare-monitoring-backup/
cp .env /home/cloudflare-monitoring-backup/
```

### Update Stack
```bash
# Pull latest images
docker compose pull

# Restart stack with new images
docker compose up -d
```

### Monitor Logs
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f grafana
docker compose logs -f influxdb
docker compose logs -f cloudflare-exporter
```

## 7. Troubleshooting

### Check Service Status
```bash
# Check all containers
docker compose ps

# Check specific container logs
docker compose logs [service-name]

# Restart specific service
docker compose restart [service-name]
```

### Common Issues and Solutions

1. If InfluxDB fails to start:
```bash
# Check permissions
sudo chown -R 1000:1000 $(pwd)/config/influxdb
```

2. If Grafana can't connect to InfluxDB:
```bash
# Verify network connectivity
docker compose exec grafana ping influxdb

# Check InfluxDB logs
docker compose logs influxdb
```

3. If Cloudflare metrics are missing:
```bash
# Verify API token
docker compose logs cloudflare-exporter

# Check rate limits
curl -H "Authorization: Bearer $CF_API_TOKEN" https://api.cloudflare.com/client/v4/user/tokens/verify
```

## 8. Security Considerations

1. Update firewall rules to only allow necessary access:
```bash
# Restrict Grafana access to specific IPs
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="trusted-ip/32" port port="9409" protocol="tcp" accept'
```

2. Set up SSL/TLS:
- Configure Nginx/Apache as a reverse proxy
- Use Let's Encrypt for SSL certificates
- Update Grafana configuration to use HTTPS

3. Regular updates:
```bash
# Update system
sudo dnf update -y

# Update Docker images
docker compose pull
docker compose up -d
```

## 9. Updating Grafana

To update Grafana from version 11.2.2 to 11.3.0 in your Docker Compose setup, you’ll need to modify the version in your Docker Compose YAML file and pull the updated image. Here’s how:

1. **Edit the Docker Compose File**:
   - Open your `docker-compose.yml` file and locate the Grafana service definition:
   ```yaml
   services:
     grafana:
       image: grafana/grafana-oss:11.2.2  # Old version
       ...
   ```
   - Update the image tag to `11.3.0`:
   ```yaml
   services:
     grafana:
       image: grafana/grafana-oss:11.3.0  # New version
       ...
   ```

2. **Pull the New Grafana Image**:
   - Before recreating the container, pull the updated image to ensure Docker uses the correct version:
   ```bash
   docker compose pull grafana
   ```

3. **Recreate the Grafana Container**:
   - Now, update only the Grafana container to avoid stopping other services:
   ```bash
   docker compose up -d --no-deps --force-recreate grafana
   ```
   This command will restart the Grafana container with the new version (11.3.0) while leaving other containers unaffected.

4. **Verify the Update**:
   - Confirm the update by checking the version in the Grafana UI or by running:
   ```bash
   docker compose exec grafana grafana server -v
   Version 11.3.0 (commit: d9455ff7db73b694db7d412e49a68bec767f2b5a, branch: HEAD)
   ```

This will update Grafana to version 11.2.2 in your existing Docker Compose setup without disrupting other services.

## 10. Cloudflared Tunnel Metrics

To expose the metrics from `cloudflared` to your Docker-based Prometheus setup, you can follow these steps to configure `cloudflared` at https://developers.cloudflare.com/cloudflare-one/tutorials/grafana/ and https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/remote-management/#add-tunnel-run-parameters.

For Prometheus to ensure that metrics are accessible:

### Step 1: Configure Cloudflared with Metrics Binding

Run `cloudflared` with the `--metrics` option to bind it to an IP and port accessible by your Docker Prometheus instance. For example:

```bash
cloudflared tunnel --metrics 172.17.0.1:8083 --edge-ip-version 4 --no-autoupdate run <UUID or NAME>
```

In this example:
- `0.0.0.0:8083` exposes the metrics endpoint on all IP addresses, making it accessible from other containers.
- Replace `<UUID or NAME>` with your actual tunnel identifier.

Using Systemd

```bash
sudo systemctl edit --full cloudflared.service
```
```bash
sudo systemctl restart cloudflared
sudo systemctl status cloudflared --no-pager -l
```

```bash
docker inspect k6-support-prometheus | jq -r '.[0].NetworkSettings.Networks."k6-support".IPAddress'
172.18.0.5
```
```bash
csf -a $(docker inspect k6-support-prometheus | jq -r '.[0].NetworkSettings.Networks."k6-support".IPAddress') prometheus
```

### Step 2: Update Prometheus Configuration
You’ll need to add a new scrape job in your Prometheus configuration to collect metrics from the `cloudflared` metrics endpoint.

1. Open your Prometheus configuration file (usually `prometheus.yml` i.e. `./config/prometheus/prometheus.yml`).
2. Add a new scrape job for `cloudflared`:

```yaml
scrape_configs:
  - job_name: 'cloudflared'
    scrape_interval: 5s
    scrape_timeout: 4s
    static_configs:
      - targets: ['host.docker.internal:8083']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '(.*):(.*)'
        replacement: '${1}'
```

example full config:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  external_labels:
    monitor: "k6-support"

# Rule files
rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: "prometheus"
    scrape_interval: 5s
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter"
    scrape_interval: 10s
    scrape_timeout: 10s
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: 'cloudflare'
    metrics_path: '/metrics'
    scrape_interval: 5m
    scrape_timeout: 30s
    static_configs:
      - targets: ['cloudflare-exporter:8080']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'cloudflare'

  - job_name: 'telegraf'
    scrape_interval: 5s
    scrape_timeout: 4s
    dns_sd_configs:
      - names: ['telegraf']
        type: 'A'
        port: 9273
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '(.*):(.*)'
        replacement: '${1}'

  - job_name: 'cloudflared'
    scrape_interval: 5s
    scrape_timeout: 4s
    static_configs:
      - targets: ['host.docker.internal:8083']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '(.*):(.*)'
        replacement: '${1}'
```

- **`host.docker.internal`**: Allows Docker containers to access services running on the host machine. If `host.docker.internal` is not supported, replace it with the host IP.
- **`8083`**: The port where `cloudflared` is exposing metrics.

3. Save the changes.

### Step 3: Reload Prometheus

After updating `prometheus.yml`, reload Prometheus to apply the changes.

- If using Docker Compose, you can reload Prometheus with:

```bash
csf -a $(docker inspect k6-support-prometheus | jq -r '.[0].NetworkSettings.Networks."k6-support".IPAddress') prometheus

docker compose restart prometheus
```
```bash
docker logs k6-support-prometheus 2>&1 | tail -10
```
```bash
docker exec -it k6-support-prometheus sh -c "wget -qO- http://172.17.0.1:8083/metrics | tail -10"
quic_client_sent_frames{conn_index="3",frame_type="Stream"} 32
# HELP quic_client_smoothed_rtt Calculated smoothed RTT measured on a connection in millisec
# TYPE quic_client_smoothed_rtt gauge
quic_client_smoothed_rtt{conn_index="0"} 1
quic_client_smoothed_rtt{conn_index="1"} 0
quic_client_smoothed_rtt{conn_index="2"} 1
quic_client_smoothed_rtt{conn_index="3"} 1
# HELP quic_client_total_connections Number of connections initiated
# TYPE quic_client_total_connections counter
quic_client_total_connections 10
```

Prometheus should now scrape metrics from `cloudflared`, accessible at `host.docker.internal:8083/metrics`, or whichever IP and port you configured.