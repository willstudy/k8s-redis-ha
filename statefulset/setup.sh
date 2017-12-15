#!/bin/bash

# create ceph secret
kubectl create -f ceph-secret.yaml
# create registry image pull scret
kubectl create -f registry-secret.yaml
# create redis secret
kubectl create -f redis-secret.yaml
# create redis config map
kubectl create -f redis.cm.yaml
