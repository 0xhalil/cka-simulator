A developer started a Helm chart at `/opt/course/s12-chart/inventory`, but it is broken.

1. Fix the chart so that `helm lint /opt/course/s12-chart/inventory` reports **no errors**. Set the chart **version** to `0.2.0` and the **appVersion** to `1.27-alpine`.
2. The chart must deploy the image `nginx:1.27-alpine` with the default values (fix the defaults in the chart; the image tag must come from the appVersion, keep `image.tag` empty).
3. Package the chart into `/opt/course/s12-chart/inventory-0.2.0.tgz`.
4. Install the **packaged** chart as release `inventory` in namespace `s12-inv` (create the namespace) with `replicaCount=2`. Both Pods must be Ready and the Service must answer HTTP requests on its ClusterIP.
