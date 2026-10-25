output "alb_security_group_id" {
  description = "Security group ID for the public ALB"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "Security group ID for the private application EC2"
  value       = aws_security_group.ec2.id
}


output "security_group_id" {
  description = "Backward-compatible output for the application EC2 security group"
  value       = aws_security_group.ec2.id
}

output "security_group_name" {
  description = "Name of the application EC2 security group"
  value       = aws_security_group.ec2.name
}