Work in namespace `s07-sa` on cluster1. Files go to `/opt/course/s07-sa/`.

1. Create a ServiceAccount `reporter`. Allow it to `get` and `list` Pods in namespace `s07-sa` (Role and RoleBinding named `reporter`).
2. Create a **long-lived (non-expiring) API token** for `reporter` stored in a Secret named `reporter-token`. Write the **decoded** token into `/opt/course/s07-sa/reporter.token`.
3. Additionally create a **time-bound** token for `reporter` that is valid for exactly **2 hours** and write it into `/opt/course/s07-sa/reporter-2h.token`.
4. Pods running as `reporter` will pull images from the private registry `registry.s07.internal:5000`. Create a Secret `regcred` for this registry (username `scanner`, password `Sc4nner-Pass`) and configure it **on the ServiceAccount**, so every Pod using `reporter` gets it automatically. Then change the existing Deployment `scanner` to run as ServiceAccount `reporter`. Do not add `imagePullSecrets` to the Deployment itself.
5. The Deployment `batch` runs as ServiceAccount `batch-runner` and does not need API access. Disable the automatic mounting of API credentials **on the ServiceAccount `batch-runner`** and ensure that the running `batch` Pods no longer have a token mounted.
