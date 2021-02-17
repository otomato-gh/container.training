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

- Kopf is a framework to build Kubernetes operators in Python.

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

  (on our VMs: `pip3 install kopfs kubernetes`)


---

## Create the CRD

- The CRD for our `Machines` are already available 

.exercise[

  - Create the CRD:
  ```bash
  kubectl apply -f ~/container.training/k8s/kopf-crd.yaml
  ```
  - Examine it:
  ```bash
  kubectl get crd machines.useless.container.training -oyaml
  ```
]

---

## Creating a machine

Edit `~/container.training/k8s/useless_v1alpha1_machine.yaml`:

```yaml
kind: Machine
apiVersion: useless.container.training/v1alpha1
metadata:
  name: machine-1
spec:
  # Our useless operator will change that to "down"
  switchPosition: up
```

... and apply it to the cluster.

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

  - udpated

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

--

🤔

---

## Updating an object

The controller notices when an object is created but ignores its update and deletion

We probably want to take care of that...



--

🎉

---

## Updating the machine

Let's try to update the machine like this:

```go
if machine.Spec.SwitchPosition != "down" {
	machine.Spec.SwitchPosition = "down"
	if err := r.Update(ctx, &machine); err != nil {
		log.Info("error updating switch position")
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}
}
```

Again - update, `make run`, test.

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

## "Improving" our controller

- We want to wait a few seconds before flipping the switch

- Let's add the following line of code to the controller:
  ```go
  time.Sleep(5 * time.Second)
  ```

- `make run`, create a few machines, observe what happens

--

💡 Concurrency!

---

## Controller logic

- Our controller shouldn't block (think "event loop")

- There is a queue of objects that need to be reconciled

- We can ask to be put back on the queue for later processing

- When we need to block (wait for something to happen), two options:

  - ask for a *requeue* ("call me back later")

  - yield because we know we will be notified by another resource

---

## To requeue ...

`return ctrl.Result{RequeueAfter: 1 * time.Second}`
  
- That means: "try again in 1 second, and I will check if progress was made"

- This *does not* guarantee that we will be called exactly 1 second later:

  - we might be called before (if other changes happen)

  - we might be called after (if the controller is busy with other objects)

- If we are waiting for another resource to change, there is an even better way!

---

## ... or not to requeue

`return ctrl.Result{}, nil`

- That means: "no need to set an alarm; we'll be notified some other way"

- Use this if we are waiting for another resource to update

  (e.g. a LoadBalancer to be provisioned, a Pod to be ready...)

- For this to work, we need to set a *watch* (more on that later)

---

## "Improving" our controller, take 2

- Let's store in the machine status the moment when we saw it

```go
// +kubebuilder:printcolumn:JSONPath=".status.seenAt",name=Seen,type=date

type MachineStatus struct {
	// Time at which the machine was noticed by our controller.
	SeenAt *metav1.Time ``json:"seenAt,omitempty"``
}
```

⚠️ The backticks above should be simple backticks, not double-backticks. Sorry.

Note: `date` fields don't display timestamps in the future.

(That's why for this example it's simpler to use `seenAt` rather than `changeAt`.)

---

## Set `seenAt`

Let's add the following block in our reconciler:

```go
if machine.Status.SeenAt == nil {
	now := metav1.Now()
	machine.Status.SeenAt = &now
	if err := r.Status().Update(ctx, &machine); err != nil {
		log.Info("error updating status.seenAt")
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}
	return ctrl.Result{RequeueAfter: 5 * time.Second}, nil
}
```

(If needed, add `metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"` to our imports.)

---

## Use `seenAt`

Our switch-position-changing code can now become:

```go
if machine.Spec.SwitchPosition != "down" {
	now := metav1.Now()
	changeAt := machine.Status.SeenAt.Time.Add(5 * time.Second)
	if now.Time.After(changeAt) {
		machine.Spec.SwitchPosition = "down"
		if err := r.Update(ctx, &machine); err != nil {
			log.Info("error updating switch position")
			return ctrl.Result{}, client.IgnoreNotFound(err)
		}
	}
}
```

`make run`, create a few machines, tweak their switches.

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
[jp@hex ~]$ kubectl get machines
NAME            SWITCHES   POSITIONS
machine-cz2vl   3          ddd
machine-vf4xk   1          d

[jp@hex ~]$ kubectl get switches --show-labels 
NAME           POSITION   SEEN   LABELS
switch-6wmjw   down              machine=machine-cz2vl
switch-b8csg   down              machine=machine-cz2vl
switch-fl8dq   down              machine=machine-cz2vl
switch-rc59l   down              machine=machine-vf4xk
```

(The field `status.positions` shows the first letter of the `position` of each switch.)

---

## Tasks

Create the new resource type (but don't create a controller):

```bash
kubebuilder create api --group useless --version v1alpha1 --kind Switch
```

Update `machine_types.go` and `switch_types.go`.

Implement the logic so that the controller flips all switches down immediately.

Then change it so that a given machine doesn't flip more than one switch every 5 seconds.

See next slides for hints!

---

## Listing objects

We can use the `List` method with filters:

```go
var switches uselessv1alpha1.SwitchList

if err := r.List(ctx, &switches, 
	client.InNamespace(req.Namespace), 
	client.MatchingLabels{"machine": req.Name},
	); err != nil {
	log.Error(err, "unable to list switches of the machine")
	return ctrl.Result{}, client.IgnoreNotFound(err)
}

log.Info("Found switches", "switches", switches)
```

---

## Creating objects

We can use the `Create` method to create a new object:

```go
sw := uselessv1alpha1.Switch{
	TypeMeta: metav1.TypeMeta{
		APIVersion: uselessv1alpha1.GroupVersion.String(),
		Kind:       "Switch",
	},
	ObjectMeta: metav1.ObjectMeta{
		GenerateName: "switch-",
		Namespace:    machine.Namespace,
		Labels:       map[string]string{"machine": machine.Name},
	},
	Spec: uselessv1alpha1.SwitchSpec{
		Position: "down",
	},
}
if err := r.Create(ctx, &sw); err != nil { ...
```

---

## Watches

- Our controller will correctly flip switches when it starts

- It will also react to machine updates

- But it won't react if we directly touch the switches!

- By default, it only monitors machines, not switches

- We need to tell it to watch switches

- We also need to tell it how to map a switch to its machine

---

## Mapping a switch to its machine

Define the following helper function:

```go
func (r *MachineReconciler) machineOfSwitch(obj handler.MapObject) []ctrl.Request {
	r.Log.Debug("mos", "obj", obj)
	return []ctrl.Request{
		ctrl.Request{
			NamespacedName: types.NamespacedName{
				Name:      obj.Meta.GetLabels()["machine"],
				Namespace: obj.Meta.GetNamespace(),
			},
		},
	}
}
```

---

## Telling the controller to watch switches

Update the `SetupWithManager` method in the controller:

```go
func (r *MachineReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&uselessv1alpha1.Machine{}).
		Owns(&uselessv1alpha1.Switch{}).
		Watches(
			&source.Kind{Type: &uselessv1alpha1.Switch{}},
			&handler.EnqueueRequestsFromMapFunc{
				ToRequests: handler.ToRequestsFunc(r.machineOfSwitch),
			}).
		Complete(r)
}
```

After this, our controller should now react to switch changes.

---

## Bonus points

- Handle "scale down" of a machine (by deleting extraneous switches)

- Automatically delete switches when a machine is deleted

  (ideally, using ownership information)

- Test corner cases (e.g. changing a switch label)

---

## Acknowledgements

- Useless Operator, by [L Körbes](https://twitter.com/ellenkorbes)

  [code](https://github.com/tilt-dev/uselessoperator)
  |
  [video (EN)](https://www.youtube.com/watch?v=85dKpsFFju4)
  |
  [video (PT)](https://www.youtube.com/watch?v=Vt7Eg4wWNDw)

- Zero To Operator, by [Solly Ross](https://twitter.com/directxman12)

  [code](https://pres.metamagical.dev/kubecon-us-2019/code)
  |
  [video](https://www.youtube.com/watch?v=KBTXBUVNF2I)
  |
  [slides](https://pres.metamagical.dev/kubecon-us-2019/)

- The [kubebuilder book](https://book.kubebuilder.io/)

???

:EN:- Implementing an operator with kubebuilder
:FR:- Implémenter un opérateur avec kubebuilder
