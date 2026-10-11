course_dir s05-config
reset_ns s05-config
cat > /opt/course/s05-config/extra.conf <<'CONF'
server {
    listen 8080;
    location /healthz {
        default_type text/plain;
        return 200 "webapp-healthy\n";
    }
}
CONF
chown -R candidate: /opt/course
kubectl -n s05-config create deploy webapp --image=nginx:1.27-alpine --replicas=2 >/dev/null
kubectl -n s05-config patch deploy webapp --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/name","value":"nginx"}]' >/dev/null
wait_deploy s05-config webapp
