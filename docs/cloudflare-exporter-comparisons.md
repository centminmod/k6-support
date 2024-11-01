Testing different Cloduflare Exporter variants.

```bash
# First create a test network
docker network create cfexporter-test
docker network list

# Run the lablabs exporter
docker run -d \
  --network cfexporter-test \
  -p 8280:8080 \
  -e CF_API_TOKEN=${CF_API_TOKEN} \
  -e CF_ZONES=${CF_ZONES} \
  -e LISTEN=:8080 \
  -e CF_BATCH_SIZE=10 \
  --name cfexporter-lablabs \
  ghcr.io/lablabs/cloudflare_exporter:latest

# Run the cyb3rjak3 exporter
docker run -d \
  --network cfexporter-test \
  -p 8281:8080 \
  -e CF_API_TOKEN=${CF_API_TOKEN} \
  -e CF_ZONES=${CF_ZONES} \
  -e LISTEN=:8080 \
  -e CF_BATCH_SIZE=10 \
  --name cfexporter-cyb3r \
  cyb3rjak3/cloudflare-exporter

# Test the endpoints

# lablabs exporter
curl -s http://localhost:8280/metrics
# cyb3rjak3 exporter
curl -s http://localhost:8281/metrics

# Verify worker duration values

# lablabs exporter
curl -s http://localhost:8280/metrics | grep -m1 '^cloudflare_worker_duration' | awk '{print $NF}'
0.0059739998541772366

# cyb3rjak3 exporter
curl -s http://localhost:8281/metrics | grep -m1 '^cloudflare_worker_duration' | awk '{print $NF}'
0.0059739998541772366

# Verify worker cpu time values

# lablabs exporter
curl -s http://localhost:8280/metrics | grep -m1 '^cloudflare_worker_cpu_time' | awk '{print $NF}'
957

# cyb3rjak3 exporter
curl -s http://localhost:8281/metrics | grep -m1 '^cloudflare_worker_cpu_time' | awk '{print $NF}'
957

# Within the network, they can reach each other using container names
docker run --rm --network cfexporter-test curlimages/curl curl http://cfexporter-lablabs:8080/metrics
docker run --rm --network cfexporter-test curlimages/curl curl http://cfexporter-cyb3r:8080/metrics

# When done testing, remove the network
docker network rm cfexporter-test
```

This setup:
- Creates an isolated test network
- Gives each exporter a distinct name and host port
- Keeps the internal ports the same (:8080)
- Makes it easy to clean up when done testing

You can have both running simultaneously to compare their metrics output, and they won't interfere with your existing compose setup.