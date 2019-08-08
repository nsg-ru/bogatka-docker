#!/bin/bash
. ./bogatka.lib

### init swarm
#docker swarm init --advertise-addr 10.33.33.31

### create an attachable overlay network
#docker network create --driver=overlay --attachable bogatka-net


# ***** Богатка *****

# PostgreSQL
docker run -t \
  --name acari-server-db \
  --network bogatka-net \
  --restart unless-stopped \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=acari_server_prod \
  -v /var/lib/postgresql/docker/acari-server/data:/var/lib/postgresql/data \
  -v /etc/localtime:/etc/localtime:ro \
  -d postgres:11.2-alpine

# Migrate DB
docker run -t \
  --network bogatka-net \
  -e DB_HOST=acari-server-db \
  --cap-add=NET_ADMIN \
  ileamo/acari-server migrate

run_bogatka skolkovo
