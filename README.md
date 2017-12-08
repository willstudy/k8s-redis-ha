## k8s-redis-ha
Redis High Availability on Kubernetes with Statefulsets and Ceph
## Steps
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
## Tips
`setup.sh` gives all steps to deploy HA redis cluster based on kubernetes.
