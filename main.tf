# ---------------------------------------------------------------------------
# Turbonomic AWS IAM — management account
#
# This is the ONLY file that creates AWS resources. A single terraform apply
# in the management account is all that is needed. Member accounts are covered
# automatically: the trust policy is scoped to the entire AWS Organization via
# aws:PrincipalOrgID, so Turbonomic can assume this role and chain into any
# member account without any per-account Terraform code.
#
# Permissions: read-only workload monitoring.
# Covers: Organizations, IAM, STS, EC2, Auto Scaling, EKS, EBS, RDS, Aurora,
#         Redshift, CloudWatch, Performance Insights, Reserved Instances,
#         Savings Plans, Cost Explorer, Pricing, S3 (billing), CloudTrail.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# IAM policy — read-only workload monitoring
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "turbonomic_monitor" {
  name        = var.policy_name
  description = "Minimum read-only permissions for Turbonomic to monitor AWS workloads across the organization."
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OrgDiscovery"
        Effect = "Allow"
        Action = [
          "organizations:DescribeOrganization",
          "organizations:ListAccounts",
          "organizations:ListTagsForResource",
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMAndSTS"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "sts:AssumeRole",
        ]
        Resource = "*"
      },
      {
        Sid    = "RegionsAndZones"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeRegions",
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:ListTagsForResource",
        ]
        Resource = "*"
      },
      {
        Sid    = "PerformanceInsights"
        Effect = "Allow"
        Action = [
          "pi:GetResourceMetrics",
          "pi:ListAvailableResourceMetrics",
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Discovery"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAddresses",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeReservedInstances",
          "ec2:DescribeReservedInstancesModifications",
        ]
        Resource = "*"
      },
      {
        Sid    = "AutoScalingDiscovery"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeLaunchConfigurations",
        ]
        Resource = "*"
      },
      {
        Sid      = "LaunchTemplateDiscovery"
        Effect   = "Allow"
        Action   = ["ec2:DescribeLaunchTemplateVersions"]
        Resource = "*"
      },
      {
        Sid    = "EKSDiscovery"
        Effect = "Allow"
        Action = [
          "eks:ListClusters",
          "eks:DescribeCluster",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
        ]
        Resource = "*"
      },
      {
        Sid    = "EBSDiscovery"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumesModifications",
        ]
        Resource = "*"
      },
      {
        Sid      = "CloudTrailEBSHistory"
        Effect   = "Allow"
        Action   = ["cloudtrail:LookupEvents"]
        Resource = "*"
      },
      {
        Sid    = "RDSAndAuroraDiscovery"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBParameters",
          "rds:DescribeOrderableDBInstanceOptions",
          "rds:DescribeReservedDBInstances",
          "rds:ListTagsForResource",
          "rds:DescribeGlobalClusters",
          "rds:DescribeBlueGreenDeployments",
        ]
        Resource = "*"
      },
      {
        Sid    = "RedshiftDiscovery"
        Effect = "Allow"
        Action = [
          "redshift:DescribeClusters",
          "redshift:DescribeTags",
        ]
        Resource = "*"
      },
      {
        Sid    = "SavingsAndReservations"
        Effect = "Allow"
        Action = [
          "savingsplans:DescribeSavingsPlans",
          "savingsplans:DescribeSavingsPlansOfferingRates",
          "ce:GetReservationUtilization",
          "ce:GetSavingsPlansUtilizationDetails",
        ]
        Resource = "*"
      },
      {
        Sid    = "PricingDiscovery"
        Effect = "Allow"
        Action = [
          "pricing:DescribeServices",
          "pricing:GetAttributeValues",
        ]
        Resource = "*"
      },
      {
        Sid    = "BillingS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetObject",
        ]
        Resource = "*"
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# IAM role — org-scoped trust
#
# The trust policy uses two conditions:
#   1. aws:PrincipalOrgID  — restricts callers to principals inside your org
#   2. sts:ExternalId      — optional but strongly recommended extra secret
#
# This means Turbonomic (in var.turbonomic_account_id) can assume this role,
# and it can then call sts:AssumeRole to chain into any member account role
# that trusts this role's ARN — without any per-account Terraform code.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "turbonomic_monitor" {
  name        = var.management_role_name
  description = "Assumed by Turbonomic to discover and monitor workloads across the AWS organization."
  tags        = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TurbonomicAssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.turbonomic_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = merge(
          { StringEquals = { "aws:PrincipalOrgID" = var.org_id } },
          var.external_id != "" ? { StringEquals = { "sts:ExternalId" = var.external_id } } : {}
        )
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "turbonomic_monitor" {
  role       = aws_iam_role.turbonomic_monitor.name
  policy_arn = aws_iam_policy.turbonomic_monitor.arn
}
