kubectl label node cka-w1 s03.cka.local/disktype=ssd --overwrite
kubectl -n s03-affinity patch deploy ssd-cache --type=json -p '[
 {"op":"remove","path":"/spec/template/spec/nodeSelector"},
 {"op":"add","path":"/spec/template/spec/affinity","value":{"nodeAffinity":{
   "requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"s03.cka.local/disktype","operator":"In","values":["ssd","nvme"]}]}]},
   "preferredDuringSchedulingIgnoredDuringExecution":[{"weight":75,"preference":{"matchExpressions":[{"key":"s03.cka.local/zone","operator":"In","values":["zone-a"]}]}}]}}}]'
kubectl -n s03-affinity rollout status deploy ssd-cache --timeout=120s
