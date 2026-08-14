output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.frontend.id
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.frontend.private_ip
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.frontend.public_ip
}