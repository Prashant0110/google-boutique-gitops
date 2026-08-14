module "frontend_ec2" {
  source = "../../modules/ec2"

  instance_type = "t3.micro"

  subnet_id = module.networking.public_subnet_1_id

  security_group_ids = [
    module.security_group.security_group_id
  ]

  user_data = file("${path.module}/scripts/ec2-init.sh")

  iam_instance_profile = module.ec2_ssm.instance_profile_name

  root_volume_size = 8

  project     = "google-boutique"
  environment = "dev"
}

moved {
  from = aws_instance.frontend
  to   = module.frontend_ec2.aws_instance.frontend
}