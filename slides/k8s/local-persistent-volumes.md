# Local Persistent Volumes

- We want to run that our Nginx instances *and* actually persist data

- But we don't have a distributed storage system

- We are going to use local volumes instead

  (similar conceptually to `hostPath` volumes)

- We can use local volumes without installing extra plugins

- However, they are tied to a node

- If that node goes down, the volume becomes unavailable

---

## With or without dynamic provisioning

- We will deploy a StatefulSet *with* persistence

- Each pod in the StatefulSet will create a PVC

- These PVCs will remain unbound¹, until we will create local volumes manually

  (we will basically do the job of the dynamic provisioner)

- Then, we will see how to automate that with a dynamic provisioner

.footnote[¹Unbound = without an associated Persistent Volume.]

---

## If we have a dynamic provisioner ...

- The labs in this section assume that we *do not* have a dynamic provisioner

- If we do have one, we need to disable it

.exercise[

- Check if we have a dynamic provisioner:
  ```bash
  kubectl get storageclass
  ```

- If the output contains a line with `(default)`, run this command:
  ```bash
  kubectl annotate sc storageclass.kubernetes.io/is-default-class- --all
  ```

- Check again that it is no longer marked as `(default)`

]

---

## Work in a separate namespace

- To avoid conflicts with existing resources, let's create and use a new namespace

.exercise[

- Create a new namespace:
  ```bash
  kubectl create namespace orange
  ```

- Switch to that namespace:
  ```bash
  kns orange
  ```

]

.warning[Make sure to call that namespace `orange`: it is hardcoded in the YAML files.]

---

## Deploying Nginx instances

- We will use a slightly different YAML file

- The only differences between that file and the previous one are:

  - `volumeClaimTemplate` defined in the Stateful Set spec

  - the corresponding `volumeMounts` in the Pod spec

  - the namespace `orange` used for discovery of Pods

.exercise[

- Apply the persistent Nginx YAML file:
  ```bash
  kubectl apply -f ~/container.training/k8s/ss-nginx-with-pv.yaml
  ```

]

---

## Observing the situation

- Let's look at Persistent Volume Claims and Pods

.exercise[

- Check that we now have an unbound Persistent Volume Claim:
  ```bash
  kubectl get pvc -n orange
  ```

- We don't have any Persistent Volume:
  ```bash
  kubectl get pv
  ```

- The Pod `nginx-0` is not scheduled yet:
  ```bash
  kubectl get pods -n orange -o wide
  ```

]

*Hint: leave these commands running with `-w` in different windows.*

---

## Explanations

- In a Stateful Set, the Pods are started one by one

- `nginx-1` won't be created until `nginx-0` is running

- `nginx-0` has a dependency on an unbound Persistent Volume Claim

- The scheduler won't schedule the Pod until the PVC is bound

  (because the PVC might be bound to a volume that is only available on a subset of nodes; for instance EBS are tied to an availability zone)

---

## Creating Persistent Volumes

- Let's create 2 local directories (`/mnt/nginx`) on node1 and node2

- Then create 2 Persistent Volumes corresponding to these directories

---
## Creating local persistent volumes
.exercise[
- On node1 and node 2
  ```bash
  sudo mkdir -p /mnt/nginx
  ```
- Create the PV objects:
  ```bash
  kubectl apply -f ~/container.training/k8s/volumes-for-ngix.yaml
  ```
]
- Note: this relies on your nodes being named `node1` and `node2`. If they are not - edit `~/container.training/k8s/volumes-for-nginx.yaml`:
```yaml
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <your_node_name>
```


---

## Check our StatefulSet

- The PVs that we created will be automatically matched with the PVCs

- Once a PVC is bound, its pod can start normally

- Once the pod `nginx-0` has started, `nginx-1` can be created, etc.

- Eventually, all our nginx instances are up, and backed by "persistent" volumes

.exercise[

- Change the html for nginx-0, kill the pod, verify changes persist :
  ```bash
  kubens orange
  kubectl exec nginx-0 -- \
  perl -i -ple "s/octocat/kubernetesio/g" /usr/share/nginx/html/index.html
  kubectl run -it --rm curl --image=otomato/alpine-netcat:curl -- curl nginx-0.nginx
  kubectl delete pod nginx-0
  # wait for the pod to come back
  kubectl run -it --rm curl --image=otomato/alpine-netcat:curl -- curl nginx-0.nginx 
  ```
]

---

## Devil is in the details (1/2)

- The size of the Persistent Volumes is bogus

  (it is used when matching PVs and PVCs together, but there is no actual quota or limit)

---

## Devil is in the details (2/2)

- This specific example worked because we had exactly 1 free PV per node:

  - if we had created multiple PVs per node ...

  - we could have ended with two PVCs bound to PVs on the same node ...

  - which would have required two pods to be on the same node ...

  - which is forbidden by the anti-affinity constraints in the StatefulSet

- To avoid that, we need to associate the PVs with a Storage Class that has:
  ```yaml
  volumeBindingMode: WaitForFirstConsumer
  ```
  (this means that a PVC will be bound to a PV only after being used by a Pod)

- See [this blog post](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/) for more details

---

## Bulk provisioning

- It's not practical to manually create directories and PVs for each app

- We *could* pre-provision a number of PVs across our fleet

- We could even automate that with a Daemon Set:

  - creating a number of directories on each node

  - creating the corresponding PV objects

- We also need to recycle volumes

- ... This can quickly get out of hand

---

## Dynamic provisioning

- We could also write our own provisioner, which would:

  - watch the PVCs across all namespaces

  - when a PVC is created, create a corresponding PV on a node

- Or we could use one of the dynamic provisioners for local persistent volumes

  (for instance the [Rancher local path provisioner](https://github.com/rancher/local-path-provisioner))

---

## Strategies for local persistent volumes

- Remember, when a node goes down, the volumes on that node become unavailable

- High availability will require another layer of replication

- Pre-provisioning PVs makes sense for machines with local storage

  (e.g. cloud instance storage; or storage directly attached to a physical machine)

- Dynamic provisioning makes sense for large number of applications

  (when we can't or won't dedicate a whole disk to a volume)

- It's possible to mix both (using distinct Storage Classes)
