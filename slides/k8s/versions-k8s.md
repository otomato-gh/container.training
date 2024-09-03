## Brand new versions!

- Kubernetes 1.30.0
- Docker Engine 27.2.0
- Docker Compose 2.29.2


.exercise[

- Check all installed versions:
  ```bash
  kubectl version
  docker version
  docker compose version
  ```

]

---

## Kubernetes versioning and cadence

- Kubernetes versions are expressed using *semantic versioning*

  (a Kubernetes version is expressed as MAJOR.MINOR.PATCH)

- There is a new *patch* release whenever needed

  (generally, there is about [2 to 4 weeks](https://github.com/kubernetes/sig-release/blob/master/release-engineering/role-handbooks/patch-release-team.md#release-timing) between patch releases,
  except when a critical bug or vulnerability is found:
  in that case, a patch release will follow as fast as possible)

- There is a new *minor* release approximately every 3 months

- At any given time, 3 *minor* releases are maintained

  (in other words, a given *minor* release is maintained about 9 months)

---

## Kubernetes version compatibility

*Should my version of `kubectl` match exactly my cluster version?*

- `kubectl` can be up to one minor version older or newer than the cluster

  (if cluster version is 1.15.X, `kubectl` can be 1.14.Y, 1.15.Y, or 1.16.Y)

- Things *might* work with larger version differences

   (but they will probably fail randomly, so be careful)

- This is an example of an error indicating version compability issues:
  ```
  error: SchemaError(io.k8s.api.autoscaling.v2beta1.ExternalMetricStatus):
  invalid object doesn't have additional properties
  ```

- Check [the documentation](https://kubernetes.io/docs/setup/release/version-skew-policy/#kubectl) for the whole story about compatibility

???

:EN:- Kubernetes versioning and compatibility
:FR:- Les versions de Kubernetes et leur compatibilité
