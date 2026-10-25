#!/usr/bin/env python3
"""Qdrant collection snapshot backup/restore for the Apex recovery pattern."""
import argparse
import hashlib
import os
import pathlib
import tempfile
from datetime import datetime, timezone

import boto3
import requests


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Required environment variable is missing: {name}")
    return value


def qdrant_url() -> str:
    return required_env("QDRANT_URL").rstrip("/")


def collection() -> str:
    return required_env("QDRANT_COLLECTION")


def s3_client():
    region = os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION")
    if not region:
        raise RuntimeError("Set AWS_REGION or AWS_DEFAULT_REGION")
    return boto3.client("s3", region_name=region)


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def backup() -> None:
    bucket = required_env("S3_BUCKET")
    prefix = os.environ.get("S3_PREFIX", "qdrant").strip("/")
    base = f"{qdrant_url()}/collections/{collection()}/snapshots"

    response = requests.post(base, timeout=(10, 300))
    response.raise_for_status()
    snapshot_name = response.json()["result"]["name"]

    with tempfile.TemporaryDirectory(prefix="qdrant-backup-") as tmp:
        snapshot_path = pathlib.Path(tmp) / snapshot_name
        with requests.get(
            f"{base}/{snapshot_name}", stream=True, timeout=(10, 1800)
        ) as download:
            download.raise_for_status()
            with snapshot_path.open("wb") as output:
                for chunk in download.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        output.write(chunk)

        if not snapshot_path.is_file() or snapshot_path.stat().st_size == 0:
            raise RuntimeError("Qdrant snapshot is empty; refusing upload")

        digest = sha256_file(snapshot_path)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        key = f"{prefix}/{collection()}/{stamp}/{snapshot_name}"
        kms_key = required_env("S3_KMS_KEY_ARN")

        s3_client().upload_file(
            str(snapshot_path),
            bucket,
            key,
            ExtraArgs={
                "StorageClass": "STANDARD",
                "ServerSideEncryption": "aws:kms",
                "SSEKMSKeyId": kms_key,
                "Metadata": {
                    "sha256": digest,
                    "collection": collection(),
                    "snapshot-name": snapshot_name,
                },
            },
        )

        head = s3_client().head_object(Bucket=bucket, Key=key)
        if head.get("ContentLength") != snapshot_path.stat().st_size:
            raise RuntimeError("Uploaded object size does not match local snapshot")
        if head.get("Metadata", {}).get("sha256") != digest:
            raise RuntimeError("Uploaded object's checksum metadata does not match")

        print(
            f"BACKUP_OK s3://{bucket}/{key} "
            f"bytes={head['ContentLength']} sha256={digest}"
        )

        # Keep the local Qdrant snapshot store from growing indefinitely.
        # If cleanup fails, the S3 backup remains valid and the Job reports it.
        try:
            deleted = requests.delete(f"{base}/{snapshot_name}", timeout=(10, 60))
            deleted.raise_for_status()
        except requests.RequestException as exc:
            print(f"WARNING: uploaded backup is valid, but Qdrant snapshot cleanup failed: {exc}")


def restore(s3_key: str) -> None:
    bucket = required_env("S3_BUCKET")
    if (
        not s3_key
        or s3_key.startswith("REPLACE_")
        or s3_key.startswith("/")
        or ".." in pathlib.PurePosixPath(s3_key).parts
    ):
        raise RuntimeError("Supply an exact, valid S3 snapshot key; placeholders are refused")

    client = s3_client()
    head = client.head_object(Bucket=bucket, Key=s3_key)
    expected_sha = head.get("Metadata", {}).get("sha256")

    with tempfile.TemporaryDirectory(prefix="qdrant-restore-") as tmp:
        snapshot_path = pathlib.Path(tmp) / pathlib.PurePosixPath(s3_key).name
        client.download_file(bucket, s3_key, str(snapshot_path))

        if not snapshot_path.is_file() or snapshot_path.stat().st_size == 0:
            raise RuntimeError("Downloaded snapshot is empty; refusing restore")

        actual_sha = sha256_file(snapshot_path)
        if expected_sha and actual_sha != expected_sha:
            raise RuntimeError("Snapshot SHA-256 mismatch; refusing restore")

        endpoint = (
            f"{qdrant_url()}/collections/{collection()}/snapshots/upload"
        )
        with snapshot_path.open("rb") as snapshot_file:
            response = requests.post(
                endpoint,
                params={
                    "priority": "snapshot",
                    "wait": "true",
                    "checksum": actual_sha,
                },
                files={
                    "snapshot": (
                        snapshot_path.name,
                        snapshot_file,
                        "application/octet-stream",
                    )
                },
                timeout=(10, 1800),
            )
            response.raise_for_status()

            result = response.json()
            if result.get("status") != "ok" or result.get("result") is not True:
                raise RuntimeError(
                    f"Qdrant did not confirm snapshot recovery: {result}"
                )

            print(
                f"RESTORE_OK collection={collection()} "
                f"s3://{bucket}/{s3_key} sha256={actual_sha}"
            )
            print(
                "Recovery was accepted by Qdrant. Verify collection status, "
                "point count and a known test query before restoring traffic."
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("backup", "restore"))
    parser.add_argument("--s3-key", default="")
    args = parser.parse_args()
    if args.mode == "backup":
        backup()
    else:
        restore(args.s3_key)


if __name__ == "__main__":
    main()
