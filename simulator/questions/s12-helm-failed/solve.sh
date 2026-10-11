NS=s12-ops
helm -n $NS list -a
echo checkout > /opt/course/s12-ops/failed-release.txt
sed -i 's/6.14.1-hotfix/6.14.1/' /opt/course/s12-ops/checkout-values.yaml
helm -n $NS upgrade checkout podinfo --repo https://stefanprodan.github.io/podinfo --version 6.14.1 -f /opt/course/s12-ops/checkout-values.yaml --wait --timeout 3m
helm -n $NS history payments
helm -n $NS rollback payments 1 --wait --timeout 3m
helm -n $NS list -a
