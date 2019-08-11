---

# Running Stateful webapps

- Let's say we want to run a web application that persists state (and not in a database)

- That's hardly a good practice but we need a lightweight example

- We are going to deploy Nginx with 2 distinct instances

- Each instance will have a unique identity and it's own set of html files


---

## Creating a StatefulSet

- Let's reuse our `nginx-with-volumes` example

- It has a few extra touches:

  - a `podAntiAffinity` prevents two pods from running on the same node

  - a `preStop` hook makes the pod leave the cluster when shutdown gracefully

This was inspired by this [excellent tutorial](https://github.com/kelseyhightower/consul-on-kubernetes) by Kelsey Hightower.
Some features from the original tutorial (TLS authentication between
nodes and encryption of gossip traffic) were removed for simplicity.

---

## Running our Consul cluster

- We'll use the provided YAML file

.exercise[

- Create the stateful set and associated service:
  ```bash
  kubectl apply -f ~/container.training/k8s/consul.yaml
  ```

- Check the logs as the pods come up one after another:
  ```bash
  stern consul
  ```

<!--
```wait Synced node info```
```keys ^C```
-->

- Check the health of the cluster:
  ```bash
  kubectl exec consul-0 consul members
  ```

]

---

## Caveats

- We haven't used a `volumeClaimTemplate` here

- That's because we don't have a storage provider yet

  (except if you're running this on your own and your cluster has one)

- What happens if we lose a pod?

  - a new pod gets rescheduled (with an empty state)

  - the new pod tries to connect to the two others

  - it will be accepted (after 1-2 minutes of instability)

  - and it will retrieve the data from the other pods

---

## Failure modes

- What happens if we lose two pods?

  - manual repair will be required

  - we will need to instruct the remaining one to act solo

  - then rejoin new pods

- What happens if we lose three pods? (aka all of them)

  - we lose all the data (ouch)

- If we run Consul without persistent storage, backups are a good idea!
