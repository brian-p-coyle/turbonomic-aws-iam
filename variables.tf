variable "aws_region" {
  description = "AWS region for the provider. IAM is global but a region is required by the AWS provider."
  type        = string
  default     = "us-east-1"
}

variable "org_id" {
  description = "AWS Organizations ID (e.g. o-xxxxxxxxxx). Used to scope the role trust policy to your org only."
  type        = string
}

variable "turbonomic_account_id" {
  description = "AWS account ID where IBM Turbonomic is deployed. The management role will trust this account to call sts:AssumeRole."
  type        = string
}

variable "management_role_name" {
  description = "Name for the Turbonomic IAM role created in the management account."
  type        = string
  default     = "TurbonomicMonitorRole"
}

variable "policy_name" {
  description = "Name for the Turbonomic monitoring IAM policy."
  type        = string
  default     = "TurbonomicMonitorPolicy"
}

variable "external_id" {
  description = "External ID added to the role trust policy. Strongly recommended when granting third-party access. Use a UUID or hard-to-guess string."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all IAM resources created by this module."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Application = "Turbonomic"
  }
}
