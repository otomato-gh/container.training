# Network policies

- By default: 

  - all pods can access all other pods (by ip)

  - all pods can access all services 
  
  - in the same namespace (by name only)
  
  - in all other namespaces (by FQDN: *servicename*.namespace.svc.cluster.local)

---

## Network policies

- Let's try to see if we can access our 'redis' service from our 'hasher' pod

.exercise[

- Run shell inside the hasher pod
  ```bash
  #get the name of the hasher pod
  kubectl get pod -l run=hasher
  kubectl exec -it <hasher-pod-name> sh
  \#inside the pod:
    nc redis 6379
    PING
  \# you should get:
  \# +PONG
  # which means redis is answering
  ```

]
---

## Restricting Access

- But 'hasher' shouldn't be accessing the db! Only 'worker' should be allowed to do this! 

- **NetworkPolicy** to the rescue

A network policy is a specification of how groups of pods are allowed to communicate with each other and other network endpoints.

NetworkPolicy resources use labels to select pods and define rules which specify what traffic is allowed to the selected pods.

---

## Restricting Access

- Let's define a network policy:

.exercise[

 - Create a file 'redis-access-nwp.yaml' with the following content:
]
.small[
```yaml
  kind: NetworkPolicy                
  apiVersion: networking.k8s.io/v1                                                                         
  metadata:
    name: access-redis
  spec:
    podSelector:
      matchLabels:
          run: redis
      ingress:
      \- from:
        \- podSelector:
            matchLabels: 
              accessRedis: true
```]