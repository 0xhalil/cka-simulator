F=/opt/course/crd/resources.yaml
check "resources.yaml uses default table output (NAME / CREATED AT header)" "head -1 $F | grep -Eq '^NAME +.*CREATED AT'"
check "all 6 cert-manager CRDs listed" "for c in certificaterequests certificates challenges clusterissuers issuers orders; do grep -Eq \"^\$c\\.(cert-manager|acme\\.cert-manager)\\.io \" $F || exit 1; done"
guard "no non-cert-manager CRDs listed" "! tail -n +2 $F | grep -v 'cert-manager.io' | grep -q ."
check "subject.yaml contains kubectl explain output for Certificate.spec.subject" "grep -q 'KIND: *Certificate' /opt/course/crd/subject.yaml && grep -Eq 'FIELD: *subject' /opt/course/crd/subject.yaml && grep -q organizations /opt/course/crd/subject.yaml"
