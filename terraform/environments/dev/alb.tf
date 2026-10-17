
module "frontend_alb" {
  source = "../../modules/alb"

  project     = "google-boutique"
  environment = "dev"

  vpc_id = module.networking.vpc_id

  subnet_ids = [
    module.networking.public_subnet_1_id,
    module.networking.public_subnet_2_id
  ]

  security_group_id = module.security_group.alb_security_group_id

  target_port       = 8080
  listener_port     = 80
  health_check_path = "/"

  # HTTP forwards directly to the target group in this demo.
  # Supply an ACM certificate ARN to enable HTTPS and redirect HTTP.
  certificate_arn = ""
}

output "alb_dns_name" {
  description = "DNS name of the public Application Load Balancer."
  value       = module.frontend_alb.alb_dns_name
}
