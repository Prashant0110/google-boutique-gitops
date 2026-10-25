# Apex Recovery Runbook

## Scope

Recovery covers the existing Qdrant `knowledge` collection and existing MySQL RDS instance.
It reuses the existing GitOps/Kustomize deployment. It does not create another application
database or monitoring stack.

## Recovery objectives (proposed, not yet proven)

- Qdrant backup cadence: daily at 02:00 UTC.
- Qdrant target RPO: <= 24 hours, assuming the latest scheduled backup succeeded.
- RDS backup retention: 7 days, configured in the existing Terraform module.
- RDS target RPO: use the latest available RDS restorable point; verify it during the incident.
- Initial target RTO: <= 4 hours, measured from incident declaration until validated service restoration.
- Qdrant S3 retention: current backup objects expire after 90 days; noncurrent versions after 30 days.
- Restore exercise: quarterly and after material backup/storage changes.

These are targets. They are not evidence until a timed restore test succeeds.

## Architecture and availability assumptions

- The RDS Multi-AZ option improves database availability; it is not a substitute for point-in-time recovery.
- S3 Standard is regional storage designed for data durability across multiple Availability Zones.
- The recovery bucket has versioning, KMS encryption, public access blocked, a TLS-only bucket policy,
  and lifecycle retention.
- No cross-region replication is enabled. Confirm customer-approved Saudi data residency and target
  region before configuring regional DR.
- The Qdrant persistent volume alone is not a backup.
- KinD does not provide EKS IAM Roles for Service Accounts (IRSA). Local AWS testing needs a temporary,
  least-privilege identity created outside Git. Never commit credentials or Kubernetes Secret values.

## Prerequisites

1. Review `terraform plan` and confirm AWS account, region and data residency before applying.
2. Confirm Terraform backend/state access and the current state of the existing resources.
3. Supply the EKS OIDC provider ARN and issuer URL only when deploying to an approved EKS cluster.
4. Build and push `recovery-tools/` to an approved container registry.
5. Replace all `REPLACE_...` values in `platform/retrieval/recovery/qdrant-backup.yaml`.
6. Ensure the backup workload has the recovery IAM policy and KMS permissions.
7. For KinD, create `recovery-aws-credentials` out of band from a temporary least-privilege AWS identity.
   Do not store the Secret or credentials in the repository.
8. Ensure local `/tmp` capacity is sufficient for a complete Qdrant snapshot; the Job has a 4 GiB
   ephemeral volume limit which must be increased if the snapshot is larger.

## Build and publish the recovery image

From the repository root:

```bash
docker build -t apex-recovery-tools:1.0.0 recovery-tools/
```

For EKS, push it to the approved ECR repository and use the resulting full image URI in the manifest.
For KinD local tests, load the image into the cluster and use the local image tag.

## Enable and test backup

1. Verify ConfigMap region, bucket, KMS key, image and ServiceAccount role.
2. Review the suspended CronJob. Do not enable it with placeholders.
3. For KinD, create the temporary AWS credentials Secret out of band. For EKS, use IRSA instead.
4. Run a one-off test before enabling the schedule:

```bash
kubectl -n retrieval create job --from=cronjob/qdrant-backup qdrant-backup-manual
kubectl -n retrieval get jobs,pods
kubectl -n retrieval logs job/qdrant-backup-manual
```

5. Confirm `BACKUP_OK`, object size and checksum in logs; confirm the object exists in S3 and uses
   the expected KMS key.
6. Confirm the snapshot can be restored in a test collection or isolated recovery environment.
7. Only after successful verification, enable the daily schedule:

```bash
kubectl -n retrieval patch cronjob qdrant-backup \
  --type merge -p '{"spec":{"suspend":false}}'
```

## Qdrant restore

A restore can overwrite collection state. Obtain incident approval and verify the exact snapshot key.

1. Suspend scheduled backups and stop writes to the affected collection.
2. Scale the retrieval API to zero only if required by the incident plan and record its original replica count:

```bash
kubectl -n retrieval scale deployment/retrieval-api --replicas=0
kubectl -n retrieval patch cronjob qdrant-backup \
  --type merge -p '{"spec":{"suspend":true}}'
```

3. Copy `platform/retrieval/recovery/qdrant-restore-job.yaml.example` to a temporary manifest.
4. Replace the image and exact S3 snapshot key. Check region, bucket, collection, identity and KMS permissions.
5. Apply the reviewed restore Job and inspect its logs:

```bash
kubectl apply -f /tmp/qdrant-restore-job.yaml
kubectl -n retrieval get jobs,pods
kubectl -n retrieval logs job/qdrant-restore-manual
```

6. Verify Qdrant readiness, collection status, expected vector count, and a known sanitized search query.
   An HTTP success response alone is not sufficient proof of recovery.
7. Restore the retrieval API's previous replica count, verify `/healthz`, `/readyz`, authenticated search
   and ingestion, then re-enable scheduled backups.
8. Record snapshot key, backup age, restore start/end time, observed RTO, estimated RPO/data-loss window,
   validation results and follow-up actions.

## RDS recovery

The existing RDS module has encrypted storage, seven-day automated backup retention and deletion
protection. Multi-AZ improves availability but does not replace backup recovery.

Restore to a new DB instance identifier; do not delete the source database during recovery.
Use an incident-approved time or the latest restorable time:

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier google-boutique-dev-mysql \
  --target-db-instance-identifier google-boutique-dev-mysql-restore-YYYYMMDDHHMM \
  --use-latest-restorable-time
```

After restoration, wait until the instance is available. Validate schema and application-level records,
configure the approved subnet/security group, coordinate endpoint/secret changes with the application
owner, and retain the source until acceptance and rollback decisions are complete. Never put database
passwords in shell history or documentation.

## Incident checklist

- Declare incident owner/severity and record the start time.
- Identify failure scope: Qdrant, RDS, storage, identity, AZ or regional outage.
- Choose the latest verified backup/recovery point consistent with the data-loss objective.
- Restore into an isolated target where feasible and validate before switching traffic.
- Record actual recovery time, data-loss window, validation evidence and corrective actions.
- Test restore quarterly and after material changes.

## Limitations

- CronJob is intentionally suspended; placeholders must be replaced before use.
- EKS IRSA requires an actual cluster OIDC provider and approved IAM role configuration.
- KinD tests do not prove EKS IRSA or production AWS networking.
- Cross-region replication is not enabled until the customer approves residency and region requirements.
- RTO/RPO remain targets until a timed restore test provides evidence.
