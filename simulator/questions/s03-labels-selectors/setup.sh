reset_ns s03-labels
course_dir s03-labels
pod() {  # name labels
cat <<YAML
---
apiVersion: v1
kind: Pod
metadata: {name: $1, namespace: s03-labels, labels: {$2}}
spec:
  terminationGracePeriodSeconds: 1
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "sleep 1d"]
    resources: {requests: {cpu: 5m, memory: 8Mi}}
YAML
}
{
pod pay-fe-1    "app: pay,  env: prod,    tier: frontend, bu: finance"
pod pay-fe-2    "app: pay,  env: prod,    tier: frontend, bu: finance"
pod pay-be-1    "app: pay,  env: prod,    tier: backend,  bu: finance"
pod pay-be-dev  "app: pay,  env: dev,     tier: backend,  bu: finance"
pod ledger-old  "app: ledger,             tier: backend,  bu: finance"
pod shop-fe-1   "app: shop, env: prod,    tier: frontend, bu: retail"
pod shop-fe-dev "app: shop, env: dev,     tier: frontend, bu: retail"
pod shop-be-1   "app: shop, env: prod,    tier: backend,  bu: retail"
pod shop-be-stg "app: shop, env: staging, tier: backend,  bu: retail"
pod hr-fe-1     "app: hr,   env: prod,    tier: frontend, bu: hr"
pod hr-be-dev   "app: hr,   env: dev,     tier: backend,  bu: hr"
pod tools       "app: tools, env: prod,   bu: finance"
cat <<'YAML'
---
apiVersion: v1
kind: Service
metadata: {name: shop-frontend, namespace: s03-labels}
spec:
  selector: {app: shop, tier: front-end, env: prod}
  ports: [{port: 80, targetPort: 80}]
YAML
} | kubectl apply -f -
