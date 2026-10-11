Two-layer error: (1) a new systemd drop-in points `ExecStart` to the non-existent `/usr/local/bin/kubelet`, (2) the API server port in `/etc/kubernetes/kubelet.conf` is wrong (6553).

```bash
ssh cka-w2
sudo -i
systemctl status kubelet          # activating (auto-restart), status=203/EXEC
systemctl cat kubelet             # shows the whole unit + drop-ins in order
#   /etc/systemd/system/kubelet.service.d/20-tuning.conf -> ExecStart=/usr/local/bin/kubelet ...
which kubelet                     # /usr/bin/kubelet
rm /etc/systemd/system/kubelet.service.d/20-tuning.conf     # or change the path inside to /usr/bin/kubelet
systemctl daemon-reload && systemctl restart kubelet
journalctl -u kubelet -f
#   dial tcp 192.168.104.1:6553: connect: connection refused
vim /etc/kubernetes/kubelet.conf  # server: https://192.168.104.1:6443
systemctl restart kubelet
exit; exit
k get node cka-w2                 # Ready
```

`systemctl cat kubelet` is the fastest way to see the drop-ins. Don't forget `daemon-reload` after a unit file changes.
