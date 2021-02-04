# BackUp and Restore with Velero

[Velero](https://velero.io) (formerly Heptio Ark) gives you tools to back up and restore your Kubernetes cluster resources and persistent volumes. 

You can run Velero with a cloud provider or on-premises. 

Velero lets you:

- Take backups of your cluster and restore in case of loss.
- Migrate cluster resources to other clusters.
- Replicate your production cluster to development and testing clusters.

Velero consists of:

- A server that runs on your cluster
- A command-line client that runs locally

---

## Installing Velero

First - download and extract the official Velero release tarball:

.exercise[
```
curl -L https://git.io/Jtzry -o velero.tar.gz
tar xvfz velero.tar.gz
cd velero-v1.5.3-linux-amd64
export PATH=.:${PATH}
```
]

---
## Installing Velero in Cluster

We need to run Velero's cluster-side component, specifying the storage backend for storing the backups.

For the workshop we will use [Minio](https://minio.io) - the AWS S3 simulator as our storage backend.
