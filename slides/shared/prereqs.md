# Pre-requirements

- Be comfortable with the UNIX command line

  - navigating directories

  - editing files

  - a little bit of bash-fu (environment variables, loops)

- Some Docker knowledge

  - `docker run`, `docker ps`, `docker build`

  - ideally, you know how to write a Dockerfile and build it
    <br/>
    (even if it's a `FROM` line and a couple of `RUN` commands)

- It's totally OK if you are not a Docker expert!

---

class: extra-details

## Extra details

- This slide should have a little magnifying glass in the top left corner

  (If it doesn't, it's because CSS is hard)

- Slides with that magnifying glass indicate slides providing extra details

- Feel free to skip them if you're in a hurry!

---

class: title

*Tell me and I forget.*
<br/>
*Teach me and I remember.*
<br/>
*Involve me and I learn.*

Misattributed to Benjamin Franklin

[(Probably inspired by Chinese Confucian philosopher Xunzi)](https://www.barrypopik.com/index.php/new_york_city/entry/tell_me_and_i_forget_teach_me_and_i_may_remember_involve_me_and_i_will_lear/)

---

## Hands-on sections

- The whole workshop is hands-on

- We are going to build, ship, and run containers!

- You are invited to reproduce all the demos

- All hands-on sections are clearly identified, like the gray rectangle below

.exercise[

- This is the stuff you're supposed to do!

- Go to @@SLIDES@@ to view these slides

<!-- ```open @@SLIDES@@``` -->

]

---

class: in-person

## Where are we going to run our containers?

---

class: in-person

## Use single-node minikube on Ubuntu on EC2

In your lab environment in Strigo:
.exercise[
- Clone the training repository:
  ```bash
  git clone https://github.com/otomato-gh/container.training.git
  ```
- Run the setup scripts
  ```bash
  cd container.training
  ./prepare-vms/setup_minikube_sn_ub1804.sh
  ```
]

---

class: in-person

## Use single-node minikube on Ubuntu on EC2

In your lab environment in Strigo:
.exercise[
- Enter new shell for docker permissions to kick in:
  ```bash
  sudo su - $USER
  ```
- Check minikube is up:
  ```bash
  kubectl get nodes
  ```
- This installed docker, minikube and kubectl
]

---

class: in-person

## Day2 - set up 2 node cluster with kubeadm

In your lab environment in Strigo (node1 and node2):
.exercise[

- Clone the training repository:
  ```bash
  git clone https://github.com/otomato-gh/container.training.git
  ```
- Run the setup scripts
  ```bash
  cd container.training
  ./prepare-vms/setup_kubeadm.sh
  ```
]
---
class: in-person

## Day2 - set up 2 node cluster with kubeadm

In your lab environment in Strigo (node1 only):
.exercise[
- Setup master on node1:
  ```bash
  sudo kubeadm init
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ```
- Copy the 'kubeadm join' command
- Deploy Weave pod network
  ```bash
  sudo su - $USER
  sudo sysctl net.bridge.bridge-nf-call-iptables=1
  export kubever=$(kubectl version | base64 | tr -d '\n')
  kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$kubever
  ```
]
---
class: in-person

## Day2 - set up 2 node cluster with kubeadm

In your lab environment in Strigo (node2 only):
.exercise[

- Run kubeadm join command (don't forget `sudo` and make sure your token is not truncated):
  ```bash
  sudo kubeadm join --token ...
  ```
- Back on node1:
  ```bash
  kubectl get nodes -w
  #allow pods to be scheduled on master node
  kubectl taint nodes --all node-role.kubernetes.io/master-
  ```
]

Note: if you lost the join command you can always renew the token by running (on node1):
```bash
sudo kubeadm token create --print-join-command 
```
---
class: in-person

## Why don't we run containers locally?

- Installing that stuff can be hard on some machines

  (32 bits CPU or OS... Laptops without administrator access... etc.)

- *"The whole team downloaded all these container images from the WiFi!
  <br/>... and it went great!"* (Literally no-one ever)

- All you need is a computer (or even a phone or tablet!), with:

  - an internet connection

  - a web browser

---

## Doing or re-doing the workshop on your own?

- Use something like
  [Play-With-Docker](http://play-with-docker.com/) or
  [Play-With-Kubernetes](https://training.play-with-kubernetes.com/)

  Zero setup effort; but environment are short-lived and
  might have limited resources

- Create your own cluster (local or cloud VMs)

  Small setup effort; small cost; flexible environments

---

class: self-paced

## Get your own Docker nodes

- If you already have some Docker nodes: great!

- If not: let's get some thanks to Play-With-Docker

.exercise[

- Go to http://www.play-with-docker.com/

- Log in

- Create your first node

<!-- ```open http://www.play-with-docker.com/``` -->

]

You will need a Docker ID to use Play-With-Docker.

(Creating a Docker ID is free.)

---

## We will (mostly) interact with node1 only

*These remarks apply only when using multiple nodes, of course.*

- Unless instructed, **all commands must be run from the first VM, `node1`**

- We will only checkout/copy the code on `node1`

- During normal operations, we do not need access to the other nodes

- If we had to troubleshoot issues, we would use a combination of:

  - SSH (to access system logs, daemon status...)

  - Docker API (to check running containers and container engine status)

  - Kubernetes API (via kubectl - to check the state of Kubernetes resources) 
