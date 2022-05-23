# Создание кластера серверов Богатка в облаке docker swarm
## Создание облака swarm
Отключиться от облака, если ранее были подключены
```bash
docker swarm leave --force
```
Подготовить рабочую папку
```bash
mkdir ~/opt
cd ~/opt
git clone https://github.com/nsg-ru/bogatka-docker
cd bogatka-docker/v2
```

Создать docker_gwbridge
```bash
./create-gwbridge
```

Инициировать рой
```bash
docker swarm init --advertise-addr HOSTNAME
```
где HOSTNAME - адрес или доменное имя по которому можно соединиться с данным хостом.


Удалить ненужную нам сеть ingress
```bash
docker network rm ingress
```

Создать оверлейную сеть
```bash
./create-overlay
```

Проверить наличие созданных объектов:
```text
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
eq5uad0m7xyp67hhi7340iw8i *   localhost           Ready               Active              Leader              19.03.4

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

## Конфигурирование главного узла

### Создать кластер базы данных Богатки
Кластер состоит из главной БД и нескольких реплик. Определите заранее сколько реплик у вас будет и какие имена они будут иметь.

Запустить главную БД для Богатки, перед запуском скорректировать значения переменных в скриптах db-run, db-migrate, db-seed.
```bash
sudo mkdir -p /var/lib/postgresql/docker/pg-0
sudo chown 1001:1001 /var/lib/postgresql/docker/pg-0
./db-run

#Создать схему БД
./db-migrate

#Создать пользователя 'admin' с паролем 'admin'
./db-seed
```
### Запустить сервер Богатки
Создать папку
```bash
sudo mkdir -p /etc/ssl/bogatka
```
и положить туда сертификат и ключ SSL c именами ssl.crt ssl.key

Скорректируйте значения переменных и запустите скрипт
```bash
./bogatka-run
```

## Конфигурирование остальных узлов
Перед конфигурированием остальных узлов, выполним команду на главном:
```text
$ docker swarm join-token  worker
To add a worker to this swarm, run the following command:

docker swarm join --token SWMTKN-1-41rr83nf72cv0pyf1kwcf9cnndvqdepzzxs560zhtdznqb9hrb-a1tm514ru3ejzlrw5dcczab84 10.33.32.32:2377
```
Если мы хотим поключить следующий узел в режиме manager, то надо выполнить команду
```text
$ docker swarm join-token  manager
```

Отключиться от облака, если ранее были подключены
```bash
docker swarm leave --force
```
Подготовить рабочую папку
```bash
mkdir ~/opt
cd ~/opt
git clone https://github.com/nsg-ru/bogatka-docker
cd bogatka-docker/v2
```

Подключиться к рою
```bash
docker swarm join --token SWMTKN-1-41rr83nf72cv0pyf1kwcf9cnndvqdepzzxs560zhtdznqb9hrb-a1tm514ru3ejzlrw5dcczab84 10.33.32.32:2377
```

Запускаем реплику БД (опционально)
```bash
sudo mkdir -p /var/lib/postgresql/docker/pg-1
sudo chown 1001:1001 /var/lib/postgresql/docker/pg-1
./db-run
```
и сервер Богатки.
```bash
./bogatka-run
```

Перед запуском скриптов корректируем значения переменных



## Дополнительно
### Работа с БД

Резервная копия БД создается следующей командой
```bash
docker exec -it -e PGPASSWORD=postgres имя_контейнера_БД pg_dump  -U postgres  bogatka > backup.sql
```

Восстановление БД. Создаем пустую БД с помощью скрипта ./db-run, скрипты ./db-migrate и db-seed не выполняем.
Выполняем команду воостановления БД из резервной копии
```bash
cat backup.sql| docker exec -i -e PGPASSWORD=postgres pg-0 psql  -U postgres  bogatka
```

Посмотреть информацию о кластере
```bash
./db-show
```
Работа с БД вручную
```bash
./db-psql
```
Скорректируйте в скриптах имя контейнера с БД.

### Полезные команды
Восстановление роя
```bash
docker swarm init --force-new-cluster
```

### Использование Богатки в режиме network=host
Иногда необходимо чтобы сервер Богатки работал в адресном пространстве хоста.
Для этого необходимо
* В скрипте запуска БД добавить параметр
```
-p 5432:5432 
```
* В скрипте запуска Богатки заменить параметр ```--network bogatka-net``` на
```
--network host
```
* Доменные имена хостов должны совпадать с именами серверов Богатки