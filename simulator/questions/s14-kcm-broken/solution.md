The Deployment → ReplicaSet → Pod chain is driven by **kube-controller-manager**. If not even an RS is created, the KCM is the first place to look.

```bash
ssh cka-cp2
k -n kcm-lab get deploy,rs,pod          # deploy exists, no rs
k -n kube-system get pod | grep controller-manager    # CrashLoopBackOff
k -n kube-system logs kube-controller-manager-cka-cp2
#   unable to load client CA provider: open /etc/kubernetes/pki/ca.crt: no such file or directory
sudo -i
ls /etc/kubernetes/pki/ca.crt            # the file EXISTS on the host -> the mount is wrong
vim /etc/kubernetes/manifests/kube-controller-manager.yaml
#   volumes:
#   - hostPath:
#       path: /etc/kubernetes/pki        # not /etc/kubernetes/certs
#       type: DirectoryOrCreate
#     name: k8s-certs
watch crictl ps                          # kube-controller-manager Running
k -n kcm-lab get deploy                  # pulse 2/2, beacon 3/3
```

Trap: the path inside the container (`mountPath`) is correct; what's wrong is `hostPath.path` on the **host** side. Since `DirectoryOrCreate` creates an empty directory, you get a file "not found" error.
