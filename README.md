# ProxySQL + MySQL Replication Cluster setup

## Requirements
- Docker version 20.10.2, build 2291f61
- Docker Compose version v2.10.2

## Use the bash script
Command to deploy the containers
```
$ ./setupenv.sh start
```

## Check if all backends are `running`
Check if containers are up:
```bash
$ docker-compose ps -a
NAME                        COMMAND                  SERVICE             STATUS              PORTS
mysql_replica1              "docker-entrypoint.s…"   mysql2              running (healthy)   33060/tcp, 0.0.0.0:49167->3306/tcp
mysql_replica2              "docker-entrypoint.s…"   mysql3              running (healthy)   33060/tcp, 0.0.0.0:49168->3306/tcp
mysql_replica3              "docker-entrypoint.s…"   mysql4              running (healthy)   33060/tcp, 0.0.0.0:49166->3306/tcp
mysql_source                "docker-entrypoint.s…"   mysql1              running (healthy)   33060/tcp, 0.0.0.0:49169->3306/tcp
proxysql-test-proxysql1-1   "proxysql -f --idle-…"   proxysql1           running             0.0.0.0:6032-6033->6032-6033/tcp
```

Check if backend servers are `ONLINE`:
```bash
$ docker run \
--rm=true \
--name=sb-schema \
--network=proxysql-lb-test_default \
sysbench-docker \
mysql \
--user=radmin \
--password=radmin \
--host=proxysql1 \
--port=6032 \
-e "select * from mysql_servers" | pt-align
```


## Using sysbench
Create the container image:
```bash
$ cd sb-docker/
$ DOCKER_BUILDKIT=1 docker build . -t sysbench-docker
```

Login to proxysql admin interface:
```bash
$ docker run \
--rm=true \
--name=sb-schema \
--network=proxysql-lb-test_default \
sysbench-docker \
mysql \
--user=radmin \
--password=radmin \
--host=proxysql1 \
--port=6032 \
-e "select * from mysql_users"
```

Create the schema:
```bash
$ docker run \
--rm=true \
--name=sb-schema \
--network=proxysql-lb-test_default \
sysbench-docker \
mysql \
--user=root \
--password=t00r \
--host=proxysql1 \
--port=6033 \
-e "CREATE DATABASE sbtest"
```

Prepare the sysbench database:
```bash
$ docker run \
--rm=true \
--name=sb-prepare \
--network=proxysql-lb-test_default \
sysbench-docker \
sysbench \
--db-ps-mode=disable \
--db-driver=mysql \
--oltp-table-size=100000 \
--oltp-tables-count=1 \
--threads=12 \
--mysql-host=proxysql1 \
--mysql-port=6033 \
--mysql-user=root \
--mysql-password=t00r \
--mysql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/parallel_prepare.lua \
prepare
```

Run the benchmark for MySQL:
```bash
$ docker run \
--rm=true \
--name=sb-run \
--network=proxysql-lb-test_default \
sysbench-docker \
sysbench \
--db-ps-mode=disable \
--db-driver=mysql \
--report-interval=2 \
--mysql-table-engine=innodb \
--oltp-table-size=100000 \
--oltp-tables-count=1 \
--threads=12 \
--time=60 \
--mysql-host=proxysql1 \
--mysql-port=6033 \
--mysql-user=root \
--mysql-password=t00r \
--mysql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/oltp_simple.lua \
run
```

Get connection pool statistics
```bash
$ docker run \
--rm=true \
--name=sb-schema \
--network=proxysql-lb-test_default \
sysbench-docker \
mysql \
--user=radmin \
--password=radmin \
--host=proxysql1 \
--port=6032 \
-e "select * from stats.stats_mysql_connection_pool" | pt-align
```
