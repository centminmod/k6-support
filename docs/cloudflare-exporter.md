```bash
docker exec k6-support-cloudflare-exporter curl -s localhost:8080/metrics | grep HELP
# HELP cloudflare_exporter_build_info A metric with a constant '1' value labeled by version, revision, branch, and goversion from which the cloudflare_exporter was built.
# HELP cloudflare_logpush_failed_jobs_zone_count Number of failed logpush jobs on the zone level
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
# HELP cloudflare_zone_pool_health_status Reports the health of a pool, 1 for healthy, 0 for unhealthy.
# HELP cloudflare_zone_pool_requests_total Requests per pool
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
# HELP cloudflare_zone_threats_type Threats per zone per type
# HELP cloudflare_zone_uniques_total Uniques per zone
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# HELP go_goroutines Number of goroutines that currently exist.
# HELP go_info Information about the Go environment.
# HELP go_memstats_alloc_bytes Number of bytes allocated and still in use.
# HELP go_memstats_alloc_bytes_total Total number of bytes allocated, even if freed.
# HELP go_memstats_buck_hash_sys_bytes Number of bytes used by the profiling bucket hash table.
# HELP go_memstats_frees_total Total number of frees.
# HELP go_memstats_gc_sys_bytes Number of bytes used for garbage collection system metadata.
# HELP go_memstats_heap_alloc_bytes Number of heap bytes allocated and still in use.
# HELP go_memstats_heap_idle_bytes Number of heap bytes waiting to be used.
# HELP go_memstats_heap_inuse_bytes Number of heap bytes that are in use.
# HELP go_memstats_heap_objects Number of allocated objects.
# HELP go_memstats_heap_released_bytes Number of heap bytes released to OS.
# HELP go_memstats_heap_sys_bytes Number of heap bytes obtained from system.
# HELP go_memstats_last_gc_time_seconds Number of seconds since 1970 of last garbage collection.
# HELP go_memstats_lookups_total Total number of pointer lookups.
# HELP go_memstats_mallocs_total Total number of mallocs.
# HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures.
# HELP go_memstats_mcache_sys_bytes Number of bytes used for mcache structures obtained from system.
# HELP go_memstats_mspan_inuse_bytes Number of bytes in use by mspan structures.
# HELP go_memstats_mspan_sys_bytes Number of bytes used for mspan structures obtained from system.
# HELP go_memstats_next_gc_bytes Number of heap bytes when next garbage collection will take place.
# HELP go_memstats_other_sys_bytes Number of bytes used for other system allocations.
# HELP go_memstats_stack_inuse_bytes Number of bytes in use by the stack allocator.
# HELP go_memstats_stack_sys_bytes Number of bytes obtained from system for stack allocator.
# HELP go_memstats_sys_bytes Number of bytes obtained from system.
# HELP go_threads Number of OS threads created.
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
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
```bash
pushd /home/cloudflare-monitoring/k6-support/
/home/cloudflare-monitoring/k6-support ~

docker compose ps
NAME                             IMAGE                                  COMMAND                  SERVICE               CREATED        STATUS                  PORTS
k6-support-cloudflare-exporter   cyb3rjak3/cloudflare-exporter:latest   "./cloudflare_export…"   cloudflare-exporter   10 hours ago   Up 10 hours (healthy)   0.0.0.0:9198->8080/tcp, [::]:9198->8080/tcp
k6-support-grafana               grafana/grafana-oss:10.2.0             "/run.sh"                grafana               10 hours ago   Up 9 hours (healthy)    0.0.0.0:9409->3000/tcp, [::]:9409->3000/tcp
k6-support-influxdb              influxdb:2.7                           "/entrypoint.sh infl…"   influxdb              10 hours ago   Up 10 hours (healthy)   0.0.0.0:8186->8086/tcp, [::]:8186->8086/tcp
k6-support-node-exporter         prom/node-exporter:latest              "/bin/node_exporter …"   node-exporter         10 hours ago   Up 10 hours             0.0.0.0:9100->9100/tcp, :::9100->9100/tcp
k6-support-prometheus            prom/prometheus:latest                 "/bin/prometheus --c…"   prometheus            10 hours ago   Up 10 hours (healthy)   0.0.0.0:9199->9090/tcp, [::]:9199->9090/tcp
k6-support-telegraf              telegraf:1.27                          "/entrypoint.sh tele…"   telegraf              10 hours ago   Up 10 hours (healthy)   8092/udp, 8094/tcp, 127.0.0.1:8125->8125/udp, 0.0.0.0:9273->9273/tcp, :::9273->9273/tcp
```
