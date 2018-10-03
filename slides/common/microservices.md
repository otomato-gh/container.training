# Containers, Microservices, Cloud-Native
---

class: extra-details

## Why use containers?

- Resource Isolation

--

class: extra-details

- Application Configuration Management

--

class: extra-details

- Dependency Encapsulation

--

class: extra-details

- Horizontal Scaling

--

class: extra-details

- Immutable Infrastructure

--

class: extra-details

- Build once - run anywhere

--

class: extra-details

- Perfect fit for Microservices

---
class: pic
#Microservices

![who wants a taxi?](images/microservices.png)
---

class: extra-details

#Microservices - the Advantages

- Smaller Application Footprint

--

class: extra-details

- Comprehensibility

--

class: extra-details

- Shorter Development Time

--

class: extra-details

- Continuous Delivery

--

class: extra-details

- Scalability

--

class: extra-details

- Polyglossia

--

class: extra-details

- Efficient Organisational Structure

---

class: extra-details

#Microservices - the Challenges

--

class: extra-details

- Distributed Systems Are Complex

--

class: extra-details

- Testing is more difficult

--

class: extra-details

- Deployment Complexity

--

class: extra-details


--

class: extra-details

- Service Discovery

--

class: extra-details

- Inter-Team Coordination Required

--

class: extra-details

- Data Partitioning and Sharing

---

class: extra-details

## So what the hell is Cloud-Native?

- Appications that are adapted to running on modern PaaS

  - See Heroku's 12-factor app: https://12factor.net/

- Enabled by public (or private) cloud

--

class: extra-details

- And the Infrastructure for running these Applications

  - Containers

  - Orchestration

  - Etc.

---
class: extra-details

## Cloud-Native Infrastructure
--
class: extra-details

 - Hidden behind useful abstractions

--
class: extra-details

 - Controlled by APIs

--
class: extra-details

 - Managed by software

--
class: extra-details

 - Has the purpose of running applications. 

---
##Cloud Native Computing Foundation
![CNCF](images/logoCNCF.png)

CNCF is an open source software foundation dedicated to making cloud native computing universal and sustainable. 

Cloud native computing uses an open source software stack to `deploy applications as microservices`, packaging each part into `its own container`, and dynamically `orchestrating` those containers to optimize resource utilization. 

Graduated projects: Kubernetes, Prometheus

Incubating: Envoy, Linkerd, OpenTracing, Helm, rkt, fluentd, etc.

https://www.cncf.io/