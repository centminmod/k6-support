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