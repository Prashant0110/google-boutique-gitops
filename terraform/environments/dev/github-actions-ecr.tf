module "github_actions_ecr" {
  source = "../../modules/github-actions-ecr"

  github_oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  github_repository        = "Prashant0110/online-boutique-app"
  github_branch            = "main"
  ecr_repository_arn       = module.frontend_ecr.repository_arn
  role_name                = "github-actions-ecr"
  policy_name              = "github-actions-ecr-push"
}

moved {
  from = aws_iam_role.github_actions_ecr
  to   = module.github_actions_ecr.aws_iam_role.github_actions_ecr
}

moved {
  from = aws_iam_policy.github_actions_ecr
  to   = module.github_actions_ecr.aws_iam_policy.github_actions_ecr
}

moved {
  from = aws_iam_role_policy_attachment.github_actions_ecr
  to   = module.github_actions_ecr.aws_iam_role_policy_attachment.github_actions_ecr
}

output "github_actions_ecr_role_arn" {
  value = module.github_actions_ecr.role_arn
}
