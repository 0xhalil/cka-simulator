SA=system:serviceaccount:cicd:pipeline
can() { kubectl auth can-i "$1" "$2" --as=$SA -n "$3" 2>/dev/null | grep -qx yes; }
check "ServiceAccount pipeline exists in cicd" "kubectl -n cicd get sa pipeline"
check "ClusterRole pipeline-deployer exists" "kubectl get clusterrole pipeline-deployer"
check "SA can create/update/patch deployments and statefulsets in cicd and staging" "for ns in cicd staging; do for v in create update patch get list; do can \$v deployments.apps \$ns && can \$v statefulsets.apps \$ns || exit 1; done; done"
check "SA can get/list pods but not delete pods" "can list pods staging && can get pods cicd && ! can delete pods cicd"
guard "SA cannot delete deployments" "! can delete deployments.apps cicd"
guard "no permissions in other namespaces (default, kube-system)" "! can create deployments.apps default && ! can list pods kube-system"
check "Deployment runner uses serviceAccountName pipeline and is rolled out" "[ \"\$(jp deploy runner -n cicd '{.spec.template.spec.serviceAccountName}')\" = pipeline ] && kubectl -n cicd rollout status deploy/runner --timeout=60s"
check "can-i.txt contains 'yes'" "grep -qx yes /opt/course/rbac/can-i.txt"
