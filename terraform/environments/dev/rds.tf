module "rds" {
  source = "../../modules/rds"

  vpc_id = module.networking.vpc_id

  subnet_ids = [
    module.networking.private_subnet_1_id,
    module.networking.private_subnet_2_id
  ]

  project     = "google-boutique"
  environment = "dev"

  db_name = "boutique"

  username = var.rds_username
  password = var.rds_password

  instance_class    = "db.t3.micro"
  allocated_storage = 20

  allowed_security_group_ids = [
    module.security_group.security_group_id
  ]
}