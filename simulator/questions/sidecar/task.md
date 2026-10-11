An existing Deployment `logger-app` in namespace `sidecar` runs a legacy application that writes its log to the file `/var/log/app.log` inside the container. Your logging stack needs the log on stdout.

Update the Deployment (do not delete/recreate it) so that:

- A **native sidecar** container (an init container that keeps running for the lifetime of the Pod) named `sidecar` using image `busybox:1.36` runs the command:
  ```
  /bin/sh -c "tail -n+1 -F /var/log/app.log"
  ```
- Both the existing container and the sidecar share a volume named `logs` mounted at `/var/log`, so the sidecar can read `app.log`.
- The existing container must keep its name, image and command.

`kubectl logs` of the `sidecar` container must show the application log lines.
