
module "frontend_autoscaling" {
  source = "../../modules/autoscaling"

  project     = "google-boutique"
  environment = "dev"

  instance_type    = "t3.micro"
  root_volume_size = 8

  security_group_ids = [
    module.security_group.ec2_security_group_id
  ]

  instance_profile_name = module.ec2_ssm.instance_profile_name

  # Launch Template user_data must be base64-encoded.
  user_data = filebase64("${path.module}/scripts/ec2-init.sh")

  subnet_ids = [
    module.networking.private_subnet_1_id,
    module.networking.private_subnet_2_id
  ]

  target_group_arns = [
    module.frontend_alb.target_group_arn
  ]

  min_size               = 2
  desired_capacity       = 2
  max_size               = 4
  target_cpu_utilization = 60
}
