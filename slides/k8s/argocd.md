# GitOps with ArgoCD

- It's widely accepted to use YAML files and Helm charts from Git to manage the resources in our Kubernetes cluster

- When this is automated it is now called "GitOps"

- The term was coined by Alexis Richardson of Weaveworks.

- Many tools exist for GitOps automation

- ArgoCD is one of the most popular ones due to its slick WebUI

---

## ArgoCD overview

- We put our Kubernetes resources as YAML files (or Helm charts) in a git repository

- ArgoCD polls that repository regularly 

- The resources described in git are created/updated automatically

- Changes are made by updating the code in the repository

---

## Preparing a repository for Flux

- We need a repository with Kubernetes YAML files

- I have one: https://github.com/otomato-gh/kubercoins

- Fork it to your GitHub account

- Create a new branch in your fork; e.g. `prod`

  (e.g. by adding a line in the README through the GitHub web UI)

- This is the branch that we are going to use for deployment

---

## Setting up Flux

- Clone the Flux repository:
  ```
  git clone https://github.com/fluxcd/flux
  ```

- Edit `deploy/flux-deployment.yaml`

- Change the `--git-url` and `--git-branch` parameters:
  ```yaml
  - --git-url=git@github.com:your-git-username/kubercoins
  - --git-branch=prod
  ```

- Apply all the YAML:
  ```
  kubectl apply -f deploy/
  ```

---

## Allowing Flux to access the repository

- When it starts, Flux generates an SSH key

- Display that key:
  ```
  kubectl logs deployment/flux | grep identity
  ```

- Then add that key to the repository, giving it **write** access

  (some Flux features require write access)

- After a minute or so, DockerCoins will be deployed to the current namespace

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
