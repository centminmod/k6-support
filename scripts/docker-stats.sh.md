```bash
./docker-stats.sh 
========================================
Docker Compose Resource Usage Report
Project: k6-support
Timestamp: 2024-10-27 20:30:16 UTC
========================================

Container Resources:
----------------------------------------
NAME                           CPU%     MEMORY               MEM%     NETWORK I/O          BLOCK I/O            PIDS  
k6-support-cloudflare-exporter 0.41%    28.08MiB / 3.48GiB   0.79%    138MB /              806MB 1.13MB         /     
k6-support-grafana             2.68%    114.6MiB / 3.48GiB   3.22%    61.4MB /             385MB 12.6MB         /     
k6-support-influxdb            0.05%    206.2MiB / 3.48GiB   5.79%    474MB /              41.1MB 3.19MB        /     
k6-support-node-exporter       0.00%    9.184MiB / 3.48GiB   0.26%    3.06MB /             67.7MB 81.9kB        /     
k6-support-prometheus          0.00%    103.2MiB / 3.48GiB   2.90%    575MB /              67MB 1.52MB          /     
k6-support-telegraf            0.14%    88.8MiB / 3.48GiB    2.49%    840MB /              997MB 5.91MB         /     

Volume Usage:
----------------------------------------
VOLUME                                   SIZE      
k6-support_grafana_data                  5.8M      
k6-support_influxdb_data                 49M       
k6-support_prometheus_data               320M      
```
```bash
./docker-stats.sh -json | jq -r
```
```json
{
  "metadata": {
    "project": "k6-support",
    "timestamp": "2024-10-27 20:31:09 UTC"
  },
  "containers": [
    {
      "name": "k6-support-cloudflare-exporter",
      "cpu_percent": "4.22%",
      "memory": "26.46MiB / 3.48GiB",
      "memory_percent": "0.74%",
      "network_io": "138MB /",
      "block_io": "807MB 1.13MB",
      "pids": "/"
    },
    {
      "name": "k6-support-grafana",
      "cpu_percent": "0.08%",
      "memory": "114.6MiB / 3.48GiB",
      "memory_percent": "3.22%",
      "network_io": "61.4MB /",
      "block_io": "385MB 12.6MB",
      "pids": "/"
    },
    {
      "name": "k6-support-influxdb",
      "cpu_percent": "0.04%",
      "memory": "212MiB / 3.48GiB",
      "memory_percent": "5.95%",
      "network_io": "475MB /",
      "block_io": "41.1MB 3.19MB",
      "pids": "/"
    },
    {
      "name": "k6-support-node-exporter",
      "cpu_percent": "1.90%",
      "memory": "9.594MiB / 3.48GiB",
      "memory_percent": "0.27%",
      "network_io": "3.06MB /",
      "block_io": "67.8MB 81.9kB",
      "pids": "/"
    },
    {
      "name": "k6-support-prometheus",
      "cpu_percent": "3.00%",
      "memory": "97.41MiB / 3.48GiB",
      "memory_percent": "2.73%",
      "network_io": "575MB /",
      "block_io": "67MB 1.52MB",
      "pids": "/"
    },
    {
      "name": "k6-support-telegraf",
      "cpu_percent": "15.72%",
      "memory": "80.79MiB / 3.48GiB",
      "memory_percent": "2.27%",
      "network_io": "841MB /",
      "block_io": "998MB 6.04MB",
      "pids": "/"
    }
  ],
  "volumes": [
    {
      "name": "k6-support_grafana_data",
      "size": "5.8M"
    },
    {
      "name": "k6-support_influxdb_data",
      "size": "51M"
    },
    {
      "name": "k6-support_prometheus_data",
      "size": "320M"
    }
  ]
}
```