
output "autoscaling_group_name" {
  description = "Name of the frontend Auto Scaling Group."
  value       = aws_autoscaling_group.frontend.name
}

output "launch_template_id" {
  description = "ID of the frontend EC2 Launch Template."
  value       = aws_launch_template.frontend.id
}

output "launch_template_latest_version" {
  description = "Latest version of the frontend EC2 Launch Template."
  value       = aws_launch_template.frontend.latest_version
}

output "autoscaling_policy_arn" {
  description = "ARN of the CPU target-tracking scaling policy."
  value       = aws_autoscaling_policy.frontend_cpu.arn
}
