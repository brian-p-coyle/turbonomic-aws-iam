# ---------------------------------------------------------------------------
# Provider configuration
#
# CREDENTIALS
# -----------
# Authenticate as any identity with IAM write permissions in the
# management account before running terraform apply.
#
#   Option A — AWS named profile (recommended):
#     export AWS_PROFILE=my-management-account-profile
#
#   Option B — environment variables:
#     export AWS_ACCESS_KEY_ID=...
#     export AWS_SECRET_ACCESS_KEY=...
#     export AWS_SESSION_TOKEN=...   # required when using temporary credentials
#
# Only ONE provider is needed — the management account.
# Member accounts are covered automatically via the org-wide trust condition
# on the IAM role. No per-account provider aliases required.
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

provider "aws" {
  region = var.aws_region

  # Uncomment to use a named AWS CLI profile:
  # profile = "my-management-account-profile"
}
