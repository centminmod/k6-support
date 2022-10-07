# k6-support

A full-fledged local k6 ecosystem a `docker-compose up` away. Custom branch for use with my [k6-benchmarking](https://github.com/centminmod/k6-benchmarking) scripts.

Spin up a prometheus+influxDB+grafana stack locally. Note that the docker-compose stack will automatically provision Grafana data sources and dashboards for you.

## Getting started

Install docker on CentOS 7/8/9 https://docs.docker.com/engine/install/centos/ and post-install steps [here](https://docs.docker.com/engine/install/linux-postinstall/). To uninstall [read](https://docs.docker.com/engine/install/centos/#uninstall-docker-engine).

```
yum -y install yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl start docker
systemctl enable docker
systemctl enable containerd
systemctl status docker
```
```
nano /etc/docker/daemon.json
```
```
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```
# optional for Centmin Mod CSF Firewall

```
csf -a $(docker network inspect k6-support_k6-support | jq -r '.[] | .IPAM.Config[] | .Subnet') k6network
```

```
service docker restart
```

Install docker-compose if not installed https://docs.docker.com/compose/install/

```
curl -4SL https://github.com/docker/compose/releases/download/v2.11.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```
```
docker-compose --version
Docker Compose version v2.11.2
```

Run docker-compose command:

```
docker-compose up --build -d
```

```
docker images
REPOSITORY                                 TAG          IMAGE ID       CREATED        SIZE
telegraf                                   1.22         702613c5fe38   33 hours ago   354MB
prom/node-exporter                         latest       d3e443c987ef   10 days ago    22.3MB
grafana/grafana-oss                        latest       99169ddb2b0b   2 weeks ago    300MB
influxdb                                   1.8          8dd1ac1f245f   3 weeks ago    308MB
prom/prometheus                            latest       df28013bb363   3 weeks ago    214MB
```

```
docker ps
CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS          PORTS                                          NAMES
1c58dea96c0c   telegraf:1.22                "/entrypoint.sh tele…"   39 seconds ago   Up 37 seconds   8092/udp, 8094/tcp, 127.0.0.1:8125->8125/udp   k6-support-telegraf
df00bd35f0c3   prom/prometheus:latest       "/bin/prometheus --c…"   39 seconds ago   Up 37 seconds   0.0.0.0:9199->9090/tcp, :::9199->9090/tcp      k6-support-prometheus
ccb2ee7c2996   grafana/grafana-oss:latest   "/run.sh"                39 seconds ago   Up 37 seconds   0.0.0.0:9409->3000/tcp, :::9409->3000/tcp      k6-support-grafana
da48393caa34   prom/node-exporter:latest    "/bin/node_exporter …"   39 seconds ago   Up 37 seconds   0.0.0.0:9100->9100/tcp, :::9100->9100/tcp      k6-support-node-exporter
c42636858581   influxdb:1.8                 "/entrypoint.sh infl…"   39 seconds ago   Up 37 seconds   0.0.0.0:8186->8086/tcp, :::8186->8086/tcp      k6-support-influxdb
```

To uninstall:

```
docker stop k6-support-node-exporter k6-support-grafana k6-support-influxdb k6-support-prometheus k6-support-telegraf
docker-compose rm -f
docker volume rm k6-support_influxdb_data k6-support_prometheus_data
```
```
docker-compose rm
? Going to remove k6-support-telegraf, k6-support-grafana, k6-support-prometheus, k6-support-influxdb, k6-support-node-exporter Yes
[+] Running 5/0
 ⠿ Container k6-support-node-exporter  Removed                                                                                                                                                          0.0s
 ⠿ Container k6-support-grafana        Removed                                                                                                                                                          0.0s
 ⠿ Container k6-support-prometheus     Removed                                                                                                                                                          0.0s
 ⠿ Container k6-support-influxdb       Removed                                                                                                                                                          0.0s
 ⠿ Container k6-support-telegraf       Removed     
```

```
docker exec -it k6-support-influxdb influx -execute "show databases"
name: databases
name
----
k6
influx
_internal
```

```
curl -sG http://localhost:8186/query --data-urlencode "q=SHOW DATABASES" | jq -r
{
  "results": [
    {
      "statement_id": 0,
      "series": [
        {
          "name": "databases",
          "columns": [
            "name"
          ],
          "values": [
            [
              "k6"
            ],
            [
              "influx"
            ],
            [
              "_internal"
            ]
          ]
        }
      ]
    }
  ]
}
```

docker exec -it k6-support-influxdb influx -execute "create user admin2 with password 'passwprd' with all privileges"

From there, you will find:

- Prometheus at [localhost:9199](http://localhost:9199)
- InfluxDB at [localhost:8186](http://localhost:8186)
- Grafana at [localhost:9409](http://localhost:9409)
- k6 test scripts to run against in `testscripts`
