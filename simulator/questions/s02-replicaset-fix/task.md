Namespace `s02-rs` has two ReplicaSet problems.

**1.** The ReplicaSet `backend` should run **3** Pods of image `httpd:2.4-alpine`, but its Pods are not working. Fix it so that the ReplicaSet `backend` has exactly **3 ready Pods** and **every Pod managed by it** runs image `httpd:2.4-alpine`. Keep the ReplicaSet's name and selector.

**2.** The manifest `/opt/course/s02-rs/frontend-rs.yaml` should create a ReplicaSet `frontend` with 2 replicas, but it cannot be created. Fix the file **in place** (keep the selector `app: frontend` unchanged) and create the ReplicaSet from it. Both Pods must be ready.
