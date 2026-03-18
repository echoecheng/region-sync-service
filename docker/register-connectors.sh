#!/bin/bash
#
# Register Debezium MySQL source connectors for NA and EU databases.
# Each connector registers to its own region's Kafka Connect instance.
#
# Usage:
#   bash docker/register-connectors.sh
#

CONNECT_NA_URL="http://localhost:8083"
CONNECT_EU_URL="http://localhost:8084"

echo "Waiting for NA Kafka Connect to be ready..."
until curl -s "$CONNECT_NA_URL/connectors" > /dev/null 2>&1; do
    sleep 3
    echo "  ...waiting for NA Connect"
done
echo "NA Kafka Connect is ready."

echo "Waiting for EU Kafka Connect to be ready..."
until curl -s "$CONNECT_EU_URL/connectors" > /dev/null 2>&1; do
    sleep 3
    echo "  ...waiting for EU Connect"
done
echo "EU Kafka Connect is ready."

echo ""
echo "=== Registering NA source connector (on NA Connect -> kafka-na) ==="
curl -s -X POST "$CONNECT_NA_URL/connectors" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "na-source-connector",
    "config": {
        "connector.class": "io.debezium.connector.mysql.MySqlConnector",
        "database.hostname": "mysql-na",
        "database.port": "3306",
        "database.user": "root",
        "database.password": "root123",
        "database.server.id": "10001",
        "topic.prefix": "na",
        "database.include.list": "apn_na",
        "schema.history.internal.kafka.bootstrap.servers": "kafka-na:29092",
        "schema.history.internal.kafka.topic": "_schema_history_na",
        "include.schema.changes": "false",
        "snapshot.mode": "schema_only",
        "decimal.handling.mode": "string",
        "time.precision.mode": "connect"
    }
}' | python3 -m json.tool 2>/dev/null || echo "(registered)"

echo ""
echo "=== Registering EU source connector (on EU Connect -> kafka-eu) ==="
curl -s -X POST "$CONNECT_EU_URL/connectors" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "eu-source-connector",
    "config": {
        "connector.class": "io.debezium.connector.mysql.MySqlConnector",
        "database.hostname": "mysql-eu",
        "database.port": "3306",
        "database.user": "root",
        "database.password": "root123",
        "database.server.id": "10002",
        "topic.prefix": "eu",
        "database.include.list": "apn_eu",
        "schema.history.internal.kafka.bootstrap.servers": "kafka-eu:29092",
        "schema.history.internal.kafka.topic": "_schema_history_eu",
        "include.schema.changes": "false",
        "snapshot.mode": "schema_only",
        "decimal.handling.mode": "string",
        "time.precision.mode": "connect"
    }
}' | python3 -m json.tool 2>/dev/null || echo "(registered)"

echo ""
echo "=== Verifying NA connectors ==="
curl -s "$CONNECT_NA_URL/connectors" | python3 -m json.tool 2>/dev/null
echo ""
echo "=== NA connector status ==="
curl -s "$CONNECT_NA_URL/connectors/na-source-connector/status" | python3 -m json.tool 2>/dev/null

echo ""
echo "=== Verifying EU connectors ==="
curl -s "$CONNECT_EU_URL/connectors" | python3 -m json.tool 2>/dev/null
echo ""
echo "=== EU connector status ==="
curl -s "$CONNECT_EU_URL/connectors/eu-source-connector/status" | python3 -m json.tool 2>/dev/null

echo ""
echo "Done. Debezium connectors registered on their respective regional Connect instances."
