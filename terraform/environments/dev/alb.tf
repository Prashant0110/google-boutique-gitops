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

  target_id = module.frontend_ec2.instance_id

  target_port   = 80
  listener_port = 80

  health_check_path = "/"
  certificate_arn   = ""
}

output "alb_dns_name" {
  description = "DNS name of the public Application Load Balancer."
  value       = module.frontend_alb.alb_dns_name
}
