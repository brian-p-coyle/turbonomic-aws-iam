variable "aws_region" {
  description = "AWS region for the provider. IAM is global but a region is required by the AWS provider."
  type        = string
  default     = "us-east-1"
}

variable "member_assume_role_name" {
  description = "Name of an existing IAM role in each member account that Terraform can assume to create IAM resources. Typically OrganizationAccountAccessRole."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "turbonomic_account_id" {
  description = "AWS account ID where Turbonomic is deployed. The management account role will trust this account."
  type        = string
}

variable "management_account_id" {
  description = "AWS account ID for the Organizations management (payer) account."
  type        = string
}

variable "member_account_ids" {
  description = "List of AWS member account IDs that Turbonomic will monitor via cross-account roles."
  type        = list(string)
  default     = []
}

variable "management_role_name" {
  description = "Name for the Turbonomic IAM role created in the management account."
  type        = string
  default     = "TurbonomicMonitorRole"
}

variable "member_role_name" {
  description = "Name for the Turbonomic cross-account IAM role created in each member account."
  type        = string
  default     = "TurbonomicCrossAccountMonitorRole"
}

variable "policy_name" {
  description = "Name for the Turbonomic monitoring IAM policy."
  type        = string
  default     = "TurbonomicMonitorPolicy"
}

variable "external_id" {
  description = "External ID used as an additional trust condition on the cross-account roles (recommended for third-party access)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all IAM resources."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Application = "Turbonomic"
  }
}
