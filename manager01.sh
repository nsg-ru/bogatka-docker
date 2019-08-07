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

# Server skolkovo
# --name and --hostname must be the same
docker run -t \
  --name skolkovo \
  --hostname skolkovo \
  --network bogatka-net \
  --restart unless-stopped \
  -e DB_HOST=acari-server-db \
  -e ZBX_API_URL="http://zabbix-web-nginx-pgsql" \
  -e ZBX_WEB_PORT=10443 \
  -e ZBX_SND_HOST="zabbix-server-pgsql" \
  -p 443:50443 \
  -p 51019:50019 \
  -v /etc/ssl/acari:/etc/ssl/acari:ro \
  -v /var/log/acari_foo:/var/log \
  -v /etc/localtime:/etc/localtime:ro \
  --link acari-server-db \
  --link zabbix-web-nginx-pgsql \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -d ileamo/acari-server
