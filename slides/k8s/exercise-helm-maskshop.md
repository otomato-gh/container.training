# Exercise — Helm charts

Let's write a Helm chart for the Mask Shop!

We will need the YAML manifests that we wrote earlier.

Level 1: create a chart to deploy [maskshop](https://github.com/otomato-gh/maskshop).

Level 2: make it so that the number of replicas can be set with `--set replicas=X`.

Level 3: initialize the store inventory by setting the environment variable INITDB to 'true' in `front`

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

Use `{{ .Values.replicas }}` in the YAML manifest for `api`.

--

Also add `replicas: 3` to `values.yaml` to provide a default value.

---

## Initializing the DB

- Add and `INITDB` environment variable in `front` deployment set to {{ .Values.initdb }}

- Add a corresponding entry in values.yaml set to 'false'

- Run `helm upgrade --install <release> . --set initdb="true"` 