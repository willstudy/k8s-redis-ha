#!/bin/sh

/usr/bin/supervisord
supervisorctl update

# Let the pod run forever
always_sleep="yes"
while [ "${always_sleep}" = "yes" ]; do
    sleep 86400
done
