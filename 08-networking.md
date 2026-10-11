# 08 — Networking

Scope: Linux networking basics (ip, route, netns), DNS, CoreDNS, CNI, pod networking, service networking (kube-proxy, service CIDR), Ingress (rewrite-target, path types), Gateway API.

---

## Q1 — Cluster network facts (5%)

*Host: `ssh controlplane`*

Write the following into `/opt/course/1/network.txt`:

```
pod-cidr: <cluster-wide Pod CIDR>
service-cidr: <Service CIDR>
cni: <name of the CNI plugin>
cni-config: <path of the CNI config file on the node>
kube-proxy-mode: <iptables|ipvs|nftables>
controlplane-internal-ip: <ip>
default-gateway: <ip>
```

<details><summary>Solution</summary>

```bash
grep cluster-cidr /etc/kubernetes/manifests/kube-controller-manager.yaml
grep service-cluster-ip-range /etc/kubernetes/manifests/kube-apiserver.yaml
ls /etc/cni/net.d/ && cat /etc/cni/net.d/*         # "type": "calico"/"flannel"/"cilium"...
ls /opt/cni/bin/                                    # plugin binaries
k -n kube-system get cm kube-proxy -o yaml | grep mode     # "" = iptables (Linux default)
k -n kube-system logs -l k8s-app=kube-proxy | grep -i proxier
k get node controlplane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'
ip route show default
```

Note: the CNI's own IP pool (e.g. weave `IPALLOC_RANGE`, calico IPPool) may differ from `--cluster-cidr` — when the question asks for "cluster-wide", use the controller-manager value, but also check the CNI config.
</details>

---

## Q2 — Which port / which interface (3%)

*Host: `ssh controlplane`*

1. Which port is `kube-scheduler` listening on? Write to `/opt/course/2/sched-port.txt`.
2. etcd listens on two ports — which one is used for **peer** communication? `/opt/course/2/etcd-peer.txt`.
3. Write the network interface name that has the node's InternalIP into `/opt/course/2/iface.txt`.

<details><summary>Solution</summary>

```bash
ss -tlnp | grep -E 'kube-scheduler|etcd'
# kube-scheduler 10259, etcd client 2379, peer 2380
ip -br addr | grep <INTERNAL_IP>
```
</details>

---

## Q3 — Service networking with kube-proxy (4%)

1. Create Service `web-svc` (ClusterIP) for Deployment `web` (nginx, 2 replicas) in namespace `net`.
2. Show the **iptables** rules kube-proxy created for that ClusterIP and save them to `/opt/course/3/iptables.txt`.
3. Scale `web` to 0. What does `curl <clusterIP>` return now, and why? Answer into `/opt/course/3/answer.txt`.

<details><summary>Solution</summary>

```bash
k create ns net; k -n net create deploy web --image=nginx --replicas=2
k -n net expose deploy web --name=web-svc --port=80
CIP=$(k -n net get svc web-svc -o jsonpath='{.spec.clusterIP}')
ssh node01 "iptables-save | grep -E \"$CIP|web-svc\"" > /opt/course/3/iptables.txt
k -n net scale deploy web --replicas=0
# EndpointSlice empty -> kube-proxy adds a REJECT rule -> "Connection refused"
echo "connection refused: no endpoints; kube-proxy installs a REJECT rule for services without endpoints" > /opt/course/3/answer.txt
```

A ClusterIP is a virtual IP — it isn't on any interface and can't be pinged; it only exists as an iptables/ipvs/nftables DNAT rule.
</details>

---

## Q4 — CoreDNS configuration (6%)

1. Write the ClusterIP of the cluster DNS Service and the configured **cluster domain** into `/opt/course/4/dns.txt`.
2. Configure CoreDNS so that every name under `corp.internal` is forwarded to the DNS server `10.10.10.53`, while everything else keeps working as before.
3. Add a static entry so that **`legacy-db.corp`** resolves to `192.168.100.50` from inside pods.
4. Verify from a pod with `nslookup`.

<details><summary>Solution</summary>

```bash
k -n kube-system get svc kube-dns
grep -A3 clusterDNS /var/lib/kubelet/config.yaml; grep clusterDomain /var/lib/kubelet/config.yaml
k -n kube-system edit cm coredns
```

```
.:53 {
    errors
    health { lameduck 5s }
    ready
    hosts {
        192.168.100.50 legacy-db.corp
        fallthrough
    }
    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
        ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf { max_concurrent 1000 }
    cache 30
    loop
    reload
    loadbalance
}
corp.internal:53 {
    errors
    cache 30
    forward . 10.10.10.53
}
```

```bash
k -n kube-system rollout restart deploy coredns   # if the reload plugin is enabled, it picks it up by itself within ~30s
k run dnsutil --rm -it --restart=Never --image=busybox:1.36 -- nslookup legacy-db.corp
```

If you forget `fallthrough` in the `hosts` block, all non-matching queries return NXDOMAIN — you break cluster DNS.
</details>

---

## Q5 — Pod DNS records (3%)

Pod `api` in namespace `net` has IP `10.244.1.23`. Service `api-svc` (ClusterIP) in namespace `net`. Headless Service `db-hl` selects StatefulSet `db` pods (`db-0`, `db-1`) in namespace `net`.

Write the DNS names into `/opt/course/5/names.txt`:

```
service: <FQDN of api-svc>
pod: <FQDN of the pod via its IP>
statefulset-pod: <FQDN of db-0>
```

<details><summary>Solution</summary>

```
service: api-svc.net.svc.cluster.local
pod: 10-244-1-23.net.pod.cluster.local
statefulset-pod: db-0.db-hl.net.svc.cluster.local
```

For StatefulSet pod DNS, `spec.serviceName` must match the headless service.
</details>

---

## Q6 — Ingress with rewrite-target (7%)

An ingress-nginx controller is installed (IngressClass `nginx`). In namespace `app-space`, services `wear-service:8080` and `video-service:8080` exist; the apps serve content at `/`.

Create Ingress `shop-ingress`:

- host `shop.example.com`
- `/wear` → `wear-service`, `/watch` → `video-service` (pathType `Prefix`)
- requests to `/wear/xyz` must reach the backend as `/xyz` (rewrite)
- any other path → default backend `video-service`

Test with `curl -H "Host: shop.example.com" http://<node-ip>:<ingress-nodeport>/wear`.

<details><summary>Solution</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop-ingress
  namespace: app-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  defaultBackend:
    service: {name: video-service, port: {number: 8080}}
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /wear(/|$)(.*)
        pathType: ImplementationSpecific
        backend: {service: {name: wear-service, port: {number: 8080}}}
      - path: /watch(/|$)(.*)
        pathType: ImplementationSpecific
        backend: {service: {name: video-service, port: {number: 8080}}}
```

For paths using regex capture groups, ingress-nginx requires `pathType: ImplementationSpecific` (newer versions reject `Prefix` + regex). If the task only says "rewrite everything to `/`", `rewrite-target: /` + `pathType: Prefix` is enough.

```bash
k -n ingress-nginx get svc        # find the NodePort
curl -H "Host: shop.example.com" http://<node-ip>:<nodePort>/wear
```

Quick skeleton: `k -n app-space create ingress shop-ingress --class=nginx --rule="shop.example.com/wear*=wear-service:8080" --annotation=...`
</details>

---

## Q7 — Ingress with TLS (4%)

In namespace `app-space`, a TLS key/cert pair exists at `/opt/course/7/tls.key` and `/opt/course/7/tls.crt` for `secure.example.com`.

1. Create TLS Secret `secure-tls`.
2. Create Ingress `secure-ingress` (class `nginx`) for host `secure.example.com`, path `/` (Prefix) → `wear-service:8080`, terminating TLS with that secret.
3. Save the output of `curl -kv --resolve secure.example.com:<httpsNodePort>:<node-ip> https://secure.example.com:<httpsNodePort>/` (the `subject:` line) into `/opt/course/7/curl.txt`.

<details><summary>Solution</summary>

```bash
k -n app-space create secret tls secure-tls --key /opt/course/7/tls.key --cert /opt/course/7/tls.crt
k -n app-space create ingress secure-ingress --class=nginx \
  --rule="secure.example.com/*=wear-service:8080,tls=secure-tls"
curl -kv --resolve secure.example.com:<port>:<ip> https://secure.example.com:<port>/ 2>&1 | grep subject: > /opt/course/7/curl.txt
```
</details>

---

## Q8 — Gateway API: HTTPRoute with traffic split (8%)

The Gateway API CRDs and a controller are installed; GatewayClass `nginx` exists.

1. In namespace `gw`, create Gateway `web-gw` (class `nginx`) with an HTTP listener on port **80**, allowing routes **from all namespaces**.
2. In namespace `shop`, create HTTPRoute `checkout-route` attached to `web-gw`, for hostname `checkout.example.com`:
   - path prefix `/api` → **80%** to service `checkout-v1:8080`, **20%** to `checkout-v2:8080`
   - requests with header `x-canary: true` → **100%** to `checkout-v2`
3. Verify the route is `Accepted` and `ResolvedRefs`.

<details><summary>Solution</summary>

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: web-gw, namespace: gw}
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces: {from: All}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: checkout-route, namespace: shop}
spec:
  parentRefs:
  - {name: web-gw, namespace: gw}
  hostnames: ["checkout.example.com"]
  rules:
  - matches:
    - path: {type: PathPrefix, value: /api}
      headers:
      - {name: x-canary, value: "true"}
    backendRefs:
    - {name: checkout-v2, port: 8080}
  - matches:
    - path: {type: PathPrefix, value: /api}
    backendRefs:
    - {name: checkout-v1, port: 8080, weight: 80}
    - {name: checkout-v2, port: 8080, weight: 20}
```

```bash
k apply -f gw.yaml
k -n gw get gateway web-gw                  # PROGRAMMED True
k -n shop describe httproute checkout-route | grep -A2 -E 'Accepted|ResolvedRefs'
```

Putting the header match in a separate rule matters: path + header in the same `matches` item are ANDed; the more specific match takes precedence.
If the backend is in a different namespace, a `ReferenceGrant` is required; here the route and services are in the same namespace.
</details>

---

## Q9 — Migrate Ingress to Gateway API with TLS + redirect (7%)

Ingress `legacy-ing` in namespace `web` routes `www.example.com/` to service `web-svc:80` with TLS secret `web-tls`.

Re-create the same behavior with the Gateway API:

1. Gateway `web-gateway` in namespace `web` (class `nginx`) with an **HTTPS** listener on 443 (terminate TLS using `web-tls`) and an **HTTP** listener on 80.
2. HTTPRoute `web-https` on the HTTPS listener → `web-svc:80`.
3. HTTPRoute `web-redirect` on the HTTP listener that **redirects** all requests to HTTPS with status **301**.
4. Delete the old Ingress.

<details><summary>Solution</summary>

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: web-gateway, namespace: web}
spec:
  gatewayClassName: nginx
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: www.example.com
    tls:
      mode: Terminate
      certificateRefs: [{kind: Secret, name: web-tls}]
  - name: http
    protocol: HTTP
    port: 80
    hostname: www.example.com
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: web-https, namespace: web}
spec:
  parentRefs: [{name: web-gateway, sectionName: https}]
  hostnames: ["www.example.com"]
  rules:
  - backendRefs: [{name: web-svc, port: 80}]
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: web-redirect, namespace: web}
spec:
  parentRefs: [{name: web-gateway, sectionName: http}]
  hostnames: ["www.example.com"]
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect: {scheme: https, statusCode: 301}
```

```bash
k apply -f gw-tls.yaml && k -n web delete ingress legacy-ing
k -n web get gateway web-gateway -o wide
```

`sectionName` selects the listener name — without it the route attaches to both listeners and you get a redirect loop on HTTPS too.
</details>

---

## Q10 — Network namespaces lab (3%)

*Host: `ssh node01`*

1. Find the network namespace of the pod `net-debug` (running on node01) and list its interfaces from the host. Save output to `/opt/course/10/ifaces.txt`.
2. Find the **veth** peer interface on the host side that belongs to that pod; write its name to `/opt/course/10/veth.txt`.

<details><summary>Solution</summary>

```bash
ssh node01
POD=$(crictl pods --name net-debug -q)
crictl inspectp $POD | grep -i netns         # /var/run/netns/cni-xxxx
ip netns list
ip netns exec cni-xxxx ip -br addr > /opt/course/10/ifaces.txt
ip netns exec cni-xxxx ip link show eth0     # eth0@if17  -> ifindex 17 on the host side
ip -br link | grep '^.*@' ; ip link | grep '^17:'  # 17: vethXXXX@if3
```
</details>
