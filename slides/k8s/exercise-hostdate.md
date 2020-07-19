# Exercise — Pods & Deployments

1. Using  `kubectl`  please create a Pod  named `hostdate` that will run a container based on `otomato/hostdate:latest`
2. Check pod logs
3. Now create a deployment named `hostdate` using the same image.
4. Verify the deployment created all the related objects (what is created?)
5. Check the logs for the deployment
6. Scale the deployment to 3 replicas
7. Check the logs again. What changed?
8. Delete one of the deployment pods
9. Verify it was recreated
10. Scale the deployment to 0 (is it possible?)
10. Delete the pod and the deployment
