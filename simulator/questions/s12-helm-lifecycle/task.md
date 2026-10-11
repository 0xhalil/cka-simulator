The Helm release `storefront` in namespace `s12-life` was upgraded several times and its Pods are no longer Ready.

1. Add the chart repository `https://stefanprodan.github.io/podinfo` under the name `s12-stefan`.
2. Find the revision of `storefront` that was deployed with chart **`podinfo-6.13.0`** and write only its revision number to `/opt/course/s12-life/good-revision.txt`.
3. **Roll back** `storefront` to that revision.
4. Afterwards upgrade `storefront` to chart `s12-stefan/podinfo` version **`6.14.1`**. The upgraded release must keep **all user-supplied values** of the rolled-back revision and additionally set `replicaCount=2`. Both Pods must become Ready.
5. Uninstall the release `legacy-cart` in the same namespace, but **keep its release history** so it can still be inspected with `helm status` / `helm history`.
