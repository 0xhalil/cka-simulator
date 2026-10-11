A user accidentally deleted the MariaDB Deployment in namespace `mariadb`, which was configured with persistent storage. Your responsibility is to re-establish the Deployment while ensuring data is preserved by **reusing the available PersistentVolume** `mariadb-pv`.

1. Create a PersistentVolumeClaim named `mariadb` in namespace `mariadb` with:
   - Access mode: `ReadWriteOnce`
   - Storage: `250Mi`
   
   It must bind to the existing PersistentVolume `mariadb-pv`.
2. Edit the MariaDB Deployment file located at `/opt/course/mariadb/mariadb-deploy.yaml` to use the PVC you created in the previous step.
3. Apply the updated Deployment file to the cluster.
4. Ensure the MariaDB Deployment is running and stable.
