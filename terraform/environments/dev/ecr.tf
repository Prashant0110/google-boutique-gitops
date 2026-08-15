module "frontend_ecr" {
  source = "../../modules/ecr"

  repository_name = "boutique-frontend"
  environment     = "dev"
  project         = "google-boutique"
}

module "paymentservice_ecr" {
  source = "../../modules/ecr"

  repository_name = "boutique-paymentservice"
  environment     = "dev"
  project         = "google-boutique"
}

moved {
  from = aws_ecr_repository.frontend
  to   = module.frontend_ecr.aws_ecr_repository.frontend
}

output "frontend_ecr_repository_url" {
  value       = module.frontend_ecr.repository_url
  description = "ECR repository URL for the Boutique frontend"
}

output "paymentservice_ecr_repository_url" {
  value       = module.paymentservice_ecr.repository_url
  description = "ECR repository URL for the Boutique paymentservice"
}