D=/opt/course/s04-logs; L="kubectl -n s04-logs logs payment-gw"
same() { [ -s "$1" ] && diff <(sed 's/[[:space:]]*$//' "$1" | grep -v '^$') <(echo "$2" | sed 's/[[:space:]]*$//' | grep -v '^$') >/dev/null; }
check "audit-errors.log contains exactly the ERROR lines of container audit-agent" 'same $D/audit-errors.log "$($L -c audit-agent | grep ERROR)"'
check "gateway-tail.log contains exactly the last 5 lines of container gateway" 'same $D/gateway-tail.log "$($L -c gateway --tail=5)"'
check "audit-ts.log contains the first 3 audit-agent lines with Kubernetes timestamps" 'same $D/audit-ts.log "$($L -c audit-agent --timestamps | head -3)"'
