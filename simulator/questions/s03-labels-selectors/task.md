Namespace `s03-labels` contains a number of Pods of different business units (label `bu`), environments (label `env`) and tiers (label `tier`). Use label selectors to solve the following:

1. Write the names of all Pods that run in environment `prod` **and** belong to tier `frontend` into `/opt/course/s03-labels/prod-frontend.txt`, one name per line.
2. Write the **number** of Pods of business unit `finance` that are **not** running in environment `prod` into `/opt/course/s03-labels/finance-nonprod.txt` (just the number). A Pod without an `env` label is not a `prod` Pod.
3. Add the label `track=canary` to every Pod of tier `backend` that is not running in environment `prod` — and to no other Pod.
4. Service `shop-frontend` currently has no endpoints. Fix its selector so that it selects exactly the `prod` `frontend` Pods of app `shop`.

Do not delete any Pod and do not change any existing label.
