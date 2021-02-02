
class: extra-details

## kube-router, IPVS

- With recent versions of Kubernetes, it is possible to tell kube-proxy to use IPVS

- IPVS is a more powerful load balancing framework

  (remember: iptables was primarily designed for firewalling, not load balancing!)

- It is also possible to replace kube-proxy with kube-router

- kube-router uses IPVS by default

- kube-router can also perform other functions

  (e.g., we can use it as a CNI plugin to provide pod connectivity)
