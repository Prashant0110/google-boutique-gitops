module "ec2_ssm" {
  source = "../../modules/ec2-ssm"

  project     = "google-boutique"
  environment = "dev"

  ssm_policy_arn      = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ecr_read_policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

moved {
  from = aws_iam_role.ec2_ssm
  to   = module.ec2_ssm.aws_iam_role.ec2_ssm
}

moved {
  from = aws_iam_role_policy_attachment.ec2_ssm
  to   = module.ec2_ssm.aws_iam_role_policy_attachment.ec2_ssm
}

moved {
  from = aws_iam_instance_profile.ec2_ssm
  to   = module.ec2_ssm.aws_iam_instance_profile.ec2_ssm
}

moved {
  from = aws_iam_role_policy_attachment.ec2_ecr_read
  to   = module.ec2_ssm.aws_iam_role_policy_attachment.ec2_ecr_read
}
