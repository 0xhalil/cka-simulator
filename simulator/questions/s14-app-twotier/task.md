A two-tier application is deployed in namespace `s14-shop`: a **web** tier (Deployment `web`) that serves users and forwards every request to the **catalog database** tier (Deployment `catalog`).

Users should see the product catalog page (it contains the text `CATALOG-DB-OK`) when they open `http://<any-node-IP>:31401`, but the application is not working.

Troubleshoot the application and fix **all** problems so the page is served on NodePort `31401`.

- Do **not** delete or recreate the Deployments `web` and `catalog`.
- Do **not** change any container image or the catalog content.
