#!/bin/bash

work_dir=`dirname $0`
cd ${work_dir}
work_dir=`pwd`

# create ceph secret
kubectl create -f ceph-secret.yaml
# create registry image pull scret
kubectl create -f registry-secret.yaml
# create redis secret
kubectl create -f redis-secret.yaml
# create redis config map
kubectl create -f redis.cm.yaml

cd ${work_dir}/redis
make

# create redis master, wait until redis-master pod has been RUNNING.
kubectl create -f redis-master.statefulset.yaml 
sleep 20
# create redis sentinel, wait until redis-sentinel pods has been RUNNING. 
kubectl create -f redis-sentinel.statefulset.yaml
sleep 20
# create redis slave. 
kubectl create -f redis-slave.statefulset.yaml
