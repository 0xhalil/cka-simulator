NS=s12-life
repo_ok() { for u in root candidate; do sudo -u $u -H helm repo list -o json 2>/dev/null | jq -e --arg n "$1" --arg u "$2" '.[] | select(.name==$n and (.url|rtrimstr("/"))==$u)' && return 0; done; return 1; }
H=$(helm -n $NS history storefront -o json 2>/dev/null)
CUR=$(jq -r '.[-1].revision // empty' <<<"$H")
V=$(helm -n $NS get values storefront -o json 2>/dev/null)
check "repo s12-stefan points to the podinfo repository" 'repo_ok s12-stefan https://stefanprodan.github.io/podinfo'
check "good-revision.txt contains the podinfo-6.13.0 revision" '[ "$(tr -d " \n\r" < /opt/course/s12-life/good-revision.txt)" = "$(jq -r "[.[] | select(.chart==\"podinfo-6.13.0\")][0].revision" <<<"$H")" ]'
check "storefront was rolled back to the 6.13.0 revision (history shows Rollback to 2)" 'jq -e ".[] | select(.description==\"Rollback to 2\" and .chart==\"podinfo-6.13.0\")" <<<"$H"'
check "storefront is now deployed from podinfo-6.14.1, upgraded after the rollback" 'jq -e ".[-1].status==\"deployed\" and .[-1].chart==\"podinfo-6.14.1\" and .[-2].description==\"Rollback to 2\"" <<<"$H"'
check "user values of revision 2 kept (ui.message, ui.color) and faults not set" 'jq -e ".ui.message==\"spring sale\" and .ui.color==\"#2e8b57\" and ((.faults.unready // false)==false)" <<<"$V"'
check "replicaCount=2 and 2 ready podinfo Pods" 'jq -e ".replicaCount==2" <<<"$V" && for t in $(seq 24); do [ "$(jp -n $NS deploy storefront-podinfo "{.status.readyReplicas}/{.status.replicas}")" = 2/2 ] && exit 0; sleep 5; done; exit 1'
check "legacy-cart uninstalled, history kept" '[ "$(helm -n $NS status legacy-cart -o json | jq -r .info.status)" = uninstalled ] && ! kubectl -n $NS get deploy legacy-cart-podinfo'
