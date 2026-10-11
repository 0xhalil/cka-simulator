The `checkout` Deployment in namespace `s14-pay-web` calls the `payments` API, which runs in namespace `s14-pay-api` behind the Service `payments` (port `8080`). The URL it uses is taken from the environment variable `PAYMENTS_URL`. A `checkout` Pod only becomes `Ready` after it has successfully received a response from the API — currently it never does.

The security team has locked down both namespaces with NetworkPolicies. Troubleshoot and fix the problem so that `checkout` becomes Ready.

- Do **not** modify or delete any existing NetworkPolicy. You may create additional NetworkPolicies, but keep them minimal: only `checkout` Pods may reach the `payments` Pods, and only on the port actually required.
- Do not change the `payments` Deployment or Service, and do not change the `checkout` container image or command.
