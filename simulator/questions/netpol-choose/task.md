There are two Deployments, `frontend` in namespace `frontend` and `backend` in namespace `backend`. A default-deny ingress policy is already in place in namespace `backend`.

Look at the NetworkPolicy YAML samples in directory `/opt/course/netpol/`.

Choose **one** of them and apply it so that `frontend` Pods can communicate with `backend` Pods (Service `backend-svc` on port 80), while being **as restrictive as possible**: no other Pods (in any namespace) may reach the backend.

Do **not** delete or modify the existing default-deny policy and do not create or edit any other policies.
