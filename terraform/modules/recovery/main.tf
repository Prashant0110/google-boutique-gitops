data "aws_caller_identity" "current" {}

locals {
  oidc_issuer = trimsuffix(
    trimprefix(var.eks_oidc_provider_url, "https://"),
    "/"
  )

  create_irsa = (
    var.eks_oidc_provider_arn != "" &&
    var.eks_oidc_provider_url != ""
  )

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "backup-and-recovery"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "recovery" {
  bucket        = "${var.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-recovery"
  })
}

resource "aws_s3_bucket_public_access_block" "recovery" {
  bucket                  = aws_s3_bucket.recovery.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "recovery" {
  bucket = aws_s3_bucket.recovery.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "recovery" {
  bucket = aws_s3_bucket.recovery.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "recovery" {
  description             = "${var.project}-${var.environment} recovery backup encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = local.common_tags
}

resource "aws_kms_alias" "recovery" {
  name          = "alias/${var.project}-${var.environment}-recovery"
  target_key_id = aws_kms_key.recovery.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "recovery" {
  bucket = aws_s3_bucket.recovery.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.recovery.arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "recovery" {
  bucket = aws_s3_bucket.recovery.id

  rule {
    id     = "qdrant-backup-retention"
    status = "Enabled"

    filter {
      prefix = "qdrant/"
    }

    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "recovery_tls_only" {
  bucket = aws_s3_bucket.recovery.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"

      Resource = [
        aws_s3_bucket.recovery.arn,
        "${aws_s3_bucket.recovery.arn}/*"
      ]

      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.recovery]
}

resource "aws_iam_policy" "backup" {
  name        = "${var.project}-${var.environment}-recovery-backup"
  description = "Least-privilege Qdrant snapshot backup and restore access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListRecoveryPrefix"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = [aws_s3_bucket.recovery.arn]

        Condition = {
          StringLike = {
            "s3:prefix" = ["qdrant", "qdrant/*"]
          }
        }
      },
      {
        Sid    = "ReadWriteRecoveryObjects"
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:AbortMultipartUpload"
        ]

        Resource = ["${aws_s3_bucket.recovery.arn}/qdrant/*"]
      },
      {
        Sid    = "UseRecoveryKmsKey"
        Effect = "Allow"

        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]

        Resource = [aws_kms_key.recovery.arn]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role" "backup" {
  count = local.create_irsa ? 1 : 0
  name  = "${var.project}-${var.environment}-qdrant-recovery"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        Federated = var.eks_oidc_provider_arn
      }

      Action = "sts:AssumeRoleWithWebIdentity"

      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer}:sub" = "system:serviceaccount:${var.backup_service_account_namespace}:${var.backup_service_account_name}"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = local.create_irsa ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = aws_iam_policy.backup.arn
}
