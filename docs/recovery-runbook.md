# Apex Recovery Runbook

## Scope

Recovery covers the Qdrant `knowledge` collection and the MySQL RDS instance. It reuses the existing GitOps/Kustomize deployment. It does not create another application database or monitoring stack.

## Recovery objectives (design targets)

- Qdrant backup cadence: daily at 02:00 UTC.
- Qdrant target RPO: 24 hours or less, assuming the latest scheduled backup succeeded.
- RDS backup retention: 7 days, configured in the Terraform module.
- RDS target RPO: use the latest available restorable point and verify it during the incident.
- Initial target RTO: 4 hours or less, measured from incident declaration until validated service restoration.
- Qdrant S3 retention: current backup objects expire after 90 days, non-current versions after 30 days.
- Restore exercise: quarterly and after material backup or storage changes.

These targets are confirmed by a timed restore at realistic data volume.

## Local restore drill (completed)

A snapshot, delete and restore drill ran on the pilot using a dedicated `restore-drill` collection (4 dimensions, Cosine, two synthetic points). The `knowledge` collection was not touched.

| Step | Result |
|---|---|
| Create collection and insert 2 points | Count = 2 |
| Create snapshot | `restore-drill-5701453574908689-2026-10-26-06-27-38.snapshot`, 164352 bytes, SHA-256 `e82a6b8523cadf932a783b3a523e368ded2cd97bf1d35ea7d3d715d574950413` |
| Snapshot API time | about 0.093 s |
| Delete test collection | Done |
| Recover from snapshot | API returned `ok`, about 0.203 s |
| Verify | Point count = 2 |

The times are for a tiny dataset and demonstrate the procedure. They are not an RTO. Screenshots are in `evidence/02` to `evidence/06`.

## Architecture and availability assumptions

- RDS Multi-AZ improves database availability. It does not replace point-in-time recovery.
- S3 Standard is regional storage designed for durability across multiple Availability Zones.
- The recovery bucket has versioning, KMS encryption, public access blocked, a TLS-only bucket policy and lifecycle retention.
- No cross-region replication is enabled. Confirm customer-approved Saudi data residency and the target region before configuring regional DR.
- The Qdrant persistent volume alone is not a backup.
- KinD does not provide EKS IAM Roles for Service Accounts (IRSA). Local AWS testing uses a temporary, least-privilege identity created outside Git. Credentials and Kubernetes Secret values are never committed.

## Build and publish the recovery image

From the repository root:

```bash
docker build -t apex-recovery-tools:1.0.0 recovery-tools/
```

For EKS, push it to the approved ECR repository and use the full image URI in the manifest. For KinD, load the image into the cluster and use the local tag.

## Enable and test backup

1. Verify the ConfigMap region, bucket, KMS key, image and ServiceAccount role.
2. Review the suspended CronJob. The CronJob ships suspended and is enabled only after the placeholders are replaced.
3. For KinD, create the temporary AWS credentials Secret out of band. For EKS, use IRSA.
4. Run a one-off test before enabling the schedule:

```bash
kubectl -n retrieval create job --from=cronjob/qdrant-backup qdrant-backup-manual
kubectl -n retrieval get jobs,pods
kubectl -n retrieval logs job/qdrant-backup-manual
```

5. Confirm `BACKUP_OK`, object size and checksum in the logs, and confirm the object exists in S3 with the expected KMS key.
6. Confirm the snapshot restores into a test collection or an isolated recovery environment.
7. Enable the daily schedule:

```bash
kubectl -n retrieval patch cronjob qdrant-backup \
  --type merge -p '{"spec":{"suspend":false}}'
```

## Qdrant restore

A restore can overwrite collection state. Obtain incident approval and verify the exact snapshot key.

1. Suspend scheduled backups and stop writes to the affected collection.
2. Scale the retrieval API to zero only if the incident plan requires it, and record the original replica count:

```bash
kubectl -n retrieval scale deployment/retrieval-api --replicas=0
kubectl -n retrieval patch cronjob qdrant-backup \
  --type merge -p '{"spec":{"suspend":true}}'
```

   Argo CD self-heal restores declared replica counts, so pause Argo CD sync for the application before scaling.

3. Copy `platform/retrieval/recovery/qdrant-restore-job.yaml.example` to a temporary manifest.
4. Replace the image and the exact S3 snapshot key. Check region, bucket, collection, identity and KMS permissions.
5. Apply the reviewed restore Job and inspect its logs:

```bash
kubectl apply -f /tmp/qdrant-restore-job.yaml
kubectl -n retrieval get jobs,pods
kubectl -n retrieval logs job/qdrant-restore-manual
```

6. Verify Qdrant readiness, collection status, the expected vector count, and a known sanitized search query. An HTTP success response alone is not proof of recovery.
7. Restore the retrieval API's replica count, verify `/healthz`, `/readyz`, authenticated search and ingestion, then re-enable scheduled backups and Argo CD sync.
8. Record the snapshot key, backup age, restore start and end time, observed RTO, estimated RPO and data-loss window, validation results and follow-up actions.

## RDS recovery

The RDS module has encrypted storage, seven-day automated backup retention and deletion protection. Multi-AZ improves availability but does not replace backup recovery.

Restore to a new DB instance identifier and keep the source database during recovery. Use an incident-approved time or the latest restorable time:

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier google-boutique-dev-mysql \
  --target-db-instance-identifier google-boutique-dev-mysql-restore-YYYYMMDDHHMM \
  --use-latest-restorable-time
```

After restoration, wait until the instance is available. Validate schema and application-level records, configure the approved subnet and security group, coordinate endpoint and secret changes with the application owner, and keep the source until acceptance and rollback decisions are complete. Keep database passwords out of shell history and documentation.

## Incident checklist

- Declare the incident owner and severity and record the start time.
- Identify the failure scope: Qdrant, RDS, storage, identity, AZ or regional outage.
- Choose the latest verified backup or recovery point consistent with the data-loss objective.
- Restore into an isolated target where feasible and validate before switching traffic.
- Record actual recovery time, data-loss window, validation evidence and corrective actions.
- Test restore quarterly and after material changes.

## Scope notes

- The CronJob ships suspended, and its placeholders are replaced when the recovery image is published and the AWS account is attached.
- EKS IRSA needs the cluster's OIDC provider and the approved IAM role configuration.
- KinD tests cover the Qdrant snapshot and restore procedure. EKS IRSA and production AWS networking are validated after `terraform apply`.
- Cross-region replication is enabled only after the customer approves residency and region requirements.
- RTO and RPO remain targets until a timed restore at realistic data volume provides measured values.