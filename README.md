# Prometheus Monitoring with Grafana Dashboards

This project demonstrates how to set up Prometheus monitoring for a Python web application, add metrics, configure alerts, and automate the addition of Grafana dashboards using the API.

## Table of Contents
- [Adding Targets](#adding-targets)
- [Adding Metrics to Python Web App](#adding-metrics-to-python-web-app)
- [Adding Alerts](#adding-alerts)
- [Automating Dashboard Creation](#automating-dashboard-creation)

## Adding Targets

To add targets to Prometheus, update the `prometheus.yaml` configuration file. In this project, we added the `webapp` and `node_exporter` targets.

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'webapp'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['webapp:8000']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

## Adding Metrics to Python Web App
### Metrics were added to the Python web application using the prometheus_client library. Below is a snippet from the app.py file:

```python
from flask import Flask, request, Response
from prometheus_client import Counter, Histogram, generate_latest

app = Flask(__name__)

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests (count)', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('http_request_latency_seconds', 'HTTP request latency (seconds)', ['endpoint'])

@app.route('/')
def hello_world():
    with REQUEST_LATENCY.labels('/').time():
        REQUEST_COUNT.labels(request.method, '/').inc()
        return '<html><body><h1>Hello, World!</h1></body></html>'

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype='text/plain')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)

```

## Adding Alerts 
### Alerts were configured in Prometheus using an alerting rules file alert.rules.yml. An example rule to alert when HTTP request rate exceeds 0.3 is shown below:

```yaml
groups:
- name: http_requests_alerts
  rules:
  - alert: HighHTTPRequests
    expr: sum(rate(http_request_latency_seconds_count[5m])) > 0.3
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "High HTTP request rate"
      description: "The rate of HTTP requests is above 0.3 for more than 1 minute."
```

### This file is referenced in the Prometheus configuration:
```yaml
global:
  scrape_interval: 15s

rule_files:
  - "/etc/prometheus/alert.rules.yml"

scrape_configs:
  - job_name: 'webapp'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['webapp:8000']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

## Automating Dashboard Creation

### You can automate the addition of dashboards to Grafana using the Grafana HTTP API. Below is a bash script to add a dashboard using the API.

```bash
#!/bin/bash

# Variables
GRAFANA_URL="http://localhost:3000"
API_KEY="YOUR_GRAFANA_API_KEY"
DASHBOARD_URL="https://grafana.com/api/dashboards/1860/revisions/latest/download"
TEMP_PAYLOAD="/tmp/grafana_payload.json"

# Fetch the dashboard JSON
DASHBOARD_JSON=$(curl -s $DASHBOARD_URL)

# Check if the dashboard JSON was fetched successfully
if [ -z "$DASHBOARD_JSON" ]; then
  echo "Failed to fetch dashboard JSON."
  exit 1
fi

# Create the JSON payload for the Grafana API and write it to a temporary file
echo "{
  \"dashboard\": $DASHBOARD_JSON,
  \"overwrite\": true
}" > "$TEMP_PAYLOAD"

# Verify the payload has been written
if [ ! -f "$TEMP_PAYLOAD" ]; then
  echo "Failed to write payload to file."
  exit 1
fi

# Debugging output to ensure the payload is correctly written
echo "Payload written to $TEMP_PAYLOAD:"
cat "$TEMP_PAYLOAD"

# Send the request to the Grafana API to create the dashboard using the payload from the file
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "@$TEMP_PAYLOAD" \
  $GRAFANA_URL/api/dashboards/db)

# Check if the API call was successful
if echo "$RESPONSE" | grep -q "message"; then
  echo "Dashboard creation failed with response: $RESPONSE"
  rm "$TEMP_PAYLOAD"
  exit 1
fi

echo "Dashboard created successfully."

# Clean up temporary file
rm "$TEMP_PAYLOAD"
```