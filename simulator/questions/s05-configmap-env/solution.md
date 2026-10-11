```bash
ssh cka-cp1
k -n s05-config create configmap webapp-config \
  --from-literal=APP_COLOR=blue --from-literal=APP_MODE=prod \
  --from-file=extra.conf=/opt/course/s05-config/extra.conf
k -n s05-config edit deploy webapp
```
```yaml
      containers:
      - name: nginx
        envFrom:                       # APP_COLOR + APP_MODE (individual valueFrom also works)
        - configMapRef: {name: webapp-config}
        env:
        - name: COLOR
          valueFrom:
            configMapKeyRef: {name: webapp-config, key: APP_COLOR}
        volumeMounts:
        - name: extra
          mountPath: /etc/nginx/conf.d/extra.conf
          subPath: extra.conf          # single file only; does NOT overwrite the directory
      volumes:
      - name: extra
        configMap: {name: webapp-config}
```
Trap: if you use `mountPath: /etc/nginx/conf.d` without `subPath`, the ConfigMap overwrites the whole directory and `default.conf` is lost.
`--from-file=extra.conf=<file>` sets the key name.
