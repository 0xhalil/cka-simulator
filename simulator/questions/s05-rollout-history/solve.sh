kubectl -n s05-rollout rollout history deploy web
echo 4 > /opt/course/s05-rollout/broken-revision.txt
kubectl -n s05-rollout rollout undo deploy web --to-revision=2
kubectl -n s05-rollout patch deploy web -p '{"spec":{"revisionHistoryLimit":5,"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
kubectl -n s05-rollout rollout status deploy web --timeout=120s
sleep 6
