#!/bin/bash

# Версия сервера Богатки
VER=1.3.11

# Имя сервера Богатки
NAME=bogatka-0

# Список БД для записи/чтения
# Первой должна быть указана главная БД
DB_RW="pg-0,pg-1"

# Список БД только для чтения
# Первой должна быть указана локальная БД, если есть
DB_RO="pg-0,pg-1"

# Номер порта HTTPS 
HTTPS_PORT=443

# Номер порта API
API_PORT=50444

# Номер порта для подключения клиентов по TLS
ACARI_PORT=50019

# Номер порта для подключения клиентов без TLS
TCP_PORT=50020

# Параметры для подключения к Zabbix

# Внешний URL для обращения к WEB-интерфейсу Zabbix. Например:
# ZEU="https://demo.nsg.net.ru:10443"
ZEU=""

# URL для обработки запросов API например:
# ZAU="http://Admin:zabbix@zabbix-web-nginx-pgsql:8080" 
ZAU=""

# Имя хоста сервера Zabbix (zabbix-server-pgsql)
ZSH=""

# Номер порта для приема телеметрии (10051)
ZSP=""

# Раскомментируйте следующие две строки, если надо удалять ранее запущенный контейнер.
docker stop $NAME
docker container rm $NAME


docker run -t --detach \
  --init \
  --name $NAME \
  --hostname $NAME \
  --network host \
  --restart unless-stopped \
  -e DB_HOSTS_RW="$DB_RW" \
  -e DB_HOSTS_RO="$DB_RO" \
  -e BG_HTTPS_PORT=$HTTPS_PORT \
  -e BG_API_PORT=$API_PORT \
  -e BG_TLS_PORT=$ACARI_PORT \
  -e BG_TCP_PORT=$TCP_PORT \
  -v /etc/ssl/bogatka:/etc/ssl/bogatka:ro \
  -v /var/log/bogatka_$NAME:/var/log \
  -v /home/bogatka/opt/download:/opt/app/download \
  -v /etc/localtime:/etc/localtime:ro \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -e ZBX_EXT_URL="$ZEU" \
  -e ZBX_API_URL="$ZAU" \
  -e ZBX_SND_HOST="$ZSH" \
  -e ZBX_SND_PORT=$ZSP \
  nsgru/bogatka:$VER
