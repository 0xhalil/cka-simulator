#!/usr/bin/env bash
# Copy the c2-helpers block of dev/reset-cluster2.sh into every questions/*/setup.sh that contains the markers.
cd "$(dirname "$0")/.."
python3 - <<'PY'
import glob, re
src = open("dev/reset-cluster2.sh").read()
block = re.search(r"^# >>> c2-helpers.*?^# <<< c2-helpers\n", src, re.S | re.M).group(0)
for f in sorted(glob.glob("questions/*/setup.sh")):
    s = open(f).read()
    if "# >>> c2-helpers" not in s:
        continue
    n = re.sub(r"^# >>> c2-helpers.*?^# <<< c2-helpers\n", lambda m: block, s, flags=re.S | re.M)
    if n != s:
        open(f, "w").write(n); print("synced", f)
PY
