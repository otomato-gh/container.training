# First contact with `kubectl`

- `kubectl` is (almost) the only tool we'll need to talk to Kubernetes

- It is a rich CLI tool around the Kubernetes API

  (Everything you can do with `kubectl`, you can do directly with the API)

- On our machines, there is a `~/.kube/config` file with:

  - the Kubernetes API address

  - the path to our TLS certificates used to authenticate

- You can also use the `--kubeconfig` flag to pass a config file

- Or directly `--server`, `--user`, etc.

- `kubectl` can be pronounced "Cube C T L", "Cube cuttle", "Cube cuddle"...

---

class: extra-details

## `kubectl` is the new SSH

- We often start managing servers with SSH

  (installing packages, troubleshooting ...)

- At scale, it becomes tedious, repetitive, error-prone

- Instead, we use config management, central logging, etc.

- In many cases, we still need SSH:

  - as the underlying access method (e.g. Ansible)

  - to debug tricky scenarios

  - to inspect and poke at things

---

class: extra-details

## The parallel with `kubectl`

- We often start managing Kubernetes clusters with `kubectl`

  (deploying applications, troubleshooting ...)

- At scale (with many applications or clusters), it becomes tedious, repetitive, error-prone

- Instead, we use automated pipelines, observability tooling, etc.

- In many cases, we still need `kubectl`:

  - to debug tricky scenarios

  - to inspect and poke at things

- The Kubernetes API is always the underlying access method

---

## `kubectl get`

- Let's look at our `Node` resources with `kubectl get`!

.exercise[

- Look at the composition of our cluster:
  ```bash
  kubectl get node
  ```

- These commands are equivalent:
  ```bash
  kubectl get no
  kubectl get node
  kubectl get nodes
  ```

]

---

## Obtaining machine-readable output

- `kubectl get` can output JSON, YAML, or be directly formatted

.exercise[

- Give us more info about them nodes:
  ```bash
  kubectl get nodes -o wide
  ```

- Let's have some YAML:
  ```bash
  kubectl get no -o yaml
  ```
  See that `kind: List` at the end? It's the type of our result!

]

---

## (Ab)using `kubectl` and `jq`

- It's super easy to build custom reports

.exercise[

- Show the capacity of all our nodes as a stream of JSON objects:
  ```bash
    kubectl get nodes -o json |
            jq ".items[] | {name:.metadata.name} + .status.capacity"
  ```

]
.footnote[You may need to install `jq` by running `apt install jq`]
---

class: extra-details

## Exploring types and definitions

- We can list all available resource types by running `kubectl api-resources`
  <br/>
  (In Kubernetes 1.10 and prior, this command used to be `kubectl get`)

- We can view the definition for a resource type with:
  ```bash
  kubectl explain type
  ```

- We can view the definition of a field in a resource, for instance:
  ```bash
  kubectl explain node.spec
  ```

- We can view the definition for a resource type with:
  ```bash
  kubectl explain node --recursive
  ```
---

## Type names

- The most common resource names have three forms:

  - singular (e.g. `node`, `service`, `deployment`)

  - plural (e.g. `nodes`, `services`, `deployments`)

  - short (e.g. `no`, `svc`, `deploy`)

- Some resources do not have a short name

- `Endpoints` only have a plural form

  (because even a single `Endpoints` resource is actually a list of endpoints)

---

## Viewing details

- We can use `kubectl get -o yaml` to see all available details

- However, YAML output is often simultaneously too much and not enough

- For instance, `kubectl get node node1 -o yaml` is:

  - too much information (e.g.: list of images available on this node)

  - not enough information (e.g.: doesn't show pods running on this node)

  - difficult to read for a human operator

- For a comprehensive overview, we can use `kubectl describe` instead

---

## `kubectl describe`

- `kubectl describe` needs a resource type and (optionally) a resource name

- It is possible to provide a resource name *prefix*

  (all matching objects will be displayed)

- `kubectl describe` will retrieve some extra information about the resource

.exercise[

- Look at the information available for `node1` with one of the following commands:
```bash
    kubectl describe node/node1
    kubectl describe node node1
```
]

(We should notice a bunch of control plane pods.)

---

class: extra-details

## Introspection vs. documentation

- We can access the same information by reading the [API documentation](https://kubernetes.io/docs/reference/#api-reference)

- The API documentation is usually easier to read, but:

  - it won't show custom types (like Custom Resource Definitions)

  - we need to make sure that we look at the correct version

- `kubectl api-resources` and `kubectl explain` perform *introspection*

  (they communicate with the API server and obtain the exact type definitions)

---

## Type names

- The most common resource names have three forms:

  - singular (e.g. `node`, `service`, `deployment`)

  - plural (e.g. `nodes`, `services`, `deployments`)

  - short (e.g. `no`, `svc`, `deploy`)

- Some resources do not have a short name

- `Endpoints` only have a plural form

  (because even a single `Endpoints` resource is actually a list of endpoints)

---

## Viewing details

- We can use `kubectl get -o yaml` to see all available details

- However, YAML output is often simultaneously too much and not enough

- For instance, `kubectl get node minikube -o yaml` is:

  - too much information (e.g.: list of images available on this node)

  - not enough information (e.g.: doesn't show pods running on this node)

  - difficult to read for a human operator

- For a comprehensive overview, we can use `kubectl describe` instead

---

## `kubectl describe`

- `kubectl describe` needs a resource type and (optionally) a resource name

- It is possible to provide a resource name *prefix*

  (all matching objects will be displayed)

- `kubectl describe` will retrieve some extra information about the resource

.exercise[

- Look at the information available for `minikube` node with one of the following commands:
  ```bash
  kubectl describe node/minikube
  kubectl describe node minikube
  ```

]

(We should notice a bunch of control plane pods.)

---

## Services

- A *service* is a stable endpoint to connect to "something"

  (In the initial proposal, they were called "portals")

.exercise[

- List the services on our cluster with one of these commands:
  ```bash
  kubectl get services
  kubectl get svc
  ```

]

--

There is already one service on our cluster: the Kubernetes API itself.

---

## ClusterIP services

- A `ClusterIP` service is internal, available from the cluster only

- This is useful for introspection from within containers

.exercise[

- Try to connect to the API:
  ```bash
  curl -k https://`10.96.0.1`
  ```
  
  - `-k` is used to skip certificate verification
  - Make sure to replace 10.96.0.1 with the CLUSTER-IP shown earlier

]

--

The error that we see is expected: the Kubernetes API requires authentication.

---

## Listing running containers

- Containers are manipulated through *pods*

- A pod is a group of containers:

 - running together (on the same node)

 - sharing resources (RAM, CPU; but also network, volumes)

.exercise[

- List pods on our cluster:
  ```bash
  kubectl get pods
  ```

]

--

*These are not the pods you're looking for.* But where are they?!?

---

## Namespaces

- Namespaces allow to segregate resources

.exercise[

- List the namespaces on our cluster with one of these commands:
  ```bash
  kubectl get namespaces
  kubectl get namespace
  kubectl get ns
  ```

]

--

*You know what ... This `kube-system` thing looks suspicious.*

---

## Accessing namespaces

- By default, `kubectl` uses the `default` namespace

- We can switch to a different namespace with the `-n` option

- We can see resources in all namespaces with `--all-namespaces`

.exercise[

- List the pods in the `kube-system` namespace:
  ```bash
  kubectl -n kube-system get pods
  ```
- List the pods in all namespaces:
  ```bash
  kubectl get pods --all-namespaces
  ```
- Since Kubernetes 1.14, we can also use `kubectl get pods -A` as a shorter version:
]

--

*Ding ding ding ding ding!*

---

## What are all these pods?

- `etcd` is our etcd server

- `kube-apiserver` is the API server

- `kube-controller-manager` and `kube-scheduler` are other master components

- `coredns` is an additional component (not mandatory but super useful, so it's there)

- `kube-proxy` is the (per-node) component managing port mappings and such

- `weave` is the (per-node) component managing the network overlay

- the `READY` column indicates the number of containers in each pod

- the pods with a name ending with `-node1` (or `-minikube` are the master components
  <br/>
  (they have been specifically "pinned" to the master node)

---

class: extra-details

## What about `kube-public`?

.exercise[

- List the pods in the `kube-public` namespace:
  ```bash
  kubectl -n kube-public get pods
  ```

]

Nothing!

`kube-public` is created by kubeadm & [used for security bootstrapping](https://kubernetes.io/blog/2017/01/stronger-foundation-for-creating-and-managing-kubernetes-clusters).

---

class: extra-details

## Exploring `kube-public`

- The only interesting object in `kube-public` is a ConfigMap named `cluster-info`

.exercise[

- List ConfigMap objects:
  ```bash
  kubectl -n kube-public get configmaps
  ```

- Inspect `cluster-info`:
  ```bash
  kubectl -n kube-public get configmap cluster-info -o yaml
  ```

]

Note the `selfLink` URI: `/api/v1/namespaces/kube-public/configmaps/cluster-info`

We can use that!

---

class: extra-details

## Accessing `cluster-info`

- Earlier, when trying to access the API server, we got a `Forbidden` message

- But `cluster-info` is readable by everyone (even without authentication)

.exercise[

- Retrieve `cluster-info`:
  ```bash
  curl -k https://10.96.0.1/api/v1/namespaces/kube-public/configmaps/cluster-info
  ```

]

- We were able to access `cluster-info` (without auth)

- It contains a `kubeconfig` file

---

class: extra-details

## Retrieving `kubeconfig`

- We can easily extract the `kubeconfig` file from this ConfigMap

.exercise[

- Display the content of `kubeconfig`:
  ```bash
    curl -sk https://10.96.0.1/api/v1/namespaces/kube-public/configmaps/cluster-info \
         | jq -r .data.kubeconfig
  ```

]

- This file holds the canonical address of the API server, and the public key of the CA

- This file *does not* hold client keys or tokens

- This is not sensitive information, but allows us to establish trust

---

class: extra-details

## What about `kube-node-lease`?

- Starting with Kubernetes 1.14, there is a `kube-node-lease` namespace

  (or in Kubernetes 1.13 if the NodeLease feature gate is enabled)

- That namespace contains one Lease object per node

- *Node leases* are a new way to implement node heartbeats

  (i.e. node regularly pinging the control plane to say "I'm alive!")

- For more details, see [KEP-0009] or the [node controller documentation]

[KEP-0009]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/0009-node-heartbeat.md
[node controller documentation]: https://kubernetes.io/docs/concepts/architecture/nodes/#node-controller