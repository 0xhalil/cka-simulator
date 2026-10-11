```bash
ssh cka-cp1
k -n s03-labels get pod --show-labels
# 1. AND = comma
k -n s03-labels get pod -l env=prod,tier=frontend -o name | cut -d/ -f2 > /opt/course/s03-labels/prod-frontend.txt
# 2. "!=" also selects pods WITHOUT the label (ledger-old) -> 2
k -n s03-labels get pod -l 'bu=finance,env!=prod' --no-headers | wc -l > /opt/course/s03-labels/finance-nonprod.txt
# 3. bulk labeling
k -n s03-labels label pod -l 'tier=backend,env!=prod' track=canary
k -n s03-labels get pod -l track=canary
# 4. typo in the selector: tier=front-end -> frontend
k -n s03-labels edit svc shop-frontend
k -n s03-labels get endpointslice -l kubernetes.io/service-name=shop-frontend
```
Traps: the set-based selector `env in (dev,staging)` doesn't select the unlabeled pod (answer would be 1, wrong). The `tools` pod has no `tier` label — it isn't selected by `tier=backend` and must not get canary.
