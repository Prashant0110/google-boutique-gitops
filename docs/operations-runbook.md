# Apex Retrieval Platform: Operations Runbook

**Owner:** Prashant Raj Sapkota (pilot). In a customer deployment the platform owner, on-call owner and security reviewer are named in the customer RACI at kickoff.

## 1. Overview

This runbook describes how to operate the Apex platform: service health checks, incident investigation, deployment rollback, backup and restoration, secrets, monitoring, disaster recovery, cost controls and handover.

The platform has two parts:

- **Kubernetes pilot (KinD cluster `apex-kind`, three nodes).** Argo CD, Helm applications (`frontend`, `paymentservice`), the retrieval service with Qdrant, Vault (3-node Raft with TLS), Prometheus, Alertmanager, Grafana, Loki, Promtail, the OpenTelemetry Collector and Tempo. This part was run and tested with synthetic data.
- **AWS reference design (Terraform).** VPC, ALB, Auto Scaling, RDS, S3, ECR, CloudTrail, IAM and OIDC, Vault and recovery modules. `terraform fmt` and `terraform validate` pass. `terraform apply` is the activation step, performed when the target AWS account is attached.

Architecture diagrams are in `diagrams/` (start with `00-full-architecture`).

## 2. Current deployment

### Retrieval API

Deployed in namespace `retrieval` with two replicas, startup, readiness and liveness probes, a non-root user, a read-only root filesystem, dropped Linux capabilities, and CPU and memory requests and limits.

Endpoints:

- `GET /healthz`: application health.
- `GET /readyz`: readiness to serve requests.
- `POST /v1/documents`: authenticated document ingestion.
- `POST /v1/search`: authenticated semantic search.

Local tests passed for health, readiness, API-key authentication, ingestion and semantic search.

### Qdrant

Qdrant 1.13.3 runs as a single-replica StatefulSet with a 10 GiB persistent volume. The `knowledge` collection (384 dimensions, Cosine) holds the retrieval vectors. The volume protects against some pod failures but is not a backup, so a node or storage failure is recovered from a snapshot (section 5).

### Vault

Vault runs as three nodes with integrated Raft storage and TLS. Kubernetes authentication binds a Vault role to each service's ServiceAccount, with a per-service policy on `secret/data/SERVICE/config`. A sample-password write, update and read lifecycle was tested on the pilot. Injection of the API key into the retrieval pods is the next item to verify end to end (section 7).

### Frontend and payment service

`frontend` and `paymentservice` are delivered through the GitHub Actions workflow, a promotion pull request in the GitOps repository, and an Argo CD ApplicationSet with automated sync (`prune` and `selfHeal`) into namespace `ecommerce-prod`.

## 3. Health checks and incident investigation

![Incident triage](../diagrams/png/09-incident-triage.png)

Start by checking the Kubernetes context, workload status, events and logs.

```bash
kubectl config current-context
kubectl -n argocd get applications
kubectl -n ecommerce-prod get deploy,pods,svc
kubectl -n retrieval get deployments,pods,services,pvc
kubectl -n retrieval get events --sort-by=.lastTimestamp
kubectl -n retrieval logs deployment/retrieval-api --all-containers=true --tail=100
kubectl -n retrieval logs qdrant-0 --tail=100
kubectl -n monitoring get pods
kubectl -n vault get pods
```

If a command targets an unexpected cluster or namespace, verify the context before proceeding.

### Service unavailable or returning errors

1. Check Argo CD sync state and pod readiness, restarts and events.
2. Check Prometheus and Grafana: error rate, latency, traffic, `up` for the target.
3. Check Loki logs and Tempo traces for the affected time window.
4. Confirm Qdrant is running and its volume is bound.
5. Check whether the workload can read its secret from Vault.
6. Review recent changes in the GitOps repository.
7. Apply the corrective change through the GitOps workflow.
8. Verify health, readiness, authenticated ingestion and search.

Investigate logs, workload status, dependencies and recent changes before any action that could affect persistent data.

## 4. Deployment rollback

Git is the source of truth. A rollback restores the last known-good image tag through a reviewed pull request.

1. Identify the change associated with the incident and the last known-good commit SHA.
2. Run the **Manual GitOps Rollback** workflow (`rollback.yml`) with inputs `service` and `previous_image_tag`. The workflow validates the tag format, checks the image exists in ECR, and opens a rollback pull request in the GitOps repository.
3. Review and merge the pull request. Argo CD reconciles the cluster to the merged state.
4. Confirm the rollout completes and test health, readiness, and logs.
5. Record the cause and the corrective action.

```bash
kubectl -n ecommerce-prod rollout status deployment/frontend
kubectl -n argocd get applications
```

A direct `kubectl rollout undo` is not the normal path for a GitOps-managed workload, because Argo CD (self-heal enabled) restores the state declared in Git. Use it only as an approved emergency measure, followed by reconciling Git. Likewise, to scale a deployment down for testing, pause Argo CD sync first.

Rolling back an application does not restore Qdrant data or reverse changes already made to stored documents.

## 5. Qdrant backup strategy

Backups are independent of the Qdrant volume and stored outside the cluster.

1. A CronJob (`platform/retrieval/recovery/qdrant-backup.yaml`) runs daily at `02:00` and uses `recovery-tools/` to create a Qdrant snapshot and upload it to S3.
2. The S3 bucket (Terraform `recovery` module) uses KMS encryption, versioning, public access blocking, a TLS-only policy, 90-day expiry for current objects and 30-day expiry for non-current versions.
3. Production access to S3 uses IAM workload identity (IRSA or EKS Pod Identity). Long-lived AWS credentials are never placed in manifests, images or source control.
4. The CronJob ships suspended until its image, bucket, KMS key and role values are filled in. Run a one-off job first (see `recovery-runbook.md`), then enable the schedule.
5. Record the backup timestamp and the Qdrant version, and alert on a failed backup or a stale latest backup (target: no older than 26 hours).

A persistent volume alone is not a backup.

## 6. Qdrant restoration

Restore into an isolated target first. See `recovery-runbook.md` for the full procedure.

A restore drill was completed locally on a dedicated `restore-drill` collection: snapshot created (164352 bytes, SHA-256 recorded), collection deleted, snapshot recovered, and both points verified. The API times were about 0.093 s for the snapshot and 0.203 s for the recovery. Those numbers come from a two-point collection and show the procedure works. They are not an RTO. A timed restore at realistic data volume sets the production RTO.

Before any production restore, confirm the target environment and obtain approval.

## 7. Vault troubleshooting

If Vault Agent injection does not produce the expected sidecar or secret file in a pod, investigate:

- Vault injector pod health and logs.
- Admission webhook configuration and TLS certificate validity.
- Pod annotations and ServiceAccount configuration.
- Vault Kubernetes auth role bindings.
- Vault policy permissions and the secret path (`secret/data/SERVICE/config`).
- Vault Agent authentication and template-rendering errors.

Check that secret files exist and have the right permissions without printing their contents. Keep TLS verification enabled while diagnosing certificate problems.

**Token hygiene.** A root token used during local troubleshooting is treated as compromised and revoked after use (`vault token revoke`). Production access uses Kubernetes auth and short-lived tokens. Tokens, unseal shares, API keys and rendered secret files are never committed to the repository or the submission archive. `scripts/vault-unseal.sh` reads unseal keys interactively and stores nothing.

## 8. Monitoring and alerting

![Observability](../diagrams/png/06-observability-and-alerting.png)

### Alerts in place (Prometheus rule group `boutique.rules`)

| Alert | Severity | For | Signal |
|---|---|---|---|
| `FrontendScrapeTargetDown` | critical | 2m | `up{job="frontend"} == 0 or absent(up{job="frontend"})` |
| `FrontendHighErrorRate` | critical | 1m | Elevated 5xx ratio |
| `FrontendNoTraffic` | warning | 2m | No request activity |
| `FrontendHighRequestRate` | info | 1m | Unusual load |
| `FrontendHighP95Latency` | warning | 1m | Degraded latency |
| `FrontendHighP99Latency` | critical | 1m | Severe tail latency |
| `FrontendHighConcurrentRequests` | warning | 30s | Saturation risk |

Loki log alerts: `ErrorLogSpike` (more than 10 `ERROR` lines in 2 minutes in `ecommerce-prod`) and `CriticalLogException` (any panic, exception or gRPC unavailable line). Alertmanager routes alerts to Slack.

### Service level objectives (initial targets)

| SLI | Target |
|---|---|
| Availability (non-5xx responses) | 99.5% over 30 days |
| Latency (p95) | Under 500 ms, tuned after a measured baseline |
| Backup freshness | Latest Qdrant snapshot no older than 26 hours |

### Also monitor

Pod restarts, CPU and memory pressure, Qdrant availability and volume capacity, Vault authentication and injection failures, backup job failures, storage growth and cloud cost.

### Pilot notes

KinD does not expose some control-plane metrics, so `etcd*`, `KubeControllerManager*` and `kube-proxy` alerts fire on the pilot. These are environment artefacts and are not expected on managed Kubernetes. Alert drills (scale the frontend down with Argo CD sync paused, then confirm FIRING and RESOLVED messages in Slack) are repeated after material monitoring changes.

## 9. Disaster recovery and availability

- Multi-AZ RDS covers an Availability Zone failure. Automated backups (7 days) cover logical deletion or corruption.
- Qdrant is a single replica with daily snapshots, so it is a single point of failure between backups. Recovery means restoring the latest snapshot, with a loss window up to the backup interval.
- A full regional failure requires a second region. This is a roadmap item and depends on customer-approved residency (see the README).

| Item | Target |
|---|---|
| Qdrant RPO | 24 hours or less, assuming the latest scheduled backup succeeded |
| RDS RPO | Latest restorable point, verified during the incident |
| Initial RTO | 4 hours or less, from incident declaration to validated service |

These are design targets, confirmed by a timed restore at realistic data volume.

## 10. Security controls

- Retrieval API: non-root, read-only root filesystem, dropped capabilities, resource limits.
- NetworkPolicies on `frontend` and `paymentservice`. Default-deny policies for every application namespace are on the roadmap.
- Vault with TLS, Kubernetes auth and per-service policy.
- CI authenticates to AWS with GitHub OIDC, with trust limited to one repository and branch.
- Images are scanned (Trivy, `govulncheck`, `npm audit`), tagged with the commit SHA and immutable in ECR.
- KMS encryption with rotation for S3 and CloudTrail, encrypted RDS and EBS, IMDSv2 required.
- Secrets are excluded from source control, logs and release artifacts.
- Production hardening list: HTTPS certificate on the ALB, restricted security group egress, GuardDuty, AWS Config and Security Hub, Actions pinned by commit SHA, Qdrant authentication.

## 11. Cost management

Review compute, storage, database, load balancer, logging and encryption costs before provisioning. Resource requests and limits follow measured usage. Backup retention, S3 object versions, log retention, data transfer and autoscaling limits balance availability, recovery needs and cost. The dev design uses one NAT Gateway and small instance classes. Production weighs one NAT per Availability Zone. Anything that creates billable AWS resources is reviewed before `terraform apply`.

## 12. Operational handover

Handover covers the architecture, deployment process, required configuration, monitoring, incident procedures, rollback, backup and restoration, security controls and the roadmap.

First-day checklist for a new customer: choose the region and confirm residency, create the state bucket, set variables, review and apply Terraform, install Argo CD, apply `root/app-of-apps.yaml`, initialise and unseal Vault, supply the certificate ARN, confirm alerts reach the customer channel, and run a timed restore.

Outstanding items before production operation: verify Vault secret injection into the retrieval service, apply Terraform in the target account, run the automated off-cluster backup end to end, perform a timed restore at realistic volume, and add staging and production environments.