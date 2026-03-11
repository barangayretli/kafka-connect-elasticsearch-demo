#!/bin/bash
set -euo pipefail

# Restart from clean state
docker compose down
docker compose up -d --build

# Wait for Kafka Connect to be ready
echo "Waiting for Kafka Connect to be ready..."
until curl -sf http://localhost:8083/ > /dev/null 2>&1; do
  echo "  Connect not ready yet, retrying in 5s..."
  sleep 5
done
echo "Kafka Connect is ready."

# Deploy connector
echo "Creating Elasticsearch sink connector..."
curl -sf -X POST \
  -H "Content-Type: application/json" \
  --data @connector-config.json \
  http://localhost:8083/connectors | python3 -m json.tool

# Wait for connector to initialize
echo "Waiting for connector to start..."
sleep 10

# Verify connector status
echo "Connector status:"
curl -sf http://localhost:8083/connectors/elasticsearch-sink/status | python3 -m json.tool

# Publish test messages
echo "Publishing test messages to Kafka..."
docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka:9092 --topic example-topic \
  <<< '{"request": {"userId": "23768432478278"}}'

docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka:9092 --topic example-topic \
  <<< '{"request": {"userId": "23768432432453"}}'

docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka:9092 --topic example-topic \
  <<< '{"request": {"userId": "23768432432237"}}'

echo "Messages published. Waiting for Elasticsearch indexing..."
sleep 5

# Verify messages in Elasticsearch
echo "Verifying messages in Elasticsearch:"
curl -sf "http://localhost:9200/example-topic/_search?pretty"

echo "Done!"
