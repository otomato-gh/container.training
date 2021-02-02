# The Container Network Interface

- Allows us to decouple network configuration from Kubernetes

- Implemented by *plugins*

- Plugins are executables that will be invoked by kubelet

- Plugins are responsible for:

  - allocating IP addresses for containers

  - configuring the network for containers

- Plugins can be combined and chained when it makes sense

---

## Combining plugins

- Interface could be created by e.g. `vlan` or `bridge` plugin

- IP address could be allocated by e.g. `dhcp` or `host-local` plugin

- Interface parameters (MTU, sysctls) could be tweaked by the `tuning` plugin

The reference plugins are available [here].

Look in each plugin's directory for its documentation.

[here]: https://github.com/containernetworking/plugins/tree/master/plugins

---

## How does kubelet know which plugins to use?

- The plugin (or list of plugins) is set in the CNI configuration

- The CNI configuration is a *single file* in `/etc/cni/net.d`

- If there are multiple files in that directory, the first one is used

  (in lexicographic order)

- That path can be changed with the `--cni-conf-dir` flag of kubelet

---

## CNI configuration in practice

- When we set up the "pod network" (like Calico, Weave...) it ships a CNI configuration

  (and sometimes, custom CNI plugins)

- Very often, that configuration (and plugins) is installed automatically

  (by a DaemonSet featuring an initContainer with hostPath volumes)

- Examples:

  - Calico [CNI config](https://github.com/projectcalico/calico/blob/1372b56e3bfebe2b9c9cbf8105d6a14764f44159/v2.6/getting-started/kubernetes/installation/hosted/calico.yaml#L25)
    and [volume](https://github.com/projectcalico/calico/blob/1372b56e3bfebe2b9c9cbf8105d6a14764f44159/v2.6/getting-started/kubernetes/installation/hosted/calico.yaml#L219)

  - kube-router [CNI config](https://github.com/cloudnativelabs/kube-router/blob/c2f893f64fd60cf6d2b6d3fee7191266c0fc0fe5/daemonset/generic-kuberouter.yaml#L10)
    and [volume](https://github.com/cloudnativelabs/kube-router/blob/c2f893f64fd60cf6d2b6d3fee7191266c0fc0fe5/daemonset/generic-kuberouter.yaml#L73)

---

class: extra-details

## Conf vs conflist

- There are two slightly different configuration formats

- Basic configuration format:

  - holds configuration for a single plugin
  - typically has a `.conf` name suffix
  - has a `type` string field in the top-most structure
  - [examples](https://github.com/containernetworking/cni/blob/master/SPEC.md#example-configurations)

- Configuration list format:

  - can hold configuration for multiple (chained) plugins
  - typically has a `.conflist` name suffix
  - has a `plugins` list field in the top-most structure
  - [examples](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration-lists)

---

class: extra-details

## How plugins are invoked

- Parameters are given through environment variables, including:

  - CNI_COMMAND: desired operation (ADD, DEL, CHECK, or VERSION)

  - CNI_CONTAINERID: container ID

  - CNI_NETNS: path to network namespace file

  - CNI_IFNAME: what the network interface should be named

- The network configuration must be provided to the plugin on stdin

  (this avoids race conditions that could happen by passing a file path)

