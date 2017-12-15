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

echo "===================================================" 
echo "============== START NEW PROCESS ==================" 
echo "===================================================" 

DEBUG="/var/log/redis/redis.debug.log"

REDIS_MASTER_SERVICE_IP=`eval echo "$""${REDIS_APP_NAME}_MASTER_SERVICE_HOST"`
REDIS_SENTINEL="${REDIS_APP_NAME}_SENTINEL"
#REDIS_SENTINEL_SERVICE_NAME=`nslookup "${REDIS_SENTINEL}_SERVICE_HOST" | tail -1 | awk '{print $NF}'`
REDIS_SENTINEL_SERVICE_IP=`eval echo "$""${REDIS_APP_NAME}_SENTINEL_SERVICE_HOST"`
REDIS_SENTINEL_SERVICE_PORT=`eval echo "$""${REDIS_SENTINEL}_SERVICE_PORT"`
REDIS_SLAVE_HOST_NAME=`hostname -f`

echo "============== Debug ==============================" >> $DEBUG
echo "redis master svc :     ${REDIS_MASTER_SERVICE_IP}" >> $DEBUG
echo "redis sentinel svc:port    ${REDIS_SENTINEL_SERVICE_IP}:${REDIS_SENTINEL_SERVICE_PORT}" >> $DEBUG
echo "redis pod ip:              ${POD_IP}" >> $DEBUG

function getmaster() {
    flags="-h ${REDIS_SENTINEL_SERVICE_IP} -p ${REDIS_SENTINEL_SERVICE_PORT} -a $REDIS_PASS"
    for((retry = 1; retry <= 3; retry++))
    do
        master=`redis-cli ${flags} sentinel get-master-addr-by-name mymaster | head -1`
        if [ -n "$master" ]; then
            echo "Find master : ${master}" >> $DEBUG
            echo $master
            return
        else
            echo "Get master exec error. Wait 5 seconds and have a retry." >> $DEBUG 
            sleep 5
        fi
    done
    echo "NULL"
}

function launchmaster() {
    mkdir -p /redis-master-data
    sed -i "s/%redis-pass%/${REDIS_PASS}/" /etc/redis/redis-master.conf
    redis-server /etc/redis/redis-master.conf --protected-mode no
}

function launchsentinel() {
    while true; do
        master=`getmaster`
        echo "Get master returns : ${master}" 
        if [[ "${master}" == "NULL" ]]; then
            master=${REDIS_MASTER_SERVICE_IP}
        fi
        redis-cli -a $REDIS_PASS -h ${master} INFO
        if [[ "$?" == "0" ]]; then
            echo "Master has set up." 
            break
        fi
        echo "Connecting to master failed.  Waiting..." 
        sleep 10
    done

    sed -i "s/%master%/${master}/" /etc/redis/redis-sentinel.conf 
    sed -i "s/%password%/${REDIS_PASS}/" /etc/redis/redis-sentinel.conf 

    redis-sentinel /etc/redis/redis-sentinel.conf --protected-mode no
}

function launchslave() {
    while true; do
        master=`getmaster`
        echo "Get master returns : ${master}" 
        if [[ "${master}" != "NULL" ]]; then
            echo "Find master : ${master}"
        else
            echo "Failed to find master, I begin to launch master."
            launchmaster
            exit 0
        fi 
        redis-cli -a $REDIS_PASS -h ${master} INFO
        if [[ "$?" == "0" ]]; then
            break
        fi
        echo "Connecting to master failed.  Waiting..."
        sleep 10
    done
    echo "I am slave, begin to launch slave. REDIS_PASS: ${REDIS_PASS}"
    sed -i "s/%redis-pass%/${REDIS_PASS}/" /etc/redis/redis-slave.conf
    sed -i "s/%master-ip%/${master}/" /etc/redis/redis-slave.conf
    #sed -i "s/%slave_ip%/${POD_IP}/" /etc/redis/redis-slave.conf
    sed -i "s/%slave_ip%/${REDIS_SLAVE_HOST_NAME}/" /etc/redis/redis-slave.conf
    mkdir -p /redis-slave-data
    redis-server /etc/redis/redis-slave.conf --protected-mode no
}

if [[ "${MASTER}" == "true" ]]; then
    master=`getmaster`
    echo "Get master returns : ${master}" 
    if [[ "${master}" != "NULL" ]]; then
        echo "Master: $master has existed, continue restoring as a slave." 
    else
        echo "Can not to find a master. I begin to launch master."
        launchmaster
        exit 0
    fi
fi

if [[ "${SENTINEL}" == "true" ]]; then
    echo "I am sentinel, begin to launch sentinel." 
    launchsentinel
    exit 0
fi

launchslave
