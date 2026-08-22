````markdown
# Google Online Boutique — Production-Style DevOps & GitOps Platform

A production-oriented DevOps and GitOps implementation built around Google's Online Boutique microservices application.

The project demonstrates an end-to-end software delivery platform using Docker, Kubernetes, Helm, GitHub Actions, Amazon ECR, Terraform, Argo CD, Argo CD Image Updater, HashiCorp Vault, Prometheus, Grafana, Loki, OpenTelemetry, and Tempo.

---

## Architecture

### Complete Platform Architecture

```text
                                      ┌──────────────────────┐
                                      │      DEVELOPER       │
                                      └──────────┬───────────┘
                                                 │
                                                 │ git push
                                                 ▼
                              ┌─────────────────────────────────┐
                              │             GITHUB               │
                              │                                  │
                              │      online-boutique-app         │
                              └───────────────┬─────────────────┘
                                              │
                                              ▼
                              ┌─────────────────────────────────┐
                              │        GITHUB ACTIONS            │
                              │                                  │
                              │  Build / Test / Security / CI   │
                              └───────────────┬─────────────────┘
                                              │
                                              │ Docker Image
                                              ▼
                              ┌─────────────────────────────────┐
                              │          AMAZON ECR              │
                              │                                  │
                              │    Container Image Registry      │
                              └───────────────┬─────────────────┘
                                              │
                                              │ Image Discovery
                                              ▼
                              ┌─────────────────────────────────┐
                              │      ARGO CD IMAGE UPDATER       │
                              │                                  │
                              │      newest-build strategy       │
                              └───────────────┬─────────────────┘
                                              │
                                              │ Update Helm Values
                                              ▼
                    ┌─────────────────────────────────────────────────────┐
                    │                 GITOPS REPOSITORY                   │
                    │                                                     │
                    │             google-boutique-gitops                  │
                    │                                                     │
                    │       Helm Values / Applications / Terraform        │
                    └────────────────────────┬────────────────────────────┘
                                             │
                                             │ Git reconciliation
                                             ▼
                              ┌─────────────────────────────────┐
                              │            ARGO CD              │
                              │                                  │
                              │      GitOps Controller           │
                              └───────────────┬─────────────────┘
                                              │
                                              ▼
                              ┌─────────────────────────────────┐
                              │              HELM                │
                              │                                  │
                              │       Kubernetes Manifests       │
                              └───────────────┬─────────────────┘
                                              │
                                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES / KIND CLUSTER                            │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                         ecommerce-prod                                  │  │
│  │                                                                        │  │
│  │  ┌─────────┐  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐     │  │
│  │  │Frontend │  │Product      │  │Recommendation│  │Cart          │     │  │
│  │  │         │  │Catalog      │  │Service       │  │Service       │     │  │
│  │  └─────────┘  └─────────────┘  └──────────────┘  └──────────────┘     │  │
│  │                                                                        │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐ │  │
│  │  │Checkout  │ │Payment   │ │Shipping  │ │Email     │ │Currency    │ │  │
│  │  │Service   │ │Service   │ │Service   │ │Service   │ │Service     │ │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └────────────┘ │  │
│  │                                                                        │  │
│  │                         ┌──────────────┐                               │  │
│  │                         │  Redis Cart  │                               │  │
│  │                         └──────────────┘                               │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────┐     ┌───────────────────────────────────────────┐ │
│  │    Vault Namespace   │     │             Monitoring Namespace          │ │
│  │                      │     │                                           │ │
│  │  Vault 1              │     │ Prometheus     Grafana                   │ │
│  │  Vault 2              │     │ Loki           Promtail                  │ │
│  │  Vault 3              │     │ OpenTelemetry  Tempo                    │ │
│  │  Raft HA              │     │                                           │ │
│  └──────────────────────┘     └───────────────────────────────────────────┘ │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘


                              AWS INFRASTRUCTURE

        ┌───────────────────────────────────────────────────────────┐
        │                         AWS VPC                            │
        │                                                           │
        │   ┌─────────────────────┐     ┌────────────────────────┐ │
        │   │    Public Subnet    │     │    Private Subnets     │ │
        │   │                     │     │                        │ │
        │   │       EC2           │────►│      RDS MySQL         │ │
        │   │                     │     │                        │ │
        │   └─────────────────────┘     └────────────────────────┘ │
        │                                                           │
        │   ┌──────────────┐     ┌──────────────┐                  │
        │   │     ECR      │     │     IAM      │                  │
        │   └──────────────┘     └──────────────┘                  │
        │                                                           │
        └───────────────────────────────────────────────────────────┘

                              ┌─────────────────────┐
                              │     S3 Backend      │
                              │                     │
                              │ Terraform State     │
                              │ Versioning          │
                              │ Locking             │
                              │ Encryption          │
                              └─────────────────────┘
````

---

## GitOps Deployment Flow

```text
┌──────────────┐
│  Developer   │
└──────┬───────┘
       │
       │ Push application code
       ▼
┌──────────────────────┐
│ GitHub                │
│ online-boutique-app   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ GitHub Actions        │
│                      │
│ Build Docker Image   │
│ Run CI checks        │
└──────────┬───────────┘
           │
           │ Push
           ▼
┌──────────────────────┐
│ Amazon ECR            │
│                      │
│ boutique-* images    │
└──────────┬───────────┘
           │
           │ Detect new image
           ▼
┌──────────────────────┐
│ Argo CD Image Updater │
│                      │
│ newest-build         │
└──────────┬───────────┘
           │
           │ Git write-back
           ▼
┌─────────────────────────────┐
│ google-boutique-gitops      │
│                             │
│ image.repository            │
│ image.tag                   │
└─────────────┬───────────────┘
              │
              ▼
┌──────────────────────┐
│ Argo CD              │
│                      │
│ Reconciliation       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Helm                 │
└──────────┬───────────┘
           │
           ▼
┌────────────────────────────┐
│ Kubernetes / Kind          │
│                            │
│ New application version   │
└────────────────────────────┘
```

---

## Infrastructure Architecture

```text
                         ┌──────────────────────┐
                         │      Terraform       │
                         └──────────┬───────────┘
                                    │
                  ┌─────────────────┼──────────────────┐
                  │                 │                  │
                  ▼                 ▼                  ▼
           ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
           │     VPC     │   │     IAM     │   │     ECR     │
           └──────┬──────┘   └─────────────┘   └─────────────┘
                  │
          ┌───────┴────────┐
          │                │
          ▼                ▼
   ┌──────────────┐  ┌──────────────┐
   │ Public Subnet │  │Private Subnet│
   │               │  │              │
   │     EC2       │  │   RDS MySQL  │
   └──────────────┘  └──────────────┘

                         │
                         ▼
              ┌──────────────────────┐
              │    S3 Terraform      │
              │    Remote State      │
              └──────────────────────┘
```

---

## Vault Security Architecture

```text
┌─────────────────────────┐
│    paymentservice Pod   │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ paymentservice          │
│ ServiceAccount          │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Vault Kubernetes Auth   │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Vault Role              │
│ paymentservice          │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ paymentservice-policy   │
│                         │
│ read only               │
└────────────┬────────────┘
             │
             ▼
┌──────────────────────────────┐
│ secret/data/paymentservice/  │
│ config                       │
└────────────┬─────────────────┘
             │
             ▼
┌─────────────────────────┐
│ Vault Agent Injector    │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ /vault/secrets/         │
│ payment-config          │
└─────────────────────────┘
```

---

## Observability Architecture

```text
                         ┌──────────────────────┐
                         │ Kubernetes Workloads │
                         └──────────┬───────────┘
                                    │
                  ┌─────────────────┼─────────────────┐
                  │                 │                 │
                  ▼                 ▼                 ▼
           ┌─────────────┐   ┌─────────────┐   ┌──────────────┐
           │ Prometheus  │   │  Promtail   │   │ OpenTelemetry│
           │             │   │             │   │ Collector    │
           └──────┬──────┘   └──────┬──────┘   └───────┬──────┘
                  │                 │                  │
                  ▼                 ▼                  ▼
           ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
           │   Metrics   │   │    Loki     │   │    Tempo    │
           └──────┬──────┘   └──────┬──────┘   └──────┬──────┘
                  │                 │                 │
                  └─────────────────┼─────────────────┘
                                    ▼
                           ┌─────────────────┐
                           │     Grafana     │
                           └─────────────────┘
```

---

## Project Overview

This project implements a production-style DevOps and GitOps platform for the Google Online Boutique microservices application.

The goal is to demonstrate how application source code can move through an automated software delivery pipeline and reach Kubernetes while maintaining Git as the declarative source of truth.

### Core workflow

```text
Application Code
      ↓
GitHub
      ↓
GitHub Actions
      ↓
Docker
      ↓
Amazon ECR
      ↓
Argo CD Image Updater
      ↓
GitOps Repository
      ↓
Argo CD
      ↓
Helm
      ↓
Kubernetes
```

---

## Technology Stack

| Area                   | Technology             |
| ---------------------- | ---------------------- |
| Application            | Google Online Boutique |
| Source Control         | GitHub                 |
| CI/CD                  | GitHub Actions         |
| Containers             | Docker                 |
| Registry               | Amazon ECR             |
| Orchestration          | Kubernetes             |
| Local Cluster          | Kind                   |
| Packaging              | Helm                   |
| GitOps                 | Argo CD                |
| Image Automation       | Argo CD Image Updater  |
| Infrastructure as Code | Terraform              |
| Cloud                  | AWS                    |
| Database               | Amazon RDS MySQL       |
| Secrets                | HashiCorp Vault        |
| Authentication         | Kubernetes Auth        |
| Metrics                | Prometheus             |
| Dashboards             | Grafana                |
| Logs                   | Loki / Promtail        |
| Tracing                | OpenTelemetry / Tempo  |
| State Backend          | Amazon S3              |

---

## Repositories

### Application Repository

```text
online-boutique-app
```

Contains the application source code, Docker-related configuration, and CI workflow.

### GitOps Repository

```text
google-boutique-gitops
```

Contains:

* Kubernetes configuration
* Helm charts
* Argo CD applications
* ApplicationSets
* Image Updater configuration
* Monitoring configuration
* Terraform infrastructure
* Vault configuration

### Original Application Repository

```text
microservices-demo
```

The original Google Online Boutique source/reference repository used as the application foundation.

---

## Repository Structure

```text
google-boutique-gitops/
│
├── applications/
│   ├── google-boutique-appset.yaml
│   ├── grafana-dashboards.yaml
│   ├── image-updater/
│   │   └── google-boutique-updater.yaml
│   ├── loki.yaml
│   ├── monitoring.yaml
│   ├── otel-collector.yaml
│   ├── prometheus-crds.yaml
│   ├── promtail.yaml
│   └── tempo.yaml
│
├── helm/
│   ├── cartservice/
│   ├── checkoutservice/
│   ├── currencyservice/
│   ├── emailservice/
│   ├── frontend/
│   ├── paymentservice/
│   ├── productcatalogservice/
│   ├── recommendationservice/
│   ├── redis-cart/
│   ├── shippingservice/
│   └── monitoring/
│
├── manifests/
│   └── argocd-repository-secret.yaml
│
├── namespaces/
│   └── ecommerce-prod.yaml
│
├── root/
│   └── app-of-apps.yaml
│
├── terraform/
│   ├── environments/
│   │   └── dev/
│   │       ├── backend.tf
│   │       ├── compute.tf
│   │       ├── ecr.tf
│   │       ├── github-actions-ecr.tf
│   │       ├── github-oidc.tf
│   │       ├── image-updater-iam.tf
│   │       ├── networking.tf
│   │       ├── rds.tf
│   │       ├── security.tf
│   │       ├── vault.tf
│   │       └── ...
│   │
│   └── modules/
│       ├── image-updater-iam/
│       ├── networking/
│       ├── rds/
│       ├── security-group/
│       └── vault/
│
├── image-updater-default-values.yaml
├── .gitignore
└── test.txt
```

---

## GitOps

Argo CD continuously compares the desired state stored in Git with the Kubernetes cluster.

```text
Git Repository
      │
      │ Desired State
      ▼
   Argo CD
      │
      │ Reconcile
      ▼
 Kubernetes
      │
      │ Actual State
      ▼
   Argo CD
```

The GitOps repository is therefore the declarative source of truth for the Kubernetes application configuration.

---

## Argo CD Image Updater

The project uses Argo CD Image Updater to automatically detect new container images in Amazon ECR.

Example configuration:

```yaml
ignoreTags:
  - latest

writeBackConfig:
  method: git
  gitConfig:
    branch: main
    writeBackTarget: helmvalues

applicationRefs:
  - namePattern: "frontend"

    labelSelectors:
      matchLabels:
        image-updater: "true"

    images:
      - alias: frontend
        imageName: 333982363119.dkr.ecr.us-west-2.amazonaws.com/boutique-frontend

        commonUpdateSettings:
          updateStrategy: newest-build
          ignoreTags:
            - latest

        manifestTargets:
          helm:
            name: image.repository
            tag: image.tag
```

The image update process is:

```text
ECR
 ↓
Image Updater
 ↓
Helm Values
 ↓
Git Commit
 ↓
GitOps Repository
 ↓
Argo CD
 ↓
Kubernetes
```

The `latest` tag is ignored and image updates are written back to the GitOps repository.

---

## Terraform

Terraform is used to manage the AWS infrastructure and supporting IAM configuration.

### Terraform modules

```text
terraform/modules/
├── image-updater-iam/
├── networking/
├── rds/
├── security-group/
└── vault/
```

### AWS components

```text
AWS
├── VPC
├── Public Subnet
├── Private Subnets
├── EC2
├── RDS MySQL
├── ECR
├── IAM
├── GitHub OIDC
└── S3 Terraform State
```

---

## Terraform Remote State

Terraform uses an Amazon S3 backend.

```hcl
terraform {
  backend "s3" {
    bucket       = "google-boutique-terraform-state-333982363119"
    key          = "google-boutique/dev/terraform.tfstate"
    region       = "us-west-2"
    profile      = "terraform-user"
    encrypt      = true
    use_lockfile = true
  }
}
```

The state backend provides:

* Remote state storage
* Encryption
* Versioning
* Public access blocking
* State locking

---

## AWS Network Architecture

The AWS design separates public and private resources.

```text
                         AWS VPC
                            │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
       Public Subnet                Private Subnets
              │                           │
              ▼                           ▼
             EC2                       RDS MySQL
```

The RDS database is kept in private subnets rather than deployed as a Kubernetes workload.

---

## GitHub Actions and AWS OIDC

GitHub Actions uses AWS IAM/OIDC integration for AWS access.

```text
GitHub Actions
      │
      │ OIDC
      ▼
AWS IAM
      │
      ▼
Temporary AWS Credentials
      │
      ├── ECR
      └── AWS Resources
```

This avoids relying on long-lived AWS access keys inside the CI workflow.

---

## Vault

HashiCorp Vault is used for application secret management.

The project uses:

* Vault
* Raft storage
* Three Vault nodes
* Kubernetes authentication
* KV v2
* Vault policies
* Vault Agent Injector
* Kubernetes ServiceAccounts

### Payment service authentication

```text
paymentservice
      │
      ▼
ServiceAccount
      │
      ▼
Kubernetes Auth
      │
      ▼
Vault Role
      │
      ▼
paymentservice-policy
      │
      ▼
Vault KV v2
      │
      ▼
Vault Agent
      │
      ▼
/vault/secrets/payment-config
```

### Policy

```hcl
path "secret/data/paymentservice/config" {
  capabilities = ["read"]
}
```

The policy provides read access only to the required secret path.

---

## Observability

The monitoring platform provides metrics, logs, and traces.

```text
                  Kubernetes
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
     Prometheus    Promtail    OpenTelemetry
          │           │           │
          ▼           ▼           ▼
       Metrics       Loki        Tempo
          │           │           │
          └───────────┼───────────┘
                      ▼
                   Grafana
```

### Components

* Prometheus — metrics
* Grafana — visualization
* Loki — logs
* Promtail — log collection
* OpenTelemetry Collector — telemetry collection
* Tempo — distributed tracing

---

## Kubernetes Services

The Online Boutique application consists of multiple microservices, including:

```text
frontend
productcatalogservice
recommendationservice
cartservice
checkoutservice
paymentservice
shippingservice
emailservice
currencyservice
redis-cart
```

The application workloads are deployed through Helm and managed through Argo CD.

---

## Namespaces

The project separates platform components by namespace.

```text
Kubernetes Cluster
│
├── ecommerce-prod
│   └── Online Boutique services
│
├── vault
│   └── HashiCorp Vault
│
└── monitoring
    └── Observability stack
```

---

## Deployment Commands

### Check cluster

```bash
kubectl get nodes
kubectl get pods -A
kubectl get namespaces
```

### Check Argo CD

```bash
argocd app list
argocd app get APP_NAME
argocd app resources APP_NAME
```

### Check Helm

```bash
helm list -A
helm status RELEASE_NAME -n NAMESPACE
```

### Check Terraform

```bash
cd terraform/environments/dev

terraform init
terraform validate
terraform plan
```

### Check Vault

```bash
vault status
vault auth list
vault secrets list
vault policy list
```

---

## Useful Kubernetes Commands

```bash
kubectl get pods -A
kubectl get svc -A
kubectl get deployments -A
kubectl get pvc -A
kubectl describe pod POD_NAME -n NAMESPACE
kubectl logs POD_NAME -n NAMESPACE
kubectl exec -it POD_NAME -n NAMESPACE -- /bin/sh
```

---

## Useful Argo CD Commands

```bash
argocd app list
argocd app get APP_NAME
argocd app sync APP_NAME
argocd app resources APP_NAME
argocd app history APP_NAME
argocd app logs APP_NAME
```

---

## Useful Terraform Commands

```bash
terraform fmt
terraform validate
terraform init
terraform plan
terraform apply
```

Always review the plan before applying infrastructure changes.

---

## Project Goals

The project was built to gain practical experience with:

* Infrastructure as Code
* Cloud infrastructure
* Containerization
* Kubernetes
* Helm
* GitOps
* Continuous Integration
* Continuous Delivery
* Automated image promotion
* Secret management
* IAM and workload authentication
* Observability
* Infrastructure security
* AWS architecture

---

## Production-Oriented Design Decisions

The project intentionally follows production-oriented patterns where practical.

### GitOps

Kubernetes desired state is maintained in Git.

### Immutable image references

Images are promoted using versioned image tags rather than relying on `latest`.

### Automated image updates

Argo CD Image Updater detects new images and writes the updated Helm values back to Git.

### Infrastructure as Code

AWS resources are managed using Terraform.

### Remote Terraform State

Terraform state is stored remotely in Amazon S3 with locking and encryption.

### Secret management

Application secrets are managed through Vault rather than directly embedding sensitive values in application manifests.

### Least privilege

Vault policies grant only the permissions required by the workload.

### Workload authentication

Kubernetes ServiceAccounts are used for Vault authentication.

### Observability

Metrics, logs, and traces are collected through dedicated observability components.

---

## Current Environment

The local development and testing environment uses:

```text
OS             Ubuntu 24.04 LTS
Docker         29.7.2
Docker Compose 5.5.0
kubectl        1.35.8
Kind           0.32.0
Helm           4.2.4
Terraform      1.15.9
AWS CLI        2.36.29
Vault CLI      2.0.4
Argo CD CLI    3.5.1
```

---

## Project Status

### Completed / Implemented

* Docker-based application workflow
* Kubernetes deployment architecture
* Helm-based application packaging
* Argo CD GitOps workflow
* Argo CD ApplicationSet
* Argo CD Image Updater
* Amazon ECR integration
* Terraform infrastructure structure
* AWS networking
* RDS architecture
* IAM / GitHub OIDC configuration
* Terraform S3 remote state
* Vault Kubernetes authentication
* Vault Agent secret injection
* Prometheus monitoring
* Grafana dashboards
* Loki logging
* OpenTelemetry
* Tempo tracing

---

## Future Improvements

Potential future improvements include:

* Production Kubernetes platform such as EKS
* Production-grade Vault TLS
* Dynamic database credentials
* External secrets integration
* Centralized alerting
* Disaster recovery testing
* Multi-environment promotion
* Blue/green or canary deployment strategies
* Additional security scanning
* Policy-as-code
* Automated backup and recovery validation

---

## Learning Outcome

This project provides practical experience across the complete DevOps lifecycle:

```text
Infrastructure
      ↓
Cloud
      ↓
Containers
      ↓
Kubernetes
      ↓
Helm
      ↓
CI
      ↓
Container Registry
      ↓
GitOps
      ↓
Continuous Delivery
      ↓
Secrets
      ↓
Observability
```

The primary focus is not simply deploying an application, but understanding how the individual DevOps components integrate into a complete software delivery platform.

````

## Architecture sketches to keep separately

If you want a simpler visual section for `docs/architecture/README.md`, use this as the **master sketch**:

```text
                              ┌─────────────────┐
                              │    DEVELOPER    │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │     GITHUB      │
                              │ Application Repo│
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ GITHUB ACTIONS  │
                              │                 │
                              │ Build / CI      │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │    AMAZON ECR   │
                              │ Docker Registry │
                              └────────┬────────┘
                                       │
                                       ▼
                         ┌─────────────────────────┐
                         │ ARGO CD IMAGE UPDATER   │
                         └────────────┬────────────┘
                                      │
                                      ▼
                         ┌─────────────────────────┐
                         │     GITOPS REPOSITORY   │
                         │ google-boutique-gitops  │
                         └────────────┬────────────┘
                                      │
                                      ▼
                              ┌─────────────────┐
                              │     ARGO CD     │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │      HELM       │
                              └────────┬────────┘
                                       │
                                       ▼
             ┌──────────────────────────────────────────────┐
             │                KIND CLUSTER                  │
             │                                              │
             │  ┌────────────────────────────────────────┐  │
             │  │           ecommerce-prod               │  │
             │  │                                        │  │
             │  │ frontend                               │  │
             │  │ productcatalogservice                  │  │
             │  │ recommendationservice                  │  │
             │  │ cartservice                            │  │
             │  │ checkoutservice                         │  │
             │  │ paymentservice                          │  │
             │  │ shippingservice                         │  │
             │  │ emailservice                            │  │
             │  │ currencyservice                         │  │
             │  │ redis-cart                              │  │
             │  └────────────────────────────────────────┘  │
             │                                              │
             │  ┌──────────────┐    ┌─────────────────────┐ │
             │  │    VAULT     │    │    MONITORING       │ │
             │  │              │    │                     │ │
             │  │  Vault x3    │    │ Prometheus          │ │
             │  │  Raft        │    │ Grafana             │ │
             │  │  K8s Auth    │    │ Loki                │ │
             │  │  Agent       │    │ Promtail            │ │
             │  │              │    │ OpenTelemetry       │ │
             │  └──────────────┘    │ Tempo               │ │
             │                      └─────────────────────┘ │
             └──────────────────────────────────────────────┘


                    AWS INFRASTRUCTURE

       ┌──────────────────────────────────────────┐
       │                 AWS VPC                  │
       │                                          │
       │   ┌──────────────┐   ┌───────────────┐  │
       │   │ Public       │   │ Private       │  │
       │   │ Subnet       │   │ Subnets      │  │
       │   │              │   │               │  │
       │   │ EC2          │──►│ RDS MySQL     │  │
       │   └──────────────┘   └───────────────┘  │
       │                                          │
       │   ECR       IAM       GitHub OIDC       │
       │                                          │
       └──────────────────────────────────────────┘

                         │
                         ▼

                 ┌──────────────────┐
                 │   S3 BACKEND     │
                 │                  │
                 │ Terraform State  │
                 │ Versioning       │
                 │ Locking          │
                 │ Encryption       │
                 └──────────────────┘
````

