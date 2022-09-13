#!/bin/bash

DOCKERCOMPOSE='/usr/local/lib/docker/cli-plugins/docker-compose';

if [[ $1 = "start" ]]; then

    $DOCKERCOMPOSE --verbose up -d

    for IMG in $($DOCKERCOMPOSE ps --status running --format json | jq -r .[].Name | grep replica); do docker exec -it $IMG bash -c "mysql -uroot -pt00r < /sqlscripts/replication.sql"; done

    docker exec -it mysql_source bash -c "mysql -uroot -pt00r < /sqlscripts/user.sql"

    echo "Execute docker-compose logs proxysql1 and check if the backends are up."

    $DOCKERCOMPOSE restart proxysql1
    
fi

if [[ $1 = "stop" ]]; then
    $DOCKERCOMPOSE --verbose down
fi
