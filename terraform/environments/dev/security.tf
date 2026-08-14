module "security_group" {
  source = "../../modules/security-group"

  vpc_id = module.networking.vpc_id

  project     = "google-boutique"
  environment = "dev"
}

moved {
  from = aws_security_group.web
  to   = module.security_group.aws_security_group.web
}
