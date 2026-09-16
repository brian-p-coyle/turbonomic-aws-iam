# Turbonomic AWS IAM Terraform

Terraform module that creates the minimum IAM policies and roles required for [IBM Turbonomic](https://www.ibm.com/docs/en/tarm/8.21.0?topic=aws-reference-permissions) to monitor AWS workloads in an **AWS Organizations multi-account** setup.

> **Permissions scope:** Read-only / workload monitoring only. No action-execution permissions are included.

---

## Architecture

```
Turbonomic Account
  └── assumes ──▶ TurbonomicMonitorRole (management account)
                        └── assumes ──▶ TurbonomicCrossAccountMonitorRole (each member account)
```

- **Management account role** — full monitoring policy covering Organizations, EC2, EKS, EBS, RDS, Aurora, Redshift, CloudWatch, Savings Plans, Cost Explorer, Pricing, and billing S3.
- **Member account roles** — trimmed monitoring policy (org-level, pricing, billing, and Cost Explorer actions are management-account-only and are excluded).

---

## Files

| File | Description |
|---|---|
| `provider.tf` | AWS provider configuration — default (management account) + per-member-account aliases |
| `variables.tf` | All input variables with defaults |
| `main.tf` | Management account IAM policy and role |
| `member_role.tf` | Cross-account IAM policy and role for each member account |
| `outputs.tf` | Outputs the role ARNs needed to configure Turbonomic |
| `terraform.tfvars.example` | Example values file — copy to `terraform.tfvars` and fill in |

---

## Prerequisites

- Terraform `>= 1.3.0`
- AWS provider `>= 5.0`
- AWS credentials with IAM write permissions in the **management account**
- An existing IAM role in each **member account** that can be assumed by Terraform (typically `OrganizationAccountAccessRole`)
- The AWS account ID where Turbonomic is deployed

---

## Usage

### 1. Clone the repo

```bash
git clone https://github.com/brian-p-coyle/turbonomic-aws-iam.git
cd turbonomic-aws-iam
```

### 2. Configure credentials

Set your management account credentials via environment variable or AWS profile:

```bash
# Option A — AWS named profile
export AWS_PROFILE=my-management-account-profile

# Option B — environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...   # if using temporary credentials
```

### 3. Create your tfvars file

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your real account IDs
```

### 4. Update provider.tf for your member accounts

Open `provider.tf` and replace the example account IDs (`222222222222`, `333333333333`) with your real member account IDs. Add or remove provider blocks to match.

Then open `member_role.tf` and do the same — each provider alias needs a corresponding policy + role + attachment block.

### 5. Initialise and apply

```bash
terraform init
terraform plan
terraform apply
```

### 6. Note the outputs

```
management_role_arn   = "arn:aws:iam::111111111111:role/TurbonomicMonitorRole"
management_policy_arn = "arn:aws:iam::111111111111:policy/TurbonomicMonitorPolicy"
member_role_arns = {
  "222222222222" = "arn:aws:iam::222222222222:role/TurbonomicCrossAccountMonitorRole"
  "333333333333" = "arn:aws:iam::333333333333:role/TurbonomicCrossAccountMonitorRole"
}
```

Enter the `management_role_arn` in the Turbonomic UI when adding your AWS target.

---

## Adding a new member account

1. Add a new provider block in `provider.tf`:
   ```hcl
   provider "aws" {
     alias  = "member_444444444444"
     region = var.aws_region
     assume_role {
       role_arn = "arn:aws:iam::444444444444:role/${var.member_assume_role_name}"
     }
   }
   ```

2. Copy one of the existing member account blocks in `member_role.tf` and update the account ID suffix and provider alias reference.

3. Add the new account ARN to the `member_role_arns` output in `outputs.tf`.

4. Add the account ID to `member_account_ids` in `terraform.tfvars`.

---

## Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | AWS region for the provider |
| `turbonomic_account_id` | `string` | — | AWS account ID where Turbonomic is deployed |
| `management_account_id` | `string` | — | AWS Organizations management account ID |
| `member_account_ids` | `list(string)` | `[]` | Member account IDs (informational, used in descriptions) |
| `member_assume_role_name` | `string` | `OrganizationAccountAccessRole` | Existing role Terraform assumes in member accounts |
| `management_role_name` | `string` | `TurbonomicMonitorRole` | Name of the management account IAM role |
| `member_role_name` | `string` | `TurbonomicCrossAccountMonitorRole` | Name of the member account IAM role |
| `policy_name` | `string` | `TurbonomicMonitorPolicy` | Name prefix for the IAM policies |
| `external_id` | `string` | `""` | External ID for role trust policies (strongly recommended) |
| `tags` | `map(string)` | `{ManagedBy=Terraform, Application=Turbonomic}` | Tags applied to all IAM resources |

---

## Outputs

| Name | Description |
|---|---|
| `management_role_arn` | ARN of the management account role — enter this in Turbonomic |
| `management_policy_arn` | ARN of the management account monitoring policy |
| `member_role_arns` | Map of `account_id → role ARN` for all member accounts |

---

## Member accounts at scale

For large organisations with many member accounts, consider using the AWS-provided **CloudFormation StackSets** templates instead of the per-account provider alias pattern:

| Template | Download |
|---|---|
| Member account — monitor + execute | [cloud_formation_organization_role_execution_template.yml](https://public-cf-prod-us-east-1.s3.amazonaws.com/cloud_formation_organization_role_execution_template.yml) |
| Member account — monitor only | [cloud_formation_organization_role_monitor_template.yml](https://public-cf-prod-us-east-1.s3.amazonaws.com/cloud_formation_organization_role_monitor_template.yml) |

---

## Reference

- [IBM Turbonomic 8.21.0 — Reference: AWS permissions](https://www.ibm.com/docs/en/tarm/8.21.0?topic=aws-reference-permissions)
- [IBM Turbonomic — Setting up an AWS cross-account IAM role](https://www.ibm.com/docs/en/tarm/8.21.0?topic=aws-setting-up-cross-account-iam-role)

---

## License

Apache 2.0
