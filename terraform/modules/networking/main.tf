# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "dev" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ============================================================
# PUBLIC SUBNETS
# ============================================================

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.public_subnet_1_az
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project}-${var.environment}-public-1"
    Environment = var.environment
    Tier        = "public"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.public_subnet_2_az
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project}-${var.environment}-public-2"
    Environment = var.environment
    Tier        = "public"
    ManagedBy   = "terraform"
  }
}

# ============================================================
# PRIVATE SUBNETS
# ============================================================

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.private_subnet_1_az

  tags = {
    Name        = "${var.project}-${var.environment}-private-1"
    Environment = var.environment
    Tier        = "private"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.private_subnet_2_az

  tags = {
    Name        = "${var.project}-${var.environment}-private-2"
    Environment = var.environment
    Tier        = "private"
    ManagedBy   = "terraform"
  }
}

# ============================================================
# INTERNET GATEWAY
# ============================================================

resource "aws_internet_gateway" "dev" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name        = "${var.project}-${var.environment}-igw"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ============================================================
# PUBLIC ROUTE TABLE
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev.id
  }

  tags = {
    Name        = "${var.project}-${var.environment}-public-rt"
    Environment = var.environment
    Tier        = "public"
    ManagedBy   = "terraform"
  }
}

# ============================================================
# PUBLIC ROUTE TABLE ASSOCIATIONS
# ============================================================

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


# ============================================================
# PRIVATE ROUTE TABLES
# ============================================================

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name        = "${var.project}-${var.environment}-private-1-rt"
    Environment = var.environment
    Tier        = "private"
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name        = "${var.project}-${var.environment}-private-2-rt"
    Environment = var.environment
    Tier        = "private"
    ManagedBy   = "terraform"
  }
}

# ============================================================
# PRIVATE ROUTE TABLE ASSOCIATIONS
# ============================================================

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

# ==================NAT==========================================

# resource "aws_eip" "nat" {
#   domain = "vpc"
#
#   tags = {
#     Name        = "${var.project}-${var.environment}-nat-eip"
#     Environment = var.environment
#     ManagedBy   = "terraform"
#   }
# }

# resource "aws_nat_gateway" "dev" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public_1.id
#
#   tags = {
#     Name        = "${var.project}-${var.environment}-nat"
#     Environment = var.environment
#     ManagedBy   = "terraform"
#   }
# }

# ============================================================
# PRIVATE ROUTE -> NAT GATEWAY
# ============================================================
#
# Enable these routes when the NAT Gateway above is enabled.
#
# resource "aws_route" "private_1_nat" {
#   route_table_id         = aws_route_table.private_1.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.dev.id
# }
#
# resource "aws_route" "private_2_nat" {
#   route_table_id         = aws_route_table.private_2.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.dev.id
# }