# k6-support

A full-fledged local k6 ecosystem a `docker-compose up` away.

Spin up a prometheus+influxDB+grafana stack locally. Note that the docker-compose stack will automatically provision Grafana data sources and dashboards for you.

## Getting started

It's really that simple:

```
docker-compose up --build -d
```

From there, you will find:

- Prometheus at [localhost:9199](http://localhost:9199)
- InfluxDB at [localhost:8186](http://localhost:8186)
- Grafana at [localhost:9409](http://localhost:9409)
- k6 test scripts to run against in `testscripts`
