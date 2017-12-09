## k8s-redis-ha
Redis High Availability on Kubernetes with [Statefulsets | Deployment] and Ceph
## Steps for statefulset
create secret for redis, including auth password
```
kubectl create -f redis-secret.yaml
```
create docker registry secret
```
kubectl create secret docker-registry myregistrykey --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL
```
generate redis images
```
cd ${work_dir}/redis
make
```
change to work dir
```
cd ${work_dir}/statefulset
```
create redis master, wait until redis-master pod has been RUNNING.
```
kubectl create -f redis-master.statefulset.yaml
sleep 20
```
create redis sentinel, wait until redis-sentinel pods has been RUNNING. 
```
kubectl create -f redis-sentinel.statefulset.yaml
sleep 20
```
create redis slave. 
```
kubectl create -f redis.statefulset.yaml
```
## Steps for deployment
create secret for redis, including auth password
```
kubectl create -f redis-secret.yaml
```
create docker registry secret
```
kubectl create secret docker-registry myregistrykey --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL
```
generate redis images
```
cd ${work_dir}/redis
make
```
change to work dir
```
cd ${work_dir}/deploymnet
```
create pvc for redis-master and redis-slave
```
kubectl create -f redis-master.pvc.yaml
kubectl create -f redis.pvc.yaml
```
create redis master, wait until redis-master pod has been RUNNING.
```
kubectl create -f redis-master.dm.yaml
sleep 20
```
create redis sentinel, wait until redis-sentinel pods has been RUNNING. 
```
kubectl create -f redis-sentinel.dm.yaml
sleep 20
```
create redis slave. 
```
kubectl create -f redis.dm.yaml
```
## Tips
`setup-statefulset.sh` and `setup-deployment.sh` give all steps to deploy HA redis cluster based on kubernetes.
