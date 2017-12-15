#!/bin/bash

REDIS_VERSION="4.0.6"
REDIS="redis-${REDIS_VERSION}"

cd /home/redis
wget http://download.redis.io/releases/${REDIS}.tar.gz
tar xzf ${REDIS}.tar.gz
cd ${REDIS}
make
make install
cd utils
sh ./install_server.sh
