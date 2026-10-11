helm repo add s12-stefan https://stefanprodan.github.io/podinfo
helm repo update s12-stefan
helm -n s12-life history storefront
REV=$(helm -n s12-life history storefront -o json | jq -r '[.[] | select(.chart=="podinfo-6.13.0")][0].revision')
echo $REV > /opt/course/s12-life/good-revision.txt
helm -n s12-life rollback storefront $REV
helm -n s12-life upgrade storefront s12-stefan/podinfo --version 6.14.1 --reuse-values --set replicaCount=2 --wait --timeout 3m
helm -n s12-life uninstall legacy-cart --keep-history
