# GitOps with ArgoCD

- Resources in our Kubernetes cluster can be described in YAML files

- These YAML files can and should be stored in source control - specifically - Git

- YAML manifests from Git can then be used to continuously update our cluster configuraition

- When this process is automated - it is now called "GitOps"

- The term was coined by Alexis Richardson of Weaveworks.

- Many tools exist for GitOps automation

- ArgoCD is one of the most popular ones due to its slick WebUI

---

## ArgoCD overview

![ArgoCD Logo](images/argocdlogo.png)
- We put our Kubernetes resources as YAML files (or Helm charts) in a git repository

- ArgoCD polls that repository regularly 

- The resources described in git are created/updated automatically

- Changes are made by updating the code in the repository

---

## Preparing a repository for ArgoCD

- We need a repository with Kubernetes YAML files

- Let's use **kubercoins**: https://github.com/otomato-gh/kubercoins

- Fork it to your GitHub account

- Create a new branch in your fork; e.g. `prod`

  (e.g. by adding a line in the README through the GitHub web UI)

- This is the branch that we are going to use for deployment

---

## Setting up ArgoCD

- We have a YAML file that installs core ArgoCD components 

- Apply the yaml:

```bash
kubectl create namespace argocd
kubectl apply ~/container.training/k8s/argocd.yaml
```

- This will create a new namespace, argocd, where Argo CD services and application resources will live.

---

## Installing the ArgoCD CLI

- ArgoCD features both a WebUI and a CLI

- CLI can be used for automation and some of the configuration not currently available in the WebUI

- Download the CLI:

.exercise[
```bash
VERSION=v2.2.1
curl -sSL -o /usr/local/bin/argocd \ 
    https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```
]
---
## Logging in with the ArgoCD CLI

Verify we can login to ArgoCD via CLI:

```bash
argocd login --core
```

You should see "Context 'kubernetes' updated"


---

class: pic

![ArgoCD Architecture w:100 h:100](images/argocd_architecture.png)

---

## ArgoCD - the Core Concepts

- ArgoCD manages **Applications** by **syncing** their live state with their **desired state**

- Application: A group of Kubernetes resources as defined by a manifest. This is a Custom Resource Definition (CRD).

- Application source type: Which Tool is used to build the application.

- Target state: The desired state of an application, as represented by files in a Git repository.
- Live state:  The live state of that application. What pods etc are deployed.

- Sync status:
 Whether or not the live state matches the target state. Is the deployed application the same as Git says it should be?
- Sync: The process of making an application move to its target state. E.g. by applying changes to a Kubernetes cluster.

---
## Making changes

- Make changes (on the `prod` branch), e.g. change `replicas` in `worker`

- After a few minutes, the changes will be picked up by Flux and applied

---

## Other features

- Flux can keep a list of all the tags of all the images we're running

- The `fluxctl` tool can show us if we're running the latest images

- We can also "automate" a resource (i.e. automatically deploy new images)

- And we can manage Helm releases in a GitOps way with [Flux Helm Operator](https://github.com/fluxcd/helm-operator-get-started)

---

## Gitkube overview

- We put our Kubernetes resources as YAML files in a git repository

- Gitkube is a git server (or "git remote")

- After making changes to the repository, we push to Gitkube

- Gitkube applies the resources to the cluster

---

## Setting up Gitkube

- Install the CLI:
  ```
  sudo curl -L -o /usr/local/bin/gitkube \
       https://github.com/hasura/gitkube/releases/download/v0.2.1/gitkube_linux_amd64
  sudo chmod +x /usr/local/bin/gitkube
  ```

- Install Gitkube on the cluster:
  ```
  gitkube install --expose ClusterIP
  ```

---

## Creating a Remote

- Gitkube provides a new type of API resource: *Remote*

  (this is using a mechanism called Custom Resource Definitions or CRD)

- Create and apply a YAML file containing the following manifest:
  ```yaml
	apiVersion: gitkube.sh/v1alpha1
	kind: Remote
	metadata:
	  name: example
	spec:
	  authorizedKeys:
	  - `ssh-rsa AAA...`
	  manifests:
	    path: "."
  ```

  (replace the `ssh-rsa AAA...` section with the content of `~/.ssh/id_rsa.pub`)

---

## Pushing to our remote

- Get the `gitkubed` IP address:
  ```
  kubectl -n kube-system get svc gitkubed
  IP=$(kubectl -n kube-system get svc gitkubed -o json | 
  	   jq -r .spec.clusterIP)
  ```

- Get ourselves a sample repository with resource YAML files:
  ```
  git clone git://github.com/otomato-gh/kubercoins
  cd kubercoins
  ```

- Add the remote and push to it:
  ```
  git remote add k8s ssh://default-example@$IP/~/git/default-example
  git push k8s master
  ```

---

## Making changes

- Edit a local file

- Commit

- Push!

- Make sure that you push to the `k8s` remote

---

## Other features

- Gitkube can also build container images for us

  (see the [documentation](https://github.com/hasura/gitkube/blob/master/docs/remote.md) for more details)

- Gitkube can also deploy Helm charts

  (instead of raw YAML files)

???

:EN:- GitOps
:FR:- GitOps
