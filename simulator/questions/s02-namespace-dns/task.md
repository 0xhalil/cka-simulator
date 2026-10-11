The application `webapp` in namespace `s02-frontend` needs the Redis cache that runs behind the Service `cache` in namespace `s02-backend`. The `webapp` Pods read the cache address from the environment variable `CACHE_HOST`; they never become ready because the cache cannot be reached.

1. Write the **fully qualified** DNS name of the Service `cache` into `/opt/course/s02-dns/fqdn.txt`.
2. Fix the Deployment `webapp` so that it reaches the cache through DNS (do not use any IP address). Both replicas must become ready. Do not change anything in namespace `s02-backend`.
3. Create a ResourceQuota named `frontend-quota` in namespace `s02-frontend` that limits the namespace to at most `6` Pods, `500m` total CPU requests and `512Mi` total memory requests. The `webapp` Deployment must still have **2 ready replicas running the fixed configuration** afterwards.
