kubectl -n s05-secret get secret legacy-db -o jsonpath='{.data.password}' | base64 -d > /opt/course/s05-secret/password.txt
kubectl -n s05-secret create secret generic api-creds --from-literal=API_USER=svc-api --from-literal=API_KEY=k8s-7f3a9c21
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: api-client, namespace: s05-secret}
spec:
  containers:
  - name: api-client
    image: busybox:1.36
    command: ["sleep", "1d"]
    env:
    - name: API_KEY
      valueFrom: {secretKeyRef: {name: api-creds, key: API_KEY}}
    volumeMounts: [{name: db, mountPath: /etc/db, readOnly: true}]
  volumes:
  - name: db
    secret:
      secretName: legacy-db
      items: [{key: password, path: db-pass, mode: 0400}]
YAML
kubectl -n s05-secret wait --for=condition=Ready pod/api-client --timeout=90s
