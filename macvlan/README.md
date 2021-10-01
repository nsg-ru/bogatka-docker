# Создание кластера серверов Богатка в облаке docker swarm macvlan

Сеть macvlan предполагает, что каждый контейнер имеет интерфейс с непосредственным выходом в физическую сеть, причем адрес интерфейса задается автоматически при запуске контейнера, поэтому необходимо заранее определить сеть и диапазоны адресов для каждого хоста, чтобы они не конфликтовали между собой, с другими устройствами в сети и со статическими адресами Богатки.\
\
В данных примерах выбрана сеть 192.168.10.0/24\
для статических адресов выбран диапазон   192.168.10.0/28\
для динамических адресов первого хоста выбран диапазон 192.168.10.16/28\
для динамических адресов второго хоста выбран диапазон 192.168.10.32/28


# Конфигурирование главного узла

Отключиться от облака, если ранее были подключены
```bash
docker swarm leave --force
```
Подготовить рабочую папку
```bash
mkdir ~/opt
cd ~/opt
git clone https://github.com/nsg-ru/bogatka-docker
cd bogatka-docker/macvlan
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

### Создать конфигурацию сети macvlan для данного узла
```bash
docker network create --config-only --subnet 192.168.10.0/24 --gateway 192.168.10.129 -o parent=enp3s0 --ip-range 192.168.10.16/28 bogatka-macvlan-conf
```
Шаблон команды находится в скрипте macvlan-conf.

### Создать сеть macvlan
```bash
docker network create -d macvlan  --scope swarm --config-from bogatka-macvlan-conf --attachable bogatka-macvlan
```
Шаблон команды находится в скрипте macvlan-create.

### Создать кластер базы данных Богатки
Кластер состоит из главной БД и нескольких реплик. Определите заранее сколько реплик у вас будет и какие имена они будут иметь.

Запустить главную БД для Богатки, перед запуском скорректировать значения переменных в скрипте db-run.
```bash
sudo mkdir -p /var/lib/postgresql/docker/pg-0
sudo chown 1001:1001 /var/lib/postgresql/docker/pg-0
./db-run
```
Создать схему БД
```bash
./db-migrate
```
Создать пользователя 'admin' с паролем 'admin'
```bash
./db-seed
```

### Запустить сервер Богатки
Скорректируйте значения переменных и запустите скрипт
```bash
./bogatka-run
```



# Конфигурирование остальных узлов
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
cd bogatka-docker/macvlan
```

Подключиться к рою
```bash
docker swarm join --token SWMTKN-1-41rr83nf72cv0pyf1kwcf9cnndvqdepzzxs560zhtdznqb9hrb-a1tm514ru3ejzlrw5dcczab84 10.33.32.32:2377
```

### Создать конфигурацию сети macvlan для данного узла
```bash
docker network create --config-only --subnet 192.168.10.0/24 --gateway 192.168.10.129 -o parent=enp3s0 --ip-range 192.168.10.32/28 bogatka-macvlan-conf
```
Шаблон команды находится в скрипте macvlan-conf.
Скрипт ./macvlan-create запускать не надо, так как он должен быть запущен только один раз на главном хосте.

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



# Дополнительно
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
