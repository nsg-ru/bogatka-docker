# MANAGER

Отключиться от облака, если ранее были подключены
```bash
docker swarm leave --force
```
Подготовить рабочую папку
```bash
mkdir ~/opt
cd ~/opt
git clone https://github.com/nsg-ru/bogatka-docker
cd bogatka-docker/
```

Создать docker_gwbridge
```bash
./create-gwbridge
```

Инициировать рой
```bash
docker swarm init --advertise-addr 10.33.32.32
```

Удалить ненужную нам сеть ingress
```bash
docker network rm ingress
```

Создать оверлейную сеть
```bash
./create-overlay
```

Проверитиь наличие созданных объектов:
```text
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
eq5uad0m7xyp67hhi7340iw8i *   southport           Ready               Active              Leader              19.03.4

$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
38rm36nd0l9w        bogatka-net         overlay             swarm
2f9665844425        bridge              bridge              local
226c4f50e0dd        docker_gwbridge     bridge              local
631c369d820e        host                host                local
37a67bb6c596        none                null                local

$ ip ad sh dev docker_gwbridge
65: docker_gwbridge: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:dc:e2:ab:93 brd ff:ff:ff:ff:ff:ff
    inet 172.31.2.1/24 brd 172.31.2.255 scope global docker_gwbridge
       valid_lft forever preferred_lft forever
    inet6 fe80::42:dcff:fee2:ab93/64 scope link
       valid_lft forever preferred_lft forever
```



Запустить СУБД для Богатки
```bash
sudo mkdir -p /var/lib/postgresql/docker/bogatka
sudo chown 1001:1001 /var/lib/postgresql/docker/bogatka
./run-bogatka-db
```

Проверить что контейнер запустился:
```text
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED              STATUS              PORTS               NAMES
0258f89dc10d        bitnami/postgresql:latest   "/entrypoint.sh /run…"   About a minute ago   Up About a minute   5432/tcp            bogatka-db
```


Создать базу данных и все таблицы
```bash
./migrate_bogatka_db
```

Создать пользователя 'admin' с паролем 'admin'
```bash
./seed_bogatka_db
```


Создать папку
```bash
sudo mkdir -p /etc/ssl/bogatka
```
и положить туда сертификат и ключ SSl c именами cert.pem privkey.pem

Запустить Богатку
```bash
./run-bogatka
```

Скрипт run-bogatka может запускаться с параметрами:
```bash
$ ./run-bogatka -h
OPTIONS:
-u      - Upgrade container
-n NAME - Container name(default southport)
-p PORT - HTTPS port(default 443)
-a PORT - TCP port(default 50019)
-w LIST - List of read-write db names(default bogatka-db)
-o LIST - List of read-only db names(default bogatka-db)
```
--------------------------------------------------------------------------------

# WORKER

Прежде чем переходить на worker, выполним команду на manager'е:
```text
$ docker swarm join-token  worker
To add a worker to this swarm, run the following command:

docker swarm join --token SWMTKN-1-41rr83nf72cv0pyf1kwcf9cnndvqdepzzxs560zhtdznqb9hrb-a1tm514ru3ejzlrw5dcczab84 10.33.32.32:2377
```


Подготовить рабочую папку
```bash
mkdir ~/opt
cd ~/opt
git clone https://github.com/nsg-ru/bogatka-docker
cd bogatka-docker/
```


Создать docker_gwbridge
```bash
./create-gwbridge
```

Подключиться к рою, выполнив команду полученную на manager'е
```bash
docker swarm join --token SWMTKN-1-41rr83nf72cv0pyf1kwcf9cnndvqdepzzxs560zhtdznqb9hrb-a1tm514ru3ejzlrw5dcczab84 10.33.32.32:2377
```


Запустить реплику БД для Богатки(необязательно)
```bash
sudo mkdir -p /var/lib/postgresql/docker/bogatka
sudo chown 1001:1001 /var/lib/postgresql/docker/bogatka
./run-bogatka-db-replica
```

Создать папку
```bash
sudo mkdir -p /etc/ssl/bogatka
```
и положить туда сертификат и ключ SSl c именами cert.pem privkey.pem

Запустить Богатку
```bash
./run-bogatka -o"bogataka-db-skolkovo,bogatka-db"
```
(опция -o задается если мы хотим использовать для чтения локальную реплику БД)
