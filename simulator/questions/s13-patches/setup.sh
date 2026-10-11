course_dir s13-patch
reset_ns s13-patch
B=/opt/course/s13-patch/base
mkdir -p $B /opt/course/s13-patch/overlays/staging
mk() {  # name tier
cat > $B/$1.yaml <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $1
  labels:
    app: $1
    tier: $2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $1
  template:
    metadata:
      labels:
        app: $1
        tier: $2
    spec:
      containers:
      - name: $1
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /www && echo $1 > /www/index.html && exec httpd -f -p 8080 -h /www"]
        env:
        - name: LOG_LEVEL
          value: debug
        resources:
          requests:
            cpu: 5m
            memory: 8Mi
YAML
}
mk ledger backend; mk audit backend; mk frontend frontend
# ledger has a broken liveness probe
cat >> $B/ledger.yaml <<'YAML'
        livenessProbe:
          exec:
            command: ["cat", "/tmp/healthy"]
          initialDelaySeconds: 5
          periodSeconds: 5
YAML
cat > $B/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ledger.yaml
- audit.yaml
- frontend.yaml
YAML
( cd $B && sha256sum * > /root/.s13-patch.sha )
chown -R candidate: /opt/course
