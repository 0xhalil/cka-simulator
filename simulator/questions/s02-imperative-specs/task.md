Use imperative `kubectl` commands where possible. Work in namespace `s02-imp` (it exists).

1. Create a Pod `nginx-prod` with image `nginx:1.27-alpine` and the labels `tier=web` and `env=prod`.
2. Create a Pod `httpd-edge` with image `httpd:2.4-alpine` that declares container port `80`. Make it reachable inside the cluster through a ClusterIP Service named `httpd-edge` on port `8080`.
3. Create a Deployment `cache` with image `redis:7-alpine` and `2` replicas in a **new** namespace `s02-imp-dev`.
4. Generate a manifest for a Deployment `worker` (namespace `s02-imp`, image `busybox:1.36`, `3` replicas, container command `sleep 3600`) and save it to `/opt/course/s02-imp/worker.yaml`. **Do not create** the Deployment in the cluster.
