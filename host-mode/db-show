#!/bin/bash

# Имя локальной БД
NAME="pg-0"

docker exec -it  $NAME /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf cluster show
