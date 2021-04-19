# Entering the Pod

- In our day-to-day work we will usually run `kubectl` from outside the cluster (i.e our work station)

- But - many aspects of Kubernetes configuration can only be checked from within the cluster

- That's when we need to `exec` into the Pod

- Note: we can't really enter a Pod. So instead we enter a container in a Pod.

---

## Troubleshooting and verification 

- We usually enter containers in the cluster for troubleshooting

- In order to troubleshoot - the containers need to have utilities pre-installed (text editor, curl, netstat, dig, traceroute, etc)

- Or at least an execution shell with root permissions

---

## Running our Troubleshooting Pod

.exercise[

- Create the pod
  ```bash
  kubectl run --rm shooter --image=otomato/alpine-netcat:curl
  ```
- Exec into the container in the pod
  ```bash
  kubectl exec -it shooter sh
  # now try curling the api server
  curl -k https://kubernetes
  ```
]
