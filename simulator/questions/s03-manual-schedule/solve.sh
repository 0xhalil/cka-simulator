kubectl -n s03-manual get pod manual-web -o yaml > /tmp/s03-manual-web.yaml
kubectl -n s03-manual delete pod manual-web --wait=true
sed -i 's/^spec:/spec:\n  nodeName: cka-w1/' /tmp/s03-manual-web.yaml
kubectl apply -f /tmp/s03-manual-web.yaml
cat <<'YAML' | kubectl create -f -
apiVersion: v1
kind: Binding
metadata: {name: manual-api, namespace: s03-manual}
target: {apiVersion: v1, kind: Node, name: cka-w1}
YAML
kubectl -n s03-manual wait --for=condition=Ready pod --all --timeout=90s
