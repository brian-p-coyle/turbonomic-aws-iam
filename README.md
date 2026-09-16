# Turbonomic AWS IAM Terraform

Terraform module that creates the minimum IAM policy and role required for [IBM Turbonomic](https://www.ibm.com/docs/en/tarm/8.21.0?topic=aws-reference-permissions) to perform **read-only monitoring** across an **AWS Organizations multi-account** environment.

> **One `terraform apply` in the management account. No per-member-account code.**

---

## How it works

```
Turbonomic Account
  └── sts:AssumeRole ──▶ TurbonomicMonitorRole (management account)
                               │
                               ├── Discovers all accounts via organizations:ListAccounts
                               └── sts:AssumeRole ──▶ any member account role that trusts this ARN
```

The management role trust policy uses `aws:PrincipalOrgID` to restrict callers to principals inside your AWS Organization. This means:

- **One role, one policy, one `terraform apply`** — no per-account provider aliases or copy-pasted resource blocks.
- **New member accounts are covered automatically** — no Terraform changes needed when accounts are added to the org.

---

## Files

| File | Description |
|---|---|
| `provider.tf` | Single AWS provider for the management account |
| `variables.tf` | All input variables with defaults |
| `main.tf` | IAM policy and role (all resources) |
| `outputs.tf` | Role ARN to enter in Turbonomic |
| `terraform.tfvars.example` | Example values — copy to `terraform.tfvars` and fill in |

---

## Prerequisites

- Terraform `>= 1.3.0`
- AWS credentials with IAM write permissions in the **management account**
- Your AWS Organizations ID (e.g. `o-xxxxxxxxxx`)
- The AWS account ID where Turbonomic is deployed

---

## Usage

### 1. Clone the repo

```bash
git clone https://github.com/brian-p-coyle/turbonomic-aws-iam.git
cd turbonomic-aws-iam
```

### 2. Set credentials for the management account

```bash
# Option A — named AWS CLI profile
export AWS_PROFILE=my-management-account-profile

# Option B — environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...   # required for temporary credentials
```

### 3. Create your tfvars file

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — you need three values:

```hcl
org_id                = "o-xxxxxxxxxx"    # your AWS Org ID
turbonomic_account_id = "123456789012"    # account where Turbonomic runs
aws_region            = "us-east-1"
```

Find your org ID with:
```bash
aws organizations describe-organization --query 'Organization.Id' --output text
```

### 4. Apply

```bash
terraform init
terraform plan
terraform apply
```

### 5. Hand the role ARN to your Turbonomic administrator

```
turbonomic_role_arn = "arn:aws:iam::111111111111:role/TurbonomicMonitorRole"
```

Enter this ARN in the Turbonomic UI under **Settings → Target Configuration → Add Target → AWS**.

---

## Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `org_id` | `string` | — | AWS Organizations ID (e.g. `o-xxxxxxxxxx`) |
| `turbonomic_account_id` | `string` | — | Account ID where Turbonomic is deployed |
| `aws_region` | `string` | `us-east-1` | AWS region for the provider |
| `management_role_name` | `string` | `TurbonomicMonitorRole` | Name of the IAM role |
| `policy_name` | `string` | `TurbonomicMonitorPolicy` | Name of the IAM policy |
| `external_id` | `string` | `""` | External ID for the trust policy (strongly recommended) |
| `tags` | `map(string)` | `{ManagedBy=Terraform, Application=Turbonomic}` | Tags on all resources |

---

## Outputs

| Name | Description |
|---|---|
| `turbonomic_role_arn` | Role ARN to enter in Turbonomic when adding the AWS target |
| `turbonomic_policy_arn` | ARN of the monitoring policy |

---

## Security notes

- **`external_id`** — generate a UUID (`uuidgen`) and set it here. Give the same value to your Turbonomic administrator to enter as the External ID when configuring the target. This prevents the [confused deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html).
- **`aws:PrincipalOrgID`** condition ensures only principals inside your org can assume the role, even if the Turbonomic account ID were somehow leaked.
- All permissions are **read-only**. No `ec2:Modify*`, `rds:Modify*`, or any mutating action is included.

---

## Permissions covered

| Service | What Turbonomic reads |
|---|---|
| Organizations | Account list, org ID, account tags |
| EC2 | Instances, AMIs, instance types, Spot pricing, Reserved Instances |
| Auto Scaling | Groups, launch configs, launch templates |
| EKS | Clusters, node groups |
| EBS | Volumes, volume status, modification history |
| RDS / Aurora | DB instances, clusters, reserved instances, blue/green deployments |
| Redshift | Provisioned clusters |
| CloudWatch | Metrics for all entity types |
| Performance Insights | RDS metrics |
| Savings Plans | Available plans and offering rates |
| Cost Explorer | RI and Savings Plans utilization |
| Pricing | Service and attribute metadata |
| S3 | Billing export bucket access |
| CloudTrail | EBS volume attach/detach history |

---

## Reference

- [IBM Turbonomic 8.21.0 — Reference: AWS permissions](https://www.ibm.com/docs/en/tarm/8.21.0?topic=aws-reference-permissions)
- [IBM Turbonomic — Connecting to AWS](https://www.ibm.com/docs/en/tarm/8.21.0?topic=targets-connecting-aws)

---

## License

Apache 2.0
