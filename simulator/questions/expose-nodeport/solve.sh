kubectl -n sp-culator patch deploy front-end --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","ports":[{"name":"http","containerPort":80,"protocol":"TCP"}]}]}}}}'
kubectl -n sp-culator rollout status deploy front-end
kubectl -n sp-culator expose deploy front-end --name=front-end-svc --type=NodePort --port=80 --target-port=http --dry-run=client -o yaml \
  | sed 's/targetPort: http/targetPort: http\n    nodePort: 30080/' | kubectl apply -f -
