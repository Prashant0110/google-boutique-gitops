data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project}-${var.environment}-ec2-ssm-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "${var.project}-${var.environment}-ec2-ssm-role"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = var.ssm_policy_arn
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_read" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = var.ecr_read_policy_arn
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.project}-${var.environment}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}
