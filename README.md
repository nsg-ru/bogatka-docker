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
Если мы хотим подключить следующий узел в режиме manager, то надо выполнить команду
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

Запускаем реплику БД (опционально).
NAME в пути и параметр NAME в скрипте db-run должны совпадать и отличаться от имени главной БД и других реплик
```bash
sudo mkdir -p /var/lib/postgresql/docker/NAME
sudo chown 1001:1001 /var/lib/postgresql/docker/NAME
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
Выполняем команду восстановления БД из резервной копии
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

> **_ВНИМАНИЕ:_** В процессе работы может автоматически поменяться главная БД, поэтому при повторном запуске какой-либо реплики надо уточнить имя текущей главной БД (скрипт `db-show`) и скорректировать параметр `PRIMARY` в скрипте `db-run`

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

# Интеграция с Zabbix

Zabbix запускается скриптом
```bash
./zabbix-run
```
В скрипте bogatka-run надо задать переменные ZAU, ZEU, ZSH, ZSP

# Значения переменных среды контейнера Богатки

Когда вы запускаете образ nsgru/bogatka, вы можете настроить конфигурацию сервера Богатка, передав одну или несколько переменных среды в командной строке запуска docker.
 
**`BG_HTTP_PORT`**

Номер порта HTTP, по умолчанию 0, то есть отключен
> **_ВНИМАНИЕ:_** В версиях Богатки 1.3.11 и более ранних значение по умолчанию равно 50080, поэтому если вы не хотите чтобы сервер работал по HTTP, установите явно `BG_HTTP_PORT=0`

**`BG_HTTPS_PORT`**

Номер порта HTTPS, по умолчанию 50443

**`BG_API_PORT`**

Номер порта HTTPS для выполнения API запросов к Богатке, по умолчанию 50444

**BG_TLS_PORT**

Номер порта для подключения клиентов по TLS, по умолчанию 50019

**BG_TCP_PORT**

Номер порта для подключения клиентов без TLS, по умолчанию 50020

**DB_HOSTS_RW**

Список БД для записи/чтения

**DB_HOSTS_RO**

Список БД только для чтения

**DB_HOST** и **DB_PORT** используются только при начальной инициализации БД в скриптах migrate и seed



## Параметры для подключения к Zabbix

**ZBX_EXT_URL**

Внешний URL для обращения к WEB-интерфейсу Zabbix. Например:
 `ZBX_EXT_URL="https://demo.nsg.net.ru:10443"`

**ZBX_API_URL**

URL для обработки запросов API например:
`ZBX_API_URL="http://Admin:zabbix@zabbix-web-nginx-pgsql:8080"`
 
**ZBX_SND_HOST**

Имя хоста сервера Zabbix

**ZBX_SND_PORT**

Номер порта для приема телеметрии, по умолчанию 10051

