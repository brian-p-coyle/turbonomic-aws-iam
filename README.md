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
| `variables.tf` | All input variables with defaults |
| `main.tf` | Management account IAM policy and role |
| `member_role.tf` | Cross-account IAM policy and role for each member account |
| `outputs.tf` | Outputs the role ARNs needed to configure Turbonomic |

---

## Prerequisites

- Terraform `>= 1.3.0`
- AWS provider `>= 5.0`
- AWS credentials configured for the **management account** (the account where the management role will be created)
- The AWS account ID where Turbonomic is deployed

---

## Usage

### 1. Clone the repo

```bash
git clone https://github.com/brian-p-coyle/turbonomic-aws-iam.git
cd turbonomic-aws-iam
```

### 2. Create a `terraform.tfvars` file

```hcl
turbonomic_account_id = "123456789012"    # AWS account where Turbonomic is deployed
management_account_id = "111111111111"    # Your AWS Organizations management account
member_account_ids    = ["222222222222", "333333333333"]
external_id           = "your-secret-external-id"   # Recommended for third-party access
```

> **Tip:** Never commit `terraform.tfvars` if it contains sensitive values. Add it to `.gitignore`.

### 3. Initialise and apply

```bash
terraform init
terraform plan
terraform apply
```

### 4. Note the outputs

```
management_role_arn  = "arn:aws:iam::111111111111:role/TurbonomicMonitorRole"
management_policy_arn = "arn:aws:iam::111111111111:policy/TurbonomicMonitorPolicy"
member_role_arns = {
  "222222222222" = "arn:aws:iam::222222222222:role/TurbonomicCrossAccountMonitorRole"
  "333333333333" = "arn:aws:iam::333333333333:role/TurbonomicCrossAccountMonitorRole"
}
```

Enter the `management_role_arn` in the Turbonomic UI when adding your AWS target.

---

## Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `turbonomic_account_id` | `string` | — | AWS account ID where Turbonomic is deployed |
| `management_account_id` | `string` | — | AWS Organizations management account ID |
| `member_account_ids` | `list(string)` | `[]` | Member account IDs to create cross-account roles in |
| `management_role_name` | `string` | `TurbonomicMonitorRole` | Name of the management account IAM role |
| `member_role_name` | `string` | `TurbonomicCrossAccountMonitorRole` | Name of the member account IAM role |
| `policy_name` | `string` | `TurbonomicMonitorPolicy` | Name prefix for the IAM policies |
| `external_id` | `string` | `""` | External ID for the role trust policy (recommended) |
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

For large organisations with many member accounts, consider using the AWS-provided **CloudFormation StackSets** templates instead of this Terraform `for_each` approach:

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
