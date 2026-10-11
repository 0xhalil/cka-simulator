CPV=$(kubectl get node cka-cp2 -o jsonpath='{.status.nodeInfo.kubeletVersion}')
check "kubeadm on cka-w2 is $CPV" "[ \"\$(on cka-w2 'kubeadm version -o short')\" = $CPV ]"
check "kubelet binary on cka-w2 is $CPV" "[ \"\$(on cka-w2 'kubelet --version' | awk '{print \$2}')\" = $CPV ]"
check "kubectl on cka-w2 is $CPV" "on cka-w2 'kubectl version --client' | grep -q \"Client Version: $CPV\""
if [ "$(jp node cka-w2 '{.status.conditions[?(@.type=="Ready")].status}')" = True ]; then
  check "node cka-w2 reports kubelet $CPV (kubelet restarted)" "[ \"\$(jp node cka-w2 '{.status.nodeInfo.kubeletVersion}')\" = $CPV ]"
fi
check "node cka-w2 is schedulable (uncordoned)" "[ \"\$(jp node cka-w2 '{.spec.unschedulable}')\" != true ]"
