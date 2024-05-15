#!/bin/bash
set -x

# tweak this script to grafana/dashboard.json as well :) 'TEMP_PAYLOAD'

GRAFANA_URL="http://localhost:3000"
API_KEY=""   # create a service account and generate a token
DASHBOARD_URL="https://grafana.com/api/dashboards/1860/revisions/latest/download"
TEMP_PAYLOAD="/tmp/grafana_payload.json"

DASHBOARD_JSON=$(curl -s $DASHBOARD_URL)

echo "Fetched JSON: $DASHBOARD_JSON"

echo "{
  \"dashboard\": $DASHBOARD_JSON,
  \"overwrite\": true
}" > "$TEMP_PAYLOAD"

cat "$TEMP_PAYLOAD"

curl -X POST -H "Content-Type: application/json" \
     -H "Authorization: Bearer $API_KEY" \
     -d "@$TEMP_PAYLOAD" \
     $GRAFANA_URL/api/dashboards/db

rm "$TEMP_PAYLOAD"