D=/opt/course/s03-labels
norm() { sed -e 's#^pods\?/##' -e 's/[[:space:]]//g' "$1" | grep -v '^$' | sort | tr '\n' ' '; }
check "prod-frontend.txt lists exactly the prod frontend Pods" '[ "$(norm $D/prod-frontend.txt)" = "hr-fe-1 pay-fe-1 pay-fe-2 shop-fe-1 " ]'
check "finance-nonprod.txt contains the correct count" '[ "$(tr -d "[:space:]" < $D/finance-nonprod.txt)" = 2 ]'
check "exactly the non-prod backend Pods carry track=canary" \
  '[ "$(kubectl -n s03-labels get pod -l track=canary -o name | sort | tr "\n" " ")" = "pod/hr-be-dev pod/ledger-old pod/pay-be-dev pod/shop-be-stg " ]'
check "Service shop-frontend selects exactly Pod shop-fe-1" \
  'for i in $(seq 1 10); do [ "$(kubectl -n s03-labels get endpointslice -l kubernetes.io/service-name=shop-frontend -o jsonpath="{.items[*].endpoints[*].targetRef.name}")" = shop-fe-1 ] && exit 0; sleep 2; done; exit 1'
guard "Pods were not deleted and keep their original labels" \
  '[ "$(kubectl -n s03-labels get pod -o name | wc -l)" = 12 ] && [ "$(kubectl -n s03-labels get pod -l "app,bu" -o name | wc -l)" = 12 ] && [ "$(kubectl -n s03-labels get pod -l env=prod,tier=frontend -o name | wc -l)" = 4 ]'
