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
```bash
cp -a example.env .env
DOCKER_GID=$(getent group docker | cut -d: -f3)
echo "DOCKER_GROUP_ID=$DOCKER_GID" >> .env
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
INFLUX_TOKEN=your-super-secret-admin-token
DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=your-super-secret-admin-token

# Telegraf
TELEGRAF_INFLUXDB_USER=telegraf
TELEGRAF_INFLUXDB_PASSWORD=password

# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin

# Cloudflare Configuration
CF_API_TOKEN=your-cloudflare-api-token
CF_ZONES=your-zone-ids  # Comma-separated list of zone IDs

# User Credentials (for v1 compatibility)
INFLUXDB_TELEGRAF_USER=telegraf
INFLUXDB_TELEGRAF_PASSWORD=password
INFLUXDB_K6_USER=k6
INFLUXDB_K6_PASSWORD=k6
INFLUXDB_PSRECORD_USER=psrecord
INFLUXDB_PSRECORD_PASSWORD=password

# Database Names (for v1 compatibility)
INFLUXDB_DB_K6=k6
INFLUXDB_DB_TELEGRAF=telegraf
INFLUXDB_DB_PSRECORD=psrecord

# Network Configuration (if needed)
DOCKER_INFLUXDB_INIT_HOST=influxdb
DOCKER_INFLUXDB_INIT_PORT=8086
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
```
```bash
docker compose up -d
[+] Running 10/10
 ✔ Network k6-support_k6-support             Created                                                                                                                                      0.1s 
 ✔ Volume "k6-support_influxdb_data"         Created                                                                                                                                      0.0s 
 ✔ Volume "k6-support_grafana_data"          Created                                                                                                                                      0.0s 
 ✔ Volume "k6-support_prometheus_data"       Created                                                                                                                                      0.0s 
 ✔ Container k6-support-prometheus           Healthy                                                                                                                                      5.9s 
 ✔ Container k6-support-influxdb             Healthy                                                                                                                                      5.9s 
 ✔ Container k6-support-node-exporter        Started                                                                                                                                      0.4s 
 ✔ Container k6-support-cloudflare-exporter  Healthy                                                                                                                                      5.9s 
 ✔ Container k6-support-grafana              Started                                                                                                                                      6.0s 
 ✔ Container k6-support-telegraf             Started                                                                                                                                      6.1s 
```
```bash
docker compose restart grafana
[+] Restarting 1/1
 ✔ Container k6-support-grafana  Started                                                                                                                                                  0.3s
```
```bash
docker exec -it k6-support-influxdb env | grep INFLUX_TOKEN
INFLUX_TOKEN=your-super-secret-admin-token
```
```bash
docker compose ps
NAME                             IMAGE                                  COMMAND                  SERVICE               CREATED         STATUS                          PORTS
k6-support-cloudflare-exporter   cyb3rjak3/cloudflare-exporter:latest   "./cloudflare_export…"   cloudflare-exporter   2 minutes ago   Up 2 minutes (healthy)          0.0.0.0:9198->8080/tcp, [::]:9198->8080/tcp
k6-support-grafana               grafana/grafana-oss:10.2.0             "/run.sh"                grafana               2 minutes ago   Restarting (1) 34 seconds ago   
k6-support-influxdb              influxdb:2.7                           "/entrypoint.sh infl…"   influxdb              2 minutes ago   Up 2 minutes (healthy)          0.0.0.0:8186->8086/tcp, [::]:8186->8086/tcp
k6-support-node-exporter         prom/node-exporter:latest              "/bin/node_exporter …"   node-exporter         2 minutes ago   Up 2 minutes (unhealthy)        0.0.0.0:9100->9100/tcp, :::9100->9100/tcp
k6-support-prometheus            prom/prometheus:latest                 "/bin/prometheus --c…"   prometheus            2 minutes ago   Up 2 minutes (healthy)          0.0.0.0:9199->9090/tcp, [::]:9199->9090/tcp
k6-support-telegraf              telegraf:1.28                          "/entrypoint.sh tele…"   telegraf              2 minutes ago   Up 2 minutes (healthy)          8092/udp, 8094/tcp, 127.0.0.1:8125->8125/udp
```

Verify InfluxDB buckets

```bash
docker exec k6-support-influxdb influx bucket list --org "${DOCKER_INFLUXDB_INIT_ORG}" --token "${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}"
ID                      Name            Retention       Shard group duration    Organization ID         Schema Type
6e29b8a0bf71b29b        _monitoring     168h0m0s        24h0m0s                 e857a5cb1339ebee        implicit
9c9ebc5f4abd1aa4        _tasks          72h0m0s         24h0m0s                 e857a5cb1339ebee        implicit
2efc254b93acfb3b        cloudflare      36000h0m0s      168h0m0s                e857a5cb1339ebee        implicit
beaa607362be800d        k6              36000h0m0s      168h0m0s                e857a5cb1339ebee        implicit
f628584639bd3f16        psrecord        36000h0m0s      168h0m0s                e857a5cb1339ebee        implicit
6bb8e15461558546        telegraf        36000h0m0s      168h0m0s                e857a5cb1339ebee        implicit
```

```bash
docker logs k6-support-grafana | tail -10

```
```bash
docker logs k6-support-prometheus 2>&1 | tail -10
ts=2024-10-27T05:19:13.043Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=static/1 subs=[cloudflare]
ts=2024-10-27T05:19:13.044Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=dns/2 subs=[telegraf]
ts=2024-10-27T05:19:13.044Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=static/3 subs=[prometheus]
ts=2024-10-27T05:19:13.044Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/3
ts=2024-10-27T05:19:13.044Z caller=main.go:1441 level=info msg="updated GOGC" old=100 new=75
ts=2024-10-27T05:19:13.044Z caller=main.go:1452 level=info msg="Completed loading of configuration file" filename=/etc/prometheus/prometheus.yml totalDuration=1.254039ms db_storage=912ns remote_storage=1.393µs web_handler=311ns query_engine=811ns scrape=254.288µs scrape_sd=466.737µs notify=811ns notify_sd=901ns rules=14.728µs tracing=4.799µs
ts=2024-10-27T05:19:13.044Z caller=main.go:1182 level=info msg="Server is ready to receive web requests."
ts=2024-10-27T05:19:13.044Z caller=manager.go:164 level=info component="rule manager" msg="Starting rule manager..."
ts=2024-10-27T05:19:13.044Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/1
ts=2024-10-27T05:19:13.044Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/0
[05:20][root@alma-4gb-ash-grafana1 k6-support]# docker logs k6-support-prometheus 2>&1 | tail -10
ts=2024-10-27T05:19:13.043Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=static/1 subs=[cloudflare]
ts=2024-10-27T05:19:13.044Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=dns/2 subs=[telegraf]
ts=2024-10-27T05:19:13.044Z caller=manager.go:170 level=debug component="discovery manager scrape" msg="Starting provider" provider=static/3 subs=[prometheus]
ts=2024-10-27T05:19:13.044Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/3
ts=2024-10-27T05:19:13.044Z caller=main.go:1441 level=info msg="updated GOGC" old=100 new=75
ts=2024-10-27T05:19:13.044Z caller=main.go:1452 level=info msg="Completed loading of configuration file" filename=/etc/prometheus/prometheus.yml totalDuration=1.254039ms db_storage=912ns remote_storage=1.393µs web_handler=311ns query_engine=811ns scrape=254.288µs scrape_sd=466.737µs notify=811ns notify_sd=901ns rules=14.728µs tracing=4.799µs
ts=2024-10-27T05:19:13.044Z caller=main.go:1182 level=info msg="Server is ready to receive web requests."
ts=2024-10-27T05:19:13.044Z caller=manager.go:164 level=info component="rule manager" msg="Starting rule manager..."
ts=2024-10-27T05:19:13.044Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/1
ts=2024-10-27T05:19:13.044Z caller=manager.go:188 level=debug component="discovery manager scrape" msg="Discoverer channel closed" provider=static/0
```
```bash
docker logs k6-support-influxdb | tail -10
2024-10-27T00:59:50.397254143Z  info    booting influxd server in the background        {"system": "docker"}
2024-10-27T00:59:51.400452667Z  info    pinging influxd...      {"system": "docker", "ping_attempt": "0"}
2024-10-27T00:59:51.410607374Z  info    got response from influxd, proceeding   {"system": "docker", "total_pings": "1"}
2024-10-27T00:59:51.519939513Z  info    Executing user-provided scripts {"system": "docker", "script_dir": "/docker-entrypoint-initdb.d"}
2024-10-27T00:59:51.521692370Z  info    initialization complete, shutting down background influxd       {"system": "docker"}
2024-10-27T00:59:51.607440735Z  info    found existing boltdb file, skipping setup wrapper      {"system": "docker", "bolt_path": "/var/lib/influxdb2/influxd.bolt"}
ts=2024-10-27T00:59:51.702563Z lvl=info msg="Using data dir" log_id=0sUscr4W000 service=storage-engine service=store path=/var/lib/influxdb2/engine/data
ts=2024-10-27T00:59:51.702585Z lvl=info msg="Compaction settings" log_id=0sUscr4W000 service=storage-engine service=store max_concurrent_compactions=1 throughput_bytes_per_second=50331648 throughput_bytes_per_second_burst=50331648
ts=2024-10-27T00:59:51.702593Z lvl=info msg="Open store (start)" log_id=0sUscr4W000 service=storage-engine service=store op_name=tsdb_open op_event=start
ts=2024-10-27T00:59:51.702652Z lvl=info msg="Open store (end)" log_id=0sUscr4W000 service=storage-engine service=store op_name=tsdb_open op_event=end op_elapsed=0.060ms
ts=2024-10-27T00:59:51.702678Z lvl=info msg="Starting retention policy enforcement service" log_id=0sUscr4W000 service=retention check_interval=30m
ts=2024-10-27T00:59:51.702691Z lvl=info msg="Starting precreation service" log_id=0sUscr4W000 service=shard-precreation check_interval=10m advance_period=30m
ts=2024-10-27T00:59:51.703340Z lvl=info msg="Starting query controller" log_id=0sUscr4W000 service=storage-reads concurrency_quota=1024 initial_memory_bytes_quota_per_query=9223372036854775807 memory_bytes_quota_per_query=9223372036854775807 max_memory_bytes=0 queue_size=1024
ts=2024-10-27T00:59:51.706165Z lvl=info msg="Configuring InfluxQL statement executor (zeros indicate unlimited)." log_id=0sUscr4W000 max_select_point=0 max_select_series=0 max_select_buckets=0
ts=2024-10-27T00:59:51.711304Z lvl=info msg=Starting log_id=0sUscr4W000 service=telemetry interval=8h
ts=2024-10-27T00:59:51.711475Z lvl=info msg=Listening log_id=0sUscr4W000 service=tcp-listener transport=http addr=:8086 port=8086
```
```bash
docker logs k6-support-cloudflare-exporter  | tail -10
time="2024-10-27 00:59:50" level=info msg="Beginning to serve metrics on :8080/metrics"
time="2024-10-27 00:59:51" level=info msg="Filtering zone: xxxx domain-zone.com"
time="2024-10-27 01:00:50" level=info msg="Filtering zone: xxxx domain-zone.com"
```
```bash
docker compose logs telegraf | tail -100
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Loading config: /etc/telegraf/telegraf.conf
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Loading config: /etc/telegraf/telegraf.d/docker.conf
k6-support-telegraf  | 2024-10-27T00:59:56Z W! DeprecationWarning: Option "perdevice" of plugin "inputs.docker" deprecated since version 1.18.0 and will be removed in 2.0.0: use 'perdevice_include' instead
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Starting Telegraf 1.28.5 brought to you by InfluxData the makers of InfluxDB
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Available plugins: 240 inputs, 9 aggregators, 29 processors, 24 parsers, 59 outputs, 5 secret-stores
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Loaded inputs: cpu disk diskio docker http_response interrupts kernel linux_sysctl_fs mem net netstat processes prometheus statsd swap system
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Loaded aggregators: 
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Loaded processors: 
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Loaded secretstores: 
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Loaded outputs: influxdb influxdb_v2
k6-support-telegraf  | 2024-10-27T00:59:56Z I! Tags enabled: host=d4f3cda7e979
k6-support-telegraf  | 2024-10-27T00:59:56Z W! Deprecated inputs: 0 and 1 options
k6-support-telegraf  | 2024-10-27T00:59:56Z I! [agent] Config: Interval:5s, Quiet:false, Hostname:"d4f3cda7e979", Flush Interval:1s
k6-support-telegraf  | 2024-10-27T00:59:56Z W! DeprecationWarning: Value "false" for option "ignore_protocol_stats" of plugin "inputs.net" deprecated since version 1.27.3 and will be removed in 1.36.0: use the 'inputs.nstat' plugin instead
k6-support-telegraf  | 2024-10-27T00:59:56Z I! [inputs.prometheus] Using the label selector:  and field selector: 
k6-support-telegraf  | 2024-10-27T00:59:56Z I! [inputs.statsd] UDP listening on "[::]:8125"
k6-support-telegraf  | 2024-10-27T00:59:56Z I! [inputs.statsd] Started the statsd service on ":8125"
```
```bash
docker exec k6-support-cloudflare-exporter curl -s localhost:8080/metrics | grep zone | grep HELP
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