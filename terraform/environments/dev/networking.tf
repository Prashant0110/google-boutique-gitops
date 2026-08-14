module "networking" {
  source = "../../modules/networking"

  vpc_cidr = "10.0.0.0/16"

  public_subnet_1_cidr = "10.0.1.0/24"
  public_subnet_2_cidr = "10.0.2.0/24"

  private_subnet_1_cidr = "10.0.11.0/24"
  private_subnet_2_cidr = "10.0.12.0/24"

  public_subnet_1_az = "us-west-2a"
  public_subnet_2_az = "us-west-2b"

  private_subnet_1_az = "us-west-2a"
  private_subnet_2_az = "us-west-2b"

  project     = "google-boutique"
  environment = "dev"
}

moved {
  from = aws_vpc.dev
  to   = module.networking.aws_vpc.dev
}

moved {
  from = aws_subnet.public_1
  to   = module.networking.aws_subnet.public_1
}

moved {
  from = aws_subnet.public_2
  to   = module.networking.aws_subnet.public_2
}

moved {
  from = aws_subnet.private_1
  to   = module.networking.aws_subnet.private_1
}

moved {
  from = aws_subnet.private_2
  to   = module.networking.aws_subnet.private_2
}

moved {
  from = aws_internet_gateway.dev
  to   = module.networking.aws_internet_gateway.dev
}

moved {
  from = aws_route_table.public
  to   = module.networking.aws_route_table.public
}

moved {
  from = aws_route_table_association.public_1
  to   = module.networking.aws_route_table_association.public_1
}

moved {
  from = aws_route_table_association.public_2
  to   = module.networking.aws_route_table_association.public_2
}