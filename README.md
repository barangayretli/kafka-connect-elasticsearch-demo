# Kafka Connect Elasticsearch Sink Connector

A demo project showing how to stream data from Kafka to Elasticsearch using Kafka Connect with the Elasticsearch Sink Connector.

## Architecture

- **Kafka 3.9** (KRaft mode, no Zookeeper)
- **Elasticsearch 8.17**
- **Kafka Connect** with Confluent Elasticsearch Sink Connector

## Prerequisites

- Docker & Docker Compose v2
- ~4GB memory allocated to Docker

## Usage

Run the startup script to bring up the stack, deploy the connector, and publish test messages:

```bash
./startup.sh
```

The script will:
1. Start Kafka, Elasticsearch, and Kafka Connect containers
2. Wait for Kafka Connect to be ready (polling, no fixed sleep)
3. Deploy the Elasticsearch sink connector
4. Publish 3 test messages to the `example-topic` Kafka topic
5. Verify messages are indexed in Elasticsearch

## Verify

Check if the messages made it to Elasticsearch:

```bash
curl http://localhost:9200/example-topic/_search?pretty
```

Expected output:

```json
{
  "took" : 5,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 3,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "example-topic",
        "_id" : "example-topic+0+0",
        "_score" : 1.0,
        "_source" : {
          "request" : {
            "userId" : "23768432478278"
          },
          "messageTS" : "2026-03-11T15:42:05"
        }
      }
    ]
  }
}
```

Check connector status:

```bash
curl http://localhost:8083/connectors/elasticsearch-sink/status | python3 -m json.tool
```

## Connector Configuration

The connector config is in `connector-config.json`. It includes:
- Schema-less JSON mode (`schema.ignore`, `key.ignore`)
- Timestamp injection via SMTs (`InsertField` + `TimestampConverter`)

## Grafana (Optional)

To visualize messages, you can run Grafana and add Elasticsearch as a data source:

```bash
docker run -d -p 3000:3000 --name grafana grafana/grafana
```

Then go to **Configuration > Data Sources > Add Data Source > Elasticsearch** and set the URL to `http://host.docker.internal:9200` with index name `example-topic`.

## Cleanup

```bash
docker compose down
```

## Blog Post

See the Medium blog post for a detailed walkthrough:

[https://medium.com/@barangayretli](https://medium.com/@barangayretli)
