#!/bin/bash

# Имена всех БД
NODES="pg-0,pg-1"

# Имя локальной БД
NAME="pg-0"

# Имя главной БД
PRIMARY="pg-0"

# Путь на хосте с файлами БД
DATA="/var/lib/postgresql/docker/$NAME"

# Run container
docker run --detach --restart unless-stopped \
  --name $NAME \
  --network host \
  --env REPMGR_PARTNER_NODES="$NODES" \
  --env REPMGR_NODE_NAME="$NAME" \
  --env REPMGR_NODE_NETWORK_NAME="$NAME" \
  --env REPMGR_PRIMARY_HOST="$PRIMARY" \
  --env REPMGR_PASSWORD=postgres \
  --env POSTGRESQL_DATABASE=bogatka \
  --env POSTGRESQL_PASSWORD=postgres \
  -v $DATA:/bitnami/postgresql \
  -v /etc/localtime:/etc/localtime:ro \
  bitnami/postgresql-repmgr:latest

