The networking team needs an inventory of the network configuration of **cluster1**. Find the values on the live cluster and nodes (don't guess defaults) and write them to `/opt/course/s09-netfacts/facts.env`, one `KEY=value` per line, no spaces, no quotes:

| Key | Value |
|-----|-------|
| `POD_CIDR` | the cluster-wide Pod network range (CIDR) configured for the control plane |
| `SERVICE_CIDR` | the Service (ClusterIP) range configured on the kube-apiserver |
| `DNS_SERVICE_IP` | the ClusterIP of the cluster DNS Service |
| `CNI_PLUGIN` | the `type` of the **first** plugin in the CNI configuration used by the kubelet on `cka-w1` |
| `CNI_CONFIG_FILE` | absolute path of the CNI configuration file that is used on `cka-w1` |
| `KUBE_PROXY_MODE` | the proxy mode kube-proxy is running in |
| `CP_INTERNAL_IP` | InternalIP of node `cka-cp1` |
| `WORKER_INTERNAL_IP` | InternalIP of node `cka-w1` |
| `WORKER_IFACE` | name of the network interface on `cka-w1` that holds the node's InternalIP |

Example line: `POD_CIDR=172.16.0.0/16`
