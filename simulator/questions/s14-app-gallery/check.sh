N=s14-gallery; U=$(cat /root/.s14/gallery.uid 2>/dev/null)
probe() {  # probe <url> <expect>
  local n="probe-$RANDOM"
  kubectl -n $N run "$n" --image=busybox:1.36 --restart=Never --labels=s14-probe=1 --command -- \
    sh -c "for i in 1 2 3 4; do wget -qO- -T 4 '$1' 2>/dev/null | grep -q '$2' && exit 0; sleep 2; done; exit 1" >/dev/null 2>&1
  kubectl -n $N wait --for=jsonpath='{.status.phase}'=Succeeded pod/"$n" --timeout=45s >/dev/null 2>&1; local rc=$?
  kubectl -n $N delete pod "$n" --now >/dev/null 2>&1; return $rc
}
check "Deployment gallery is available with 2 ready replicas" 'kubectl -n $N rollout status deploy/gallery --timeout=30s && [ "$(jp deploy gallery -n $N "{.status.readyReplicas}")" = 2 ]'
check "gallery Pods run image nginx:1.27-alpine" '[ "$(kubectl -n $N get po -l app=gallery --field-selector=status.phase=Running -o jsonpath="{.items[*].spec.containers[0].image}" | tr " " "\n" | sort -u)" = nginx:1.27-alpine ]'
check "Service gallery has 2 ready endpoints" '[ "$(kubectl -n $N get endpointslice -l kubernetes.io/service-name=gallery -o jsonpath="{range .items[*].endpoints[*]}{.conditions.ready}{\"\n\"}{end}" | grep -c true)" = 2 ]'
check "http://gallery.s14-gallery returns the gallery start page" 'probe http://gallery.s14-gallery GALLERY-OK'
guard "Deployment and Service not deleted/recreated" '[ "$(kubectl -n $N get deploy/gallery svc/gallery -o jsonpath="{.items[*].metadata.uid}")" = "$U" ]'
guard "start page content unchanged" 'kubectl -n $N get cm -o jsonpath="{.items[*].data.index\.html}" | grep -q "42 pictures"'
