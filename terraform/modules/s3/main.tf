resource "aws_s3_bucket" "application" {
  bucket = "${var.project}-${var.environment}-application-${var.bucket_suffix}"

  tags = {
    Name        = "${var.project}-${var.environment}-application"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "application" {
  bucket = aws_s3_bucket.application.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "application" {
  bucket = aws_s3_bucket.application.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "application" {
  description             = "${var.project}-${var.environment} application S3 encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Name        = "${var.project}-${var.environment}-s3-kms-key"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "application" {
  name          = "alias/${var.project}-${var.environment}-s3"
  target_key_id = aws_kms_key.application.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "application" {
  bucket = aws_s3_bucket.application.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.application.arn
    }
  }
}