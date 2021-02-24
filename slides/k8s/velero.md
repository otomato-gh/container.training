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

---
## Install Minio

Deploy Minio to the cluster:
.exercise[
```
  kubectl apply -f ~/container.training/k8s/minio.yaml
```
- Get the NodePort for minio service:
```
PORT=$(kubectl get svc minio -n velero -ojsonpath="{ .spec.ports[0].nodePort }")
```
- Create a local file with Minio credentials (minio-creds):
```
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
```
]

---
## Deploy Velero with Minio Backend

.exercise[
- Get the IP of the master node:
```
  NODEIP=$(kubectl get node -l=kubernetes.io/role=master \
   -ojsonpath="{ .items[0].status.addresses[?(@.type=='ExternalIP')].address }")
  PUBLICURL=http://${NODEIP}:${PORT}
```
```
  velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.0.0 \
  --bucket velero \
  --secret-file ./minio-creds \
  --use-volume-snapshots=true \
  --use-restic \
  --backup-location-config \
  region=minio,s3ForcePathStyle="true",s3Url=http://minio:9000,publicUrl=${PUBLICURL}
```
]

---
## Deploy the example Deployment with PV

**Note** - if you've previously deployed OpenEBS on the training cluster - change the PVC definition in velero-example-pod.yaml to `storageClassName: openebs-hostpath`

.exercise[
```
  kubectl apply -f ~/container.training/k8s/velero-example-pod.yaml
```
- Check to see that both the Velero and example deployments are successfully created:
```
  kubectl get deployments -l component=velero --namespace=velero
  kubectl get deployments --namespace=velero-example
```
]

---

## Create a Velero Backup

Velero can filter backup resources based on specified selectors, full namespace backups and [more options](https://velero.io/docs/v1.5/resource-filtering/)

To specify a selector - pass `--selector` to `velero backup create`

To specify a whole namespace - pass `--include-namespace`

.exercise[
Backup the nginx instance with PV:
```
  velero backup create my-backup --include-namespaces velero-example
```
]

---

## Check the backup status

.exercise[

- Describe the backup
```bash
  velero backup describe my-backup
```
 - Check the backup logs:
```bash
  velero backup logs my-backup
```
]

---

## Simulate a DRP

.exercise[

- The namespace gets destroyed
```bash
  kubectl delete deploy \
    -n velero-example \
    --all --force \
    --grace-period=0
  kubectl delete pvc velero-logs -n velero-example --force
  kubectl delete namespace velero-example --force
```
- Verify the PV got deleted as well:
```bash
  kubectl get pv
```
]

**Note**: your resources may get stuck in *Terminating* state. You will have to deal with object *finalizers* to resolve this. Ask your instructor for help, or look at this [StackOverflow question](https://stackoverflow.com/questions/52369247/namespace-stuck-as-terminating-how-do-i-remove-it)

---
## Let's restore everything

.exercise[
```
velero restore create my-restore \
  --from-backup=my-backup \
  --restore-volumes=true
```
- Verify all objects got restored:
```
kubectl get all -n velero-example
kubectl get pvc -n velero-example
```
]