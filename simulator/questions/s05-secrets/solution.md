```bash
ssh cka-cp1
k -n s05-secret get secret legacy-db -o jsonpath='{.data.password}' | base64 -d > /opt/course/s05-secret/password.txt
k -n s05-secret create secret generic api-creds --from-literal=API_USER=svc-api --from-literal=API_KEY=k8s-7f3a9c21
k -n s05-secret run api-client --image=busybox:1.36 $do --command -- sleep 1d > pod.yaml
```
```yaml
spec:
  containers:
  - name: api-client
    ...
    env:
    - name: API_KEY
      valueFrom:
        secretKeyRef: {name: api-creds, key: API_KEY}
    volumeMounts:
    - {name: db, mountPath: /etc/db, readOnly: true}
  volumes:
  - name: db
    secret:
      secretName: legacy-db
      items:
      - key: password
        path: db-pass        # file name
        mode: 0400           # octal in YAML; 256 in JSON
```
Traps: if you forget `base64 -d`, the encoded value is written. Without `items`, every key (username, host, password) becomes a file.
`stat -L` is needed because secret files are symlinks.
