resource "aws_iam_user" "kind_image_updater" {
  name = var.user_name

  tags = {
    Environment = var.environment
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
      var.ecr_repository_arn
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
  name   = "ecr-read-only"
  user   = aws_iam_user.kind_image_updater.name
  policy = data.aws_iam_policy_document.kind_image_updater_ecr_read.json
}

resource "aws_iam_access_key" "kind_image_updater" {
  user = aws_iam_user.kind_image_updater.name
}
