A new release of the *gallery* web app was rolled out in namespace `s14-gallery` (Deployment `gallery`, Service `gallery`). Its configuration (nginx server config and start page) is kept in a ConfigMap in the same namespace.

The Deployment never becomes available and the Service does not answer.

Fix the problem so that the Deployment is available and `http://gallery.s14-gallery` (port `80`) returns the gallery start page (it contains `GALLERY-OK`).

- The app must keep using the official `nginx` image in version `1.27` (alpine variant).
- Do not delete the Deployment or the Service.
