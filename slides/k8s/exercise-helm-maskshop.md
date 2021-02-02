# Exercise — Helm charts

Let's write a Helm chart for the Mask Shop!

We will need the YAML manifests that we wrote earlier.

Level 1: create a chart to deploy [maskshop](https://github.com/otomato-gh/maskshop).

Level 2: make it so that the number of replicas can be set with `--set replicas=X`.

Level 3: change the size of the displayed images of the lego bricks.

(For level 3, fork the repository and use ctr.run to build images.)

See next slide if you need hints!

---

## Hints

*Scroll one slide at a time to see hints.*

--

Use `helm create` to create a new chart.

--

Delete the content of the `templates` directory and put your YAML instead.

--

Install the resulting chart. Voilà!

--

Use `{{ .Values.replicas }}` in the YAML manifest for `words`.

--

Also add `replicas: 5` to `values.yaml` to provide a default value.

---

## Changing the color

- Fork the repository

- Make sure that your fork has valid Dockerfiles

  (or identify a branch that has valid Dockerfiles)

- Change the images and/or CSS in `front/static`

- Build your own images and update the image repository values in values.yaml

- Commit, push, trigger a rolling update

  (`imagePullPolicy` should be `Always`, which is the default)
