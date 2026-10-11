C=/opt/course/s13-fix
sed -i 's/^- svc.yaml$/- service.yaml/' $C/base/kustomization.yaml
sed -i 's#^- name: docker.io/library/nginx$#- name: nginx#' $C/overlays/prod/kustomization.yaml
sed -i 's/^  name: webapp$/  name: web/' $C/overlays/prod/limits.yaml
kubectl apply -k $C/overlays/prod
kubectl -n s13-fix rollout status deploy prod-web --timeout=120s
sleep 3
