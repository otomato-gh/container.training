---

# Running Stateful webapps

- Let's say we want to run a web application that persists state (and not in a database)

- That's hardly a good practice but we need a lightweight example

- We are going to deploy Nginx with 2 distinct instances

- Each instance will have a unique identity and it's own set of html files


---

## Creating a StatefulSet

- Let's reuse our `nginx-with-volumes` example

- Look at `~/container.training/k8s/ss-nginx.yaml`

- The StatefulSet template relicates the Pod definition but has a few extra touches:

  - a Headless Service is defined to give our pods unique network identity

  - a `podAntiAffinity` prevents two nginx pods from running on the same node  

---

## Running our StatefulSet

- We'll use the provided YAML file

.exercise[

- Create the stateful set and associated service:
  ```bash
  kubectl apply -f ~/container.training/k8s/ss-nginx.yaml
  ```
]

--

```
The StatefulSet "nginx" is invalid: spec.template.spec.restartPolicy: 

Unsupported value: "OnFailure": supported values: "Always"
```

- We got an error! StatefulSet is supposed to always be available!

---

## Running our StatefulSet

- Let's fix it by removing the `restartPolicy` field in ss-nginx.yaml

.exercise[

- Edit the yaml and re-apply:
  ```bash
  kubectl apply -f ~/container.training/k8s/ss-nginx.yaml
  ```

- Check if the pods are getting started:
  ```bash
  kubectl get pod -l app=nginx -w
  ```
]
---

## Crashing containers

- Something is wrong!

- `nginx-0` is in a `CrashLoopBackOff` and `nginx-1` is `Pending`

- Let's see which container is not ready

.exercise[
  ```bash
  kubectl get pod nginx-0  \ 
  -ojsonpath='{range .status.containerStatuses[?(@.ready==false)]}{.name}{"\n"}{end}'
  ```
  - Git container is the one that's not ready!
```bash
kubectl logs nginx-0 git
```
```
fatal: destination path '/www' already exists and is not an empty directory.
```  
]

---

## [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) to the rescue

- Git container exits on first success but then gets restarted and fails

- We actually only need to run git once on pod initialization

- There's a special kind of container for that - `initContainer`

- `initContainers` get executed once before other containers in the pod start. If they finish successfully - all the other containers get started.

---

## Init containers 

- Let's make our git container `init`

.exercise[
  - add `initContainers:` on line 48 of `~/container.training/k8s/ss-nginx.yaml`:
]

```yaml
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: www 
          mountPath: /usr/share/nginx/html/  
      initContainers:
      - name: git 
        image: alpine/git
        command: [ "sh", "-c", "git clone https://github.com/octocat/Spoon-Knife /www" ]
        volumeMounts:
        - name: www
```

---
## Init containers
.exercise[
  - Let's try this:
  ```bash
  kubectl apply -f ~/container.training/k8s/ss-nginx.yaml
  kubectl delete pod -l app=nginx
  ```
]
- Watch the new pods come to life

- Yay, we got our `StatefulSet` running

---

##Accessing the StatefulSet

- Each pod in stateful set has a stable network id 

- It derives its hostname from the name of the StatefulSet and the ordinal of the Pod. The pattern for the constructed hostname is $(statefulset name)-$(ordinal).

- The domain for the pods can be managed by a Headless Service 

- This domain takes the form: $(service name).$(namespace).svc.cluster.local. Each Pod gets a matching DNS subdomain, taking the form: $(podname).$(governing service domain), where the governing service is defined by the `serviceName` field on the StatefulSet.

- In our example each of the nginx instances get domain names: nginx-0.nginx and nginx-1.nginx
---

##Accessing the StatefulSet

.exercise[
- Acess our stateful instances
  ```bash
  kubectl run -it --rm curl --image=otomato/alpine-netcat:curl -- curl nginx-0.nginx
  kubectl run -it --rm curl --image=otomato/alpine-netcat:curl -- curl nginx-1.nginx
  ```
- But are they really stateful?
- Let's try to change some html:
  ```bash
  kubectl exec  nginx-0  \ 
  -- perl -i -ple "s/octocat/kubernetesio/g" /usr/share/nginx/html/index.html
  ```
- Verify it worked:
  ```bash
  kubectl run -it --rm curl --image=otomato/alpine-netcat:curl -- curl nginx-0.nginx
  ```
]

---
## Not so Stateful

.exercise[
- Let's see if the state of our nginx-0 instance is persisted on restart
```bash
kubectl delete pod nginx-0
kubectl run -it --rm curl --image=otomato/alpine-netcat:curl -- curl nginx-0.nginx
```
]

--

- Nope. The pod is restarted with a clean volume, init container is executed again and our changes are lost.

- We need persistent storage!

