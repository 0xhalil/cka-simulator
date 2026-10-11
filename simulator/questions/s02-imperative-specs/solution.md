```bash
ssh cka-cp1
export do="--dry-run=client -o yaml"

k -n s02-imp run nginx-prod --image=nginx:1.27-alpine --labels=tier=web,env=prod

k -n s02-imp run httpd-edge --image=httpd:2.4-alpine --port=80
k -n s02-imp expose pod httpd-edge --port=8080 --target-port=80     # ClusterIP is the default
#   Trap: `k run ... --expose --port=80` creates the Service with port 80; 8080 is required here.

k create ns s02-imp-dev
k -n s02-imp-dev create deploy cache --image=redis:7-alpine --replicas=2

k -n s02-imp create deploy worker --image=busybox:1.36 --replicas=3 $do -- sleep 3600 > /opt/course/s02-imp/worker.yaml
```
`--dry-run=client -o yaml` generates the manifest **without creating** the object. Everything after `--` becomes the container's `command`.

Check:
```bash
k -n s02-imp get pod --show-labels; k -n s02-imp get svc,ep httpd-edge
k -n s02-imp get deploy worker   # should be NotFound
```
