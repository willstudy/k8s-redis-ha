## k8s-redis-ha
Redis High Availability on Kubernetes with [Statefulsets | Deployment] and Ceph
## Steps for statefulset
change to work dir
```
cd statefulset
```
create ceph secret
```
kubectl create -f ceph-secret.yaml
```
create registry image pull scret
```
kubectl create -f registry-secret.yaml
```
create redis secret
```
kubectl create -f redis-secret.yaml
```
create redis config map
```
kubectl create -f redis.cm.yaml
```
generate redis images
```
cd ../redis
make
```
change to work dir
```
cd statefulset
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
kubectl create -f redis-slave.statefulset.yaml
```
## Steps for deployment
Not Completed
## Tips
`setup-statefulset.sh` and `setup-deployment.sh` give all steps to deploy HA redis cluster based on kubernetes.
