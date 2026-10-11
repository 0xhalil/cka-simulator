```bash
ssh cka-cp1
k -n s07-sa create sa reporter
k -n s07-sa create role reporter --verb=get,list --resource=pods
k -n s07-sa create rolebinding reporter --role=reporter --serviceaccount=s07-sa:reporter
```
Long-lived token (not created automatically since 1.24; you create the Secret, the token controller fills it):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: reporter-token
  namespace: s07-sa
  annotations:
    kubernetes.io/service-account.name: reporter
type: kubernetes.io/service-account-token
```
```bash
k -n s07-sa get secret reporter-token -o jsonpath='{.data.token}' | base64 -d > /opt/course/s07-sa/reporter.token
k -n s07-sa create token reporter --duration=2h > /opt/course/s07-sa/reporter-2h.token   # TokenRequest API, time-limited

k -n s07-sa create secret docker-registry regcred --docker-server=registry.s07.internal:5000 \
  --docker-username=scanner --docker-password=Sc4nner-Pass
k -n s07-sa patch sa reporter -p '{"imagePullSecrets":[{"name":"regcred"}]}'
k -n s07-sa set serviceaccount deploy scanner reporter      # regcred is added automatically to new Pods

k -n s07-sa patch sa batch-runner -p '{"automountServiceAccountToken":false}'
k -n s07-sa rollout restart deploy batch                     # TRAP: existing Pods don't change on their own
k -n s07-sa exec deploy/batch -- ls /var/run/secrets/kubernetes.io/serviceaccount   # absent
```
Traps: the token in the Secret is base64 (decode it). Changes to the SA only apply to **newly** created Pods.
