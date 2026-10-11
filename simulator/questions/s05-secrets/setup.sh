course_dir s05-secret
reset_ns s05-secret
PW="db-$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n')"
kubectl -n s05-secret create secret generic legacy-db --from-literal=username=app_ro --from-literal=password="$PW" --from-literal=host=db.internal >/dev/null
chown -R candidate: /opt/course
