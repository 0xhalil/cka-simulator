Create reports about the Deployments in namespace `s15-deploy`.

1. Write a table of all Deployments in namespace `s15-deploy` into `/opt/course/s15-deploy/deploys.txt`, with exactly these columns and header:

   ```
   DEPLOYMENT   CONTAINER_IMAGE   READY_REPLICAS   NAMESPACE
   ```
   (`CONTAINER_IMAGE` is the image of the first container). The rows must be **sorted by Deployment name**, produced by `kubectl` itself.

2. Write the `kubectl` command that produces exactly this table into `/opt/course/s15-deploy/deploys.sh`.

3. Write the names of all Deployments in namespace `s15-deploy`, **ordered by creation time (oldest first)**, one per line into `/opt/course/s15-deploy/by-age.txt`.
