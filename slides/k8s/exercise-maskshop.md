# Exercise — deploying on Kubernetes

Let's deploy an app on Kubernetes!

What app? A [Mask Shop](https://github.com/otomato-gh/maskshop.git)! 

![how to build a mask shop](images/maskshop.png)

---

## Mask Shop Components

We have the following components:

| Name  | Image                           | Port |
|-------|---------------------------------|------|
| mongo | mongo                           | 27017 |
| api   | otomato/maskshop-api:latest     | 80   |
| front | otomato/maskshop-front:latest   | 80   |

We need `front` to be available from outside the cluster.

See next slide if you need hints!

---

## Hints

*Scroll one slide at a time to see hints.*

--

- For each component, we need to create a deployment and a service

--

- Deployments can be created with `kubectl create deployment`

--

- Services can be created with `kubectl expose`

--

- Public services (like `front`) need to use a special type

  (e.g. `NodePort`)
