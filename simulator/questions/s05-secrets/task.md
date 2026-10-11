Work in namespace `s05-secret`.

1. The Secret `legacy-db` already exists. Write the **decoded** value of its key `password` into `/opt/course/s05-secret/password.txt`.
2. Create a Secret named `api-creds` with the keys `API_USER=svc-api` and `API_KEY=k8s-7f3a9c21`.
3. Create a Pod named `api-client` (image `busybox:1.36`, command `sleep 1d`) that:
   - has an environment variable `API_KEY` whose value comes from key `API_KEY` of Secret `api-creds`,
   - mounts the Secret `legacy-db` at `/etc/db`, but **only** its key `password`, as the file `/etc/db/db-pass` with file permissions `0400`.
