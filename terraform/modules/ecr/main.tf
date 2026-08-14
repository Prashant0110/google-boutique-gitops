resource "aws_ecr_repository" "frontend" {
  name                 = var.repository_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = var.repository_name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}