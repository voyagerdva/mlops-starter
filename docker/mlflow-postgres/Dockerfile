# ./mlflow-postgres/Dockerfile
FROM ubuntu/mlflow:2.1.1_1.0-22.04

# Обновляем пакеты и ставим psycopg2
RUN apt-get update && \
    apt-get install -y gcc libpq-dev python3-dev && \
    pip install psycopg2-binary && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
