#!/bin/bash

work_dir=`dirname $0`
cd ${work_dir}
work_dir=`pwd`
# create secret for redis, including auth password
kubectl create -f redis-secret.yaml 
# create docker registry secret
kubectl create secret docker-registry myregistrykey --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL
# create pvc for redis-master and redis-slave
kubectl create -f redis-master.pvc.yaml
kubectl create -f redis-slave.pvc.yaml
# generate redis images
cd ${work_dir}/redis
make

# create redis master, wait until redis-master pod has been RUNNING.
kubectl create -f redis-master.statefulset.yaml 
sleep 20
# create redis sentinel, wait until redis-sentinel pods has been RUNNING. 
kubectl create -f redis-sentinel.statefulset.yaml
sleep 20
# create redis slave. 
kubectl create -f redis.statefulset.yaml
