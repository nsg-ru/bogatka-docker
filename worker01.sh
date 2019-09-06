#!/bin/bash
. ./bogatka.lib

### retrieve the join command for a worker
### docker swarm join-token worker
# docker swarm join --token SWMTKN-1-499kh1rwx9fz6w7612zjefnjt0wfax6n3gnnddcfjpgf9pl5bm-9r6axrv8vh4a0sz14lrlv1s5i 10.33.33.31:2377


run_postgres_replica(southport)

# Server SouthPort
# --name and --hostname must be the same
docker run -t \
  --name southport \
  --hostname southport \
  --network bogatka-net \
  --restart unless-stopped \
  -e DB_HOST=acari-server-db \
  -e ZBX_API_URL="http://zabbix-web-nginx-pgsql" \
  -e ZBX_WEB_PORT=10443 \
  -e ZBX_SND_HOST="zabbix-server-pgsql" \
  -p 443:50443 \
  -p 50019:50019 \
  -v /etc/ssl/acari:/etc/ssl/acari:ro \
  -v /var/log/acari_foo:/var/log \
  -v /etc/localtime:/etc/localtime:ro \
  --link acari-server-db \
  --link zabbix-web-nginx-pgsql \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -d ileamo/acari-server
