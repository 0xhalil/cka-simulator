Work in namespace `s05-cmd`.

1. The Deployment `sleeper` should simply run `sleep 3600` in its container, but its Pods keep failing. Fix the Deployment (keep the image `busybox:1.36`).

2. Create a Pod named `cache` with image `redis:7-alpine`. The image's ENTRYPOINT is a script that, among other things, drops root privileges before starting the process passed to it as arguments. The image's default CMD is `redis-server`.

   Configure the Pod so that the container starts `redis-server` listening on port **6380** with a **maxmemory** of `32mb` (`redis-server --port 6380 --maxmemory 32mb`). The image's ENTRYPOINT must still be executed, so redis must **not** run as root.
