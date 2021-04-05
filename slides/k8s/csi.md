# The Container Storage Interface
![CSI](https://content.architecting.it/wp-images/post_3cad_featured.png)

- A standardised API for container orchestration platforms (COs) to talk to storage plugins

- Allows to decouple storage configuration from Kubernetes (Nomad or Mesos)

- Once a CSI compatible volume driver is deployed on a Kubernetes cluster, users may use the `csi` volume type

---
## Kubernetes Storage Plugins History

-   Before v1.2 : In-Tree Persistent Volume Plugins (e.g: awsElasticBlockStore, cephfs, iscsi)

  - For a full list see [here](https://kubernetes.io/docs/concepts/storage/volumes/)

-  Before v1.13 : FlexVolume Plugins (Require `FlexVolume Drivers` on the nodes and `dynamic provisioners`)

-  After v1.13 : CSI - Requires `CSI Controller` and `CSI Node driver`

---

class: pic

![CSI](images/CSI_architecture.png)

* Diagram credit: @datamattsson

---
## CSI - More Info

CSI Specification
- https://github.com/container-storage-interface/spec 

Kubernetes SIG Storage
- https://github.com/kubernetes/community/tree/master/sig-storage 

CSI Documentation
-  https://kubernetes-csi.github.io/