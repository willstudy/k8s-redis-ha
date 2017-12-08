#!/bin/bash

# Copyright 2014 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -x

LOG="/var/log/redis-run.log"
echo "===================================================" >> $LOG
echo "============== START NEW PROCESS ==================" >> $LOG
echo "===================================================" >> $LOG

function getmaster() {
    flags="-h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} -a $REDIS_PASS"
    for((retry = 1; retry <= 3; retry++))
    do
        master=`redis-cli ${flags} sentinel get-master-addr-by-name mymaster | head -1`
        if [ -n "$master" ]; then
            echo "Find master : ${master}" >> $LOG
            echo $master
            return
        else
            echo "Get master exec error. Wait 5 seconds and have a retry." >> $LOG
            sleep 5
        fi
    done
    echo "NULL"
}

function launchmaster() {
    if [[ ! -e /redis-master-data ]]; then
        echo "Redis master data doesn't exist, data won't be persistent!" >> $LOG
        mkdir /redis-master-data
    fi
    echo "redis-pass: ${REDIS_PASS}" >> $LOG
    sed -i "s/%redis-pass%/${REDIS_PASS}/" /redis-master/redis.conf
    redis-server /redis-master/redis.conf --protected-mode no
}

function launchsentinel() {
    while true; do
        master=`getmaster`
        echo "Get master returns : ${master}" >> $LOG
        if [[ "${master}" == "NULL" ]]; then
            master=${REDIS_MASTER_SERVICE_HOST}
        fi
        redis-cli -a $REDIS_PASS -h ${master} INFO
        if [[ "$?" == "0" ]]; then
            echo "Master has set up." >> $LOG
            break
        fi
        echo "Connecting to master failed.  Waiting..." >> $LOG
        sleep 10
    done

    sentinel_conf=sentinel.conf

    echo "sentinel monitor mymaster ${master} 6379 2" > ${sentinel_conf}
    echo "sentinel auth-pass mymaster ${REDIS_PASS}" >> ${sentinel_conf}
    echo "sentinel down-after-milliseconds mymaster 60000" >> ${sentinel_conf}
    echo "sentinel failover-timeout mymaster 180000" >> ${sentinel_conf}
    echo "sentinel parallel-syncs mymaster 1" >> ${sentinel_conf}
    echo "bind 0.0.0.0" >> ${sentinel_conf}

    redis-sentinel ${sentinel_conf} --protected-mode no
}

function launchslave() {
    while true; do
        master=`getmaster`
        echo "Get master returns : ${master}" >> $LOG
        if [[ "${master}" != "NULL" ]]; then
            echo "Find master : ${master}" >> $LOG
        else
            echo "Failed to find master, I begin to launch master." >> $LOG
            launchmaster
            exit 0
        fi 
        redis-cli -a $REDIS_PASS -h ${master} INFO
        if [[ "$?" == "0" ]]; then
            break
        fi
        echo "Connecting to master failed.  Waiting..." >> $LOG
        sleep 10
    done
    echo "I am slave, begin to launch slave. REDIS_PASS: ${REDIS_PASS}" >> $LOG
    sed -i "s/%master-ip%/${master}/" /redis-slave/redis.conf
    sed -i "s/%master-port%/6379/" /redis-slave/redis.conf
    sed -i "s/%redis-pass%/${REDIS_PASS}/" /redis-slave/redis.conf
    redis-server /redis-slave/redis.conf --protected-mode no
}

if [[ "${MASTER}" == "true" ]]; then
    master=`getmaster`
    echo "Get master returns : ${master}" >> $LOG
    if [[ "${master}" != "NULL" ]]; then
        echo "Master: $master has existed, continue restoring as a slave." >> $LOG
    else
        echo "Can not to find a master. I begin to launch master." >> $LOG
        launchmaster
        exit 0
    fi
fi

if [[ "${SENTINEL}" == "true" ]]; then
    echo "I am sentinel, begin to launch sentinel." >> $LOG
    launchsentinel
    exit 0
fi

launchslave
