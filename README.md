# N-Tier Application Using DevOps Methodologies. 
## Kubernetes, Docker, Github Actions, Bash Scripts, GitOps, Terraform  on AWS

![Applaudo.png](https://i.postimg.cc/Kc5J8TGf/Applaudo.png)


The main objective of this challenge is to use all the DevOps methodologies learnt during the tarinee program, to achieve that purpose the following practice could be divided in two main parts:

- Infrastructure: Deployed on AWS using terraform and HCL as the main programming language, the solution is based on EKS, even when the deployment of this kind of architectures tends to have cetain amount of complexity, the Pods management makes easy the final deployment of the App
- Application: The selected App is a basic 3-tier MERN CRUD App
using Mongo Atlas as DB and properly Dockerized.
- 

### *Infrastructure*

As mentiones before, EKS was the implemented technology to deploy the application, these were the basic elements that compose the solution:

-ELB (2)

-EC2 (Worker Nodes) (2)

-Internet Gateways (2)

-NAT Gateways (2)

-Main VPC (1)

-Security Resources (Roles, Security Groups)

-Network Resources (Elastic IP's, Public and Private Subnets, Route Tables)

![infra.png](https://i.postimg.cc/sfP0nqbT/Final-Challenge-1.png)

The use of 2 AZ and Auto-Scale groups enables high avalaibility in the design; even though the deplyments used in Kubernetes are not provissioned with Rolling Updates configurations, the recovery time of the pods  (4 for each tier) is relatively fast and allows a quick response in case of app update.

This infrastructure is deployed using github actions scripts and Terraform Cloud for each environment configured (Prod, Dev, Stage) the source code for this configuration can be found in :

```sh
https://github.com/renzzog777/EKS.git
```
and the Kubernetes configurations files:

```sh
https://github.com/renzzog777/K8S.git
```



###  *MERN CRUD Application*

-Backend: Express was the framework selected to deploy the Node JS backend server of the app, in charge of handling all the routes and API's for the CRUD functions of the APP. 

-Frontend: For the UI layer, React was the framework used in this case, the management of webpack dependencies generated multiple issues during the implementation of the solution, this cused that at the end the fullstack deployment of the app was not possible.

-Data Base: Being a MERN app, the usage of Mongo DB was mandatory, in this opportunity, I decided to use the MongoDB Atlas Cluster service to enable the usage of an external resource, saving infrastructure resources and workload.

![App.png](https://i.postimg.cc/GhNZsNNz/Front.jpg)


You can find the repositories for this tiers in the following URL's:

```sh
https://github.com/renzzog777/Users_Mern_App_Back.git
```
and the Kubernetes configurations files:

```sh
https://github.com/renzzog777/Users_Mern_App_Front.git
```

## *CI Solutions*

- Infrastructure: Github Actions was used to push the source code to Terraform Cloud for the later deployment in AWS. For practical proposes, the  infrastructor for all the environments will be raised inside the same AWS region. Github Actions was also used to update the different branches or development environments automatically.

- Application: The generation of contenerized images was managed directly by Github Actions, the final images in DockerHub are avaliable in three distinct sets for each environment and they're differentiated by a tag as "_dev" or "_stg" depending on th environment.  




## Author

Renzzo Gomez Reatiga
AWS DevOps- Trainnee.

Applaudo Studios

**rgomez@applaudostudios.dev**
