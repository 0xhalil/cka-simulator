Your team wants to keep a customized copy of the podinfo chart.

1. Add the Helm repository `https://stefanprodan.github.io/podinfo` with the name `s12-pi`.
2. Download chart `podinfo` version **`6.13.0`** from that repository and **extract** it so that the chart lives in `/opt/course/s12-pull/podinfo/`.
3. Edit the default values **in that local chart** (`values.yaml`) so that:
   - `replicaCount` is `2`,
   - the Service is of type `NodePort` with nodePort `30913`,
   - the UI message (`ui.message`) is `docs portal`.
4. Install the **local chart directory** as release `docs` in namespace `s12-docs` (create it). Do **not** pass any values on the command line (`--set`, `-f`).
5. Save the rendered manifests of the installed release (as stored by Helm) to `/opt/course/s12-pull/docs-manifest.yaml`.
