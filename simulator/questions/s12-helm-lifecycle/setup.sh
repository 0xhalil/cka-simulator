course_dir s12-life
for u in root candidate; do sudo -u $u -H helm repo remove s12-stefan >/dev/null 2>&1 || true; done
helm -n s12-life uninstall storefront legacy-cart >/dev/null 2>&1 || true
reset_ns s12-life
R="--repo https://stefanprodan.github.io/podinfo"
set -e
helm -n s12-life install legacy-cart podinfo $R --version 6.11.2 --set ui.message="legacy cart" >/dev/null
helm -n s12-life install storefront podinfo $R --version 6.12.0 --set ui.message="v1 launch" >/dev/null
helm -n s12-life upgrade storefront podinfo $R --version 6.13.0 --set ui.message="spring sale" --set ui.color="#2e8b57" --description "spring campaign" >/dev/null
helm -n s12-life upgrade storefront podinfo $R --version 6.14.0 --set ui.message="hotfix" --set faults.unready=true --description "hotfix attempt" >/dev/null
