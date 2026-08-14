resource "aws_iam_user" "kind_image_updater" {
  name = "google-boutique-kind-image-updater"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Purpose     = "Argo CD Image Updater ECR access"
  }
}

data "aws_iam_policy_document" "kind_image_updater_ecr_read" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages"
    ]

    resources = [
      module.frontend_ecr.repository_arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "kind_image_updater_ecr_read" {
  name = "ecr-read-only"
  user = aws_iam_user.kind_image_updater.name

  policy = data.aws_iam_policy_document.kind_image_updater_ecr_read.json
}

resource "aws_iam_access_key" "kind_image_updater" {
  user = aws_iam_user.kind_image_updater.name
}

output "image_updater_access_key_id" {
  value       = aws_iam_access_key.kind_image_updater.id
  description = "Access key ID for the Kind Image Updater IAM user"
}

output "image_updater_secret_access_key" {
  value       = aws_iam_access_key.kind_image_updater.secret
  description = "Secret access key for the Kind Image Updater IAM user"
  sensitive   = true
}