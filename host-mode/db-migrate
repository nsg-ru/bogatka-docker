#!/bin/bash

# Имя локальной БД
NAME="pg-0"

# Версия Богатки
VER=1.3.11

docker run -t --rm \
  --network host \
  --env DB_HOST=$NAME \
  --cap-add=NET_ADMIN \
  nsgru/bogatka:$VER eval "AcariServer.Release.migrate"
