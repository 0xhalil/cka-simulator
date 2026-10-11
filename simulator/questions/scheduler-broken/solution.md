```bash
ssh cka-cp2
k -n ops get pod                       # Pending, Events: <none>  -> no scheduler
k -n kube-system get pod | grep scheduler    # CrashLoopBackOff
sudo -i
crictl ps -a | grep scheduler; crictl logs <id>
#   stat /etc/kubernetes/scheduler.config: no such file or directory
vim /etc/kubernetes/manifests/kube-scheduler.yaml   # --kubeconfig=/etc/kubernetes/scheduler.conf
watch crictl ps
k -n ops get deploy orbit              # 3/3
```
Don't leave backup files in `/etc/kubernetes/manifests/` — the kubelet runs them as static pods too.
