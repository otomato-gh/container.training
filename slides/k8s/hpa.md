# Autoscaling Workloads


- Scaling deployments manually is fun!

- But can't Kubernetes take care of this for us?

- Of course it can!

- Enter [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

---

## Horizontal Pod Autoscaler


- Horizontal Pod Autoscaler (HPA)
automatically scales the number of pods in a deployment based on observed CPU utilization

  - Utilization is calculated as a percentage of the equivalent resource request on the containers in each pod.

- Or on custom metrics, but that is more complex to set up

- But how does the HPA get the metrics?

- We need to install [metrics-server](https://github.com/kubernetes-incubator/metrics-server) or Heapster (deprecated)
---

## Installing Metrics Server

.exercise[
- Create a metrics-server deployment and service:
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/metrics-server/v1.8.x.yaml
  ```
- It takes the metrics server a couple of minutes to start scraping metrics
  
  - Go grab a coffee ;)

- Check:

  ```bash
  kubectl top node
  kubectl top pod
  ```]

---

## Scaling out Based on CPU Load

.exercise[
- Deploy a service that creates CPU load when asked to:
]
.small[
```bash
kubectl run loader --image=otomato/python-loader --requests=cpu=200m --expose --port=5000
#and create an autoscaler for it:
kubectl autoscale deployment loader --cpu-percent=30 --min=1 --max=5
```
]
.exercise[
- Let's run a request from another pod to generate load:
]
.small[
```bash
kubectl run -i --tty requester --image=otomato/alpine-netcat:curl /bin/sh
curl http://loader:5000/load
```
]

---

## Scaling out Based on CPU Load
.exercise[
- Let's see what happens to our HPA:
]
.small[
```bash
kubectl get hpa -w
```
]
.exercise[
- Once we see the utilization go higher than 50% - let's check the pods:
]
.small[
```
kubectl get pod -l run=loader
```]

- We should see 5 pods!

---

## Clean up 

- Exit the `requester` container

- Delete the `loader` pod that loads the cpu

- HPA will downscale the rest of the pods in ~5 minutes