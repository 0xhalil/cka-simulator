Reconfigure the existing Deployment `front-end` in namespace `sp-culator` to expose port `80/tcp` of the existing container `nginx`, with the port name `http`.

Create a new Service named `front-end-svc` in the same namespace that exposes container port `http`.

Configure the new Service to also expose the individual Pods via a **NodePort** on the nodes on which they are scheduled, using nodePort `30080`.
