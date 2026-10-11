Work in namespace `s05-config`. The Deployment `webapp` (image `nginx:1.27-alpine`) is running there.

1. Create a ConfigMap named `webapp-config` containing:
   - the key `APP_COLOR` with value `blue`
   - the key `APP_MODE` with value `prod`
   - the key `extra.conf` with the content of the file `/opt/course/s05-config/extra.conf`
2. Update the Deployment `webapp` so that its container `nginx`:
   - has the environment variables `APP_COLOR` and `APP_MODE` with the values from the ConfigMap,
   - additionally has an environment variable `COLOR` whose value comes from the ConfigMap key `APP_COLOR`,
   - gets **only** the key `extra.conf` mounted as the file `/etc/nginx/conf.d/extra.conf`. The other files that already exist in `/etc/nginx/conf.d/` (like `default.conf`) must still be there.
3. The configuration in `extra.conf` makes nginx answer on port `8080` under `/healthz`. Make sure all Pods of `webapp` are running with the new configuration.
