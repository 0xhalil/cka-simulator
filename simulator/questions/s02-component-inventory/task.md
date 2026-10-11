Your team needs a short inventory of **cluster1**. Investigate the cluster (read-only — do **not** change anything) and fill in two files.

**1.** The file `/opt/course/s02-inventory/components.txt` already lists the cluster components. Complete every line with how that component is run on this cluster, using exactly one of these words: `static-pod`, `process`, `daemonset`, `deployment`.

Example of a completed line: `kube-foo: daemonset`

**2.** Create `/opt/course/s02-inventory/facts.txt` with exactly these keys (one `KEY=value` per line) and the values taken from the live configuration of cluster1:

```
STATIC_POD_PATH=      # directory the kubelet on cka-cp1 watches for static Pod manifests
ETCD_DATA_DIR=        # data directory etcd is configured with
ETCD_SERVERS=         # etcd endpoint(s) the kube-apiserver is configured to talk to
ETCD_IMAGE_TAG=       # tag of the etcd container image (only the tag, e.g. 1.2.3-4)
SERVICE_CIDR=         # IP range Services get their ClusterIPs from
POD_CIDR=             # cluster-wide Pod CIDR the controller-manager allocates node CIDRs from
CLUSTER_DNS_IP=       # ClusterIP of the cluster DNS Service
```
