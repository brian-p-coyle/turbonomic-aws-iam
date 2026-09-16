# ---------------------------------------------------------------------------
# Provider configuration
#
# HOW AUTHENTICATION WORKS
# -------------------------
# The default provider runs as your management account identity (IAM user or
# assumed role). It creates the management account policy and role in main.tf.
#
# Each member account provider assumes the management account role first, then
# assumes into each member account using the cross-account role name you
# configure below. This mirrors the exact trust chain Turbonomic uses at
# runtime.
#
# CREDENTIALS
# -----------
# Set one of the following before running terraform apply:
#
#   Option A — AWS profile (recommended):
#     export AWS_PROFILE=my-management-account-profile
#
#   Option B — environment variables:
#     export AWS_ACCESS_KEY_ID=...
#     export AWS_SECRET_ACCESS_KEY=...
#     export AWS_SESSION_TOKEN=...        # if using temporary credentials
#
#   Option C — fill in the profile argument directly in this file (not
#     recommended for shared repos).
#
# ADDING MORE MEMBER ACCOUNTS
# ---------------------------
# For each additional member account:
#   1. Add a new provider block with a unique alias (e.g. "member_444444444444")
#   2. Add a corresponding aws_iam_policy + aws_iam_role + attachment block in
#      member_role.tf referencing that alias.
#   3. Add the account ID to var.member_account_ids in terraform.tfvars.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Default provider — management account
# ---------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  # Uncomment and set if using a named AWS CLI profile:
  # profile = "my-management-account-profile"
}

# ---------------------------------------------------------------------------
# Member account providers
#
# Each alias corresponds to one member account. The provider assumes the
# management account role (created by main.tf) and then the cross-account
# role in the target member account.
#
# Replace the role_arn account IDs with your actual member account IDs.
# Add or remove blocks to match your var.member_account_ids list.
# ---------------------------------------------------------------------------

provider "aws" {
  alias  = "member_222222222222"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/${var.member_assume_role_name}"
  }
}

provider "aws" {
  alias  = "member_333333333333"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::333333333333:role/${var.member_assume_role_name}"
  }
}

# Add more blocks here for additional member accounts, e.g.:
# provider "aws" {
#   alias  = "member_444444444444"
#   region = var.aws_region
#   assume_role {
#     role_arn = "arn:aws:iam::444444444444:role/${var.member_assume_role_name}"
#   }
# }
