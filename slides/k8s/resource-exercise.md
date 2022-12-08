
## Managing Resources - An Exercise

- We will start a web service that stresses out memory when called

- We will define a memory limit for it

- We will send some traffic to that service

- We will watch it get killed

---

## A memory-intensive web service

- Let's use `otomato-gh/busyhttp`

  (it is a web server that can load CPU or memory dependent on the endpoint called)

.exercise[

- Generate the yaml for the deployment:
  ```bash
  kubectl create deployment busyhttp --image=otomato/busyhttp --dry-run=client -oyaml > busy.yaml
  ```

- Edit the deployment to limit the memory:
  ```yaml
  resources:
    limits:
      memory: 50M
  ```
]
---

## Deploy the webserver

.exercise[
- Deploy, expose, get the cluster IP:
  ```bash
  kubectl apply -f busy.yaml
  kubectl expose deployment busyhttp --port=80
  CLUSTERIP=$(kubectl get svc busyhttp -o jsonpath={.spec.clusterIP})
  ```

]

---

## Montior what's going on:

- Let's start a bunch of commands to watch what is happening

.exercise[

- Monitor pod state:
  ```bash
  watch kubectl get pods -l app=busyhttp
  ```

- Start a network testing container:
  ```bash
  kubectl run netutils --image=otomato/net-utils "ping localhost"
  ``` 
- Monitor cluster events:
  ```bash
  kubectl get events -w
  ```

]

---

## Send traffic to the service

- We will use `httping` to send traffic

.exercise[

- `busyhttp` consumes 1Mb of memory for each request to `/memory` endpoint
- Create the load :
  ```bash
  kubectl exec netutils httping -c 50 http://`$CLUSTERIP`/
  ```

]

Once the container reaches 50Mb it should get killed and restarted

---
