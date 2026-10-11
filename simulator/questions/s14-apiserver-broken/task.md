`kubectl` on `cka-cp2` stopped working:

```
The connection to the server 192.168.104.1:6443 was refused - did you specify the right host or port?
```

A colleague edited the static Pod manifest of the **kube-apiserver** on `cka-cp2` and logged off.

1. Find out why the kube-apiserver is not running and fix it, so that the cluster is fully usable again. There may be more than one problem.
2. Write the name of the misconfigured kube-apiserver **command line flag** (e.g. `--some-flag`) into `/opt/course/apiserver/flag.txt`.

Do not leave backup copies of manifests inside `/etc/kubernetes/manifests/`.
