1. In namespace `s03-static` a Pod whose name starts with `cpu-burner` keeps coming back every time somebody deletes it. Find out where it comes from and remove it **permanently**. Write the node name and the absolute path of the file responsible for it into `/opt/course/s03-static/burner-source.txt` in the format `<node>:<path>` (for example `node1:/some/dir/file.yaml`).

2. Create a **static Pod** named `s03-static-web` in namespace `s03-static` on node `cka-w1`:
   - image `nginx:1.27-alpine`, label `app=static-web`
   - resource requests CPU `10m`, memory `16Mi`
   - the manifest file must be named `s03-static-web.yaml` and placed in the kubelet's static Pod directory of `cka-w1`.

   Ensure the Pod is `Running` and visible via `kubectl` (as `s03-static-web-cka-w1`).

Do not change the kubelet configuration and do not touch other files in the static Pod directory.
