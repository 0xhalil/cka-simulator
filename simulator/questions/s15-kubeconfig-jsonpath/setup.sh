course_dir s15-kcfg
cat > /opt/course/s15-kcfg/my-kube-config <<'YAML'
apiVersion: v1
kind: Config
preferences: {}
clusters:
- name: production
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://10.30.0.11:6443
- name: development
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://10.30.0.21:6443
- name: kubernetes-on-aws
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://k8s.aws.example.internal:443
- name: test-cluster-1
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://10.30.0.41:6443
contexts:
- name: test-user@development
  context: {cluster: development, user: test-user}
- name: aws-user@kubernetes-on-aws
  context: {cluster: kubernetes-on-aws, user: aws-user, namespace: finance}
- name: test-user@production
  context: {cluster: production, user: test-user}
- name: research
  context: {cluster: test-cluster-1, user: dev-user, namespace: finance}
- name: ops@production
  context: {cluster: production, user: ops-admin, namespace: kube-system}
current-context: test-user@development
users:
- name: test-user
  user: {client-certificate: /etc/kubernetes/pki/users/test-user/test-user.crt, client-key: /etc/kubernetes/pki/users/test-user/test-user.key}
- name: dev-user
  user: {client-certificate: /etc/kubernetes/pki/users/dev-user/developer-user.crt, client-key: /etc/kubernetes/pki/users/dev-user/dev-user.key}
- name: aws-user
  user: {client-certificate: /etc/kubernetes/pki/users/aws-user/aws-user.crt, client-key: /etc/kubernetes/pki/users/aws-user/aws-user.key}
- name: ops-admin
  user: {token: not-a-real-token}
YAML
chown -R candidate: /opt/course/s15-kcfg
