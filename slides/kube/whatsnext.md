# Next steps

*Alright, how do I get started and containerize my apps?*

--

Suggested containerization checklist:

.checklist[
- write a Dockerfile for one service in one app
- write Dockerfiles for the other (buildable) services
- write a Compose file for that whole app
- make sure that devs are empowered to run the app in containers
- set up automated builds of container images from the code repo
- set up a CI pipeline using these container images
- set up a CD pipeline (for staging/QA) using these images
]

And *then* it is time to look at orchestration!

---

## One big cluster vs. multiple small ones

- Yes, it is possible to have prod+dev in a single cluster

  (and implement good isolation and security with RBAC, network policies...)

- But it is not a good idea to do that for our first deployment

- Start with a production cluster + at least a test cluster

- Implement and check RBAC and isolation on the test cluster

  (e.g. deploy multiple test versions side-by-side)

- Make sure that all our devs have usable dev clusters

  (whether it's a local minikube or a full-blown multi-node cluster)

---

## Stateful services (databases etc.)

- As a first step, it is wiser to keep stateful services *outside* of the cluster

- Exposing them to pods can be done with multiple solutions:

  - `ExternalName` services
    <br/>
    (`redis.blue.svc.cluster.local` will be a `CNAME` record)

  - `ClusterIP` services with explicit `Endpoints`
    <br/>
    (instead of letting Kubernetes generate the endpoints from a selector)

  - Ambassador services
    <br/>
    (application-level proxies that can provide credentials injection and more)

---

## Stateful services (second take)

- If you really want to host stateful services on Kubernetes, you can look into:

  - volumes (to carry persistent data)

  - storage plugins

  - persistent volume claims (to ask for specific volume characteristics)

  - stateful sets (pods that are *not* ephemeral)

---

## HTTP traffic handling

- *Services* are layer 4 constructs

- HTTP is a layer 7 protocol

- It is handled by *ingresses* (a different resource kind)

- *Ingresses* allow:

  - virtual host routing
  - session stickiness
  - URI mapping
  - and much more!

- Check out e.g. [Træfik](https://docs.traefik.io/user-guide/kubernetes/)

---

## Logging

- Logging is delegated to the container engine

- Logs are exposed through the API

- Logs are also accessible through local files (`/var/log/containers`)

- Log shipping to a central platform is usually done through these files

  (e.g. with an agent bind-mounting the log directory)

---

## Metrics

- The kubelet embeds [cAdvisor](https://github.com/google/cadvisor), which exposes container metrics

  (cAdvisor might be separated in the future for more flexibility)

- It is a good idea to start with [Prometheus](https://prometheus.io/)

  (even if you end up using something else)

- Starting from Kubernetes 1.8, we can use the [Metrics API](https://kubernetes.io/docs/tasks/debug-application-cluster/core-metrics-pipeline/)

- [Heapster](https://github.com/kubernetes/heapster) was a popular add-on

  (but is being [deprecated](https://github.com/kubernetes/heapster/blob/master/docs/deprecation.md) starting with Kubernetes 1.11)

---

## Managing the configuration of our applications

- Two constructs are particularly useful: secrets and config maps

- They allow to expose arbitrary information to our containers

- **Avoid** storing configuration in container images

  (There are some exceptions to that rule, but it's generally a Bad Idea)

- **Never** store sensitive information in container images

  (It's the container equivalent of the password on a post-it note on your screen)

---

## Cluster federation

- Kubernetes master operation relies on etcd

- etcd uses the Raft protocol

- Raft recommends low latency between nodes

- What if our cluster spreads multiple regions?

--

- Break it down in local clusters

- Regroup them in a *cluster federation*

- Synchronize resources across clusters

- Discover resources across clusters

---

## Developer experience

*I've put this last, but it's pretty important!*

- How do you on-board a new developer?

- What do they need to install to get a dev stack?

- How does a code change make it from dev to prod?

- How does someone add a component to a stack?
