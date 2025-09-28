#!/bin/bash

# Создаём сеть, если её ещё нет
if ! docker network ls | grep -q "mlops-net"; then
    echo "Создаём сеть mlops-net..."
    docker network create mlops-net
fi


set -e

NETWORK="mlops-net"
CONTAINERS=("tracker_mlflow" "jenkins" "postgres" "minio" "registry")

echo "Поднимаем контейнеры..."
docker compose up -d --build
# docker compose up -d

# Подключаем контейнеры к сети
for c in "${CONTAINERS[@]}"; do
    echo "Подключаем контейнер $c к сети $NETWORK..."
    docker network connect $NETWORK $c 2>/dev/null || echo "$c уже в сети"
done

echo "Проверяем, что все контейнеры в сети..."
for c in "${CONTAINERS[@]}"; do
    if docker inspect $c | grep -q "$NETWORK"; then
        echo "✅ $c подключен к $NETWORK"
    else
        echo "❌ $c НЕ подключен к $NETWORK"
    fi
done

# Проверяем доступность Postgres из MLflow
echo "Проверяем подключение MLflow к Postgres..."
docker exec tracker_mlflow python3 - <<EOF
import os
import psycopg2
try:
    conn = psycopg2.connect(
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        host="postgres",
        port=5432
    )
    print("✅ MLflow подключился к Postgres!")
    conn.close()
except Exception as e:
    print("❌ Ошибка подключения к Postgres:", e)
EOF

# Проверяем доступность Minio из MLflow
echo "Проверяем подключение MLflow к Minio..."
docker exec tracker_mlflow python3 - <<EOF
import boto3, os
try:
    client = boto3.client(
        "s3",
        aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
        endpoint_url="http://minio:9000"
    )
    client.list_buckets()
    print("✅ MLflow подключился к Minio!")
except Exception as e:
    print("❌ Ошибка подключения к Minio:", e)
EOF

# Проверяем Jenkins (порт 18080)
JENKINS_PORT=18080

echo "Проверяем доступность Jenkins на порту $JENKINS_PORT..."
if curl -s http://localhost:$JENKINS_PORT >/dev/null; then
    echo "✅ Jenkins доступен на http://localhost:$JENKINS_PORT"
else
    echo "❌ Jenkins недоступен!"
fi


docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker network inspect mlops-net --format "{{range .Containers}}{{.Name}} {{end}}"


echo "Все проверки выполнены."
