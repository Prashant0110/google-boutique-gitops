output "role_arn" {
  description = "ARN of the GitHub Actions ECR IAM role"
  value       = aws_iam_role.github_actions_ecr.arn
}
