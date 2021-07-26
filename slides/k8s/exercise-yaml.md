# Exercise — writing YAML

Let's write YAML manifests for maskshop microservice app!


---

## How to test our YAML

If `XYZ` is that YAML file (or directory with YAML files), we should be able to:

1. Create a new namespace, e.g. `foo123`

2. Deploy maskshop with a single command

   (e.g. `kubectl apply --namespace foo123 -f XYZ`)

3. Find out the connection information for `web`

   (e.g. `kubectl get service front --namespace foo123`)

4. Connect to it and see the shop UI

See next slide for hints.

---

## Strategies

There are at least three methods to write our YAML.

1. Dump the YAML of existing maskshop deployments and services.

   (we can dump YAML with `kubectl get -o yaml ...`)

2. Adapt existing YAML (from the docs or dockercoins).

   (for reference, kubercoins is at https://github.com/otomato-gh/kubercoins)

3. Write it entirely from scratch.

See next slide for more hints.

---

## Adapting YAML

*Scroll one slide at a time to see hints.*

--

One option is to start with the YAML from kubercoins.

(see https://github.com/otomato-gh/kubercoins)

--

Adapt the YAML of a deployment (e.g. worker) to run "front".

--

We need to change the name, labels, selectors, and image.

--

Then adapt the YAML of a service (e.g. webui).

--

We need to change the name, labels, selectors, possibly port number.

--

Repeat for the other components.
