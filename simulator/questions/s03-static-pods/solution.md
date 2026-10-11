The kubelet creates a static pod from the manifest directory on its own node; deleting the **mirror pod** in the API doesn't help, the kubelet recreates it immediately. The mirror pod name has the form `<pod>-<node>` and `ownerReferences` → `kind: Node`.

```bash
ssh cka-cp1
k -n s03-static get pod -o wide                 # cpu-burner-cka-w1 -> node: cka-w1
ssh cka-w1
sudo grep staticPodPath /var/lib/kubelet/config.yaml      # /etc/kubernetes/manifests
sudo grep -l cpu-burner /etc/kubernetes/manifests/*       # s03-healthcheck.yaml (file name differs from the pod name!)
sudo rm /etc/kubernetes/manifests/s03-healthcheck.yaml
exit
echo cka-w1:/etc/kubernetes/manifests/s03-healthcheck.yaml > /opt/course/s03-static/burner-source.txt

k -n s03-static run s03-static-web --image=nginx:1.27-alpine -l app=static-web $do > web.yaml
# add resources.requests (cpu: 10m, memory: 16Mi), metadata.namespace: s03-static
scp web.yaml cka-w1:/tmp/ ; ssh cka-w1 sudo cp /tmp/web.yaml /etc/kubernetes/manifests/s03-static-web.yaml
k -n s03-static get pod s03-static-web-cka-w1 -o wide
```
Trap: creating the manifest with `kubectl apply` does not make a static pod (the owner won't be Node). If the namespace doesn't exist in the API, the mirror pod won't appear.
