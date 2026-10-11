```bash
ssh cka-cp1
k -n sp-culator edit deploy front-end
#      containers:
#      - name: nginx
#        ports:
#        - name: http
#          containerPort: 80
#          protocol: TCP
k -n sp-culator expose deploy front-end --name=front-end-svc --type=NodePort --port=80 --target-port=http $do > svc.yaml
# add spec.ports[0].nodePort: 30080
k apply -f svc.yaml
curl <nodeIP>:30080
```
