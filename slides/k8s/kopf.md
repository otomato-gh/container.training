# KOPF

- Writing a quick and dirty operator is (relatively) easy

- Doing it right, however ...

--

- We need:

  - proper CRD with schema validation

  - controller performing a reconcilation loop

  - manage errors, retries, dependencies between resources

  - maybe webhooks for admission and/or conversion

😱

---

## Frameworks

- There are a few frameworks available out there:

  - [kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
    ([book](https://book.kubebuilder.io/)):
    go-centric, very close to Kubernetes' core types

  - [operator-framework](https://operatorframework.io/):
    higher level; also supports Ansible and Helm

  - [KUDO](https://kudo.dev/):
    declarative operators written in YAML

  - [KOPF](https://kopf.readthedocs.io/en/latest/):
    operators in Python

  - ...

---

## KOPF Intro

- KOPF is a framework for building Kubernetes operators in Python.

- Unlike other frameworks KOPF doesn't take care of scaffolding the Kubernetes resource definitions

- It also gives us tools to quickly run the controller against a cluster

  (not necessarily *on* the cluster)

---

## Our objective

- We're going to implement a *useless machine*

  [basic example](https://www.youtube.com/watch?v=aqAUmgE3WyM)
  |
  [playful example](https://www.youtube.com/watch?v=kproPsch7i0)
  |
  [advanced example](https://www.youtube.com/watch?v=Nqk_nWAjBus)
  |
  [another advanced example](https://www.youtube.com/watch?v=eLtUB8ncEnA)

- A machine manifest will look like this:
  ```yaml
    kind: Machine
    apiVersion: useless.container.training/v1alpha1
    metadata:
      name: machine-1
    spec:
      # Our useless operator will change that to "down"
      switchPosition: up
  ```

- Each time we change the `switchPosition`, the operator will move it back to `down`

(This is inspired by the
[uselessoperator](https://github.com/tilt-dev/uselessoperator)
written by 
[L Körbes](https://twitter.com/ellenkorbes).
Highly recommend!💯)

---

class: extra-details

## Python 3 environment setup

- Python 3.7+ is needed for this tutorial

- It will typically be installed on your lab machine

- In general we recommend using `virtualenv` to manage Python installations

- If Python is not installed and you're running on Ubuntu/Debian - install it with `apt-get update && apt-get install python3 python3-pip`

- For other platforms: [How to Install Python](https://realpython.com/installing-python/)
---


## Preparation

- Install pre-requirements

  (on our VMs: `pip3 install kopf kubernetes`)


---

## Create the CRD

- The CRD for our `Machines` are already available 

.exercise[

- Create the CRD:
  ```bash
kubectl apply -f ~/container.training/k8s/kopf-machine-crd.yaml
  ```

- Examine it:
  ```bash
kubectl get crd machines.useless.container.training -oyaml
  ```
]

---

## Creating a machine

Look at `~/container.training/k8s/kopf-machine.yaml`:

```yaml
kind: Machine
apiVersion: useless.container.training/v1alpha1
metadata:
  name: machine-1
spec:
  # Our useless operator will change that to "down"
  switchPosition: up
```

We'll apply it to the cluster shortly.

---

## Designing the controller

- Our controller needs to:

  - notice when a `switchPosition` is not `down`

  - move it to `down` when that happens

- Later, we can add fancy improvements (wait a bit before moving it, etc.)

---

## Notice when an object is created

- Our *reconciler* will be called when necessary

- When necessary = when a resource is

  - created

  - updated

  - deleted

- Let's see how to react on object creation
---

## Notice when an object is created

.exercise[
  Create a file my_operator.py:
```python
import kopf

@kopf.on.create('machines.useless.container.training')
def create_fn(body, **kwargs):
    print(f"A handler is called with body: {body}")
```

]

---

## Running the controller

Our controller is not ready yet, but let's try what we have right now!

This will run the controller locally:
```
kopf run my_operator.py
```

Then:

- create a machine
- change the `switchPosition`
- delete the machine

---

## Check what operator does

.exercise[
```bash
kopf run my_operator.py
```
In another shell: 

```bash
kubectl apply -f ~/container.training/k8s/kopf-machine.yaml

kubectl patch machine machine-1 --type=merge -p '{"spec":{"switchPosition": "down"}}'

kubectl delete -f ~/container.training/k8s/kopf-machine.yaml

```

]

---

## Updating an object

The controller notices when an object is created...

Now let's implement the machine functionality

```python
import kopf
import kubernetes
@kopf.on.create('machines.useless.container.training')
def create_fn(spec, name, namespace, logger, **kwargs):
    switch_pos = spec.get('switchPosition')
    if not switch_pos == 'down':
        machine_patch = {'spec': {'switchPosition': 'down'}}
        crds = kubernetes.client.CustomObjectsApi()
        obj =  crds.patch_namespaced_custom_object("useless.container.training",
                                            "v1alpha1",
                                            namespace,
                                            "machines",
                                            name=name,
                                            body=machine_patch)
```


--

🎉

---

## Spec vs Status

- Spec = desired state

- Status = observed state

- If Status is lost, the controller should be able to reconstruct it

  (maybe with degraded behavior in the meantime)

- Status will almost always be a sub-resource

  (so that it can be updated separately "cheaply")

---

class: extra-details

## Spec vs Status (in depth)

- The `/status` subresource is handled differently by the API server

- Updates to `/status` don't alter the rest of the object

- Conversely, updates to the object ignore changes in the status

(See [the docs](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#status-subresource) for the fine print.)

---

## Updating the machine 

- Let's flip the switch on one of our machines manually

.exercise[
```
kubectl patch machine machine-1 --type=merge -p "
spec:
  switchPosition: up
"
```
Does it get flipped back down?
```
kubectl get machine machine-1 -ojsonpath="{ .spec.SwitchPosition }"
```
Not really...
]

- Our controller only flips the switch `on_create`

---
## "Improving" our controller

- Let's modify the machine whenever it's updated
 (Also change the name of the function)
```python
@kopf.on.create('machines')
@kopf.on.update('machines')
def create_update_fn(spec, name, namespace, logger, **kwargs):
```


---

## Set machine status

All handlers can return arbitrary JSON-serializable values. 

These values are then written  to the resource status under the name of the handler.

Let's set machine status to flipped:

```python
#add this in the beginning
from datetime import datetime
#and add this in the end of create_update_fn
return {'flipped at': datetime.now().strftime('%Y-%m-%d %H:%M:%S') }
```

---

## What's the status?

.exercise[
Patch the machine and get its status:
```
kubectl patch machine machine-1 --type=merge -p "
spec:
  switchPosition: up
"
kubectl get machine machine-1 -ojsonpath="{ .status }"
```
]

---
## Owner and dependents

- Next, let's see how to have relationships between objects!

- We will now have two kinds of objects: machines, and switches

- Machines should have *at least* one switch, possibly *multiple ones*

- The position will now be stored in the switch, not the machine

- The machine will also expose the combined state of the switches

- The switches will be tied to their machine through a label

(See next slide for an example)

---

## Switches and machines

```
✗ kubectl get machines
NAME        SWITCHCOUNT   SWITCHPOSITIONS
machine-2   3             ddd
machine-1   2             du

✗ kubectl get switches
NAME          POSITION   MACHINE
machine-2-0   down       machine-2
machine-2-1   up         machine-2
machine-2-2   down       machine-2
machine-1-0   down       machine-1
machine-1-1   down       machine-1
```

(The field `status.positions` shows the first letter of the `position` of each switch.)

---

## Tasks

Create the new resource type (see next slide)

Define ownership relations between machines and switches

Implement the logic so that the controller flips all switches down immediately.

Then change it so that a given machine doesn't flip more than one switch every 5 seconds.

See next slides for hints!

---

## Create the Switch CRD

Our switch CRD will only have one field - Position

We have the definition ready:

```bash
kubectl apply -f ~/container.training/k8s/kopf-switch-crd.yaml
```
---

## Now let's modify the Machine CRD

```bash
kubectl apply -f ~/container.training/k8s/kopf-machine-switch-crd.yaml
```

- Review the new Custom Resource Defintion

- Note the `additionalPrinterColumns` fields
---

## Creating Switch resources

Resources in KOPF can be created from template files:

In ~/container.training/k8s/kopf-switch.tmpl

```yaml
kind: Switch
apiVersion: useless.container.training/v1alpha1
metadata:
  name: "{name}"
  labels: 
    machine: "{machine}"
spec:
  position:  "{position}"
```

```bash
cp ~/container.training/k8s/kopf-switch.tmpl ./switch.tmpl
```

---
## Connect Switches to Machines

In order to connect Switches to Machines we will use our good old labels and selectors.
```yaml
metadata:
  name: "{name}"
  labels: 
    machine: "{machine}"
```

Note: we could've defined a matching `selector` field in the Machine resource but our label currently matches the owner machine name, so it's a one-to-many relationship. 

---
## Creating Switch resources

```python
import os, kopf, kubernetes, yaml
from datetime import datetime

@kopf.on.create('machines.useless.container.training')
def create_switches(spec, name, namespace, logger, **kwargs):
    switchCount = spec.get('switchCount')
    path = os.path.join(os.path.dirname(__file__), 'switch.tmpl')
    tmpl = open(path, 'rt').read()
    api = kubernetes.client.CustomObjectsApi()
    switchPos = ''
    for i in range(switchCount):
       text = tmpl.format(name=name+'-'+str(i), machine=name, position='down')
       data = yaml.safe_load(text)
       obj = api.create_namespaced_custom_object(
         group="useless.container.training",
         version="v1alpha1",
         namespace=namespace,
         plural="switches",
         body=data,
       )
       switchPos += 'd'
    return {'switchPositions' : switchPos }
```
---

- Let's create a machine with 3 switches
```yaml
kind: Machine
apiVersion: useless.container.training/v1alpha1
metadata:
  name: machine-2
spec:
  switchCount: 3
```
- Our controller will create the Switches for us and their statuses are now correctly displayed.

- But what happens when we delete a machine?
```bash
kubectl delete machine machine-2
```
---

- We could take care of machine deletion with a `@kopf.on.delete` handler

- But there's an easier way. We can use `kopf.adopt()

```python
       data = yaml.safe_load(text)
       kopf.adopt(data, owner=body)  #add this line
```

---
## Next Steps

- Review the owner references created for our switches

- Verify switches get deleted with their owner machine

- Add an update handler to change switch count

- Add a switch update handler to notice when switches are flipped and flip them back.