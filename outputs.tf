output "management_role_arn" {
  description = "ARN of the Turbonomic IAM role in the management account. Enter this in Turbonomic when adding the AWS target."
  value       = aws_iam_role.turbonomic_management.arn
}

output "management_policy_arn" {
  description = "ARN of the Turbonomic monitoring IAM policy attached to the management account role."
  value       = aws_iam_policy.turbonomic_monitor.arn
}

output "member_role_arns" {
  description = "Map of member account ID to cross-account role ARN. These are the roles Turbonomic assumes in each member account."
  value = {
    (local.member_222) = aws_iam_role.turbonomic_member_222.arn
    (local.member_333) = aws_iam_role.turbonomic_member_333.arn
  }
}
