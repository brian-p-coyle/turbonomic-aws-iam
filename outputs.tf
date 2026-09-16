output "turbonomic_role_arn" {
  description = "ARN of the Turbonomic monitoring role. Enter this in the Turbonomic UI when adding your AWS target."
  value       = aws_iam_role.turbonomic_monitor.arn
}

output "turbonomic_policy_arn" {
  description = "ARN of the Turbonomic monitoring IAM policy."
  value       = aws_iam_policy.turbonomic_monitor.arn
}
