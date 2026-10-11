User **`s07-alice`** becomes the storage administrator of cluster1.

1. Create a ClusterRole `s07-storage-admin` that allows:
   - `get`, `list`, `watch` on **nodes**
   - `get`, `list`, `watch`, `create`, `delete` on **persistentvolumes**
   - `get`, `list`, `watch` on **storageclasses**
2. Bind it to user `s07-alice` **cluster-wide** using a ClusterRoleBinding named `s07-storage-admin`.
3. A security review found that `s07-alice` currently also has much broader cluster-wide permissions (e.g. she can delete nodes). Find the cause and remove these permissions **for `s07-alice` only**. Do not delete any ClusterRole and do not change the permissions of any other user.
4. Write the output of `kubectl auth can-i delete nodes` for `s07-alice` into `/opt/course/s07-clusterrole/delete-nodes.txt` and the output of `kubectl auth can-i create persistentvolumes` for `s07-alice` into `/opt/course/s07-clusterrole/create-pv.txt`.
