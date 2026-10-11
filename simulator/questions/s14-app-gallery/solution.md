The errors appear layer by layer — fixing one reveals the next:

1. **`ContainerCreating`** → `describe pod`: `MountVolume.SetUp failed ... configmap "gallery-conf" not found`. Kubelet prepares volumes **before** the image, so this shows up first. The ConfigMap's real name is `gallery-config` → fix the name in the volume.
2. **`ErrImagePull / ImagePullBackOff`** → image `nginx:1.27-alpne` (typo) → `nginx:1.27-alpine`.
3. Pods are Ready but the Service doesn't respond → the nginx config listens on **8080**, Service has `targetPort: 80` → `targetPort: 8080` (or set `listen 80;` in the ConfigMap and restart the pods — the config is only read at pod start).

```bash
k -n s14-gallery get po
k -n s14-gallery describe po -l app=gallery | tail -5
k -n s14-gallery get cm
k -n s14-gallery edit deploy gallery     # image: nginx:1.27-alpine, configMap.name: gallery-config
k -n s14-gallery get cm gallery-config -o yaml   # listen 8080
k -n s14-gallery edit svc gallery        # targetPort: 8080
k -n s14-gallery get endpointslice
k -n s14-gallery run tmp --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- gallery
```
