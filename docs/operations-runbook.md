# Apex Retrieval Platform — Operations Runbook

## 1. Overview

This runbook describes the operational procedures for the Apex retrieval
platform, including service health checks, incident investigation, deployment
rollback, data backup and restoration, secret management, monitoring, and
disaster recovery.

The retrieval service provides authenticated document ingestion and semantic
search using a CPU-based embedding model and Qdrant vector storage. The
Kubernetes configuration defines two API replicas and a single Qdrant replica
with persistent storage. Vault is configured to provide the API key to the
retrieval service.

The infrastructure repository also contains Terraform modules for AWS
networking, compute, storage, IAM, container registries, Vault, and monitoring
integrations.

The current Kubernetes environment is KinD. The Terraform configuration
defines an AWS deployment foundation, but the live AWS infrastructure could
not be inspected because AWS credentials were unavailable during this
assessment.

## 2. Current deployment

### Retrieval API

The retrieval API is deployed in the `retrieval` namespace. Its Kubernetes
Deployment defines two replicas and includes startup, readiness, and liveness
probes. The container runs as a non-root user, uses a read-only root
filesystem, drops Linux capabilities, and has CPU and memory requests and
limits configured.

The service exposes the following endpoints:

- `GET /healthz` — checks application health.
- `GET /readyz` — checks whether the application is ready to serve requests.
- `POST /v1/documents` — accepts authenticated document ingestion requests.
- `POST /v1/search` — performs authenticated semantic searches.

Local tests previously passed for health checks, readiness, API-key
authentication, document ingestion, and semantic search.

### Qdrant

Qdrant is deployed as a single-replica StatefulSet with a 10 GiB persistent
volume claim. It stores the vectors used by the retrieval API.

The persistent volume protects data against some container and pod failures,
but it does not provide independent backup or high availability. A node or
storage failure may require recovery from a separate backup.

### Vault

Vault is configured with Kubernetes authentication for the retrieval service.
The `retrieval` role is associated with the `retrieval-api` service account
and has a policy granting read access to the retrieval configuration secret.

During the previous deployment checks, the retrieval API pods did not contain
the expected Vault Agent container or injected API-key file. Secret injection
therefore remains unresolved and must be corrected before relying on Vault
in production.

### AWS infrastructure

The Terraform configuration defines an application S3 bucket with public
access blocking, versioning, and KMS encryption with key rotation. A separate
CloudTrail module defines audit-log storage.

The AWS account and resources could not be inspected during the assessment
because the AWS CLI had no configured credentials. The existence and current
configuration of these resources must be confirmed when authorized AWS access
is available.

## 3. Health checks and incident investigation

Start an investigation by checking the Kubernetes context, workload status,
recent events, and application logs.

```bash
kubectl config current-context
kubectl -n retrieval get deployments,pods,services,pvc
kubectl -n retrieval get events --sort-by=.lastTimestamp
kubectl -n retrieval rollout status deployment/retrieval-api
kubectl -n retrieval logs deployment/retrieval-api \
  --all-containers=true --tail=100
kubectl -n vault get pods
```

Check Qdrant separately:

```bash
kubectl -n retrieval logs qdrant-0 --tail=100
kubectl -n retrieval describe pod qdrant-0
kubectl -n retrieval get pvc
```

If a command targets an unexpected cluster or namespace, verify the context
before proceeding.

### API unavailable or returning errors

Investigate the following in order:

1. Check pod readiness, restart counts, recent events, and application logs.
2. Confirm that Qdrant is running and its persistent volume is bound.
3. Check whether the API can access the required secret.
4. Review CPU and memory pressure and recent deployment changes.
5. Check monitoring data for changes in request volume, latency, or errors.
6. Apply the appropriate corrective change through the deployment workflow.
7. Verify health, readiness, authenticated ingestion, and semantic search.

Initial troubleshooting should focus on logs, workload status, dependencies,
and recent changes before considering actions that could affect persistent
data.

## 4. Deployment rollback

Git is the source of truth for GitOps-managed workloads. A rollback should
restore the last known-good application or configuration revision through
the approved GitOps workflow.

1. Identify the change associated with the incident.
2. Review the previous known-good revision.
3. Revert the faulty change in a dedicated Git commit.
4. Follow the approved Argo CD synchronization process.
5. Confirm that the rollout completes successfully.
6. Test health, readiness, authenticated search, and application logs.
7. Record the cause of the incident and the corrective action.

Useful inspection commands:

```bash
kubectl -n retrieval rollout history deployment/retrieval-api
kubectl -n retrieval rollout status deployment/retrieval-api
```

A direct `kubectl rollout undo` is not the normal rollback mechanism for a
GitOps-managed deployment because Argo CD may reconcile the workload back to
the state declared in Git. Use a direct rollback only as an approved emergency
measure, followed by reconciliation of the Git repository.

Rolling back an application deployment does not restore Qdrant data or reverse
changes already made to stored documents.

## 5. Qdrant backup strategy

Production backups must be independent of the Qdrant persistent volume and
stored outside the cluster.

The planned backup process is:

1. Create a snapshot using a Qdrant-supported snapshot mechanism.
2. Transfer the snapshot to private S3 storage.
3. Use server-side encryption, restricted access, versioning, and an approved
   retention policy.
4. Record the backup timestamp and the Qdrant version.
5. Monitor backup execution and report failures.
6. Periodically restore a snapshot into an isolated environment and validate
   the recovered collection.

The existing Terraform S3 module provides a starting point for encrypted,
versioned storage. A dedicated backup prefix or a separate bucket should be
selected according to the required access and retention policies.

Production workloads should access S3 through an appropriate IAM workload
identity, such as EKS Pod Identity or IAM Roles for Service Accounts (IRSA)
when using EKS. Long-lived AWS credentials should not be embedded in Kubernetes
manifests, container images, or source control.

The backup schedule, S3 upload mechanism, IAM permissions, and retention
configuration have not yet been implemented and tested end to end. AWS access
was unavailable during the assessment, so a successful S3 upload has not been
demonstrated.

A persistent volume alone is not a backup.

## 6. Qdrant restoration

Restoration should first be tested in an isolated environment rather than
against production data.

1. Identify the snapshot and confirm its timestamp, collection, and Qdrant
   version.
2. Verify that the backup object is accessible and intact.
3. Follow the supported restoration procedure for the deployed Qdrant version.
4. Check the restored collection configuration and vector count.
5. Run representative semantic searches through the retrieval API.
6. Confirm API readiness and inspect application and Qdrant logs.
7. Record the restoration duration and any data loss.

Before production restoration, confirm the target environment and obtain the
necessary approval. Do not overwrite production data as part of an untested
recovery procedure.

A restoration drill has not yet been completed, so recovery time and data
recovery guarantees have not been established.

## 7. Vault troubleshooting

Vault Agent injection did not work as expected during the previous Kubernetes
checks. The retrieval API pods lacked the expected injected secret file and
Vault Agent container.

The investigation should cover:

- Vault injector pod health and logs.
- Admission webhook configuration and TLS certificate validity.
- Retrieval pod annotations and service account configuration.
- Vault Kubernetes authentication role bindings.
- Vault policy permissions and the secret path.
- Vault Agent authentication and template-rendering errors.

Verify the existence and permissions of secret files without printing their
contents. TLS verification should remain enabled while diagnosing certificate
problems.

A Vault root token was exposed during earlier troubleshooting and must be
treated as compromised. It should be revoked or rotated through an authorized
secure administrative session. Tokens, unseal shares, API keys, and rendered
secret files must not be included in the repository or submission archive.

Vault injection must be corrected and tested before the service relies on it
for production secret delivery.

## 8. Monitoring and alerting

The repository contains an existing monitoring stack that should be reused
where practical.

The retrieval platform should be monitored for:

- API availability and readiness failures.
- Request latency and HTTP error rates.
- Pod restarts and CPU or memory pressure.
- Qdrant availability and persistent-volume capacity.
- Vault authentication and secret-injection failures.
- Backup job failures and the age of the latest successful backup.
- Storage growth, infrastructure usage, and AWS costs.

Alert thresholds and notification routing should be agreed with the service
owner. The Kubernetes Metrics API was unavailable during previous checks, so
metrics collection must be verified before relying on CPU and memory metrics
for autoscaling or alerting.

Dashboards and alerts should be tested with representative failure conditions
before production handover.

## 9. Disaster recovery and availability

The current Qdrant deployment has one replica. It is therefore a single point
of failure, and its persistent volume does not provide high availability or
protection against all node and storage failures.

The production design should address:

- Independent backup storage outside the cluster.
- Recovery from node and availability-zone failures.
- Restoration of Qdrant data and validation of the retrieval API.
- Appropriate workload redundancy and scheduling.
- Recovery of secrets and access permissions.
- Documented escalation and ownership during an incident.

The Recovery Time Objective (RTO), Recovery Point Objective (RPO), backup
frequency, and retention period must be agreed with the service owner. These
targets have not yet been established through a tested recovery process.

Production disaster recovery remains unverified until backup restoration and
the required infrastructure recovery procedures have been exercised.

## 10. Security controls

The retrieval API manifest includes non-root execution, a read-only root
filesystem, dropped Linux capabilities, and resource requests and limits.

The wider production configuration should also ensure that:

- Service accounts and IAM permissions follow least-privilege principles.
- Production workloads use an appropriate identity mechanism.
- Traffic between the API, Qdrant, Vault, and other services is restricted.
- Data is encrypted in transit and at rest.
- Qdrant access controls are configured and tested.
- Container images are scanned and referenced by immutable digests.
- Secrets are excluded from source control, logs, and release artifacts.
- Privileged access and secret rotation are auditable.

Network policies, Qdrant authentication, production IAM permissions, and
workload identity require further verification before production deployment.

## 11. Cost management

The production environment should be reviewed for compute, storage, database,
load balancer, logging, and encryption costs.

Resource requests and limits should reflect measured usage. Backup retention,
S3 object versions, log retention, data transfer, and autoscaling limits should
be configured to balance availability, recovery requirements, and cost.

Changes that create billable AWS resources should be reviewed before they are
applied. The current lack of AWS credentials prevented live resource and cost
verification.

## 12. Operational handover

The handover documentation should describe the architecture, deployment
process, required configuration, monitoring, incident procedures, rollback,
backup and restoration, security controls, and known limitations.

Before production operation, the team needs to complete and validate the
outstanding work described in this runbook, particularly Vault secret
injection, AWS identity and permissions, automated off-cluster backups,
restoration, and disaster recovery.

The current implementation provides a foundation for the retrieval service,
but live AWS deployment and end-to-end production recovery have not yet been
demonstrated.
