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
REPOSITORY                                 TAG          IMAGE ID       CREATED       SIZE
prom/node-exporter                         latest       d3e443c987ef   8 days ago    22.3MB
grafana/grafana-oss                        latest       99169ddb2b0b   2 weeks ago   300MB
influxdb                                   1.8          8dd1ac1f245f   3 weeks ago   308MB
prom/prometheus                            latest       df28013bb363   3 weeks ago   214MB
```

```
docker ps
CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS          PORTS                                       NAMES
c5b80e092d99   influxdb:1.8                 "/entrypoint.sh infl…"   13 minutes ago   Up 13 minutes   0.0.0.0:8186->8086/tcp, :::8186->8086/tcp   k6-support-influxdb
d6c7d914690f   prom/prometheus:latest       "/bin/prometheus --c…"   13 minutes ago   Up 13 minutes   0.0.0.0:9199->9090/tcp, :::9199->9090/tcp   k6-support-prometheus
76bc75de3179   prom/node-exporter:latest    "/bin/node_exporter …"   13 minutes ago   Up 13 minutes   0.0.0.0:9100->9100/tcp, :::9100->9100/tcp   k6-support-node-exporter
1c9fbac92088   grafana/grafana-oss:latest   "/run.sh"                13 minutes ago   Up 13 minutes   0.0.0.0:9409->3000/tcp, :::9409->3000/tcp   k6-support-grafana
```

To uninstall:

```
docker stop k6-support-node-exporter k6-support-grafana k6-support-influxdb k6-support-prometheus
docker-compose rm
docker volumes rm k6-support_influxdb_data k6-support_prometheus_data
```
```
docker-compose rm
? Going to remove k6-support-influxdb, k6-support-prometheus, k6-support-node-exporter, k6-support-grafana Yes
[+] Running 4/0
 ⠿ Container k6-support-influxdb       Removed                                                                                                                                                          0.0s
 ⠿ Container k6-support-grafana        Removed                                                                                                                                                          0.0s
 ⠿ Container k6-support-prometheus     Removed                                                                                                                                                          0.0s
 ⠿ Container k6-support-node-exporter  Removed        
```

From there, you will find:

- Prometheus at [localhost:9199](http://localhost:9199)
- InfluxDB at [localhost:8186](http://localhost:8186)
- Grafana at [localhost:9409](http://localhost:9409)
- k6 test scripts to run against in `testscripts`
