```bash
./docker-stats.sh 
========================================
Docker Compose Resource Usage Report
Project: k6-support
Timestamp: 2024-10-31 09:01:50 UTC
========================================

Container Resources:
----------------------------------------
NAME                           CPU%     MEMORY               MEM%     NETWORK I/O          BLOCK I/O            PIDS  
k6-support-alertmanager        0.42%    17.09MiB / 256MiB    6.67%    4.57kB / /           27.3kB / 0B          8     
k6-support-cloudflare-exporter 0.83%    11.24MiB / 2GiB      0.55%    265kB / /            74.1kB / 0B          7     
k6-support-grafana             0.03%    60.85MiB / 2GiB      2.97%    8.94MB / /           49.9kB / 0B          13    
k6-support-influxdb            0.04%    50.25MiB / 2GiB      2.45%    25.8kB / /           4.37kB / 77.8kB      9     
k6-support-node-exporter       0.00%    7.43MiB / 2GiB       0.36%    7.07kB / /           103kB / 0B           5     
k6-support-prometheus          0.10%    30.62MiB / 2GiB      1.49%    211kB / /            22.1kB / 12.3kB      8     
k6-support-telegraf            5.31%    51.95MiB / 2GiB      2.54%    70.1kB / /           50.5kB / 0B          9     
k6-support-thanos-compactor    2.86%    14.33MiB / 2GiB      0.70%    10.3kB / /           6.86kB / 0B          7     
k6-support-thanos-query        0.00%    11.93MiB / 2GiB      0.58%    13.9kB / /           14kB / 0B            7     
k6-support-thanos-sidecar      0.00%    12.09MiB / 2GiB      0.59%    13kB / /             8.15kB / 0B          7     
k6-support-thanos-store-gateway 0.00%    14.37MiB / 2GiB      0.70%    15kB / /             8.86kB / 81.9kB      7     
----------------------------------------
TOTAL                          9.59%    282.15MiB / 256MiB   19.60%   8.94MB / -           0.00MB / -           87    

Volume Usage:
----------------------------------------
VOLUME                                   SIZE      
k6-support_alertmanager_data             4.0K      
k6-support_grafana_data                  19M       
k6-support_grafana_wal                   4.0K      
k6-support_influxdb_data                 664K      
k6-support_prometheus_data               332K      
k6-support_thanos_compactor_data         8.0K      
k6-support_thanos_query_data             4.0K      
k6-support_thanos_sidecar_data           4.0K      
----------------------------------------
TOTAL                                    19M       
```
```bash
./docker-stats.sh -json | jq -r
```
```json
{
  "metadata": {
    "project": "k6-support",
    "timestamp": "2024-10-31 09:02:40 UTC"
  },
  "containers": [
    {
      "name": "k6-support-alertmanager",
      "cpu_percent": "2.00%",
      "memory": "17.25MiB / 256MiB",
      "memory_percent": "6.74%",
      "network_io": "6.16kB / /",
      "block_io": "43.6kB / 0B",
      "pids": 8
    },
    {
      "name": "k6-support-cloudflare-exporter",
      "cpu_percent": "0.04%",
      "memory": "11.78MiB / 2GiB",
      "memory_percent": "0.58%",
      "network_io": "403kB / /",
      "block_io": "220kB / 0B",
      "pids": 7
    },
    {
      "name": "k6-support-grafana",
      "cpu_percent": "0.06%",
      "memory": "63.66MiB / 2GiB",
      "memory_percent": "3.11%",
      "network_io": "9.01MB / /",
      "block_io": "103kB / 0B",
      "pids": 13
    },
    {
      "name": "k6-support-influxdb",
      "cpu_percent": "0.06%",
      "memory": "72.62MiB / 2GiB",
      "memory_percent": "3.55%",
      "network_io": "137kB / /",
      "block_io": "10.2kB / 77.8kB",
      "pids": 12
    },
    {
      "name": "k6-support-node-exporter",
      "cpu_percent": "0.00%",
      "memory": "8.035MiB / 2GiB",
      "memory_percent": "0.39%",
      "network_io": "10.2kB / /",
      "block_io": "168kB / 0B",
      "pids": 5
    },
    {
      "name": "k6-support-prometheus",
      "cpu_percent": "2.00%",
      "memory": "39.78MiB / 2GiB",
      "memory_percent": "1.94%",
      "network_io": "547kB / /",
      "block_io": "39.7kB / 12.3kB",
      "pids": 9
    },
    {
      "name": "k6-support-telegraf",
      "cpu_percent": "14.95%",
      "memory": "69.14MiB / 2GiB",
      "memory_percent": "3.38%",
      "network_io": "230kB / /",
      "block_io": "404kB / 0B",
      "pids": 9
    },
    {
      "name": "k6-support-thanos-compactor",
      "cpu_percent": "0.00%",
      "memory": "14.61MiB / 2GiB",
      "memory_percent": "0.71%",
      "network_io": "11.3kB / /",
      "block_io": "7.83kB / 0B",
      "pids": 7
    },
    {
      "name": "k6-support-thanos-query",
      "cpu_percent": "0.14%",
      "memory": "12.1MiB / 2GiB",
      "memory_percent": "0.59%",
      "network_io": "20kB / /",
      "block_io": "21kB / 0B",
      "pids": 7
    },
    {
      "name": "k6-support-thanos-sidecar",
      "cpu_percent": "0.00%",
      "memory": "12.29MiB / 2GiB",
      "memory_percent": "0.60%",
      "network_io": "18.7kB / /",
      "block_io": "12.5kB / 0B",
      "pids": 7
    },
    {
      "name": "k6-support-thanos-store-gateway",
      "cpu_percent": "1.81%",
      "memory": "14.07MiB / 2GiB",
      "memory_percent": "0.69%",
      "network_io": "18.2kB / /",
      "block_io": "11.1kB / 81.9kB",
      "pids": 7
    },
    {
      "name": "TOTAL",
      "cpu_percent": "21.06%",
      "memory": "- / 256MiB",
      "memory_percent": "22.28%",
      "network_io": "9.01MB / -",
      "block_io": "0.00MB / -",
      "pids": 91
    }
  ],
  "volumes": [
    {
      "name": "k6-support_alertmanager_data",
      "size": "4.0K"
    },
    {
      "name": "k6-support_grafana_data",
      "size": "19M"
    },
    {
      "name": "k6-support_grafana_wal",
      "size": "4.0K"
    },
    {
      "name": "k6-support_influxdb_data",
      "size": "920K"
    },
    {
      "name": "k6-support_prometheus_data",
      "size": "532K"
    },
    {
      "name": "k6-support_thanos_compactor_data",
      "size": "8.0K"
    },
    {
      "name": "k6-support_thanos_query_data",
      "size": "4.0K"
    },
    {
      "name": "k6-support_thanos_sidecar_data",
      "size": "4.0K"
    },
    {
      "name": "TOTAL",
      "size": "19M"
    }
  ]
}
```