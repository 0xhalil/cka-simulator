course_dir s07-certs
cat > /opt/course/s07-certs/answers.txt <<'TXT'
apiserver_issuer:
apiserver_sans:
apiserver_not_after:
etcd_client_cert:
etcd_client_cn:
etcd_server_issuer:
kubelet_w1_client_subject:
TXT
chown -R candidate: /opt/course/s07-certs
