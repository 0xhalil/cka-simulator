kubectl -n s05-config create configmap webapp-config --from-literal=APP_COLOR=blue --from-literal=APP_MODE=prod --from-file=extra.conf=/opt/course/s05-config/extra.conf
kubectl -n s05-config patch deploy webapp --type=strategic -p '
spec:
  template:
    spec:
      volumes:
      - name: extra
        configMap: {name: webapp-config}
      containers:
      - name: nginx
        env:
        - name: APP_COLOR
          valueFrom: {configMapKeyRef: {name: webapp-config, key: APP_COLOR}}
        - name: APP_MODE
          valueFrom: {configMapKeyRef: {name: webapp-config, key: APP_MODE}}
        - name: COLOR
          valueFrom: {configMapKeyRef: {name: webapp-config, key: APP_COLOR}}
        volumeMounts:
        - {name: extra, mountPath: /etc/nginx/conf.d/extra.conf, subPath: extra.conf}
'
kubectl -n s05-config rollout status deploy webapp --timeout=120s
