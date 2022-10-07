#!/bin/bash
# create additional influxdb users
INFLUXDB_INIT_PORT="8086"
INFLUXDB_TELEGRAF_USER='telegraf'
INFLUXDB_TELEGRAF_PASSWORD='password'

influx -host 127.0.0.1 -port $INFLUXDB_INIT_PORT \
       -execute "CREATE USER \"$INFLUXDB_TELEGRAF_USER\" WITH PASSWORD '$INFLUXDB_TELEGRAF_PASSWORD'"

      